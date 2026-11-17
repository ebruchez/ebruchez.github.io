# frozen_string_literal: true

module BruchezCategoriesData
  CATEGORY_META = {
    'Technology' => {
      order: 1,
      icon: 'fas fa-microchip',
      description: 'Computers, operating systems, hardware, web standards, and digital tools.'
    },
    'Typewriters' => {
      order: 2,
      icon: 'fas fa-keyboard',
      description: 'Mechanical and electronic typewriter restorations, IBM Selectric and Composer machines, and history.'
    },
    'Programming' => {
      order: 3,
      icon: 'fas fa-code',
      description: 'Scala, functional programming, XForms, APIs, and software engineering.'
    },
    'Music' => {
      order: 4,
      icon: 'fas fa-music',
      description: 'Opera, Pietro Mascagni, 78 rpm audio restoration, concerts, and recordings.'
    },
    'Book Reviews' => {
      order: 5,
      icon: 'fas fa-book-open',
      description: 'Reviews and notes on science fiction, history, science, and biographies.'
    },
    'Link Blog' => {
      order: 6,
      icon: 'fas fa-link',
      description: 'Short commentary on articles, essays, and ideas from around the web.'
    },
    'Other' => {
      order: 99,
      icon: 'fas fa-compass',
      description: 'Travel, Switzerland, reading plans, society, and miscellaneous notes.'
    }
  }.freeze

  DEFAULT_META = {
    order: 50,
    icon: 'far fa-folder-open',
    description: nil
  }.freeze

  RECENT_PREVIEW_LIMIT = 5

  module_function

  def serialize_post(post)
    dt = post.date
    {
      'title' => post.data['title'].to_s,
      'url' => post.url,
      'year' => dt ? dt.strftime('%Y') : '',
      'date_short' => dt ? dt.strftime('%b %Y') : '',
      'date_long' => dt ? dt.strftime('%b %-d, %Y') : '',
      'date_iso' => dt ? dt.xmlschema : '',
      'rating' => post.data['rating'],
      'is_french' => Array(post.data['tags']).include?('french')
    }
  end

  def precompute(site)
    published_posts = site.posts.docs.reject { |p| p.data['published'] == false }
    site.data['categories_total_posts'] = published_posts.size

    years_all = published_posts.filter_map { |p| p.date&.year }
    if years_all.any?
      min_all = years_all.min
      max_all = years_all.max
      site.data['categories_year_span'] = min_all == max_all ? max_all.to_s : "#{min_all}–#{max_all}"
    end

    showcase = []
    by_name = {}
    by_slug = {}

    site.categories.each do |cat_name, raw_docs|
      docs = raw_docs.reject { |p| p.data['published'] == false }.sort_by { |p| p.date || Time.at(0) }.reverse
      next if docs.empty?

      meta = CATEGORY_META[cat_name] || DEFAULT_META
      slug = Jekyll::Utils.slugify(cat_name)
      years = docs.filter_map { |p| p.date&.year }
      year_span = if years.empty?
                    ''
                  elsif years.min == years.max
                    years.max.to_s
                  else
                    "#{years.min}–#{years.max}"
                  end

      items = docs.map { |d| serialize_post(d) }
      grouped_years = []
      items.each do |item|
        yr = item['year']
        if grouped_years.empty? || grouped_years.last['year'] != yr
          grouped_years << { 'year' => yr, 'posts' => [item] }
        else
          grouped_years.last['posts'] << item
        end
      end

      entry = {
        'name' => cat_name,
        'slug' => slug,
        'url' => "/categories/#{slug}/",
        'order' => meta[:order],
        'icon' => meta[:icon],
        'description' => meta[:description],
        'count' => items.size,
        'year_span' => year_span,
        'recent_posts' => items.first(RECENT_PREVIEW_LIMIT),
        'older_posts' => items.drop(RECENT_PREVIEW_LIMIT),
        'posts_by_year' => grouped_years
      }

      showcase << entry
      by_name[cat_name] = entry
      by_slug[slug] = entry
    end

    showcase.sort_by! { |e| [e['order'], -e['count'], e['name'].downcase] }

    site.data['categories_showcase'] = showcase
    site.data['categories_by_name'] = by_name
    site.data['categories_by_slug'] = by_slug
  end
end

Jekyll::Hooks.register :site, :pre_render do |site|
  BruchezCategoriesData.precompute(site)
end
