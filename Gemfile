source "https://rubygems.org"

gem "jekyll", "~> 4.3"

# Jekyll plugins
group :jekyll_plugins do
  gem 'jekyll-archives', '~> 2.2'
  gem 'jekyll-redirect-from'
  gem 'jekyll-relative-links'
  gem 'jekyll-seo-tag', '~> 2.8'
  gem 'jekyll-sitemap', '~> 1.4'
  gem 'nokogiri'
end

group :test do
  gem "html-proofer", "~> 3.19"
end

# Windows and JRuby does not include zoneinfo files, so bundle the tzinfo-data gem
# and associated library.
install_if -> { RUBY_PLATFORM =~ %r!mingw|mswin|java! } do
  gem "tzinfo", "~> 1.2"
  gem "tzinfo-data"
end

# # # Performance-booster for watching directories on Windows
gem "wdm", "~> 0.1.1", :install_if => Gem.win_platform?

# https://github.com/jekyll/jekyll/issues/8523
gem "webrick"

gem "csv"
gem "base64"
gem "bigdecimal"
