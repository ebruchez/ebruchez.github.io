# frozen_string_literal: true

require 'date'
require 'uri'
require 'cgi'

module BruchezTypewriters
  ASSETS_REL_DIR = '/assets/pages/typewriters'

  STATUS_LABELS = {
    'restored'    => 'Restored',
    'working'     => 'Working / Cleaned',
    'in_progress' => 'In Progress',
    'to_process'  => 'To Process',
    'parts'       => 'For Parts',
    'sold'        => 'Former / Sold',
    'unknown'     => 'Cataloged'
  }.freeze

  module_function

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

  def slugify(str)
    str.to_s
       .unicode_normalize(:nfd)
       .gsub(/\p{Mn}/, '')
       .downcase
       .gsub(/[^a-z0-9]+/, '-')
       .gsub(/\A-+|-+\z/, '')
  end

  def extract_year_num(year_str)
    s = year_str.to_s.strip
    if (m = s.match(/\A(\d{4})/))
      return m[1].to_i
    elsif (m = s.match(/\A(\d{3})[x?]/i))
      return m[1].to_i * 10
    end

    nil
  end

  def compute_decade(year_str, sheet_decade = nil)
    if (y = extract_year_num(year_str))
      return "#{(y / 10) * 10}s"
    end
    d = sheet_decade.to_s.strip
    return "#{d}s" if d.match?(/\A\d{4}\z/)

    nil
  end

  def classify_status(status_str, for_parts: false)
    return 'parts' if for_parts

    s = status_str.to_s.strip.downcase
    return 'unknown' if s.empty?
    return 'sold' if s.include?('sold') || s.include?('given away')
    return 'parts' if s == 'parts'
    return 'restored' if s.include?('restored')
    return 'working' if s.include?('works') || s.include?('serviced')
    return 'in_progress' if s.include?('in progress')
    return 'to_process' if s.include?('to process') || s.include?('displayable')

    'unknown'
  end

  def format_description_html(raw_text, converter)
    text = raw_text.to_s.strip
    return '' if text.empty?

    # Convert plain paragraphs/linebreaks cleanly through Kramdown
    if converter
      converter.convert(text)
    else
      "<p>#{CGI.escapeHTML(text).gsub("\n", '<br>')}</p>"
    end
  end

  def thematic_guides_for(machine)
    guides = []
    brand_lc = machine['brand'].to_s.downcase
    model_lc = machine['model'].to_s.downcase

    if brand_lc.include?('hermes') || brand_lc.include?('paillard') || brand_lc == 'ruf'
      guides << { 'title' => 'Hermes Typewriters', 'url' => '/pages/typewriter-collection-hermes/' }
    end
    if brand_lc.include?('ibm')
      guides << { 'title' => 'IBM Typewriters', 'url' => '/pages/typewriter-collection-ibm/' }
    end
    if brand_lc.include?('varityper') || brand_lc.include?('vari-typer') || brand_lc.include?('hammond')
      guides << { 'title' => 'Varityper Collection', 'url' => '/pages/typewriter-collection-varityper/' }
    end
    if machine['accounting'] || model_lc.include?('accounting') || model_lc.include?('bookkeeping') || model_lc.include?('adder')
      guides << { 'title' => 'Accounting Machines', 'url' => '/pages/typewriter-collection-accounting/' }
    end
    if machine['status_group'] == 'restored'
      guides << { 'title' => 'Completed Restorations', 'url' => '/pages/typewriter-collection-completed-restorations/' }
    end
    guides
  end

  def reconcile(twdb_list, sheet_list, overrides)
    overrides_by_seq = Hash(overrides['by_seq'] || {})
    twdb_by_id = {}
    twdb_list.each { |t| twdb_by_id[t['twdb_id'].to_i] = t if t['twdb_id'] }

    matches_by_twdb = {}
    matched_sheet_rows = {}

    # Pass 1: explicit twdb_id in Sheet or overrides
    sheet_list.each do |s|
      tid = s['twdb_id']&.to_i
      if tid.nil? && s['seq'] && (ov = overrides_by_seq[s['seq']] || overrides_by_seq[s['seq'].to_s])
        tid = ov['twdb_id']&.to_i
      end
      next unless tid && twdb_by_id[tid] && !matches_by_twdb[tid]

      matches_by_twdb[tid] = s
      matched_sheet_rows[s['sheet_row']] = true
    end

    # Pass 2: normalized (brand, serial) match against My Collection
    twdb_collection = twdb_list.select { |t| t['collection_status'].to_s.downcase == 'my collection' }
    sheet_list.each do |s|
      next if matched_sheet_rows[s['sheet_row']]

      ss = norm_serial(s['serial'])
      next if ss.length < 3

      sb = norm_brand(s['manufacturer'])
      cands = twdb_collection.select do |t|
        next if matches_by_twdb[t['twdb_id'].to_i]

        ts = norm_serial(t['serial'])
        next if ts.empty?

        tb = norm_brand(t['brand'])
        brand_ok = sb.empty? || tb.empty? || tb.include?(sb) || sb.include?(tb)
        brand_ok && (ts == ss || (ts.length >= 5 && ss.length >= 5 && (ts.end_with?(ss) || ss.end_with?(ts))))
      end

      if cands.size == 1
        matches_by_twdb[cands.first['twdb_id'].to_i] = s
        matched_sheet_rows[s['sheet_row']] = true
      end
    end

    # Pass 3: unique (brand, model, year) match
    sheet_list.each do |s|
      next if matched_sheet_rows[s['sheet_row']]

      sb = norm_brand(s['manufacturer'])
      sm = norm_model(s['model'])
      sy = s['year'].to_s.strip
      next if sb.empty? || sm.empty? || sy.empty?

      cands = twdb_collection.select do |t|
        next if matches_by_twdb[t['twdb_id'].to_i]

        norm_brand(t['brand']) == sb && norm_model(t['model']) == sm && t['year'].to_s.strip == sy
      end

      next unless cands.size == 1

      sheet_dups = sheet_list.count do |other|
        !matched_sheet_rows[other['sheet_row']] &&
          norm_brand(other['manufacturer']) == sb &&
          norm_model(other['model']) == sm &&
          other['year'].to_s.strip == sy
      end
      next unless sheet_dups == 1

      matches_by_twdb[cands.first['twdb_id'].to_i] = s
      matched_sheet_rows[s['sheet_row']] = true
    end

    unmatched_sheet = sheet_list.reject { |s| matched_sheet_rows[s['sheet_row']] }
    [matches_by_twdb, unmatched_sheet]
  end

  def build_all(site)
    twdb_list = Array(site.data['typewriters_twdb'])
    sheet_list = Array(site.data['typewriters_sheet'])
    overrides = site.data['typewriters_overrides'].is_a?(Hash) ? site.data['typewriters_overrides'] : {}
    overrides_by_twdb = Hash(overrides['by_twdb_id'] || {})
    overrides_by_seq = Hash(overrides['by_seq'] || {})

    converter = site.find_converter_instance(Jekyll::Converters::Markdown)
    matches_by_twdb, unmatched_sheet = reconcile(twdb_list, sheet_list, overrides)

    machines = []

    # 1. All TWDB galleries (enriched with matched Sheet row + overrides)
    twdb_list.each do |t|
      tid = t['twdb_id'].to_i
      s = matches_by_twdb[tid]
      ov = overrides_by_twdb[tid] || overrides_by_twdb[tid.to_s] || {}
      next if ov['hidden'] == true

      brand = (ov['brand'] || t['brand'] || s&.dig('manufacturer')).to_s.strip
      model = (ov['model'] || t['model'] || s&.dig('model')).to_s.strip
      year = (ov['year'] || t['year'] || s&.dig('year')).to_s.strip
      serial = (ov['serial'] || t['serial'] || s&.dig('serial')).to_s.strip
      serial = '' if serial =~ /\A(\?+|todo)\b/i

      status_raw = (ov['status'] || s&.dig('status')).to_s.strip
      status_group = classify_status(status_raw, for_parts: s&.dig('for_parts') == true)
      is_sighting = t['collection_status'].to_s.downcase == 'sightings'
      bucket = if is_sighting
                 'sightings'
               elsif %w[sold parts].include?(status_group)
                 'former'
               else
                 'collection'
               end

      slug = (ov['slug'] || t['slug']).to_s.strip
      title = [year, brand, model].reject(&:empty?).join(' ')

      hero_url = nil
      if (hi = t['hero_image'].to_s.strip) && !hi.empty?
        rel = hi.start_with?('/') ? hi : "#{ASSETS_REL_DIR}/#{hi}"
        hero_url = rel if File.exist?(File.join(site.source, rel.delete_prefix('/')))
      end

      tf_url = nil
      if (ti = t['typeface_image'].to_s.strip) && !ti.empty?
        rel = ti.start_with?('/') ? ti : "#{ASSETS_REL_DIR}/#{ti}"
        tf_url = rel if File.exist?(File.join(site.source, rel.delete_prefix('/')))
      end

      # Split TWDB links into internal blog links vs external links (e.g., Google Photos)
      blog_links = []
      external_links = []
      Array(t['links']).each do |lnk|
        u = lnk['url'].to_s.strip
        next if u.empty?

        if u.include?('blog.bruchez.name')
          rel_path = u.sub(%r{\Ahttps?://blog\.bruchez\.name}, '')
          blog_links << { 'title' => lnk['title'].to_s.strip, 'url' => rel_path }
        else
          external_links << { 'title' => lnk['title'].to_s.strip, 'url' => u }
        end
      end
      Array(ov['related_posts']).each do |p_url|
        next if blog_links.any? { |b| b['url'] == p_url }

        post = site.posts.docs.find { |d| d.url == p_url }
        blog_links << { 'title' => post ? post.data['title'].to_s : p_url, 'url' => p_url }
      end

      machine = {
        'id' => "twdb-#{tid}",
        'slug' => slug,
        'url' => "/typewriters/#{slug}/",
        'has_detail_page' => true,
        'title' => title,
        'brand' => brand,
        'model' => model,
        'year' => year,
        'year_num' => extract_year_num(year) || 9999,
        'decade' => compute_decade(year, s&.dig('decade')),
        'serial' => serial,
        'typeface' => (ov['typeface'] || s&.dig('typeface')).to_s.strip,
        'machine_type' => (ov['machine_type'] || s&.dig('machine_type')).to_s.strip,
        'status' => status_raw,
        'status_group' => status_group,
        'status_label' => STATUS_LABELS[status_group],
        'weight_lbs' => s&.dig('weight_lbs'),
        'weight_with_case_lbs' => s&.dig('weight_with_case_lbs'),
        'acquisition_date' => s&.dig('acquisition_date').to_s.strip,
        'seq' => s&.dig('seq'),
        'accounting' => s&.dig('accounting') == true,
        'source' => s ? 'both' : 'twdb_only',
        'bucket' => bucket,
        'on_twdb' => true,
        'twdb_id' => tid,
        'twdb_url' => t['twdb_url'],
        'collection_status' => t['collection_status'],
        'photo_count' => t['photo_count'].to_i,
        'created_at' => t['created_at'].to_s.strip,
        'updated_at' => t['updated_at'].to_s.strip,
        'hero_url' => hero_url,
        'hero_width' => t['hero_width'],
        'hero_height' => t['hero_height'],
        'typeface_url' => tf_url,
        'typeface_width' => t['typeface_width'],
        'typeface_height' => t['typeface_height'],
        'description_raw' => t['description'].to_s.strip,
        'description_html' => format_description_html(t['description'], converter),
        'notes_html' => format_description_html(ov['notes'], converter),
        'blog_links' => blog_links,
        'external_links' => external_links,
        'featured' => ov['featured'] == true
      }
      machine['thematic_guides'] = thematic_guides_for(machine)
      machines << machine
    end

    # 2. Sheet-only typewriters (not yet on TWDB)
    unmatched_sheet.each do |s|
      seq = s['seq']
      ov = (seq ? (overrides_by_seq[seq] || overrides_by_seq[seq.to_s]) : nil) || {}
      next if ov['hidden'] == true

      brand = (ov['brand'] || s['manufacturer']).to_s.strip
      model = (ov['model'] || s['model']).to_s.strip
      year = (ov['year'] || s['year']).to_s.strip
      serial = (ov['serial'] || s['serial']).to_s.strip
      serial = '' if serial =~ /\A(\?+|todo)\b/i

      status_raw = (ov['status'] || s['status']).to_s.strip
      status_group = classify_status(status_raw, for_parts: s['for_parts'] == true)
      bucket = %w[sold parts].include?(status_group) ? 'former' : 'backlog'

      id_token = seq ? "seq-#{seq}" : "row-#{s['sheet_row']}"
      slug = slugify([year, brand, model, id_token].reject(&:empty?).join('-'))
      title = [year, brand, model].reject(&:empty?).join(' ')

      machine = {
        'id' => id_token,
        'slug' => slug,
        'url' => nil,
        'has_detail_page' => false,
        'title' => title,
        'brand' => brand,
        'model' => model,
        'year' => year,
        'year_num' => extract_year_num(year) || 9999,
        'decade' => compute_decade(year, s['decade']),
        'serial' => serial,
        'typeface' => (ov['typeface'] || s['typeface']).to_s.strip,
        'machine_type' => (ov['machine_type'] || s['machine_type']).to_s.strip,
        'status' => status_raw,
        'status_group' => status_group,
        'status_label' => STATUS_LABELS[status_group],
        'weight_lbs' => s['weight_lbs'],
        'weight_with_case_lbs' => s['weight_with_case_lbs'],
        'acquisition_date' => s['acquisition_date'].to_s.strip,
        'seq' => seq,
        'accounting' => s['accounting'] == true,
        'source' => 'sheet_only',
        'bucket' => bucket,
        'on_twdb' => false,
        'twdb_flag' => s['twdb_flag'].to_s.strip,
        'photo_count' => 0,
        'updated_at' => s['acquisition_date'].to_s.strip,
        'blog_links' => [],
        'external_links' => [],
        'featured' => ov['featured'] == true
      }
      machine['thematic_guides'] = thematic_guides_for(machine)
      machines << machine
    end

    # Default sort: brand A-Z, then year ascending, then model A-Z
    machines.sort_by! do |m|
      [m['brand'].downcase, m['year_num'], m['model'].downcase, m['id']]
    end

    # Compute stats
    coll = machines.select { |m| m['bucket'] == 'collection' }
    backlog = machines.select { |m| m['bucket'] == 'backlog' }
    former = machines.select { |m| m['bucket'] == 'former' }
    sightings = machines.select { |m| m['bucket'] == 'sightings' }

    brand_counts = Hash.new(0)
    decade_counts = Hash.new(0)
    type_counts = Hash.new(0)
    years_valid = []

    machines.each do |m|
      brand_counts[m['brand']] += 1 unless m['brand'].empty?
      decade_counts[m['decade']] += 1 if m['decade']
      type_counts[m['machine_type']] += 1 unless m['machine_type'].empty?
      years_valid << m['year_num'] if m['bucket'] == 'collection' && m['year_num'] < 9999
    end

    stats = {
      'total_all' => machines.size,
      'total_collection' => coll.size,
      'total_backlog' => backlog.size,
      'total_former' => former.size,
      'total_sightings' => sightings.size,
      'total_on_twdb' => machines.count { |m| m['on_twdb'] },
      'total_restored_or_working' => (coll + backlog).count { |m| %w[restored working].include?(m['status_group']) },
      'total_photos_on_twdb' => coll.sum { |m| m['photo_count'].to_i },
      'year_min' => years_valid.min,
      'year_max' => years_valid.max,
      'brands_count' => coll.map { |m| m['brand'] }.reject(&:empty?).uniq.size,
      'brands' => brand_counts.sort_by { |k, _| k.downcase }.map { |k, v| { 'name' => k, 'count' => v } },
      'decades' => decade_counts.keys.sort,
      'machine_types' => type_counts.keys.sort
    }

    [machines, stats]
  end

  class TypewriterPage < Jekyll::PageWithoutAFile
    def initialize(site, machine, prev_machine, next_machine)
      @site = site
      @base = site.source
      @dir = "typewriters/#{machine['slug']}"
      @name = 'index.html'

      process(@name)
      self.data = {
        'layout' => 'typewriter',
        'title' => machine['title'],
        'description' => build_meta_description(machine),
        'image' => machine['hero_url'],
        'machine' => machine,
        'prev_machine' => prev_machine,
        'next_machine' => next_machine,
        'comments' => true,
        'breadcrumb' => [
          { 'label' => 'Home', 'url' => '/' },
          { 'label' => 'Typewriters', 'url' => '/typewriters/' }
        ]
      }.compact
      self.content = ''
    end

    private

    def build_meta_description(m)
      parts = [m['title']]
      parts << "Serial ##{m['serial']}" unless m['serial'].to_s.empty?
      parts << m['machine_type'] unless m['machine_type'].to_s.empty?
      parts << "Status: #{m['status_label']}" if m['status_group'] && m['status_group'] != 'unknown'
      "From Erik Bruchez's typewriter collection: #{parts.join(' · ')}."
    end
  end

  class Generator < Jekyll::Generator
    safe true
    priority :high

    def generate(site)
      machines, stats = BruchezTypewriters.build_all(site)
      site.data['typewriters'] = machines
      site.data['typewriters_stats'] = stats

      detail_machines = machines.select { |m| m['has_detail_page'] }
      detail_machines.each_with_index do |m, idx|
        prev_m = idx.positive? ? detail_machines[idx - 1] : nil
        next_m = idx < detail_machines.size - 1 ? detail_machines[idx + 1] : nil
        site.pages << TypewriterPage.new(site, m, prev_m, next_m)
      end
    end
  end
end
