#!/usr/bin/env ruby
# frozen_string_literal: true

# One-time / repeatable migration script converting pages/comic-books-YYYY.md
# (2015..2026) into structured _data/comics/YYYY.yml files.

require 'yaml'
require 'fileutils'
require 'unicode_normalize/normalize' rescue nil

ROOT = File.expand_path('..', __dir__)
PAGES_DIR = File.join(ROOT, 'pages')
OUT_DIR = File.join(ROOT, '_data', 'comics')

BARE_CREATORS = [
  'Roger Leloup',
  'Jacques Martin',
  'Edgar P. Jacobs',
  'Cosey',
  'Eddy Paape',
  'Greg',
  'Fábio Moon',
  'Gabriel Bá',
  'Massimo De Vita',
  'Guido Martina, Giovan Battista Carpi',
  'Guido Martina, Romano Scarpa, Giovan Battista Carpi, Giorgio Cavazzano',
  'Tackian',
  'Brion',
  'Gonzalbo',
  'Palma',
  'Don Rosa',
  'Carl Barks',
  'Daan Jippes',
  'William Van Horn',
  'Marco Rota',
  'wanda Gattino & Daniel Branca',
  'Faccini'
].freeze

EDITION_RE = /\A(?:La Grande Collection|Topolino Limited De Luxe Edition|Disney Golden Edition|version facsimil[eé]|édition facsimil[eé]|\d+\s+pages|\d+\s+volumes|\d{3}-\d{3})\z/i
YEAR_RE = /\A(?:19\d\d|20\d\d)(?:\s*(?:[,\/\-–]\s*(?:19\d\d|20\d\d|\d\d)|\(.*\)|-TODO))?\??\z/i
RATING_BARE_RE = /\A([1-5](?:\.\d)?)\s*\/\s*5\z/

def slugify(str)
  s = str.to_s
         .gsub(/Æ/i, 'ae')
         .gsub(/Œ/i, 'oe')
         .gsub(/ß/, 'ss')
         .gsub(/Ø/i, 'o')
         .unicode_normalize(:nfd)
         .gsub(/\p{Mn}/, '')
  s = s.downcase.gsub(/[^a-z0-9]+/, '-').gsub(/\A-+|-+\z/, '')
  s.empty? ? 'entry' : s[0, 72].sub(/-+\z/, '')
end

def clean_url(url)
  return nil if url.nil?

  u = url.strip
  return nil if u.empty?

  u = u.sub(/\.htmlx\z/i, '.html')
  u = u.sub(%r{\Ahttp://(www\.)?bedetheque\.com/}i, 'https://www.bedetheque.com/')
  u
end

def fix_inline_links(text)
  return '' if text.nil?

  s = text.dup
  # Fix accidental double opening brackets: [[Title](url) -> [Title](url)
  s.gsub!(/\[\[([^\[\]]+)\]\(([^)]+)\)/, '[\1](\2)')
  # Fix accidental trailing double closing paren on bedetheque links: [Title](url.html)) -> [Title](url.html)
  s.gsub!(/(\[[^\]]+\]\(https?:\/\/[^\s)]+\.htmlx?\))\)/, '\1')
  # Fix .htmlx typo inside markdown links
  s.gsub!(/(\(https?:\/\/[^\s)]+)\.htmlx\)/, '\1.html)')
  # Upgrade http bedetheque links
  s.gsub!(%r{\(http://(?:www\.)?bedetheque\.com/}, '(https://www.bedetheque.com/')
  # Convert empty links [Title]() -> Title
  s.gsub!(/\[([^\]]+)\]\(\s*\)/, '\1')
  s
end

def extract_title_and_link(raw)
  s = fix_inline_links(raw.strip)
  # Strip stray leading "- " if any (e.g. "- 2026-09-30: - [Blake...")
  s = s.sub(/\A-\s+/, '')
  # Unwrap bare [Title] with no (url)
  if s.match?(/\A\[[^\]]+\]\z/)
    return [s[1..-2].strip, nil]
  end

  # Case 1: entire string is [Title](url)
  if (m = s.match(/\A\[([^\]]+)\]\(([^\)]+)\)\z/))
    return [m[1].strip, clean_url(m[2])]
  end

  # Case 2: "4\. [Title](url)" or "9. Title ([tome 9](url))"
  if (m = s.match(/\A(\d+)\\?\.\s*\[([^\]]+)\]\(([^\)]+)\)\z/))
    return ["#{m[1]}. #{m[2].strip}", clean_url(m[3])]
  end

  if (m = s.match(/\A(.+?)\s*\(\[[^\]]+\]\(([^\)]+)\)\)\z/))
    return [m[1].strip, clean_url(m[2])]
  end

  [s.gsub('\\.', '.').strip, nil]
