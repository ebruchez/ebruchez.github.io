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

    node = img
    while node && node.element?
      return true if node.key?('data-no-lightbox')

      if (cls = node['class']) && (cls.include?('no-lightbox') || cls.include?('post-carousel'))
        classes = cls.split
        return true if classes.include?('no-lightbox') || classes.include?('post-carousel')
      end
      node = node.parent
    end
    false
  end

  def collect_text_with_br(node, buf = +'')
    node.children.each do |child|
      if child.text?
        buf << child.content
      elsif child.element?
        if child.name == 'br'
          buf << "\n"
        else
          collect_text_with_br(child, buf)
        end
      end
    end
    buf
  end

  def derive_alt_from_figcaption(figcaption)
    return nil unless figcaption

    text = collect_text_with_br(figcaption)
    first_line = text.lines.map(&:strip).reject(&:empty?).first
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

  def collect_elements(root, tag_name, out = [])
    root.children.each do |child|
      next unless child.element?

      out << child if child.name == tag_name
      collect_elements(child, tag_name, out)
    end
    out
  end

  def find_first_element(root, tag_name)
    root.children.each do |child|
      next unless child.element?
      return child if child.name == tag_name

      found = find_first_element(child, tag_name)
      return found if found
    end
    nil
  end

  def transform(html)
    fragment = parse_fragment(html)
    changed = false

    collect_elements(fragment, 'img').each do |img|
      src = img['src']&.strip
      next if src.nil? || src.empty? || src.start_with?('data:')

      # Walk ancestors once in Ruby instead of compiling CSS/XPath per image
      skip = false
      figure = nil
      anchor = nil
      node = img
      while node && node.element?
        if node.key?('data-no-lightbox')
          skip = true
          break
        end
        if (cls = node['class']) && (cls.include?('no-lightbox') || cls.include?('post-carousel'))
          classes = cls.split
          if classes.include?('no-lightbox') || classes.include?('post-carousel')
            skip = true
            break
          end
        end
        if node != img
          figure ||= node if node.name == 'figure'
          anchor ||= node if node.name == 'a'
        end
        node = node.parent
      end
      next if skip

      figcaption = figure ? find_first_element(figure, 'figcaption') : nil
      caption_html = extract_caption_html(figcaption, img)

      if img['alt'].nil?
        derived_alt = derive_alt_from_figcaption(figcaption)
        img['alt'] = derived_alt || ''
      end

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
        anchor['href'] = src
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
