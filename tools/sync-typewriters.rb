#!/usr/bin/env ruby
# frozen_string_literal: true

# Sync typewriter collection metadata from The Typewriter Database (TWDB)
# and Erik's Google Sheet ("List of Acquisitions") into _data/ YAML files
# and optimized local WebP images (hero + typeface specimen).
#
# Usage examples:
#   ruby tools/sync-typewriters.rb --twdb                     # Fetch new TWDB galleries + missing images
#   ruby tools/sync-typewriters.rb --twdb --refresh-recent 15 # Also refresh 15 most recent galleries
#   ruby tools/sync-typewriters.rb --twdb --id 25557          # Force refresh one gallery
#   ruby tools/sync-typewriters.rb --sheet                    # Sync allowlisted public fields from Google Sheet
#   ruby tools/sync-typewriters.rb --all --audit              # Sync both and print reconciliation audit
#   ruby tools/sync-typewriters.rb --write-sheet-links        # Dry-run: preview TWDB URLs to write to Sheet
#   ruby tools/sync-typewriters.rb --write-sheet-links --apply # Write matched TWDB URLs into Google Sheet

require 'yaml'
require 'json'
require 'csv'
require 'uri'
require 'fileutils'
require 'tmpdir'
require 'open3'
require 'optparse'
require 'nokogiri'
require 'date'

ROOT = File.expand_path('..', __dir__)
TWDB_YML = File.join(ROOT, '_data', 'typewriters_twdb.yml')
SHEET_YML = File.join(ROOT, '_data', 'typewriters_sheet.yml')
OVERRIDES_YML = File.join(ROOT, '_data', 'typewriters_overrides.yml')
ASSETS_DIR = File.join(ROOT, 'assets', 'pages', 'typewriters')

TWDB_BASE = 'https://typewriterdatabase.com'
TWDB_HUNTER_ID = '3614'
SPREADSHEET_ID = '1oZktJJt11kJwSZbs6g0RdsMSXqv3PIPYZiglFag5AoA'
SHEET_NAME = 'List of Acquisitions'
USER_AGENT = 'BruchezNameTypewritersMirror/1.0 (https://blog.bruchez.name; mailto:erik@bruchez.org)'

TYPEWRITER_ITEM_TYPES = [
  'typewriter',
  'typewriter/accounting machine',
  'typewriter for parts'
].freeze

# Strict allowlist of Sheet columns that may ever be read into _data/.
# Financial columns (Price, S&H / Tax, Total, Current Value), Loc., My Score,
# and private Comment notes are intentionally excluded.
def load_yaml_array(path)
  return [] unless File.exist?(path)

  YAML.safe_load(File.read(path), permitted_classes: [Date]) || []
end

def load_yaml_hash(path)
  return {} unless File.exist?(path)

  YAML.safe_load(File.read(path), permitted_classes: [Date]) || {}
end

def save_yaml(path, header, payload)
  FileUtils.mkdir_p(File.dirname(path))
  yaml_str = YAML.dump(payload, line_width: 110).sub(/\A---\s*\n/, '')
  File.write(path, "#{header}\n#{yaml_str}")
end

def magick_binary
  @magick_binary ||= ['/opt/homebrew/bin/magick', '/usr/local/bin/magick', 'magick'].find do |bin|
    File.executable?(bin) || system('which', bin, out: File::NULL, err: File::NULL)
  end
end

def http_get(url_str, timeout: 20)
  out, _err, status = Open3.capture3(
    'curl', '-sSL',
    '--max-time', timeout.to_s,
    '-A', USER_AGENT,
    '-w', "\n__META__:%{http_code}",
    url_str
  )
  return nil unless status.success? && out.include?("\n__META__:")

  body, meta = out.rpartition("\n__META__:")[0], out.rpartition("\n__META__:")[2]
  code = meta.strip.to_i
  return nil unless code.between?(200, 299)

  unless body.valid_encoding?
    body = body.dup.force_encoding('Windows-1252').encode('UTF-8', invalid: :replace, undef: :replace, replace: '')
  end
  body
end

