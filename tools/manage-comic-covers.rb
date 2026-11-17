#!/usr/bin/env ruby
# frozen_string_literal: true

# Manage local WebP comic book covers for bruchez.name.
#
# Usage examples:
#   ruby tools/manage-comic-covers.rb --status --year 2026
#   ruby tools/manage-comic-covers.rb --inbox
#   ruby tools/manage-comic-covers.rb --clipboard thorgal-43-la-vengeance-de-la-deesse-skaedhi
#   ruby tools/manage-comic-covers.rb --set lefranc-36-la-regate ~/Downloads/regate.jpg
#   ruby tools/manage-comic-covers.rb --fetch-online --year 2026

require 'yaml'
require 'json'
require 'uri'
require 'net/http'
require 'fileutils'
require 'tmpdir'
require 'open3'
require 'optparse'
require 'nokogiri'

ROOT = File.expand_path('..', __dir__)
DATA_DIR = File.join(ROOT, '_data', 'comics')
COVERS_DIR = File.join(ROOT, 'assets', 'pages', 'comic-books', 'covers')
INBOX_DIR = File.join(ROOT, '_covers_inbox')

STOPWORDS = %w[
  le la les un une des du de d l au aux et en dans sur sous pour par avec sans
  the a an of in on at to and or by from tome vol volume int integrale edition
  bd aventures histoire stories complete
].freeze

PUBLISHER_OG_HOSTS = %w[
  www.fantagraphics.com
  fantagraphics.com
  shop.sergiobonelli.it
  www.lustiges-taschenbuch.de
  lustiges-taschenbuch.de
  www.panini.it
].freeze

def normalize_tokens(str)
  s = str.to_s
         .gsub(/Æ/i, 'ae')
         .gsub(/Œ/i, 'oe')
         .gsub(/ß/, 'ss')
         .gsub(/Ø/i, 'o')
         .unicode_normalize(:nfd)
         .gsub(/\p{Mn}/, '')
         .downcase
  s.scan(/[a-z0-9]+/)
end

def significant_tokens(str)
  normalize_tokens(str).reject { |t| STOPWORDS.include?(t) || t.length < 2 }
end

def extract_volume_markers(title)
  t = title.to_s
  markers = []
  if (m = t.match(/\b(?:integrale|int)\s*0*(\d+)\b/i))
    markers << [:integrale, m[1].to_i]
  end
  if (m = t.match(/(?:\btome|\bvol\.?|\bn\.?|-)\s*(-?\d{1,5})\./i))
    markers << [:tome, m[1].to_i]
  elsif (m = t.match(/\b(?:tome|vol\.?)\s*(-?\d{1,5})\b/i))
    markers << [:tome, m[1].to_i]
  elsif (m = t.match(/\)\s*(\d{1,2})\.\s*\d{4}/))
    markers << [:tome, m[1].to_i]
  end
  markers
end

def load_all_years(filter_year = nil)
  paths = Dir.glob(File.join(DATA_DIR, '*.yml')).sort.reverse
  paths.select! { |p| File.basename(p, '.yml') == filter_year.to_s } if filter_year
  paths.map do |p|
    yr = File.basename(p, '.yml')
    entries = YAML.safe_load(File.read(p), permitted_classes: [Date]) || []
    [yr, p, entries]
  end
end

def save_year_yaml(year, path, entries)
  yaml_str = YAML.dump(entries, line_width: 100).sub(/\A---\s*\n/, '')
  File.write(path, "# Comic book reads for #{year}\n#{yaml_str}")
end

def find_entry_across_years(entry_id)
  load_all_years.each do |yr, path, entries|
    idx = entries.index { |e| e['id'] == entry_id }
    return [yr, path, entries, entries[idx]] if idx
  end
  nil
end

