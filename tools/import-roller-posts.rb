#!/usr/bin/env ruby
# frozen_string_literal: true

# Import historical Apache Roller blog posts (2002-2006) from erik-roller-import/
# and copy/normalize referenced images from "Images from blog/" into assets/posts/roller/.

require 'cgi'
require 'fileutils'
require 'nokogiri'
require 'rexml/document'
require 'time'
require 'uri'
require 'yaml'

ROOT_DIR = File.expand_path('..', __dir__)
JAN_DUMP = File.join(ROOT_DIR, 'erik-roller-import', '2007-01-14 - roller.xml')
JUL_DUMP = File.join(ROOT_DIR, 'erik-roller-import', '2007-07-06 - roller [nothing new].xml')
IMAGES_SRC_DIR = File.join(ROOT_DIR, 'Images from blog')
IMAGES_DEST_DIR = File.join(ROOT_DIR, 'assets', 'posts', 'roller')
POSTS_DIR = File.join(ROOT_DIR, '_posts')
DRAFTS_DIR = File.join(ROOT_DIR, '_drafts')

HIGH_RES_UPGRADES = {
  'Lyon01a.jpg' => 'Lyon01.jpg',
  'Printing01a.jpg' => 'Printing01.jpg'
}.freeze

FRENCH_ANCHORS = %w[
  un_plaisant_voyage
  bonne_intention_de_d_eacute
  d_eacute_cevant_la_religion
  une_bonne_et_attendue_biographie
  n_allez_pas_a_l
  quand_google_defie_l_europe
  gastrosuisse_le_mauvais_combat
  aap_google_print_and_new
  un_juriste_vendu_au_lobby
  personne_pour_d_eacute_fendre
].freeze

CUSTOM_SLUGS = {
  'un_plaisant_voyage' => 'un-plaisant-voyage-mysterieux-mozart',
  'speaker_for_the_dead_by' => 'speaker-for-the-dead',
  'bonne_intention_de_d_eacute' => 'l-obsession-anti-americaine',
  'd_eacute_cevant_la_religion' => 'decevant-la-religion-dans-la-democratie',
  'une_bonne_et_attendue_biographie' => 'la-damnation-d-edgar-p-jacobs',
  'surprising_but_not_as_good' => 'the-man-in-the-high-castle',
  'boukreev_s_explanation_the_climb' => 'boukreevs-explanation-the-climb',
  'the_immortal_cell_by_michael' => 'the-immortal-cell',
  'n_allez_pas_a_l' => 'n-allez-pas-a-l-hotel-alpenblick-a-leukerbad',
  'quand_google_defie_l_europe' => 'quand-google-defie-l-europe',
  'wikipedia_on_cell_phones_not' => 'wikipedia-on-cell-phones-not-quite-there',
  'the_hammer_of_god_by' => 'the-hammer-of-god',
  'gastrosuisse_has_picked_the_wrong' => 'gastrosuisse-has-picked-the-wrong-fight',
  'aap_google_print_and_new' => 'aap-google-print-et-les-nouveaux-luddites',
  'aap_google_print_and_the' => 'aap-google-print-and-the-new-luddites',
  'pietro_mascagni_not_doing_too' => 'pietro-mascagni-not-doing-too-bad-in-italian-streets',
  'carl_sagan_a_life_in' => 'carl-sagan-a-life-in-the-cosmos',
  'the_singularity_do_people_want' => 'the-singularity-do-people-want-it',
  'macbook_pro_17_worth_it' => 'getting-more-ready-to-switch',
  'credit_cards_don_t_make' => 'credit-cards-dont-make-the-same-mistake',
  'sad_day_for_journalism_and' => 'sad-day-for-journalism-and-freedom',
  'finally_apple_releases_the_core' => 'finally-apple-releases-the-core-2-duo-macbook-pro',
  'personne_pour_d_eacute_fendre' => 'personne-pour-defendre-la-science'
}.freeze

def parse_roller_dump(path)
  doc = REXML::Document.new(File.read(path))
  tables = {}
  doc.elements.each('mysqldump/database/table_data') do |td|
    tname = td.attributes['name']
    rows = []
    td.elements.each('row') do |r|
      row = {}
      r.elements.each('field') do |f|
        row[f.attributes['name']] = f.text.to_s
      end
      rows << row
    end
    tables[tname] = rows
  end
  tables
end