def download_to_webp(url_str, dest_path, resize_geom:, quality: 82)
  raise 'ImageMagick (magick) not found in PATH' unless magick_binary

  safe_url = url_str.to_s.strip.gsub(' ', '%20')
  FileUtils.mkdir_p(File.dirname(dest_path))
  Dir.mktmpdir('twdb_img_') do |dir|
    raw_path = File.join(dir, 'source.img')
    _out, _err, status = Open3.capture3(
      'curl', '-sSL', '--fail',
      '--max-time', '25',
      '-A', USER_AGENT,
      '-o', raw_path,
      safe_url
    )
    return false unless status.success? && File.exist?(raw_path) && File.size(raw_path) > 512

    cmd = [
      magick_binary, raw_path,
      '-auto-orient',
      '-resize', resize_geom,
      '-strip',
      '-quality', quality.to_s,
      dest_path
    ]
    _mout, merr, mstatus = Open3.capture3(*cmd)
    unless mstatus.success? && File.exist?(dest_path) && File.size(dest_path) > 100
      warn "  [warn] ImageMagick failed for #{url_str}: #{merr.strip}"
      return false
    end
  end
  true
end

def webp_dimensions(abs_path)
  return [nil, nil] unless abs_path && File.exist?(abs_path)

  header = File.binread(abs_path, 64)
  return [nil, nil] if header.nil? || header.bytesize < 30
  return [nil, nil] unless header.byteslice(0, 4) == 'RIFF' && header.byteslice(8, 4) == 'WEBP'

  case header.byteslice(12, 4)
  when 'VP8 '
    w = header.byteslice(26, 2).unpack1('v') & 0x3fff
    h = header.byteslice(28, 2).unpack1('v') & 0x3fff
    [w, h]
  when 'VP8L'
    bits = header.byteslice(21, 4).unpack1('V')
    [(bits & 0x3fff) + 1, ((bits >> 14) & 0x3fff) + 1]
  when 'VP8X'
    b = header.byteslice(24, 6).bytes
    [(b[0] | (b[1] << 8) | (b[2] << 16)) + 1, (b[3] | (b[4] << 8) | (b[5] << 16)) + 1]
  else
    [nil, nil]
  end
rescue StandardError
  [nil, nil]
end

def slugify(str)
  str.to_s
     .unicode_normalize(:nfd)
     .gsub(/\p{Mn}/, '')
     .downcase
     .gsub(/[^a-z0-9]+/, '-')
     .gsub(/\A-+|-+\z/, '')
end

def fetch_twdb_index_urls
  urls = []
  seen = {}
  offset = 0
  total_expected = nil

  loop do
    index_url = if offset.zero?
                  "#{TWDB_BASE}/typewriters.php?hunter_search=#{TWDB_HUNTER_ID}"
                else
                  "#{TWDB_BASE}/twdb.#{offset}.typewriters?z=1&y=1&m=1&hunter_search=#{TWDB_HUNTER_ID}&c=1"
                end

    html = http_get(index_url)
    unless html
      warn "[warn] Failed to fetch index page at offset #{offset}: #{index_url}"
      break
    end

    doc = Nokogiri::HTML(html)
    if total_expected.nil? && (h1 = doc.at('h1')&.text)
      if (m = h1.match(/(\d+)\s+Typewriter Galleries/i))
        total_expected = m[1].to_i
        puts "TWDB reports #{total_expected} galleries for hunter #{TWDB_HUNTER_ID}."
      end
    end

    page_links = doc.css('a[href$=".typewriter"]').map { |a| a['href'].to_s.strip }.uniq
    new_count = 0
    page_links.each do |href|
      full_url = href.start_with?('http') ? href : "#{TWDB_BASE}/#{href.delete_prefix('/')}"
      next if seen[full_url]

      seen[full_url] = true
      urls << full_url
      new_count += 1
    end

    break if page_links.empty? || new_count.zero?
    break if total_expected && urls.size >= total_expected

    offset += 10
    sleep 0.35
  end

  urls
end

