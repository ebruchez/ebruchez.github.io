# frozen_string_literal: true

require 'nokogiri'

module BruchezLightbox
  IMAGE_HREF_RE = /\.(?:jpe?g|png|webp|gif|avif|svg)(?:\?[^#]*)?(?:#.*)?$/i
  GALLERY_ID = 'page-gallery'

  module_function

  def parse_fragment(html)
    if Nokogiri.respond_to?(:HTML5)
      Nokogiri::HTML5.fragment(html)
    else
      Nokogiri::HTML::DocumentFragment.parse(html)
    end
  end

  def skip_image?(img)
    src = img['src']&.strip
    return true if src.nil? || src.empty? || src.start_with?('data:')

    ([img] + img.ancestors).any? do |node|
      next false unless node.element?

      classes = node['class'].to_s.split
      node.key?('data-no-lightbox') ||
        classes.include?('no-lightbox') ||
        classes.include?('post-carousel')
    end
  end

  def derive_alt_from_figcaption(figcaption)
    return nil unless figcaption

    clone = figcaption.dup
    clone.css('br').each { |br| br.replace("\n") }
    first_line = clone.text.lines.map(&:strip).reject(&:empty?).first
    return nil if first_line.nil? || first_line.empty?

    first_line.length > 160 ? "#{first_line[0, 157].rstrip}..." : first_line
  end

  def extract_caption_html(figcaption, img)
    if figcaption
      html = figcaption.inner_html.strip.gsub(/\s*\n\s*/, ' ')
      return html unless html.empty?
    end
    title = img['data-caption']&.strip || img['title']&.strip
    title && !title.empty? ? title : nil
  end

  def add_classes(node, *names)
    existing = node['class'].to_s.split
    node['class'] = (existing | names).join(' ')
  end

  def transform(html)
    fragment = parse_fragment(html)
    changed = false

    fragment.css('img').each do |img|
      next if skip_image?(img)

      figure = img.ancestors('figure').first
      figcaption = figure&.at_css('figcaption')
      caption_html = extract_caption_html(figcaption, img)

      if img['alt'].nil?
        derived_alt = derive_alt_from_figcaption(figcaption)
        img['alt'] = derived_alt || ''
      end

      anchor = img.ancestors('a').first
      if anchor
        next if anchor.key?('data-lightbox')

        href = anchor['href']&.strip.to_s
        next unless href.match?(IMAGE_HREF_RE)

        add_classes(anchor, 'img-hyperlink', 'lightbox-trigger')
        anchor['data-lightbox'] = GALLERY_ID
        anchor['data-caption'] = caption_html if caption_html && !anchor.key?('data-caption')
        anchor['aria-label'] = 'Expand image' if img['alt'].to_s.strip.empty? && !anchor.key?('aria-label')
        changed = true
      else
        anchor = fragment.document.create_element('a')
        anchor['href'] = img['src'].strip
        anchor['class'] = 'img-hyperlink lightbox-trigger'
        anchor['data-lightbox'] = GALLERY_ID
        anchor['data-caption'] = caption_html if caption_html
        anchor['aria-label'] = 'Expand image' if img['alt'].to_s.strip.empty?
        img.replace(anchor)
        anchor.add_child(img)
        changed = true
      end
    end

    changed ? fragment.to_html : html
  end
end

Jekyll::Hooks.register [:pages, :documents], :post_convert do |item|
  next unless %w[post page].include?(item.data['layout'])
  next if item.data['lightbox'] == false
  next unless item.output_ext == '.html'
  next unless item.content&.include?('<img')

  item.content = BruchezLightbox.transform(item.content)
end