def convert_to_webp(src_path, dest_path)
  FileUtils.mkdir_p(File.dirname(dest_path))
  magick_bin = ['/opt/homebrew/bin/magick', '/usr/local/bin/magick', 'magick'].find do |bin|
    system('which', bin, out: File::NULL, err: File::NULL) || File.executable?(bin)
  end

  if magick_bin
    cmd = [
      magick_bin, src_path,
      '-auto-orient',
      '-resize', '600x900>',
      '-strip',
      '-quality', '82',
      dest_path
    ]
    _out, err, status = Open3.capture3(*cmd)
    raise "ImageMagick failed: #{err}" unless status.success? && File.exist?(dest_path)
  else
    raise 'ImageMagick (magick) not found in PATH'
  end
end

ResultHTTP = Struct.new(:code, :body, :content_type)

def http_get(url_str, _limit = 4)
  out, _err, status = Open3.capture3(
    'curl', '-sSL',
    '--max-time', '12',
    '-A', 'BruchezNameComicCovers/1.0 (https://blog.bruchez.name; mailto:erik@bruchez.org)',
    '-w', "\n__META__:%{http_code}:%{content_type}",
    url_str
  )
  return nil unless status.success? && out.include?("\n__META__:")

  body, meta = out.rpartition("\n__META__:").values_at(0, 2)
  code, ctype = meta.to_s.strip.split(':', 2)
  return nil unless code == '200' && body.bytesize.positive?

  ResultHTTP.new(code, body, ctype.to_s)
rescue StandardError
  nil
end

def download_and_convert_image(img_url, dest_webp)
  res = http_get(img_url)
  return false unless res && res.body && res.body.bytesize > 1500

  ctype = res.content_type.to_s.downcase
  return false if ctype.include?('text/html')

  Dir.mktmpdir('comic-cover-') do |dir|
    ext = case ctype
          when /png/ then '.png'
          when /webp/ then '.webp'
          else '.jpg'
          end
    tmp_src = File.join(dir, "raw#{ext}")
    File.binwrite(tmp_src, res.body)
    convert_to_webp(tmp_src, dest_webp)
  end
  true
rescue StandardError => e
  warn "  ! Failed converting #{img_url}: #{e.message}"
  false
end