def parse_twdb_gallery(url, html)
  doc = Nokogiri::HTML(html)
  twdb_id = url[/\.(\d+)\.typewriter\z/, 1]&.to_i
  return nil unless twdb_id

  # Breadcrumb: Home » Brand » Model » Year #Serial
  crumbs = []
  if (bc_container = doc.at('a[href="https://typewriterdatabase.com"], a[href="https://typewriterdatabase.com/"]')&.parent)
    crumbs = bc_container.text.split('»').map { |s| s.gsub(/\s+/, ' ').strip }.reject(&:empty?)
  end

  h1 = doc.at('h1')
  h1_serial = h1&.at('small')&.text.to_s.strip.sub(/\A#\s*/, '')
  h1_title = h1 ? h1.children.select(&:text?).map(&:text).join(' ').gsub(/\s+/, ' ').strip : ''

  year = ''
  if (m = h1_title.match(/\A(\d{2,4}[x?]{0,2})\s+(.+)\z/i))
    year = m[1]
    title_rest = m[2].strip
  else
    title_rest = h1_title
  end

  brand = crumbs[1].to_s.strip
  model = crumbs[2].to_s.strip
  if brand.empty? && !title_rest.empty?
    parts = title_rest.split(' ', 2)
    brand = parts[0].to_s
    model = parts[1].to_s
  end

  # Status, Created, Last Edit
  collection_status = 'My Collection'
  body_text = doc.text
  if (m = body_text.match(/Status:\s*(My Collection|Sightings|Parting Out|For Sale|Sold|Museum)/i))
    collection_status = m[1].strip
  end

  created_at = doc.at('[itemprop="datePublished"]')&.text.to_s.strip
  updated_at = doc.at('[itemprop="dateModified"]')&.text.to_s.strip

  # Description
  description = ''
  desc_h2 = doc.css('h2').find { |h| h.text.strip =~ /\ADescription:?/i }
  if desc_h2 && (p_el = desc_h2.next_element)
    desc_html = p_el.inner_html.gsub(/<br\s*\/?>/i, "\n")
    description = Nokogiri::HTML.fragment(desc_html).text
                                .gsub("\r\n", "\n")
                                .gsub(/[ \t]+\n/, "\n")
                                .gsub(/\n{3,}/, "\n\n")
                                .strip
  end

  # Typeface specimen
  typeface_src = nil
  tf_h2 = doc.css('h2').find { |h| h.text.strip =~ /\ATypeface Specimen:?/i }
  if tf_h2 && (sib = tf_h2.next_element)
    img = sib.name == 'img' ? sib : sib.at('img')
    src = img ? img['src'].to_s.strip : ''
    if !src.empty? && !src.include?('type-not-entered')
      typeface_src = src.start_with?('http') ? src : "#{TWDB_BASE}/#{src.delete_prefix('/')}"
    end
  end

  # Links
  links = []
  links_h2 = doc.css('h2').find { |h| h.text.strip =~ /\ALinks:?/i }
  if links_h2 && (ul = links_h2.next_element) && ul.name == 'ul'
    ul.css('li a[href]').each do |a|
      href = a['href'].to_s.strip
      next if href.empty?

      links << {
        'title' => a.text.gsub(/\s+/, ' ').strip,
        'url' => href
      }
    end
  end

  # Hero image: prefer TWDB's explicit full-size img[itemprop="image"]
  hero_src = nil
  if (prop_img = doc.at('img[itemprop="image"]'))
    s = prop_img['src'].to_s.strip
    if !s.empty? && !s.include?('type-not-entered') && !s.include?('member_')
      hero_src = s.start_with?('http') ? s : "#{TWDB_BASE}/#{s.delete_prefix('/')}"
      hero_src = hero_src.sub('/img/thumbs/', '/img/')
    end
  end
  if hero_src.nil?
    doc.css('img[src]').each do |img|
      s = img['src'].to_s.strip
      next if s.include?('/thumbs/') || s.include?('type-not-entered') || s.include?('member_')

      if s =~ %r{/img/g_?[a-z0-9 _-]+_#{twdb_id}_}i
        hero_src = s.start_with?('http') ? s : "#{TWDB_BASE}/#{s.delete_prefix('/')}"
        break
      end
    end
  end
  if hero_src.nil?
    meta_img = doc.at('meta[itemprop="image"]')&.[]('content').to_s.strip
    unless meta_img.empty?
      hero_src = meta_img.sub('/img/thumbs/', '/img/')
    end
  end

  # Gallery photo count & fallback first photo
  photos_h2 = doc.css('h2').find { |h| h.text.strip =~ /\APhotos:?/i }
  photo_count = 0
  fallback_hero_src = nil
  if photos_h2 && (pdiv = photos_h2.next_element)
    photo_imgs = pdiv.css("img[src*='/img/g#{twdb_id}_']")
    photo_count = photo_imgs.size
    if (first_p = photo_imgs.first)
      s = first_p['src'].to_s.strip
      fallback_hero_src = s.start_with?('http') ? s : "#{TWDB_BASE}/#{s.delete_prefix('/')}"
      hero_src ||= fallback_hero_src
    end
  end

  slug = slugify("#{year}-#{brand}-#{model}-#{twdb_id}")

  entry = {
    'twdb_id' => twdb_id,
    'slug' => slug,
    'twdb_url' => url,
    'brand' => brand,
    'model' => model,
    'year' => year,
    'serial' => h1_serial,
    'collection_status' => collection_status,
    'created_at' => created_at,
    'updated_at' => updated_at,
    'photo_count' => photo_count
  }
  entry['description'] = description unless description.empty?
  entry['links'] = links unless links.empty?
  entry['_hero_src'] = hero_src if hero_src
  entry['_fallback_hero_src'] = fallback_hero_src if fallback_hero_src && fallback_hero_src != hero_src
  entry['_typeface_src'] = typeface_src if typeface_src
  entry
end

def sync_twdb(force: false, refresh_recent: 0, only_id: nil)
  existing_list = load_yaml_array(TWDB_YML)
  existing_by_id = {}
  existing_list.each { |e| existing_by_id[e['twdb_id'].to_i] = e if e['twdb_id'] }

  if only_id
    existing = existing_by_id[only_id.to_i]
    urls = existing ? [existing['twdb_url']] : fetch_twdb_index_urls.select { |u| u.include?(".#{only_id}.typewriter") }
    if urls.empty?
      warn "Could not find TWDB gallery ID #{only_id}."
      return existing_list
    end
  else
    urls = fetch_twdb_index_urls
    puts "Found #{urls.size} gallery URLs on TWDB."
  end

  updated_entries = []
  fetched_count = 0
  img_count = 0

  urls.each_with_index do |url, idx|
    twdb_id = url[/\.(\d+)\.typewriter\z/, 1]&.to_i
    next unless twdb_id

    cached = existing_by_id[twdb_id]
    hero_rel = "#{twdb_id}/hero.webp"
    hero_abs = File.join(ASSETS_DIR, hero_rel)
    tf_rel = "#{twdb_id}/typeface.webp"
    tf_abs = File.join(ASSETS_DIR, tf_rel)

    needs_fetch = force ||
                  only_id ||
                  cached.nil? ||
                  idx < refresh_recent ||
                  (cached['hero_image'] && !File.exist?(hero_abs)) ||
                  (cached['hero_image'].nil? && cached['photo_count'].to_i > 0)

    if needs_fetch
      print "[#{idx + 1}/#{urls.size}] Fetching ##{twdb_id} (#{File.basename(url)})... "
      html = http_get(url)
      unless html
        puts 'FAILED'
        updated_entries << cached if cached
        next
      end

      entry = parse_twdb_gallery(url, html)
      unless entry
        puts 'PARSE ERROR'
        updated_entries << cached if cached
        next
      end

      hero_src = entry.delete('_hero_src')
      fallback_hero_src = entry.delete('_fallback_hero_src')
      tf_src = entry.delete('_typeface_src')

      if (hero_src || fallback_hero_src) && (force || only_id || !File.exist?(hero_abs))
        ok = hero_src ? download_to_webp(hero_src, hero_abs, resize_geom: '800x800>', quality: 82) : false
        ok = download_to_webp(fallback_hero_src, hero_abs, resize_geom: '800x800>', quality: 82) if !ok && fallback_hero_src
        img_count += 1 if ok
      end
      if File.exist?(hero_abs)
        w, h = webp_dimensions(hero_abs)
        entry['hero_image'] = hero_rel
        entry['hero_width'] = w if w
        entry['hero_height'] = h if h
      end

      if tf_src && (force || only_id || !File.exist?(tf_abs))
        if download_to_webp(tf_src, tf_abs, resize_geom: '1000x1400>', quality: 82)
          img_count += 1
        end
      end
      if File.exist?(tf_abs)
        w, h = webp_dimensions(tf_abs)
        entry['typeface_image'] = tf_rel
        entry['typeface_width'] = w if w
        entry['typeface_height'] = h if h
      end

      fetched_count += 1
      puts "OK (#{entry['year']} #{entry['brand']} #{entry['model']}, #{entry['photo_count']} photos)"
      updated_entries << entry
      sleep 0.35
    else
      updated_entries << cached
    end
  end

  if only_id
    updated_entries.each { |e| existing_by_id[e['twdb_id'].to_i] = e }
    final_list = existing_by_id.values.sort_by { |e| [-e['twdb_id'].to_i] }
  else
    final_list = updated_entries
  end

  save_yaml(
    TWDB_YML,
    "# Auto-generated by tools/sync-typewriters.rb --twdb (hunter #{TWDB_HUNTER_ID})\n# Do not hand-edit; put manual curation in _data/typewriters_overrides.yml",
    final_list
  )
  puts "Saved #{final_list.size} TWDB galleries to _data/typewriters_twdb.yml (fetched #{fetched_count}, converted #{img_count} images)."
  final_list
end

def clean_sheet_date(raw)
  s = raw.to_s.strip.sub(/\A[;']+/, '')
  return '' if s.empty?

  s
end

def parse_twdb_id_from_url(url)
  return nil if url.to_s.strip.empty?

  m = url.to_s.match(/\.(\d+)\.typewriter\b/)
  m ? m[1].to_i : (url.to_s.strip.match?(/\A\d+\z/) ? url.to_s.strip.to_i : nil)
end

def sync_sheet(csv_path: nil)
  rows = if csv_path
           CSV.read(csv_path)
         else
           out, err, status = Open3.capture3(
             'gsheets', 'readonly', 'read', SPREADSHEET_ID, "'#{SHEET_NAME}'!A1:Z500", '--json'
           )
           raise "gsheets CLI failed: #{err}" unless status.success?

           JSON.parse(out)
         end

  raise 'Sheet appears empty' if rows.nil? || rows.empty?

  headers = rows.first.map { |h| h.to_s.strip }
  # Map header indices carefully (note: there are TWO "Type" columns: col 3 = item type, col 11 = machine sub-type)
  idx_date = headers.index('Date')
  idx_month = headers.index('Month')
  idx_seq = headers.index('Seq.')
  type_indices = headers.each_index.select { |i| headers[i] == 'Type' }
  idx_item_type = type_indices[0]
  idx_machine_type = type_indices[1]
  idx_manufacturer = headers.index('Manufacturer')
  idx_model = headers.index('Model')
  idx_year = headers.index('Year')
  idx_decade = headers.index('Decade')
  idx_serial = headers.index('Serial')
  idx_typeface = headers.index('Typeface')
  idx_status = headers.index('Status')
  idx_twdb = headers.index('TWDB')
  idx_weight = headers.index('Weight (lbs)')
  idx_weight_case = headers.index('Weight with case')
  idx_link = headers.index('Link')
  idx_twdb_url = headers.index('TWDB URL') || headers.index('TWDB ID')

  entries = []
  rows[1..].each_with_index do |r, i|
    row_num = i + 2 # 1-based Google Sheet row number
    next if r.nil? || r.all? { |c| c.to_s.strip.empty? }

    item_type = idx_item_type ? r[idx_item_type].to_s.strip.downcase : ''
    next unless TYPEWRITER_ITEM_TYPES.include?(item_type)

    seq_raw = idx_seq ? r[idx_seq].to_s.strip : ''
    seq = seq_raw.match?(/\A\d+\z/) ? seq_raw.to_i : nil
    manufacturer = idx_manufacturer ? r[idx_manufacturer].to_s.strip : ''
    model = idx_model ? r[idx_model].to_s.strip : ''
    next if manufacturer.empty? && model.empty?

    status_val = idx_status ? r[idx_status].to_s.strip : ''
    # Always exclude trashed machines from public YAML
    next if status_val.downcase == 'trashed'

    twdb_flag = idx_twdb ? r[idx_twdb].to_s.strip.lines.first.to_s.strip : ''
    explicit_twdb_url = idx_twdb_url ? r[idx_twdb_url].to_s.strip : ''
    link_val = idx_link ? r[idx_link].to_s.strip : ''
    twdb_url_val = if !explicit_twdb_url.empty?
                     explicit_twdb_url
                   elsif link_val.include?('typewriterdatabase.com')
                     link_val
                   else
                     ''
                   end

    entry = {
      'sheet_row' => row_num,
      'seq' => seq,
      'acquisition_date' => clean_sheet_date(idx_date ? r[idx_date] : ''),
      'acquisition_month' => clean_sheet_date(idx_month ? r[idx_month] : ''),
      'manufacturer' => manufacturer,
      'model' => model,
      'year' => idx_year ? r[idx_year].to_s.strip : '',
      'decade' => idx_decade ? r[idx_decade].to_s.strip : '',
      'serial' => idx_serial ? r[idx_serial].to_s.strip : '',
      'typeface' => idx_typeface ? r[idx_typeface].to_s.strip : '',
      'machine_type' => idx_machine_type ? r[idx_machine_type].to_s.strip.gsub(/\s+/, ' ') : '',
      'status' => status_val,
      'twdb_flag' => twdb_flag
    }

    w = idx_weight ? r[idx_weight].to_s.strip : ''
    wc = idx_weight_case ? r[idx_weight_case].to_s.strip : ''
    entry['weight_lbs'] = w unless w.empty?
    entry['weight_with_case_lbs'] = wc unless wc.empty?
    if (tid = parse_twdb_id_from_url(twdb_url_val))
      entry['twdb_id'] = tid
      entry['twdb_url'] = twdb_url_val if twdb_url_val.start_with?('http')
    end
    entry['for_parts'] = true if item_type == 'typewriter for parts'
    entry['accounting'] = true if item_type == 'typewriter/accounting machine'

    # Strip empty optional strings to keep YAML compact
    entry.reject! { |k, v| v.nil? || (v.is_a?(String) && v.empty? && !%w[manufacturer model].include?(k)) }
    entries << entry
  end

  save_yaml(
    SHEET_YML,
    "# Auto-generated by tools/sync-typewriters.rb --sheet (strict public allowlist)\n# Financial columns (Price, S&H, Total, Value), Loc., My Score, and Comment are NEVER exported.",
    entries
  )
  puts "Saved #{entries.size} typewriter rows to _data/typewriters_sheet.yml (excluded non-typewriters & private columns)."
  entries
end

def norm_brand(s)
  s.to_s.downcase.gsub(/[^a-z0-9]+/, '')
end

def norm_serial(s)
  v = s.to_s.strip
  return '' if v.empty? || v =~ /\A(\?+|todo|n\/a|none|unknown)\b/i

  v.downcase.gsub(/[^a-z0-9]/, '')
end

def norm_model(s)
  s.to_s.downcase.gsub(/[^a-z0-9]+/, '')
end

def reconcile(twdb_list, sheet_list, overrides)
  overrides_by_twdb = Hash(overrides['by_twdb_id'] || {})
  overrides_by_seq = Hash(overrides['by_seq'] || {})

  twdb_by_id = {}
  twdb_list.each { |t| twdb_by_id[t['twdb_id'].to_i] = t }

  matches = {} # sheet_row => { twdb: t, sheet: s, method: '...' }
  matched_twdb_ids = {}

  # Pass 1: explicit twdb_id in Sheet or overrides
  sheet_list.each do |s|
    tid = s['twdb_id']&.to_i
    if tid.nil? && s['seq'] && (ov = overrides_by_seq[s['seq']] || overrides_by_seq[s['seq'].to_s])
      tid = ov['twdb_id']&.to_i
    end
    next unless tid && twdb_by_id[tid] && !matched_twdb_ids[tid]

    matches[s['sheet_row']] = { twdb: twdb_by_id[tid], sheet: s, method: 'explicit' }
    matched_twdb_ids[tid] = true
  end

  # Pass 2: normalized (brand, serial) match against My Collection
  twdb_collection = twdb_list.select { |t| t['collection_status'].to_s.downcase == 'my collection' }
  sheet_list.each do |s|
    next if matches[s['sheet_row']]

    ss = norm_serial(s['serial'])
    next if ss.length < 3

    sb = norm_brand(s['manufacturer'])
    cands = twdb_collection.select do |t|
      next if matched_twdb_ids[t['twdb_id'].to_i]

      ts = norm_serial(t['serial'])
      next if ts.empty?

      tb = norm_brand(t['brand'])
      brand_ok = sb.empty? || tb.empty? || tb.include?(sb) || sb.include?(tb)
      brand_ok && (ts == ss || (ts.length >= 5 && ss.length >= 5 && (ts.end_with?(ss) || ss.end_with?(ts))))
    end

    if cands.size == 1
      t = cands.first
      matches[s['sheet_row']] = { twdb: t, sheet: s, method: 'serial' }
      matched_twdb_ids[t['twdb_id'].to_i] = true
    end
  end

  # Pass 3: unique (brand, model, year) match
  sheet_list.each do |s|
    next if matches[s['sheet_row']]

    sb = norm_brand(s['manufacturer'])
    sm = norm_model(s['model'])
    sy = s['year'].to_s.strip
    next if sb.empty? || sm.empty? || sy.empty?

    cands = twdb_collection.select do |t|
      next if matched_twdb_ids[t['twdb_id'].to_i]

      norm_brand(t['brand']) == sb && norm_model(t['model']) == sm && t['year'].to_s.strip == sy
    end

    if cands.size == 1
      # Ensure no other unmatched sheet row shares the same (brand, model, year)
      sheet_dups = sheet_list.count do |other|
        !matches[other['sheet_row']] &&
          norm_brand(other['manufacturer']) == sb &&
          norm_model(other['model']) == sm &&
          other['year'].to_s.strip == sy
      end
      if sheet_dups == 1
        t = cands.first
        matches[s['sheet_row']] = { twdb: t, sheet: s, method: 'brand+model+year' }
        matched_twdb_ids[t['twdb_id'].to_i] = true
      end
    end
  end

  unmatched_twdb = twdb_collection.reject { |t| matched_twdb_ids[t['twdb_id'].to_i] }
  unmatched_sheet = sheet_list.reject { |s| matches[s['sheet_row']] }

  {
    matches: matches,
    unmatched_twdb: unmatched_twdb,
    unmatched_sheet: unmatched_sheet,
    overrides_by_twdb: overrides_by_twdb
  }
end

def print_audit
  twdb_list = load_yaml_array(TWDB_YML)
  sheet_list = load_yaml_array(SHEET_YML)
  overrides = load_yaml_hash(OVERRIDES_YML)

  res = reconcile(twdb_list, sheet_list, overrides)
  by_method = Hash.new(0)
  res[:matches].each_value { |m| by_method[m[:method]] += 1 }

  collection_count = twdb_list.count { |t| t['collection_status'].to_s.downcase == 'my collection' }
  sightings_count = twdb_list.count { |t| t['collection_status'].to_s.downcase == 'sightings' }

  puts "\n=== Typewriter Collection Audit ==="
  puts "TWDB galleries:      #{twdb_list.size} (#{collection_count} My Collection, #{sightings_count} Sightings)"
  puts "Sheet typewriters:   #{sheet_list.size}"
  puts "Matched pairs:       #{res[:matches].size} (#{by_method.map { |k, v| "#{k}: #{v}" }.join(', ')})"
  puts "TWDB-only (Coll.):   #{res[:unmatched_twdb].size}"
  puts "Sheet-only backlog:  #{res[:unmatched_sheet].size}"

  if res[:unmatched_twdb].any?
    puts "\n--- TWDB My Collection galleries without a Sheet match (first 15) ---"
    res[:unmatched_twdb].first(15).each do |t|
      puts "  ##{t['twdb_id']} | #{t['year']} #{t['brand']} #{t['model']} | serial=#{t['serial']}"
    end
  end

  if res[:unmatched_sheet].any?
    by_flag = res[:unmatched_sheet].group_by { |s| s['twdb_flag'].to_s.empty? ? '(blank)' : s['twdb_flag'] }
    puts "\n--- Sheet-only typewriters by TWDB flag ---"
    by_flag.sort_by { |_, arr| -arr.size }.each { |flag, arr| puts "  #{flag}: #{arr.size}" }
  end
end

def col_letter(zero_idx)
  s = +''
  n = zero_idx
  while n >= 0
    s.prepend((65 + (n % 26)).chr)
    n = (n / 26) - 1
  end
  s
end

def write_sheet_links(apply: false)
  twdb_list = load_yaml_array(TWDB_YML)
  sheet_list = load_yaml_array(SHEET_YML)
  overrides = load_yaml_hash(OVERRIDES_YML)
  res = reconcile(twdb_list, sheet_list, overrides)

  # Read header row to find or create "TWDB URL" column
  out, err, status = Open3.capture3('gsheets', 'readonly', 'read', SPREADSHEET_ID, "'#{SHEET_NAME}'!1:1", '--json')
  raise "gsheets header read failed: #{err}" unless status.success?

  headers = JSON.parse(out).first.map { |h| h.to_s.strip }
  col_idx = headers.index('TWDB URL')
  creating_header = col_idx.nil?
  col_idx ||= headers.size
  col = col_letter(col_idx)

  to_write = res[:matches].values.select do |m|
    m[:sheet]['twdb_id'].nil? # only write rows not already linked in the sheet
  end

  puts "Target column: #{col} (#{creating_header ? 'NEW header: TWDB URL' : 'existing TWDB URL'})"
  puts "Matched rows to write: #{to_write.size}"
  to_write.first(20).each do |m|
    puts "  Row #{m[:sheet]['sheet_row']} (Seq #{m[:sheet]['seq']}): #{m[:sheet]['manufacturer']} #{m[:sheet]['model']} => #{m[:twdb]['twdb_url']} [#{m[:method]}]"
  end
  puts "  ... and #{to_write.size - 20} more" if to_write.size > 20

  unless apply
    puts "\nDry-run complete. Re-run with --write-sheet-links --apply to update the Google Sheet."
    return
  end

  ops = []
  ops << { 'op' => 'write', 'range' => "'#{SHEET_NAME}'!#{col}1", 'data' => [['TWDB URL']] } if creating_header
  to_write.each do |m|
    ops << {
      'op' => 'write',
      'range' => "'#{SHEET_NAME}'!#{col}#{m[:sheet]['sheet_row']}",
      'data' => [[m[:twdb]['twdb_url']]]
    }
  end

  if ops.empty?
    puts 'Nothing to write — all matched rows already have a TWDB URL in the Sheet.'
    return
  end

  Dir.mktmpdir('gsheets_batch_') do |dir|
    req_path = File.join(dir, 'requests.json')
    File.write(req_path, JSON.pretty_generate(ops))
    bout, berr, bstatus = Open3.capture3('gsheets', 'mutate', 'batch', SPREADSHEET_ID, '-f', req_path)
    raise "gsheets batch write failed: #{berr}\n#{bout}" unless bstatus.success?

    puts "Successfully wrote #{to_write.size} TWDB URLs into column #{col} of '#{SHEET_NAME}'."
  end
end

options = {
  twdb: false,
  sheet: false,
  audit: false,
  force: false,
  refresh_recent: 0,
  only_id: nil,
  csv_path: nil,
  write_sheet_links: false,
  apply: false
}

OptionParser.new do |opts|
  opts.banner = 'Usage: ruby tools/sync-typewriters.rb [options]'
  opts.on('--twdb', 'Sync galleries & hero/typeface WebP images from TWDB') { options[:twdb] = true }
  opts.on('--sheet', 'Sync allowlisted public fields from Google Sheet') { options[:sheet] = true }
  opts.on('--all', 'Run both --twdb and --sheet') { options[:twdb] = true; options[:sheet] = true }
  opts.on('--audit', 'Print TWDB <-> Sheet reconciliation report') { options[:audit] = true }
  opts.on('--force', 'Re-fetch all TWDB galleries and re-download images') { options[:force] = true }
  opts.on('--refresh-recent N', Integer, 'Also refresh the N most recently updated TWDB galleries') { |n| options[:refresh_recent] = n }
  opts.on('--id ID', Integer, 'Force refresh a single TWDB gallery ID') { |id| options[:twdb] = true; options[:only_id] = id }
  opts.on('--csv PATH', String, 'Read Sheet data from local CSV instead of gsheets CLI') { |p| options[:sheet] = true; options[:csv_path] = p }
  opts.on('--write-sheet-links', 'Preview writing matched TWDB URLs into Google Sheet') { options[:write_sheet_links] = true }
  opts.on('--apply', 'Apply changes for --write-sheet-links') { options[:apply] = true }
end.parse!

unless options[:twdb] || options[:sheet] || options[:audit] || options[:write_sheet_links]
  puts 'Nothing to do. Try --all --audit (or --help).'
  exit 0
end

sync_twdb(force: options[:force], refresh_recent: options[:refresh_recent], only_id: options[:only_id]) if options[:twdb]
sync_sheet(csv_path: options[:csv_path]) if options[:sheet]
print_audit if options[:audit]
write_sheet_links(apply: options[:apply]) if options[:write_sheet_links]
