# frozen_string_literal: true

module BruchezTranslations
  module_function

  def normalize_url(url)
    return '' if url.nil?

    u = url.to_s.strip
    u = "/#{u}" unless u.empty? || u.start_with?('/')
    u.end_with?('/') ? u : "#{u}/"
  end

  def precompute(site)
    posts_by_url = {}
    site.posts.docs.each do |post|
      posts_by_url[normalize_url(post.url)] = post
    end

    fr_collection = site.collections['posts_fr']
    fr_docs = fr_collection ? fr_collection.docs : []

    # Link translations (in posts_fr or any post declaring translation_of) bidirectionally
    (fr_docs + site.posts.docs).each do |doc|
      target_url = doc.data['translation_of']
      next if target_url.nil? || target_url.to_s.strip.empty?

      source = posts_by_url[normalize_url(target_url)]
      next unless source

      lang = (doc.data['lang'] || 'fr').to_s
      source_lang = (source.data['lang'] || 'en').to_s

      source.data['translations'] ||= {}
      source.data['translations'][lang] = {
        'url' => doc.url,
        'title' => doc.data['title'].to_s,
        'lang' => lang
      }

      doc.data['translation_source'] = {
        'url' => source.url,
        'title' => source.data['title'].to_s,
        'lang' => source_lang
      }
    end

    # Build combined French posts list (translations + original French posts), newest first
    original_fr_posts = site.posts.docs.select { |p| p.data['lang'].to_s == 'fr' }
    all_fr = (fr_docs + original_fr_posts).uniq(&:url)
    all_fr.sort_by! { |d| d.date || Time.at(0) }
    all_fr.reverse!

    site.data['french_posts'] = all_fr.map do |doc|
      {
        'title' => doc.data['title'].to_s,
        'url' => doc.url,
        'date' => doc.date,
        'year' => doc.date ? doc.date.strftime('%Y') : '',
        'day' => doc.date ? doc.date.strftime('%d') : '',
        'month' => doc.date ? doc.date.strftime('%b') : '',
        'is_translation' => !doc.data['translation_of'].nil?,
        'translation_source' => doc.data['translation_source']
      }
    end
  end
end

Jekyll::Hooks.register :site, :pre_render, priority: :high do |site|
  BruchezTranslations.precompute(site)
end
