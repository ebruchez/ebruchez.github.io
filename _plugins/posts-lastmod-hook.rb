#!/usr/bin/env ruby
# frozen_string_literal: true

# Populate `last_modified_at` for posts with more than one git commit.
# Batches git history lookup into a single `git log` command per HEAD revision
# instead of spawning two git subprocesses per post.

module BruchezPostsLastmod
  @cached_head = nil
  @checked_this_build = false
  @repo_root = nil
  @lastmod_by_path = {}

  class << self
    def mark_build_reset
      @checked_this_build = false
    end

    def ensure_loaded(site)
      return if @checked_this_build

      @checked_this_build = true
      source = site ? site.source : Dir.pwd
      head = `git -C "#{source}" rev-parse --verify HEAD 2>/dev/null`.chomp
      if head.empty?
        @cached_head = nil
        @lastmod_by_path = {}
        return
      end

      return if head == @cached_head

      root = `git -C "#{source}" rev-parse --show-toplevel 2>/dev/null`.chomp
      return if root.empty?

      @repo_root = File.realpath(root)
      raw = `git -C "#{@repo_root}" -c core.quotepath=false log --no-renames --format="COMMIT:%ad" --date=iso --name-only HEAD -- _posts _drafts 2>/dev/null`

      counts = Hash.new(0)
      latest_date = {}
      current_date = nil

      raw.each_line do |line|
        line.chomp!
        next if line.empty?

        if line.start_with?('COMMIT:')
          current_date = line.delete_prefix('COMMIT:')
        else
          counts[line] += 1
          latest_date[line] ||= "#{current_date}\n"
        end
      end

      map = {}
      counts.each do |rel_path, count|
        map[rel_path] = latest_date[rel_path] if count > 1
      end

      @lastmod_by_path = map
      @cached_head = head
    end

    def lastmod_for(post)
      ensure_loaded(post.site)
      return nil unless @repo_root

      full = File.exist?(post.path) ? File.realpath(post.path) : post.path
      prefix = "#{@repo_root}/"
      rel = if full.start_with?(prefix)
              full.delete_prefix(prefix)
            else
              post.relative_path.delete_prefix('/')
            end
      @lastmod_by_path[rel]
    end
  end
end

Jekyll::Hooks.register :site, :after_reset do
  BruchezPostsLastmod.mark_build_reset
end

Jekyll::Hooks.register :posts, :post_init do |post|
  lastmod_date = BruchezPostsLastmod.lastmod_for(post)
  post.data['last_modified_at'] = lastmod_date if lastmod_date
end