def ascii_slug(str)
  s = str.to_s.unicode_normalize(:nfd).gsub(/\p{Mn}/, '')
  s.downcase.gsub(/[^a-z0-9]+/, '-').gsub(/\A-+|-+\z/, '')
end

def normalize_asset_filename(orig_name)
  ext = File.extname(orig_name).downcase
  base = File.basename(orig_name, File.extname(orig_name))
  "#{ascii_slug(base)}#{ext}"
end

def read_image_dimensions(path)
  out = `sips -g pixelWidth -g pixelHeight "#{path}" 2>/dev/null`
  w = out[/pixelWidth:\s*(\d+)/, 1]&.to_i
  h = out[/pixelHeight:\s*(\d+)/, 1]&.to_i
  w && h && w.positive? && h.positive? ? [w, h] : [nil, nil]
end

def locate_source_image(raw_filename, disk_files)
  nfc = raw_filename.unicode_normalize(:nfc)
  exact = disk_files.find { |f| f.unicode_normalize(:nfc) == nfc }
  return exact if exact

  return disk_files.find { |f| f.include?('Mozart - 01a.jpg') } if nfc.include?('Mozart')
  return disk_files.find { |f| f.include?('anti-am') && f.end_with?('01a.jpg') } if nfc.include?('anti-am')

  nil
end

def map_categories_and_tags(entry, roller_cat_name)
  anchor = entry['anchor']
  tags = []
  tags << 'french' if FRENCH_ANCHORS.include?(anchor)

  categories = case roller_cat_name
               when 'Technology'
                 ['Technology']
               when 'Music'
                 ['Music']
               when 'Book Reviews'
                 tags << 'reading'
                 ['Book Reviews']
               when 'Français'
                 anchor == 'aap_google_print_and_new' ? ['Technology'] : ['Other']
               else
                 anchor == 'bbc_downloads' ? ['Music'] : ['Other']
               end

  [categories, tags.uniq]
end