end

def strip_md_links(str)
  str.to_s.gsub(/\[([^\]]+)\]\([^\)]*\)/, '\1').strip
end

def split_creators(val)
  cleaned = strip_md_links(val).sub(/,\s*\z/, '')
  cleaned.split(/\s*(?:,|&|\bet\b)\s*/).map(&:strip).reject(&:empty?)
end

def assign_url(target, url)
  return unless url

  if url.include?('bedetheque.com')
    target['bedetheque_url'] = url
  else
    target['url'] = url
  end
end

# Parse lines after `# Comic Books (YYYY)` into top-level blocks + section labels
def parse_markdown_file(path)
  lines = File.readlines(path, chomp: true)
  body_start = lines.index { |l| l.start_with?('# ') }
  raise "No H1 found in #{path}" unless body_start

  body_lines = lines[(body_start + 1)..] || []
  entries = []
  pending_section = nil
  current_root = nil
  stack = [] # [[indent, node], ...]

  body_lines.each do |raw_line|
    next if raw_line.strip.empty?

    if raw_line.match?(/\A\s*-\s*/)
      indent = raw_line[/\A */].length
      text = raw_line.sub(/\A\s*-\s*/, '').rstrip
      node = { 'text' => text, 'indent' => indent, 'children' => [] }

      if indent == 0
        node['section'] = pending_section if pending_section
        pending_section = nil
        entries << node
        current_root = node
        stack = [[0, node]]
      else
        while stack.length > 1 && stack.last[0] >= indent
          stack.pop
        end
        parent = stack.last ? stack.last[1] : current_root
        if parent
          parent['children'] << node
          stack << [indent, node]
        end
      end
    elsif raw_line.start_with?('#')
      pending_section = raw_line.sub(/\A#+\s*/, '').strip
    elsif raw_line.match?(/\A\s*\(ordered .*\)\s*\z/i)
      pending_section = raw_line.strip.sub(/\A\(/, '').sub(/\)\z/, '')
      pending_section = pending_section[0].upcase + pending_section[1..]
    elsif !stack.empty?
      # Continuation line inside a bullet (e.g. multi-paragraph blockquote/note in 2020/2023)
      last_node = stack.last[1]
      last_node['text'] = "#{last_node['text']}\n\n#{raw_line.strip}"
    end
  end

  entries
end

def render_nodes_to_markdown(nodes, depth = 0)
  valid_nodes = nodes.reject do |n|
    t = fix_inline_links(n['text'].to_s).strip
    (t.empty? || t == 'TODO') && Array(n['children']).empty?
  end

  lines = []
  valid_nodes.each do |n|
    txt = fix_inline_links(n['text'].to_s).strip
    next if txt.empty? || txt == 'TODO'

    if depth == 0 && valid_nodes.length == 1 && n['children'].empty?
      lines << txt
    else
      prefix = '  ' * depth
      # Indent internal blank-line continuations nicely
      formatted = txt.lines.each_with_index.map do |l, idx|
        idx == 0 ? "#{prefix}- #{l.rstrip}" : "#{prefix}  #{l.rstrip}"
      end.join("\n")
      lines << formatted
      unless n['children'].empty?
        lines << render_nodes_to_markdown(n['children'], depth + 1)
      end
    end
  end
  lines.join("\n")
end

PLOT_SIGNAL_RE = /\b(?:kills?|killed|murdered|murder|dies|died|dead|escapes?|escaped|rescued|kidnapped|imprisoned|prisoner|betrays?|cliffhanger|in the meanwhile|in the end|at the end|that's the end|prophecy|suicide|tortures?|paralyzes?|explodes?)\b/i
OPINION_SIGNAL_RE = /\b(?:i like|i love|i think|i wish|i find|i found|i prefer|i disagree|i agree|my favorite|good story|great story|excellent|beautiful|amazing|well done|not bad|disappointing|so-so|rating|bedetheque|art is|drawings are|humor is|humour is|masterpiece|classic)\b/i

def looks_like_plot_recap?(md_text)
  plain = md_text.gsub(/\s+/, ' ').strip
  return false if plain.length < 240

  plot_hits = plain.scan(PLOT_SIGNAL_RE).size
  opinion_hits = plain.scan(OPINION_SIGNAL_RE).size

  return true if plot_hits >= 3 && plain.length >= 300
  return true if plot_hits >= 2 && opinion_hits == 0 && plain.length >= 260
  return true if md_text.include?('- Tome 1') && md_text.include?('- Tome 2')

  false
end

def split_notes_blocks(note_blocks)
  reviews = []
  spoilers = []

  note_blocks.each do |block|
    next if block.nil?

    if block.is_a?(Hash) && block[:kind] == :spoiler
      spoilers << block[:text] unless block[:text].to_s.strip.empty?
      next
    end

    txt = block.is_a?(Hash) ? block[:text].to_s : block.to_s
    next if txt.strip.empty? || txt.strip == 'TODO'

    if looks_like_plot_recap?(txt)
      spoilers << txt
    else
      reviews << txt
    end
  end

  [
    reviews.empty? ? nil : reviews.join("\n\n"),
    spoilers.empty? ? nil : spoilers.join("\n\n")
  ]
end

def extract_notes_node(node)
  raw = node['text'].to_s
  head = raw.sub(/\ANOTES?[.:]?\s*/i, '').strip
  children = node['children'] || []

  blocks = []
  review_bullets = []

  if !head.empty? && head != 'TODO'
    blocks << { kind: looks_like_plot_recap?(head) ? :spoiler : :auto, text: fix_inline_links(head) }
  end

  unless children.empty?
    # Check if there is an explicit "- The story:" or "- Tome 1" plot child alongside review bullets!
    has_story_subtree = children.any? do |c|
      c['text'].to_s.strip.match?(/\A(?:The story:?|Tome \d+)\z/i) && !c['children'].empty?
    end

    if has_story_subtree
      story_nodes = []
      other_nodes = []
      children.each do |c|
        if c['text'].to_s.strip.match?(/\A(?:The story:?|Tome \d+)\z/i) && !c['children'].empty?
          if c['text'].to_s.strip.match?(/\AThe story:?\z/i)
            story_nodes.concat(c['children'])
          else
            story_nodes << c
          end
        else
          other_nodes << c
        end
      end
      unless other_nodes.empty?
        blocks << { kind: :review_prefer, text: render_nodes_to_markdown(other_nodes) }
      end
      unless story_nodes.empty?
        blocks << { kind: :spoiler, text: render_nodes_to_markdown(story_nodes) }
      end
    elsif children.length == 1 && children.first['children'].empty?
      single = fix_inline_links(children.first['text'].to_s.strip)
      blocks << { kind: :auto, text: single } unless single.empty? || single == 'TODO'
    else
      rendered = render_nodes_to_markdown(children)
      blocks << { kind: :auto, text: rendered } unless rendered.strip.empty?
    end
  end

  blocks.map do |b|
    if b[:kind] == :review_prefer
      b[:text]
    else
      b
    end
  end
end

def parse_header_date_and_title(raw_text)
  s = raw_text.strip
  read_date = nil

  # Fix 2025-032 typo -> 2025-02
  if s.start_with?('2025-032 ')
    read_date = '2025-02'
    s = s.sub(/\A2025-032\s+/, '')
  elsif (m = s.match(/\A((?:19|20)\d\d(?:-\d\d(?:-(?:\d\d|xx|0x))?)?)\s*:\s*(.+)\z/))
    read_date = m[1]
    s = m[2]
  end

  title, link = extract_title_and_link(s)
  [read_date, title, link]
end

def parse_item_fields(node, is_sub_item: false)
  read_date, title, link = parse_header_date_and_title(node['text'])
  item = {}
  item['read_date'] = read_date if read_date
  item['title'] = title
  assign_url(item, link)

  writers = []
  artists = []
  colors = []
  authors = []
  editions = []
  extra_tags = []
  note_blocks = []
  sub_items = []

  (node['children'] || []).each do |child|
    ctext = child['text'].to_s.strip
    cchildren = child['children'] || []

    # 1. Explicit NOTES / NOTE / Synopsis
    if ctext.match?(/\ANOTES?(?:[.:]|\z)/i)
      note_blocks.concat(extract_notes_node(child))
      next
    end

    if ctext.casecmp('Synopsis').zero?
      syn_md = render_nodes_to_markdown(cchildren)
      note_blocks << { kind: :spoiler, text: syn_md } unless syn_md.empty?
      next
    end

    if ctext.casecmp('Stories').zero? && !cchildren.empty?
      cchildren.each do |sc|
        sub_items << parse_item_fields(sc, is_sub_item: true)
      end
      next
    end

    # 2. Key: Value metadata lines (only when child has no sub-children, except NOTES handled above)
    if cchildren.empty? && (km = ctext.match(/\A([A-Za-zÀ-ÿ' ]+?)\s*:\s*(.*)\z/))
      key = km[1].strip
      val = km[2].strip

      case key.downcase
      when 'language'
        item['language'] = val unless val.empty?
        next
      when 'tags'
        tokens = val.split(/\s+/)
        tokens.each do |tok|
          if tok.casecmp('#reread').zero? || tok.casecmp('reread').zero?
            item['reread'] = true
          else
            extra_tags << tok.sub(/\A#/, '')
          end
        end
        next
      when 'rating'
        if (rm = val.match(/\A([1-5](?:\.\d)?)\s*\/\s*5\z/))
          num = rm[1].include?('.') ? rm[1].to_f : rm[1].to_i
          item['rating'] = num
          next
        end
      when 'date'
        cleaned_yr = val.sub(/-TODO\z/i, '')
        item['year'] = cleaned_yr.match?(/\A\d{4}\z/) ? cleaned_yr.to_i : cleaned_yr unless cleaned_yr.empty?
        next
      when 'scénario', 'scenario', 'scenarios', 'story', 'sceneggiatura', 'soggetto'
        writers.concat(split_creators(val))
        next
      when 'dessin', 'dessins', 'drawings', 'disegni', 'artists', 'art'
        artists.concat(split_creators(val))
        next
      when 'couleurs', 'color', 'colors'
        colors.concat(split_creators(val))
        next
      when 'dessin et couleur', 'dessin et couleurs'
        shared = split_creators(val)
        artists.concat(shared)
        colors.concat(shared)
        next
      when 'author', 'authors', 'scénario et dessin', 'scénario et dessins'
        authors.concat(split_creators(val))
        next
      when 'adapted from', "d'après"
        item['adapted_from'] = strip_md_links(val) unless val.empty?
        next
      end
    end

    # "Story by X" / "Art by Y" (used in Wizards of Mickey in 2021)
    if ctext.match?(/\AStory by /i)
      writers.concat(split_creators(ctext.sub(/\AStory by /i, '')))
      cchildren.each do |gc|
        if gc['text'].to_s.strip.match?(/\AArt by /i)
          artists.concat(split_creators(gc['text'].to_s.strip.sub(/\AArt by /i, '')))
        end
      end
      next
    elsif ctext.match?(/\AArt by /i) && cchildren.empty?
      artists.concat(split_creators(ctext.sub(/\AArt by /i, '')))
      next
    end

    # 3. Leaf metadata patterns (year, bare rating, edition, bare creator, slash creator in Italian anthologies)
    if cchildren.empty?
      if (rm = ctext.match(RATING_BARE_RE))
        num = rm[1].include?('.') ? rm[1].to_f : rm[1].to_i
        item['rating'] = num
        next
      end

      if ctext.match?(YEAR_RE)
        cleaned_yr = ctext.sub(/-TODO\z/i, '')
        item['year'] = cleaned_yr.match?(/\A\d{4}\z/) ? cleaned_yr.to_i : cleaned_yr
        next
      end

      if ctext.match?(EDITION_RE)
        editions << ctext
        next
      end

      if BARE_CREATORS.any? { |bc| bc.casecmp(ctext).zero? }
        fixed_creator = ctext.sub(/\Awanda /, 'Wanda ')
        authors.concat(split_creators(fixed_creator))
        next
      end

      # Slash creator pair inside anthology stories (e.g. "Transgaard/Andersen", "Carpi/Bottaro")
      if is_sub_item && ctext.match?(/\A[A-ZÀ-Ÿ][A-Za-zÀ-ÿ.' &]+\/[A-ZÀ-Ÿ][A-Za-zÀ-ÿ.' &]+\z/)
        parts = ctext.split('/', 2).map(&:strip)
        writers << parts[0]
        artists << parts[1]
        next
      end
    end

    # 4. Sub-items (Intégrale tomes, magazine stories, dated sub-reads, or items with nested metadata)
    looks_like_sub_tome =
      ctext.start_with?('[') ||
      ctext.match?(/\A(?:19|20)\d\d-\d\d.*:\s*\[/) ||
      ctext.match?(/\A\d+\\?\.\s+\S/) ||
      ctext.match?(/\A-\d+:\s+\S/) ||
      !cchildren.empty? ||
      (!sub_items.empty? && ctext.length < 60 && !ctext.end_with?('.'))

    if looks_like_sub_tome
      # Wait: inside an Intégrale sub-tome like `[Tome 2 - Il y a un sorcier...]` in 2026.md,
      # its children might be direct review bullet points (without a `NOTES:` wrapper)!
      if is_sub_item
        # Already inside a sub_item (e.g. Wizards of Mickey arc -> chapter, or direct review bullets on a sub-tome)
        # Check if children are Story by / Art by -> nested sub_item, else treat as note bullets!
        has_sub_meta = cchildren.any? { |gc| gc['text'].to_s.match?(/\A(?:Story by|Art by|Scénario|Dessin|19\d\d|20\d\d|NOTES?)/i) }
        if !cchildren.empty? && has_sub_meta
          sub_items << parse_item_fields(child, is_sub_item: true)
        else
          md = render_nodes_to_markdown([child])
          note_blocks << { kind: :auto, text: md } unless md.empty?
        end
      else
        sub_items << parse_item_fields(child, is_sub_item: true)
      end
      next
    end

    # 5. Bare comment / note bullet on the entry itself (e.g. "one of the best Lefranc albums")
    fixed_comment = fix_inline_links(ctext)
    note_blocks << { kind: :auto, text: fixed_comment } unless fixed_comment.empty? || fixed_comment == 'TODO'
  end

  # Deduplicate creator lists preserving order
  writers.uniq!
  artists.uniq!
  colors.uniq!
  authors.uniq!

  # If writers == artists (e.g. Hergé / Fournier / Fabio Celoni), collapse into authors for cleaner YAML
  if !writers.empty? && writers == artists && authors.empty?
    authors = writers
    writers = []
    artists = []
  end

  item['edition'] = editions.join(', ') unless editions.empty?
  item['authors'] = authors unless authors.empty?
  item['writers'] = writers unless writers.empty?
  item['artists'] = artists unless artists.empty?
  item['colors'] = colors unless colors.empty?
  item['tags'] = extra_tags unless extra_tags.empty?

  review_txt, notes_txt = split_notes_blocks(note_blocks)
  item['review'] = review_txt if review_txt && !review_txt.strip.empty?
  item['notes'] = notes_txt if notes_txt && !notes_txt.strip.empty?
  item['sub_items'] = sub_items unless sub_items.empty?

  item
end

FileUtils.mkdir_p(OUT_DIR)

summary = []

Dir.glob(File.join(PAGES_DIR, 'comic-books-20*.md')).sort.each do |md_path|
  year = File.basename(md_path)[/20\d\d/]
  raw_nodes = parse_markdown_file(md_path)
  seen_ids = Hash.new(0)

  items = raw_nodes.map do |node|
    parsed = parse_item_fields(node, is_sub_item: false)
    base_id = slugify(parsed['title'])
    seen_ids[base_id] += 1
    final_id = seen_ids[base_id] == 1 ? base_id : "#{base_id}-#{seen_ids[base_id]}"

    ordered = { 'id' => final_id }
    ordered['section'] = node['section'] if node['section']
    %w[
      read_date title year edition language
      authors writers artists colors adapted_from
      bedetheque_url url cover rating reread tags
      featured review notes sub_items
    ].each do |k|
      ordered[k] = parsed[k] if parsed.key?(k)
    end
    ordered
  end

  out_path = File.join(OUT_DIR, "#{year}.yml")
  yaml_str = YAML.dump(items, line_width: 100).sub(/\A---\s*\n/, '')
  File.write(out_path, "# Comic book reads for #{year}\n#{yaml_str}")

  bede_count = items.count { |i| i['bedetheque_url'] || Array(i['sub_items']).any? { |s| s['bedetheque_url'] } }
  rev_count = items.count { |i| i['review'] }
  note_count = items.count { |i| i['notes'] }
  sub_count = items.sum { |i| Array(i['sub_items']).size }
  summary << format('%s: %3d entries (%3d bedetheque, %2d reviews, %2d spoiler-notes, %2d sub_items)',
                    year, items.size, bede_count, rev_count, note_count, sub_count)
end

puts summary.join("\n")
