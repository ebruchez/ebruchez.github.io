# frozen_string_literal: true

require 'bigdecimal'
require 'cgi'

# 1. O(1) path lookup for `jekyll-relative-links` instead of O(N) scan over
#    all static files and documents on every Markdown link/image.
begin
  require 'jekyll-relative-links'
rescue LoadError
  # Plugin gem not installed
end

if defined?(JekyllRelativeLinks::Generator)
  module BruchezFastRelativeLinks
    def generate(site)
      @targets_by_path = nil
      @potential_targets = nil
      super
    end

    private

    def targets_by_path
      @targets_by_path ||= begin
        map = {}
        potential_targets.each do |target|
          key = target.relative_path.delete_prefix('/')
          map[key] ||= target
        end
        map
      end
    end

    def url_for_path(path)
      target = targets_by_path[CGI.unescape(path)]
      relative_url(target.url) if target&.url
    end
  end

  JekyllRelativeLinks::Generator.prepend(BruchezFastRelativeLinks)
end

# 2. Avoid deleting and re-copying hundreds of MB of unchanged static assets on
#    fresh `jekyll build` / `jekyll serve` startups when destination files
#    already exist on disk with identical size and mtime.
module BruchezFastStaticFile
  def write(dest)
    dest_path = destination(dest)
    if self.class.mtimes[path].nil? && File.exist?(dest_path) && !File.symlink?(dest_path)
      begin
        src_stat = File.stat(path)
        dest_stat = File.lstat(dest_path)
        if dest_stat.file? && dest_stat.size == src_stat.size && dest_stat.mtime.to_i == src_stat.mtime.to_i
          self.class.mtimes[path] = mtime
          return false
        end
      rescue SystemCallError
        # Fall back to standard Jekyll copy if stat fails
      end
    end
    super
  end
end

Jekyll::StaticFile.prepend(BruchezFastStaticFile)

# 3. Precompute related posts and memoize plain-text 200-char excerpts once per
#    referenced post instead of running O(N^2) Liquid loops and hundreds of
#    full-post Kramdown `markdownify` passes during layout rendering.
module BruchezRelatedPostsCache
  TOTAL_SIZE = 3
  HALF = BigDecimal('0.5')

  FilterHost = Class.new do
    include Liquid::StandardFilters
  end.new

  module_function

  def strip_linenos(html)
    return html unless html.include?('<td class="rouge-gutter gl"><pre class="lineno">')

    html
      .gsub('<td class="rouge-gutter gl"><pre class="lineno">', '<!-- <td class="rouge-gutter gl"><pre class="lineno">')
      .gsub('</td><td class="rouge-code">', '</td> --><td class="rouge-code">')
  end

  def score_to_liquid_s(score)
    score.is_a?(BigDecimal) ? score.to_s('F') : score.to_s
  end

  def precompute(site)
    posts = site.posts.docs.reverse
    return if posts.empty?

    post_tags = posts.map { |p| Array(p.data['tags']) }
    post_cats = posts.map { |p| Array(p.data['categories']) }

    referenced = {}

    posts.each_with_index do |page_doc, page_idx|
      p_tags = post_tags[page_idx]
      p_cats = post_cats[page_idx]

      score_list = []
      posts.each_with_index do |_cand, i|
        next if i == page_idx

        score = 0
        unless p_tags.empty?
          post_tags[i].each do |t|
            score += 1 if p_tags.include?(t)
          end
        end
        unless p_cats.empty?
          post_cats[i].each do |c|
            score = (score.is_a?(BigDecimal) ? score : BigDecimal(score)) + HALF if p_cats.include?(c)
          end
        end

        score_list << "#{score_to_liquid_s(score)}:#{i}" if score.positive?
      end

      index_list = []
      unless score_list.empty?
        score_list.sort!.reverse!
        score_list.first(TOTAL_SIZE).each do |entry|
          index_list << entry.split(':').last.to_i
        end
      end

      if index_list.size < TOTAL_SIZE
        posts.each_index do |i|
          next if i == page_idx
          next if index_list.include?(i)

          index_list << i
          break if index_list.size >= TOTAL_SIZE
        end
      end

      related_docs = index_list.map { |idx| posts[idx] }
      related_docs.each { |d| referenced[d] = true }
      page_doc.data['related_posts_cached'] = related_docs
    end

    converter = site.find_converter_instance(Jekyll::Converters::Markdown)
    payload = site.site_payload
    referenced.each_key do |doc|
      html = doc.content.to_s
      if doc.render_with_liquid? && Jekyll::Utils.has_liquid_construct?(html)
        html = site.liquid_renderer.file(doc.path).parse(html).render!(
          payload,
          registers: { site: site, page: doc.to_liquid }
        )
      end
      html = converter.convert(html) if converter.matches(doc.extname)
      cleaned = strip_linenos(html)
      text = FilterHost.strip_html(cleaned)
      doc.data['related_excerpt'] = FilterHost.truncate(text, 200)
    end
  end
end

Jekyll::Hooks.register :site, :pre_render do |site|
  BruchezRelatedPostsCache.precompute(site)
end