class RollerHtmlConverter
  def initialize(url_rewrites:, disk_files:, copied_assets:)
    @url_rewrites = url_rewrites
    @disk_files = disk_files
    @copied_assets = copied_assets
    @rating = nil
  end

  attr_reader :rating

  def convert(raw_html)
    frag = if Nokogiri.respond_to?(:HTML5)
             Nokogiri::HTML5.fragment(raw_html)
           else
             Nokogiri::HTML::DocumentFragment.parse(raw_html)
           end

    extract_star_rating!(frag)
    blocks = render_block_children(frag)
    blocks.join("\n\n").gsub(/\n{3,}/, "\n\n").strip
  end

  private

  def extract_star_rating!(frag)
    stars = frag.css('img').select { |img| img['src'].to_s.start_with?('/images/star-') }
    return if stars.empty?

    score = 0.0
    stars.each do |img|
      src = img['src'].to_s
      if src.include?('star-full')
        score += 1.0
      elsif src.include?('star-half')
        score += 0.5
      end
      img.remove
    end
    @rating = (score % 1.0).zero? ? score.to_i : score
  end

  def rewrite_href(href)
    return '' if href.nil?

    clean = href.strip
    return @url_rewrites[clean] if @url_rewrites.key?(clean)

    no_slash = clean.chomp('/')
    return @url_rewrites[no_slash] if @url_rewrites.key?(no_slash)

    clean
  end

  def copy_and_render_image(img_node)
    src = img_node['src'].to_s.strip
    return nil if src.empty?

    # Omit dead 2005 external gallery processed-image URL in marcus_miller_in_cully
    return nil if src.include?('erik.bruchez.name/pictures/processed-images/')

    return nil unless src.include?('/resources/ebruchez/')

    raw_fname = CGI.unescape(src.split('/resources/ebruchez/').last)
    disk_fname = locate_source_image(raw_fname, @disk_files)
    raise "Missing image in 'Images from blog/': #{raw_fname} (from #{src})" unless disk_fname

    chosen_disk_fname = HIGH_RES_UPGRADES[disk_fname] || disk_fname
    clean_label_fname = HIGH_RES_UPGRADES[disk_fname] || raw_fname
    dest_fname = normalize_asset_filename(clean_label_fname)
    src_path = File.join(IMAGES_SRC_DIR, chosen_disk_fname)
    dest_path = File.join(IMAGES_DEST_DIR, dest_fname)

    unless @copied_assets.key?(dest_fname)
      FileUtils.mkdir_p(IMAGES_DEST_DIR)
      FileUtils.cp(src_path, dest_path)
      File.chmod(0o644, dest_path)
      @copied_assets[dest_fname] = read_image_dimensions(dest_path)
    end

    actual_w, _actual_h = @copied_assets[dest_fname]
    disp_w = img_node['width']&.to_i
    disp_h = img_node['height']&.to_i
    if disp_w.nil? || disp_w <= 0
      disp_w, disp_h = @copied_assets[dest_fname]
    end

    align = img_node['align'].to_s.downcase
    fig_cls = align == 'left' ? 'roller-figure roller-figure--left' : 'roller-figure'
    no_lb = actual_w && actual_w <= 260 ? ' data-no-lightbox' : ''
    alt = CGI.escapeHTML(img_node['alt'].to_s.strip)
    wh = disp_w && disp_h ? %( width="#{disp_w}" height="#{disp_h}") : ''
    asset_url = "/assets/posts/roller/#{dest_fname}"

    %(<figure class="#{fig_cls}"#{no_lb}><img src="#{asset_url}" alt="#{alt}"#{wh} loading="lazy"></figure>)
  end

  def wrap_inline_marker(inner, marker)
    return '' if inner.empty?

    lead = inner[/\A\s+/] || ''
    trail = inner[/\s+\z/] || ''
    core = inner.strip
    return inner if core.empty?

    "#{lead}#{marker}#{core}#{marker}#{trail}"
  end

  def render_inline(node)
    return '' if node.comment?
    if node.text?
      return node.content.gsub(/\s+/, ' ')
    end
    return '' unless node.element?

    case node.name.downcase
    when 'b', 'strong'
      wrap_inline_marker(render_inline_children(node), '**')
    when 'i', 'em'
      wrap_inline_marker(render_inline_children(node), '*')
    when 'code'
      "`#{node.text}`"
    when 'sup'
      "<sup>#{render_inline_children(node)}</sup>"
    when 'br'
      "  \n"
    when 'span'
      render_inline_children(node)
    when 'a'
      href = rewrite_href(node['href'])
      # Unwrap anchor if its only child was the omitted dead image
      inner_imgs = node.css('img')
      if !inner_imgs.empty? && node.text.strip.empty?
        figs = inner_imgs.filter_map { |im| copy_and_render_image(im) }
        return figs.join("\n")
      end
      label = render_inline_children(node)
      return label if href.empty?

      lead = label[/\A\s+/] || ''
      trail = label[/\s+\z/] || ''
      core = label.strip
      core.empty? ? '' : "#{lead}[#{core}](#{href})#{trail}"
    when 'img'
      copy_and_render_image(node) || ''
    else
      render_inline_children(node)
    end
  end

  def render_inline_children(parent)
    parent.children.map { |c| render_inline(c) }.join
  end

  def extract_leading_figures!(element)
    figs = []
    element.css('img').each do |img|
      parent_a = img.ancestors('a').first
      fig = copy_and_render_image(img)
      if parent_a && parent_a.text.strip.empty?
        parent_a.remove
      else
        img.remove
      end
      figs << fig if fig
    end
    figs
  end

  def render_table(table_node)
    rows = []
    table_node.css('tr').each do |tr|
      cells = tr.css('th, td').map do |cell|
        render_inline_children(cell).gsub(/\s+/, ' ').strip.gsub('|', '\\|')
      end
      rows << cells unless cells.empty?
    end
    return '' if rows.empty?

    col_count = rows.map(&:size).max
    lines = []
    rows.each_with_index do |r, idx|
      padded = r + Array.new(col_count - r.size, '')
      lines << "| #{padded.join(' | ')} |"
      if idx.zero?
        lines << "| #{Array.new(col_count, '---').join(' | ')} |"
      end
    end
    lines.join("\n")
  end

  def render_list(list_node, ordered: false)
    items = []
    idx = 0
    list_node.children.each do |li|
      next unless li.element? && li.name.downcase == 'li'

      idx += 1
      bullet = ordered ? "#{idx}. " : '- '
      p_children = li.children.select { |c| c.element? && c.name.downcase == 'p' }
      text = if p_children.any?
               p_children.map { |p| render_inline_children(p).gsub(/\s+/, ' ').strip }.reject(&:empty?).join("\n\n  ")
             else
               render_inline_children(li).gsub(/\s+/, ' ').strip
             end
      items << "#{bullet}#{text}" unless text.empty?
    end
    items.join("\n")
  end

  def render_blockquote(bq_node)
    inner_blocks = render_block_children(bq_node)
    inner_blocks.map do |blk|
      blk.lines.map { |l| l.strip.empty? ? '>' : "> #{l.chomp}" }.join("\n")
    end.join("\n>\n")
  end

  def render_block_children(container)
    blocks = []
    inline_buf = +''

    flush_inline = lambda do
      cleaned = inline_buf.gsub(/[ \t]+/, ' ').gsub(/ *\n */, "\n").strip
      blocks << cleaned unless cleaned.empty?
      inline_buf.clear
    end

    container.children.each do |node|
      next if node.comment?

      if node.text?
        inline_buf << node.content unless node.content.strip.empty?
        next
      end
      next unless node.element?

      tag = node.name.downcase
      case tag
      when 'p'
        flush_inline.call
        figs = extract_leading_figures!(node)
        blocks.concat(figs)
        para = render_inline_children(node).gsub(/[ \t]+/, ' ').gsub(/ +\n/, "\n").strip
        blocks << para unless para.empty?
      when 'ul'
        flush_inline.call
        blocks << render_list(node, ordered: false)
      when 'ol'
        flush_inline.call
        blocks << render_list(node, ordered: true)
      when 'blockquote'
        flush_inline.call
        blocks << render_blockquote(node)
      when 'table'
        flush_inline.call
        blocks << render_table(node)
      when 'hr'
        flush_inline.call
        blocks << '---'
      when 'embed'
        flush_inline.call
        blocks << '*[Archive note: the embedded 2006 Google Video Flash player is no longer available.]*'
      when 'div'
        flush_inline.call
        blocks.concat(render_block_children(node))
      when 'img'
        flush_inline.call
        fig = copy_and_render_image(node)
        blocks << fig if fig
      when 'a'
        if !node.css('img').empty? && node.text.strip.empty?
          flush_inline.call
          node.css('img').each do |im|
            fig = copy_and_render_image(im)
            blocks << fig if fig
          end
        else
          inline_buf << render_inline(node)
        end
      else
        inline_buf << render_inline(node)
      end
    end

    flush_inline.call
    blocks.reject(&:empty?)
  end
end

def sanitize_comment_url(raw_url)
  u = raw_url.to_s.strip
  return nil if u.empty?
  return '/' if u.include?('erik.bruchez.name/roller')

  u = u.sub(%r{\Ahttp://htttp://}i, 'http://')
  u
end

def convert_comment_content(raw_content)
  frag = if Nokogiri.respond_to?(:HTML5)
           Nokogiri::HTML5.fragment(raw_content.to_s.gsub("\r\n", "\n"))
         else
           Nokogiri::HTML::DocumentFragment.parse(raw_content.to_s.gsub("\r\n", "\n"))
         end

  # Convert <a href="...">...</a> to Markdown links while preserving paragraph breaks
  frag.css('a').each do |a|
    href = a['href'].to_s.strip
    label = a.text.strip
    replacement = if href.empty?
                    label
                  elsif label == href
                    "<#{href}>"
                  else
                    "[#{label}](#{href})"
                  end
    a.replace(Nokogiri::XML::Text.new(replacement, frag.document))
  end

  text = frag.text
  # Auto-link bare http(s) URLs not already wrapped in <> or ()
  text = text.gsub(%r{(?<![<(\[])(https?://[^\s<>)\]]+)}) do |m|
    trail = m[/[.,;:!?]+\z/] || ''
    url = trail.empty? ? m : m[0...-trail.length]
    "<#{url}>#{trail}"
  end

  paragraphs = text.split(/\n\s*\n+/).map(&:strip).reject(&:empty?)
  paragraphs.join("\n\n")
end

# ------------------------------------------------------------------------------
# Main Execution
# ------------------------------------------------------------------------------
jan_tables = parse_roller_dump(JAN_DUMP)
jul_tables = parse_roller_dump(JUL_DUMP)

cats_by_id = jan_tables['weblogcategory'].each_with_object({}) { |r, h| h[r['id']] = r['name'] }
valid_comment_ids = jul_tables['comment'].each_with_object({}) { |r, h| h[r['id']] = true }

comments_by_entry = Hash.new { |h, k| h[k] = [] }
jan_tables['comment']
  .select { |c| valid_comment_ids[c['id']] }
  .sort_by { |c| c['posttime'] }
  .each do |c|
    entry_hash = {
      'author' => c['name'].to_s.strip,
      'date' => "#{c['posttime'].strip} UTC"
    }
    clean_url = sanitize_comment_url(c['url'])
    entry_hash['url'] = clean_url if clean_url
    entry_hash['content'] = convert_comment_content(c['content'])
    comments_by_entry[c['entryid']] << entry_hash
  end

entries = jan_tables['weblogentry'].sort_by { |e| e['pubtime'] }
disk_files = Dir.children(IMAGES_SRC_DIR).reject { |f| f.start_with?('.') }.sort

# Pass 1: Assign deterministic slugs & permalinks
slug_by_anchor = {}
entries.each do |e|
  raw_title = e['title'].to_s
  dec_title = (Nokogiri.respond_to?(:HTML5) ? Nokogiri::HTML5.fragment(raw_title).text : Nokogiri::HTML::DocumentFragment.parse(raw_title).text).gsub(/\s+/, ' ').strip
  e['_decoded_title'] = dec_title
  slug = CUSTOM_SLUGS[e['anchor']] || ascii_slug(dec_title)
  e['_slug'] = slug
  e['_permalink'] = "/posts/#{slug}/"
  slug_by_anchor[e['anchor']] = slug
end

url_rewrites = {
  'http://erik.bruchez.name/roller/page/ebruchez/20050625' => "/posts/#{slug_by_anchor['antidigitalism']}/",
  'http://erik.bruchez.name/roller/page/ebruchez/20050717' => "/posts/#{slug_by_anchor['quand_google_defie_l_europe']}/",
  '/roller/page/ebruchez/20050922' => "/posts/#{slug_by_anchor['wikipedia_on_cell_phones_not']}/",
  'http://erik.bruchez.name/books/review/500064' => "/posts/#{slug_by_anchor['the_immortal_cell_by_michael']}/"
}

copied_assets = {}
published_count = 0
draft_count = 0

entries.each do |e|
  anchor = e['anchor']
  slug = e['_slug']
  is_published = e['publishentry'] == '1'
  pub_time = Time.utc(*e['pubtime'].split(/[- :]/).map(&:to_i))
  date_prefix = pub_time.strftime('%Y-%m-%d')

  converter = RollerHtmlConverter.new(
    url_rewrites: url_rewrites,
    disk_files: disk_files,
    copied_assets: copied_assets
  )
  body_md = converter.convert(e['text'])

  # Cross-link bilingual EN <-> FR pairs
  case anchor
  when 'aap_google_print_and_new'
    body_md.sub!('available in English.', "available [in English](/posts/#{slug_by_anchor['aap_google_print_and_the']}/).")
  when 'aap_google_print_and_the'
    body_md.sub!('disponible en français.', "disponible [en français](/posts/#{slug_by_anchor['aap_google_print_and_new']}/).")
  when 'gastrosuisse_has_picked_the_wrong'
    body_md.sub!('an article in French posted', "an [article in French](/posts/#{slug_by_anchor['gastrosuisse_le_mauvais_combat']}/) posted")
  end

  roller_cat = cats_by_id[e['categoryid']]
  categories, tags = map_categories_and_tags(e, roller_cat)

  fm = {
    'layout' => 'post',
    'title' => e['_decoded_title'],
    'date' => pub_time.strftime('%Y-%m-%d %H:%M:%S'),
    'categories' => categories
  }
  fm['tags'] = tags unless tags.empty?
  fm['rating'] = converter.rating if converter.rating

  if is_published
    redirects = [
      "/blog/#{pub_time.year}/#{pub_time.month}/#{pub_time.day}/#{anchor}",
      "/roller/page/ebruchez/#{anchor}"
    ]
    redirects << '/books/review/500064' if anchor == 'the_immortal_cell_by_michael'
    fm['redirect_from'] = redirects
  end

  entry_comments = comments_by_entry[e['id']]
  fm['archived_comments'] = entry_comments if entry_comments && !entry_comments.empty?

  out_dir = is_published ? POSTS_DIR : DRAFTS_DIR
  FileUtils.mkdir_p(out_dir)
  out_path = File.join(out_dir, "#{date_prefix}-#{slug}.md")

  yaml_header = YAML.dump(fm).sub(/\A---\s*\n/, "---\n")
  File.write(out_path, "#{yaml_header}---\n\n#{body_md}\n")

  if is_published
    published_count += 1
  else
    draft_count += 1
  end
end

puts "Imported #{published_count} published posts into _posts/, #{draft_count} drafts into _drafts/, and #{copied_assets.size} images into assets/posts/roller/."
