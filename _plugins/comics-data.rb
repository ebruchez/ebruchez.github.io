# frozen_string_literal: true

require 'date'
require 'uri'

module BruchezComicsData
  MONTH_ABBR = %w[nil Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec].freeze
  COVERS_REL_DIR = '/assets/pages/comic-books/covers'

  module_function

  # Fast pure-Ruby WebP / PNG / JPEG header dimension reader (avoids spawning processes)
  def image_dimensions(abs_path)
    return nil unless abs_path && File.exist?(abs_path)

    header = File.binread(abs_path, 64)
    return nil if header.nil? || header.bytesize < 24

    if header.byteslice(0, 4) == 'RIFF' && header.byteslice(8, 4) == 'WEBP'
      chunk = header.byteslice(12, 4)
      case chunk
      when 'VP8 '
        # Lossy WebP: 14-bit width & height at offset 26..29
        return nil if header.bytesize < 30
        w = header.byteslice(26, 2).unpack1('v') & 0x3fff
        h = header.byteslice(28, 2).unpack1('v') & 0x3fff
        return [w, h] if w.positive? && h.positive?
      when 'VP8L'
        # Lossless WebP: 4 bytes at offset 21
        return nil if header.bytesize < 25
        bits = header.byteslice(21, 4).unpack1('V')
        w = (bits & 0x3fff) + 1
        h = ((bits >> 14) & 0x3fff) + 1
        return [w, h] if w.positive? && h.positive?
      when 'VP8X'
        # Extended WebP: 24-bit width-1 at 24..26, height-1 at 27..29
        return nil if header.bytesize < 30
        b = header.byteslice(24, 6).bytes
        w = (b[0] | (b[1] << 8) | (b[2] << 16)) + 1
        h = (b[3] | (b[4] << 8) | (b[5] << 16)) + 1
        return [w, h] if w.positive? && h.positive?
      end
    elsif header.byteslice(0, 8) == "\x89PNG\r\n\x1a\n".b
      w, h = header.byteslice(16, 8).unpack('NN')
      return [w, h] if w.positive? && h.positive?
    end
    nil
  rescue StandardError
    nil
  end

  def format_read_date(raw)
    return nil if raw.nil?

    s = raw.to_s.strip
    return nil if s.empty?

    if (m = s.match(/\A(\d{4})-(\d{2})-(\d{2})\z/))
      yr = m[1].to_i
      mo = m[2].to_i
      dy = m[3].to_i
      return "#{MONTH_ABBR[mo]} #{dy}, #{yr}" if mo.between?(1, 12)
    elsif (m = s.match(/\A(\d{4})-(\d{2})(?:-(?:xx|0x))?\z/i))
      yr = m[1].to_i
      mo = m[2].to_i
      return "#{MONTH_ABBR[mo]} #{yr}" if mo.between?(1, 12)
    end
    s
  end

  def sortable_date_key(raw, fallback_year, reverse_idx)
    s = raw.to_s.strip
    norm = if (m = s.match(/\A(\d{4})-(\d{2})-(\d{2})\z/))
             "#{m[1]}-#{m[2]}-#{m[3]}"
           elsif (m = s.match(/\A(\d{4})-(\d{2})/))
             "#{m[1]}-#{m[2]}-00"
           elsif s.match?(/\A\d{4}\z/)
             "#{s}-00-00"
           else
             "#{fallback_year}-00-00"
           end
    [norm, format('%05d', reverse_idx)]
  end

  def external_url_label(url)
    return nil if url.nil? || url.to_s.strip.empty?

    host = URI.parse(url.to_s.strip).host.to_s.downcase.sub(/\Awww\./, '')
    case host
    when /fantagraphics\.com/        then 'Fantagraphics'
    when /sergiobonelli\.it/         then 'Sergio Bonelli'
    when /panini\.it/                then 'Panini'
    when /lustiges-taschenbuch\.de/  then 'LTB'
    when /wikipedia\.org/            then 'Wikipedia'
    when /amazon\./                  then 'Amazon'
    when /goodreads\.com/            then 'Goodreads'
    else
      host.empty? ? 'Reference' : host
    end
  rescue StandardError
    'Reference'
  end

  def build_creators_parts(item)
    authors = Array(item['authors']).map(&:to_s).reject(&:empty?)
    writers = Array(item['writers']).map(&:to_s).reject(&:empty?)
    artists = Array(item['artists']).map(&:to_s).reject(&:empty?)
    colors  = Array(item['colors']).map(&:to_s).reject(&:empty?)
    adapted = item['adapted_from'].to_s.strip

    # Collapse identical writer & artist
    if !writers.empty? && writers == artists && authors.empty?
      authors = writers
      writers = []
      artists = []
    end

    parts = []
    if !authors.empty? && writers.empty? && artists.empty?
      parts << { 'role' => 'By', 'names' => authors.join(', ') }
    else
      if !authors.empty? && artists.any? && writers.empty?
        parts << { 'role' => 'Story', 'names' => authors.join(', ') }
        parts << { 'role' => 'Art', 'names' => artists.join(', ') }
      else
        parts << { 'role' => 'By', 'names' => authors.join(', ') } unless authors.empty?
        parts << { 'role' => 'Story', 'names' => writers.join(', ') } unless writers.empty?
        parts << { 'role' => 'Art', 'names' => artists.join(', ') } unless artists.empty?
      end
    end

    # Only show Colors if distinct from main author/artist
    distinct_colors = colors - authors - artists
    parts << { 'role' => 'Colors', 'names' => distinct_colors.join(', ') } unless distinct_colors.empty?
    parts << { 'role' => 'Adapted from', 'names' => adapted } unless adapted.empty?
    parts
  end

  def enrich_item!(item, converter, site_source)
    item['read_date_display'] = format_read_date(item['read_date'])
    item['creators_parts'] = build_creators_parts(item)
    item['creators_plain'] = item['creators_parts'].map { |p| "#{p['role']}: #{p['names']}" }.join(' · ')
    item['url_label'] = external_url_label(item['url']) if item['url']

    if (cov = item['cover'].to_s.strip) && !cov.empty?
      rel_url = cov.start_with?('/') ? cov : "#{COVERS_REL_DIR}/#{cov}"
      abs_cov = File.join(site_source, rel_url.delete_prefix('/'))
      if File.exist?(abs_cov)
        item['cover_url'] = rel_url
        dims = image_dimensions(abs_cov)
        if dims
          item['cover_width'] = dims[0]
          item['cover_height'] = dims[1]
        else
          item['cover_width'] = 450
          item['cover_height'] = 600
        end
      end
    end

    if (rev = item['review'].to_s.strip) && !rev.empty?
      item['review_html'] = converter.convert(rev)
    end

    if (nts = item['notes'].to_s.strip) && !nts.empty?
      item['notes_html'] = converter.convert(nts)
    end

    if item['rating']
      r = item['rating'].to_f
      full = r.floor
      empty = [5 - full, 0].max
      item['rating_stars_full'] = full
      item['rating_stars_empty'] = empty
      item['rating_display'] = (r == r.to_i ? r.to_i.to_s : r.to_s)
    end

    Array(item['sub_items']).each do |sub|
      enrich_item!(sub, converter, site_source)
    end
  end

  def enrich_all(site)
    comics_hash = site.data['comics']
    return unless comics_hash.is_a?(Hash) && !comics_hash.empty?

    converter = site.find_converter_instance(Jekyll::Converters::Markdown)
    years_sorted = comics_hash.keys.grep(/\A\d{4}\z/).sort.reverse

    years_meta = []
    total_reads = 0
    total_reviewed = 0
    featured_candidates = []

    years_sorted.each do |yr|
      entries = Array(comics_hash[yr])
      entries.each_with_index do |entry, idx|
        enrich_item!(entry, converter, site.source)
        entry['year_log'] = yr
        entry['deep_url'] = "/pages/comic-books-#{yr}/##{entry['id']}"

        # Collect candidates from the two most recent years for the Hub showcase
        next unless years_sorted.first(2).include?(yr)

        has_good_review = entry['review'].to_s.strip.length >= 90
        next unless entry['featured'] || has_good_review

        priority = 0
        priority += 100 if entry['featured']
        priority += 10 if entry['cover_url']
        priority += 3 if entry['rating']
        reverse_idx = entries.size - idx
        sort_key = [priority, *sortable_date_key(entry['read_date'], yr, reverse_idx)]
        featured_candidates << [sort_key, entry]
      end

      rev_count = entries.count { |e| e['review_html'] || Array(e['sub_items']).any? { |s| s['review_html'] } }
      bede_count = entries.count { |e| e['bedetheque_url'] || Array(e['sub_items']).any? { |s| s['bedetheque_url'] } }
      cover_count = entries.count { |e| e['cover_url'] }

      total_reads += entries.size
      total_reviewed += rev_count

      years_meta << {
        'year' => yr,
        'url' => "/pages/comic-books-#{yr}/",
        'count' => entries.size,
        'reviewed_count' => rev_count,
        'bedetheque_count' => bede_count,
        'cover_count' => cover_count
      }
    end

    featured_sorted = featured_candidates
                      .sort_by { |k, _| k }
                      .reverse
                      .first(6)
                      .map { |_, e| e }

    site.data['comics_years'] = years_meta
    site.data['comics_total_reads'] = total_reads
    site.data['comics_total_reviewed'] = total_reviewed
    site.data['comics_latest_featured'] = featured_sorted

    favs = site.data['comics_favorites']
    if favs.is_a?(Hash)
      %w[individual_works classics].each do |group_key|
        Array(favs[group_key]).each do |fav_entry|
          enrich_item!(fav_entry, converter, site.source)
        end
      end
    end
  end
end

Jekyll::Hooks.register :site, :pre_render do |site|
  BruchezComicsData.enrich_all(site)
end