def fetch_publisher_og_image(entry)
  url = entry['url'].to_s.strip
  return nil if url.empty?

  uri = URI.parse(url)
  return nil unless PUBLISHER_OG_HOSTS.include?(uri.host&.downcase)

  res = http_get(url)
  return nil unless res

  doc = Nokogiri::HTML(res.body)
  og = doc.at_css('meta[property="og:image"]')&.[]('content') ||
       doc.at_css('meta[name="twitter:image"]')&.[]('content')
  return nil if og.nil? || og.strip.empty?

  og = og.strip.sub(%r{\A//}, 'https://').sub(%r{\Ahttp://}, 'https://')
  URI.join(url, og).to_s
rescue StandardError
  nil
end

def build_apple_books_query(entry)
  title = entry['title'].to_s
  cleaned_title = title
                  .gsub(/\(The complete\)\s*\(\d{4}\)/i, 'The Complete Peanuts')
                  .gsub(/\bINT0*(\d+)\.\s*/i, '')
                  .gsub(/\bTome\s+(-?\d+)\s*[:.]\s*/i, '\1 ')
                  .gsub(/\s+-\s+/, ' ')
                  .gsub(/[^\p{L}\p{N}\s'-]/, ' ')
                  .gsub(/\s+/, ' ')
                  .strip

  creators = Array(entry['authors']) + Array(entry['writers']) + Array(entry['artists'])
  primary_creator = creators.first.to_s.split.last # surname
  if !primary_creator.to_s.empty? && !cleaned_title.downcase.include?(primary_creator.downcase)
    "#{cleaned_title} #{primary_creator}".strip
  else
    cleaned_title
  end
end

def country_for_entry(entry)
  return 'us' if entry['title'].to_s.match?(/Peanuts|Uncle Scrooge|Donald Duck|Calvin and Hobbes/i)

  case entry['language'].to_s.downcase
  when 'italian' then 'it'
  when 'english' then 'us'
  when 'german'  then 'de'
  else 'fr'
  end
end

def candidate_matches_entry?(entry, track_name, artist_name)
  entry_title = entry['title'].to_s
  cand_title = track_name.to_s

  # 1. Check integrale / tome mismatch strictly
  entry_markers = extract_volume_markers(entry_title)
  cand_markers = extract_volume_markers(cand_title)

  if entry_markers.any? { |k, _| k == :integrale }
    return false unless cand_title.match?(/int[ée]grale|omnibus|complete|raccolta/i)
    int_num = entry_markers.find { |k, _| k == :integrale }[1]
    cand_nums = cand_title.scan(/\d+/).map(&:to_i)
    return false unless cand_nums.include?(int_num)
  elsif cand_title.match?(/\bint[ée]grale\b|\bcoffret\b|\bpack\b/i) && !entry_title.match?(/int[ée]grale/i)
    return false
  end

  if (tome_m = entry_markers.find { |k, _| k == :tome })
    expected_num = tome_m[1].abs
    if (cm = cand_markers.find { |k, _| k == :tome })
      return false unless cm[1].abs == expected_num
    end
  end

  # 2. Check significant token overlap, prioritizing subtitle tokens
  parts = entry_title.split(/\s*(?:-\s*(?:Tome\s*)?-?\d+[.:]?|:\s*|\.\s+)\s*/i).map(&:strip).reject(&:empty?)
  subtitle = parts.length > 1 ? parts.last : entry_title
  sub_tokens = significant_tokens(subtitle).reject { |t| t.match?(/\A\d+\z/) }
  all_entry_tokens = significant_tokens(entry_title).reject { |t| t.match?(/\A\d+\z/) }
  cand_tokens = normalize_tokens("#{cand_title} #{artist_name}")

  return false if all_entry_tokens.empty?

  unless sub_tokens.empty?
    matched_sub = sub_tokens.count { |t| cand_tokens.include?(t) }
    return false if matched_sub.to_f / sub_tokens.size < 0.75
  end

  matched_all = all_entry_tokens.count { |t| cand_tokens.include?(t) }
  ratio = matched_all.to_f / all_entry_tokens.size

  # 3. Verify creator or series alignment
  creators = (Array(entry['authors']) + Array(entry['writers']) + Array(entry['artists']))
  creator_surnames = creators.flat_map { |c| significant_tokens(c) }
  creator_hit = creator_surnames.empty? || creator_surnames.any? { | tok | cand_tokens.include?(tok) }

  series_tokens = significant_tokens(parts.first)
  series_hit = !series_tokens.empty? && series_tokens.all? { |t| cand_tokens.include?(t) }

  ratio >= 0.65 && (creator_hit || series_hit)
end

def search_apple_books_cover(entry)
  country = country_for_entry(entry)
  q = build_apple_books_query(entry)
  url = "https://itunes.apple.com/search?media=ebook&entity=ebook&country=#{country}&limit=6&term=#{URI.encode_www_form_component(q)}"
  res = http_get(url)
  return nil unless res

  results = JSON.parse(res.body)['results'] || []
  results.each do |r|
    next unless candidate_matches_entry?(entry, r['trackName'], r['artistName'])

    art = r['artworkUrl100'].to_s
    next if art.empty?

    return [art.sub(%r{/100x100bb\.(jpg|png)\z}i, '/600x600bb.\1'), "#{r['trackName']} (#{r['artistName']})"]
  end
  nil
rescue StandardError
  nil
end

def search_open_library_cover(entry)
  q = build_apple_books_query(entry)
  url = "https://openlibrary.org/search.json?q=#{URI.encode_www_form_component(q)}&limit=5&fields=title,author_name,cover_i"
  res = http_get(url)
  return nil unless res

  docs = JSON.parse(res.body)['docs'] || []
  docs.each do |d|
    next unless d['cover_i']
    authors_str = Array(d['author_name']).join(', ')
    next unless candidate_matches_entry?(entry, d['title'], authors_str)

    return ["https://covers.openlibrary.org/b/id/#{d['cover_i']}-L.jpg", "#{d['title']} (#{authors_str})"]
  end
  nil
rescue StandardError
  nil
end

def print_status(filter_year)
  load_all_years(filter_year).each do |yr, _path, entries|
    with_cover = entries.count { |e| e['cover'] && File.exist?(File.join(COVERS_DIR, File.basename(e['cover']))) }
    with_bede = entries.count { |e| e['bedetheque_url'] }
    with_rev = entries.count { |e| e['review'] }
    puts "=== #{yr}: #{entries.size} reads | #{with_cover} covers | #{with_bede} Bédéthèque | #{with_rev} visible reviews ==="
    next unless filter_year

    entries.each do |e|
      cov = e['cover'] && File.exist?(File.join(COVERS_DIR, File.basename(e['cover']))) ? '[COVER]' : '[     ]'
      bed = e['bedetheque_url'] ? '[BD]' : '[  ]'
      rev = e['review'] ? '[REV]' : (e['notes'] ? '[NTE]' : '[   ]')
      puts format('  %s %s %s %-48s %s', cov, bed, rev, e['id'][0, 48], e['title'])
    end
  end
end

def process_inbox
  FileUtils.mkdir_p(INBOX_DIR)
  files = Dir.glob(File.join(INBOX_DIR, '*.{jpg,jpeg,png,webp,heic,tif,tiff}'), File::FNM_CASEFOLD)
  if files.empty?
    puts "No images found in #{INBOX_DIR}. Drop <entry-id>.jpg/.png files there and re-run --inbox."
    return
  end

  processed_dir = File.join(INBOX_DIR, 'processed')
  FileUtils.mkdir_p(processed_dir)

  files.each do |src|
    id = File.basename(src, File.extname(src))
    found = find_entry_across_years(id)
    unless found
      warn "  ! No YAML entry found with id '#{id}' (skipping #{File.basename(src)})"
      next
    end

    yr, yml_path, entries, entry = found
    dest_name = "#{id}.webp"
    dest_path = File.join(COVERS_DIR, dest_name)
    convert_to_webp(src, dest_path)
    entry['cover'] = dest_name
    save_year_yaml(yr, yml_path, entries)
    FileUtils.mv(src, File.join(processed_dir, File.basename(src)))
    puts "  + Saved #{dest_name} (#{(File.size(dest_path) / 1024.0).round(1)} KB) -> #{yr}.yml"
  end
end

def set_cover_for_id(entry_id, source)
  found = find_entry_across_years(entry_id)
  abort "Error: No comic entry found with id '#{entry_id}'" unless found

  yr, yml_path, entries, entry = found
  dest_name = "#{entry_id}.webp"
  dest_path = File.join(COVERS_DIR, dest_name)

  if source.match?(%r{\Ahttps?://}i)
    ok = download_and_convert_image(source, dest_path)
    abort "Error: Could not download or convert image from #{source}" unless ok
  else
    expanded = File.expand_path(source)
    abort "Error: File does not exist: #{expanded}" unless File.exist?(expanded)
    convert_to_webp(expanded, dest_path)
  end

  entry['cover'] = dest_name
  save_year_yaml(yr, yml_path, entries)
  puts "Updated #{entry['title']} (#{yr}) -> #{dest_name} (#{(File.size(dest_path) / 1024.0).round(1)} KB)"
end

def set_cover_from_clipboard(entry_id)
  found = find_entry_across_years(entry_id)
  abort "Error: No comic entry found with id '#{entry_id}'" unless found

  yr, yml_path, entries, entry = found
  dest_name = "#{entry_id}.webp"
  dest_path = File.join(COVERS_DIR, dest_name)

  Dir.mktmpdir('clipboard-cover-') do |dir|
    png_path = File.join(dir, 'clipboard.png')
    applescript = <<~APPLESCRIPT
      try
        set imgData to the clipboard as «class PNGf»
        set outFile to open for access POSIX file "#{png_path}" with write permission
        set eof outFile to 0
        write imgData to outFile
        close access outFile
      on error errMsg
        error errMsg
      end try
    APPLESCRIPT
    _out, err, status = Open3.capture3('osascript', '-e', applescript)
    abort "Error reading image from macOS clipboard: #{err.strip}" unless status.success? && File.exist?(png_path)

    convert_to_webp(png_path, dest_path)
  end

  entry['cover'] = dest_name
  save_year_yaml(yr, yml_path, entries)
  puts "Saved clipboard cover for #{entry['title']} (#{yr}) -> #{dest_name} (#{(File.size(dest_path) / 1024.0).round(1)} KB)"
end

def fetch_online(filter_year, limit: nil)
  fetched = 0
  load_all_years(filter_year).each do |yr, yml_path, entries|
    dirty = false
    entries.each do |entry|
      break if limit && fetched >= limit
      if entry['cover'] && File.exist?(File.join(COVERS_DIR, File.basename(entry['cover'])))
        next
      end

      dest_name = "#{entry['id']}.webp"
      dest_path = File.join(COVERS_DIR, dest_name)

      # 1. Try publisher og:image if URL is on an open publisher site
      if (og_url = fetch_publisher_og_image(entry))
        if download_and_convert_image(og_url, dest_path)
          entry['cover'] = dest_name
          dirty = true
          fetched += 1
          puts "  [OG]    #{yr} #{entry['title']} -> #{dest_name} (#{(File.size(dest_path) / 1024.0).round(1)} KB)"
          sleep 0.25
          next
        end
      end

      # 2. Try Apple Books Search API, falling back to Open Library Covers API
      hit = search_apple_books_cover(entry) || search_open_library_cover(entry)
      if hit.is_a?(Array)
        art_url, matched_label = hit
        if download_and_convert_image(art_url, dest_path)
          entry['cover'] = dest_name
          dirty = true
          fetched += 1
          puts "  [BOOKS] #{yr} #{entry['title']} <= #{matched_label} (#{(File.size(dest_path) / 1024.0).round(1)} KB)"
        end
      end
      sleep 0.5
    end
    save_year_yaml(yr, yml_path, entries) if dirty
  end
  puts "Done. Fetched #{fetched} new cover(s)."
end

options = {}
parser = OptionParser.new do |opts|
  opts.banner = 'Usage: ruby tools/manage-comic-covers.rb [options]'
  opts.on('--status', 'Show cover and review status summary') { options[:mode] = :status }
  opts.on('--year YEAR', 'Filter to a specific year (e.g. 2026)') { |y| options[:year] = y }
  opts.on('--inbox', 'Ingest dropped images from _covers_inbox/<id>.*') { options[:mode] = :inbox }
  opts.on('--clipboard ID', 'Save cover from macOS clipboard for entry ID') do |id|
    options[:mode] = :clipboard
    options[:id] = id
  end
  opts.on('--set ID', 'Set cover for ID (pass file path or image URL as next arg)') do |id|
    options[:mode] = :set
    options[:id] = id
  end
  opts.on('--fetch-online', 'Fetch high-confidence covers from publisher pages & Apple Books API') do
    options[:mode] = :fetch_online
  end
  opts.on('--limit N', Integer, 'Max covers to fetch in one run') { |n| options[:limit] = n }
end
parser.parse!(ARGV)

case options[:mode]
when :inbox
  process_inbox
when :clipboard
  set_cover_from_clipboard(options[:id])
when :set
  src = ARGV.shift || abort('Error: Provide a file path or image URL after --set <id>')
  set_cover_for_id(options[:id], src)
when :fetch_online
  fetch_online(options[:year], limit: options[:limit])
else
  print_status(options[:year])
end
