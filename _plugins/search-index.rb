# frozen_string_literal: true

require 'json'

module BruchezSearchIndex
  MAX_POST_BODY_CHARS = 2400
  MAX_PAGE_BODY_CHARS = 3200
  SNIPPET_CHARS = 200

  FilterHost = Class.new do
    include Liquid::StandardFilters
  end.new

  LIQUID_TAG_RE = /\{%.*?%\}|\{\{.*?\}\}/m

  module_function

  def strip_linenos(html)
    return html unless html.include?('<td class="rouge-gutter gl"><pre class="lineno">')

    html
      .gsub('<td class="rouge-gutter gl"><pre class="lineno">', '<!-- ')
      .gsub('</td><td class="rouge-code">', ' --><td class="rouge-code">')
  end

  def plain_text_from_doc(doc, converter)
    raw = doc.content.to_s.gsub(LIQUID_TAG_RE, ' ')
    html = converter && converter.matches(doc.extname) ? converter.convert(raw) : raw
    cleaned = strip_linenos(html)
    FilterHost.strip_html(cleaned).gsub(/\s+/, ' ').strip
  end

  def build_url(baseurl, url)
    return url if baseurl.nil? || baseurl.empty?

    "#{baseurl.chomp('/')}#{url}"
  end

  def comic_creators_text(entry)
    (Array(entry['authors']) + Array(entry['writers']) + Array(entry['artists'])).join(' ')
  end

  def build_comics_year_text(entries)
    parts = []
    entries.each do |e|
      next unless e.is_a?(Hash) && e['title']

      creators = comic_creators_text(e)
      review = FilterHost.strip_html(e['review_html'].to_s).gsub(/\s+/, ' ').strip
      chunk = [e['title'], creators, review[0, 140]].reject { |s| s.nil? || s.empty? }.join(' — ')
      parts << chunk
    end
    parts.join(' · ')
  end

  def build_comics_hub_extra(site)
    favs = site.data['comics_favorites']
    return '' unless favs.is_a?(Hash)

    items = Array(favs['individual_works']) + Array(favs['classics'])
    items.filter_map do |e|
      next unless e.is_a?(Hash) && e['title']

      creators = comic_creators_text(e)
      review = FilterHost.strip_html(e['review_html'].to_s).gsub(/\s+/, ' ').strip
      [e['title'], creators, review[0, 140]].reject { |s| s.nil? || s.empty? }.join(' — ')
    end.join(' · ')
  end

  def precompute(site)
    converter = site.find_converter_instance(Jekyll::Converters::Markdown)
    baseurl = site.config['baseurl'].to_s
    entries = []

    # 1. Blog posts (newest first)
    site.posts.docs.reverse_each do |post|
      next if post.data['published'] == false

      text = plain_text_from_doc(post, converter)
      entries << {
        'title' => post.data['title'].to_s,
        'url' => build_url(baseurl, post.url),
        'type' => 'post',
        'date' => post.date ? post.date.strftime('%b %Y') : '',
        'categories' => Array(post.data['categories']).join(', '),
        'tags' => Array(post.data['tags']).join(', '),
        'snippet' => FilterHost.truncate(text, SNIPPET_CHARS),
        'body' => text[0, MAX_POST_BODY_CHARS].to_s
      }
    end

    # 1b. French translated posts (newest first)
    if site.collections['posts_fr']
      site.collections['posts_fr'].docs.sort_by { |d| d.date || Time.at(0) }.reverse_each do |post|
        next if post.data['published'] == false

        text = plain_text_from_doc(post, converter)
        entries << {
          'title' => "#{post.data['title']} (FR)",
          'url' => build_url(baseurl, post.url),
          'type' => 'post',
          'date' => post.date ? post.date.strftime('%b %Y') : '',
          'categories' => Array(post.data['categories']).join(', '),
          'tags' => (Array(post.data['tags']) | ['français']).join(', '),
          'snippet' => FilterHost.truncate(text, SNIPPET_CHARS),
          'body' => text[0, MAX_POST_BODY_CHARS].to_s
        }
      end
    end

    # 2. Standalone content pages & tabs (collections, comic books, about)
    page_docs = site.pages + (site.collections['tabs'] ? site.collections['tabs'].docs : [])
    seen_urls = {}

    page_docs.each do |page|
      next unless page.output_ext == '.html'

      url = page.url.to_s
      next if url.empty? || url == '/' || url == '/404.html'
      next if url.start_with?('/categories/', '/tags/', '/norobots/')
      next if page.data['layout'] == 'archives' || page.data['layout'] == 'categories' || page.data['layout'] == 'tags'
      next if seen_urls[url]

      title = page.data['title'].to_s.strip
      next if title.empty?

      seen_urls[url] = true
      text = plain_text_from_doc(page, converter)
      label = 'Page'
      snippet = FilterHost.truncate(text, SNIPPET_CHARS)
      body = text

      if page.data['layout'] == 'comics'
        label = 'Comic Books'
        yr = page.data['comics_year']&.to_s
        if yr && !yr.empty?
          yr_entries = Array(site.data.dig('comics', yr))
          sample_titles = yr_entries.filter_map { |e| e['title'] }.first(5).join(', ')
          snippet = "#{yr_entries.size} comic books logged in #{yr}#{sample_titles.empty? ? '' : ": #{sample_titles}"}"
          body = "#{text} #{build_comics_year_text(yr_entries)}".strip
        elsif url == '/pages/comic-books/'
          extra = build_comics_hub_extra(site)
          body = "#{text} #{extra}".strip
        end
      elsif page.data['layout'] == 'typewriter' && (m = page.data['machine']).is_a?(Hash)
        label = 'Typewriter'
        meta_parts = [m['serial'].to_s.empty? ? nil : "Serial ##{m['serial']}", m['machine_type'], m['typeface'], m['status_label']].reject { |s| s.nil? || s.empty? }
        desc_plain = FilterHost.strip_html(m['description_html'].to_s).gsub(/\s+/, ' ').strip
        snippet = FilterHost.truncate([meta_parts.join(' · '), desc_plain].reject(&:empty?).join(' — '), SNIPPET_CHARS)
        body = [m['title'], m['brand'], m['model'], m['year'], m['serial'], m['typeface'], m['machine_type'], m['status'], desc_plain].reject { |s| s.nil? || s.empty? }.join(' ')
      elsif page.data['layout'] == 'typewriters'
        label = 'Typewriters'
        stats = site.data['typewriters_stats']
        if stats.is_a?(Hash)
          snippet = "Catalog of #{stats['total_collection']} typewriters on TWDB (#{stats['year_min']}–#{stats['year_max']}, #{stats['brands_count']} brands)."
        end
      elsif url.include?('typewriter') || url.include?('computer')
        label = 'Collection'
      end

      next if body.empty? && snippet.empty?

      entries << {
        'title' => title,
        'url' => build_url(baseurl, url),
        'type' => 'page',
        'date' => '',
        'categories' => label,
        'tags' => '',
        'snippet' => snippet,
        'body' => body[0, MAX_PAGE_BODY_CHARS].to_s
      }
    end

    site.data['search_index_json'] = JSON.generate(entries)
  end
end

Jekyll::Hooks.register :site, :pre_render, priority: :low do |site|
  BruchezSearchIndex.precompute(site)
end
