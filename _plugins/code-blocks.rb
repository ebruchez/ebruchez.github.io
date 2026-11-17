# frozen_string_literal: true

require 'nokogiri'

module BruchezCodeBlocks
  LANG_NAMES = {
    'bash' => 'Bash',
    'c' => 'C',
    'cpp' => 'C++',
    'css' => 'CSS',
    'diff' => 'Diff',
    'html' => 'HTML',
    'java' => 'Java',
    'javascript' => 'JavaScript',
    'js' => 'JavaScript',
    'json' => 'JSON',
    'liquid' => 'Liquid',
    'markdown' => 'Markdown',
    'md' => 'Markdown',
    'python' => 'Python',
    'rb' => 'Ruby',
    'ruby' => 'Ruby',
    'scala' => 'Scala',
    'scss' => 'SCSS',
    'sh' => 'Shell',
    'shell' => 'Shell',
    'sql' => 'SQL',
    'ts' => 'TypeScript',
    'typescript' => 'TypeScript',
    'xml' => 'XML',
    'xslt' => 'XSLT',
    'yaml' => 'YAML',
    'yml' => 'YAML',
    'zsh' => 'Zsh'
  }.freeze

  SILENT_LANGS = %w[plaintext text console terminal].freeze

  module_function

  def parse_fragment(html)
    if Nokogiri.respond_to?(:HTML5)
      Nokogiri::HTML5.fragment(html)
    else
      Nokogiri::HTML::DocumentFragment.parse(html)
    end
  end

  def collect_rouge_divs(node, out = [])
    node.children.each do |child|
      next unless child.element?

      if child.name == 'div' && (cls = child['class']) && cls.include?('highlighter-rouge')
        classes = cls.split
        out << [child, classes] if classes.include?('highlighter-rouge')
      else
        collect_rouge_divs(child, out)
      end
    end
    out
  end

  def find_code_target(rouge_div)
    rouge_div.css('td.rouge-code > pre').first ||
      rouge_div.css('div.highlight > pre > code').first ||
      rouge_div.css('div.highlight > code').first ||
      rouge_div.css('pre').first
  end

  def format_lang(raw_lang)
    return nil if raw_lang.nil? || raw_lang.empty?

    key = raw_lang.downcase
    return nil if SILENT_LANGS.include?(key)

    LANG_NAMES[key] || raw_lang.capitalize
  end

  def transform(html)
    fragment = parse_fragment(html)
    blocks = collect_rouge_divs(fragment)
    return html if blocks.empty?

    changed = false
    seq = 0

    blocks.each do |div, classes|
      next if classes.include?('language-mermaid')
      next if div.at_css('.code-copy')

      target = find_code_target(div)
      next unless target

      seq += 1
      snippet_id = target['id']
      if snippet_id.nil? || snippet_id.empty?
        snippet_id = "code-snippet-#{seq}"
        target['id'] = snippet_id
      end

      lang_cls = classes.find { |c| c.start_with?('language-') }
      raw_lang = lang_cls ? lang_cls.delete_prefix('language-') : nil
      display_lang = format_lang(raw_lang)
      div['data-lang'] = display_lang if display_lang && !div.key?('data-lang')

      aria_label = display_lang ? "Copy #{display_lang} code" : 'Copy code'

      doc = fragment.document
      wrapper = doc.create_element('span', class: 'copy code-copy')
      btn = doc.create_element(
        'button',
        type: 'button',
        class: 'copy-button',
        command: '--copy',
        commandfor: snippet_id,
        'aria-label' => aria_label,
        title: aria_label
      )
      icon = doc.create_element('i', class: 'far fa-copy', 'aria-hidden' => 'true')
      tip = doc.create_element('span', class: 'tip', role: 'status')

      btn.add_child(icon)
      wrapper.add_child(btn)
      wrapper.add_child(tip)

      first_child = div.children.first
      if first_child
        first_child.add_previous_sibling(wrapper)
      else
        div.add_child(wrapper)
      end

      changed = true
    end

    changed ? fragment.to_html : html
  end
end

Jekyll::Hooks.register [:pages, :documents], :post_convert do |item|
  next unless item.output_ext == '.html'
  next unless item.content&.include?('highlighter-rouge')

  item.content = BruchezCodeBlocks.transform(item.content)
end
