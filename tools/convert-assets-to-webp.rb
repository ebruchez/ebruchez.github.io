#!/usr/bin/env ruby
# frozen_string_literal: true

# Convert JPEG/PNG assets under assets/ to optimized WebP and rewrite
# all site references cleanly.
#
# Usage:
#   ruby tools/convert-assets-to-webp.rb --dry-run
#   ruby tools/convert-assets-to-webp.rb --apply
#   ruby tools/convert-assets-to-webp.rb --tracked-only --apply
#   ruby tools/convert-assets-to-webp.rb --max-dim 2000 --quality 82 --apply

require 'find'
require 'fileutils'
require 'open3'
require 'optparse'
require 'etc'
require 'uri'

ROOT = File.expand_path('..', __dir__)
ASSETS_DIR = File.join(ROOT, 'assets')

EXCLUDED_PATH_RE = %r{/(favicons|orig|original)/}i
CONVERTIBLE_EXT_RE = /\.(jpe?g|png)\z/i
TEXT_EXTS = %w[.md .html .yml .yaml .rb .scss .css .js .xml .txt].freeze

def magick_bin
  @magick_bin ||= ['/opt/homebrew/bin/magick', '/usr/local/bin/magick', 'magick'].find do |bin|
    File.executable?(bin) || system('which', bin, out: File::NULL, err: File::NULL)
  end
end

def collect_candidates(tracked_only: false)
  paths = if tracked_only
            `git -C #{ROOT} ls-files assets`.lines.map { |l| File.join(ROOT, l.chomp) }
          else
            list = []
            Find.find(ASSETS_DIR) { |p| list << p if File.file?(p) }
            list
          end

  paths.select do |abs|
    next false unless File.file?(abs)

    rel = abs.delete_prefix("#{ROOT}/")
    rel.match?(CONVERTIBLE_EXT_RE) && !rel.match?(EXCLUDED_PATH_RE)
  end.sort
end

def text_files_to_update
  globs = %w[_posts _drafts pages _layouts _includes _tabs _data _sass _plugins].flat_map do |d|
    Dir.glob(File.join(ROOT, d, '**', '*'))
  end
  extras = %w[_config.yml index.html assets/css/style.scss].map { |f| File.join(ROOT, f) }
  (globs + extras).select { |f| File.file?(f) && TEXT_EXTS.include?(File.extname(f).downcase) }.uniq.sort
end

def convert_one(abs_src, max_dim:, quality:)
  dir = File.dirname(abs_src)
  base = File.basename(abs_src, File.extname(abs_src))
  abs_dest = File.join(dir, "#{base}.webp")
  orig_size = File.size(abs_src)

  # If a .webp with the exact same stem already exists, skip to avoid clobbering
  if File.exist?(abs_dest)
    return { status: :exists, src: abs_src, dest: abs_dest, orig_size: orig_size, new_size: File.size(abs_dest) }
  end

  tmp_dest = "#{abs_dest}.tmp.webp"
  cmd = [
    magick_bin, abs_src,
    '-auto-orient',
    '-resize', "#{max_dim}x#{max_dim}>",
    '-strip',
    '-quality', quality.to_s,
    tmp_dest
  ]
  _out, err, st = Open3.capture3(*cmd)
  unless st.success? && File.exist?(tmp_dest) && File.size(tmp_dest) > 0
    FileUtils.rm_f(tmp_dest)
    return { status: :error, src: abs_src, error: err.strip, orig_size: orig_size }
  end

  new_size = File.size(tmp_dest)
  if new_size >= orig_size
    FileUtils.rm_f(tmp_dest)
    return { status: :larger, src: abs_src, orig_size: orig_size, new_size: new_size }
  end

  File.rename(tmp_dest, abs_dest)
  File.delete(abs_src)
  { status: :converted, src: abs_src, dest: abs_dest, orig_size: orig_size, new_size: new_size }
end

def rewrite_references(converted_map)
  return { files_changed: 0, replacements: 0 } if converted_map.empty?

  # Build lookup from relative path (leading slash, lowercased) -> new webp path (leading slash)
  lookup = {}
  converted_map.each do |rel_src, rel_dest|
    s_slash = "/#{rel_src}"
    d_slash = "/#{rel_dest}"
    lookup[s_slash.downcase] = d_slash
    enc_src = s_slash.gsub(' ', '%20')
    enc_dest = d_slash.gsub(' ', '%20')
    lookup[enc_src.downcase] = enc_dest if enc_src != s_slash
  end

  pattern = %r{/assets/[^\s"'\)\]>]+\.(?:jpe?g|png)}i
  files_changed = 0
  total_replacements = 0

  text_files_to_update.each do |path|
    raw = File.read(path, mode: 'rb')
    next unless raw.valid_encoding? || raw.force_encoding('UTF-8').valid_encoding?

    content = raw.force_encoding('UTF-8')
    file_hits = 0
    updated = content.gsub(pattern) do |match|
      if (replacement = lookup[match.downcase])
        file_hits += 1
        replacement
      else
        match
      end
    end

    if file_hits.positive?
      File.write(path, updated)
      files_changed += 1
      total_replacements += file_hits
    end
  end

  { files_changed: files_changed, replacements: total_replacements }
end

options = {
  apply: false,
  tracked_only: false,
  max_dim: 2000,
  quality: 82,
  threads: [Etc.nprocessors, 8].min
}

OptionParser.new do |opts|
  opts.banner = 'Usage: ruby tools/convert-assets-to-webp.rb [options]'
  opts.on('--dry-run', 'Preview candidates without modifying files (default)') { options[:apply] = false }
  opts.on('--apply', 'Convert images to WebP, remove originals, and rewrite references') { options[:apply] = true }
  opts.on('--tracked-only', 'Only process git-tracked files under assets/') { options[:tracked_only] = true }
  opts.on('--max-dim N', Integer, 'Max width/height in pixels (default: 2000)') { |n| options[:max_dim] = n }
  opts.on('--quality N', Integer, 'WebP quality 1..100 (default: 82)') { |n| options[:quality] = n }
  opts.on('--threads N', Integer, 'Parallel worker threads') { |n| options[:threads] = n }
end.parse!

raise 'ImageMagick (magick) not found in PATH' unless magick_bin

candidates = collect_candidates(tracked_only: options[:tracked_only])
total_orig_bytes = candidates.sum { |p| File.size(p) }
existing_conflicts = candidates.count do |p|
  File.exist?(File.join(File.dirname(p), "#{File.basename(p, File.extname(p))}.webp"))
end

puts "Candidates: #{candidates.size} files (#{format('%.1f MB', total_orig_bytes / 1_048_576.0)})"
puts "Settings:   max_dim=#{options[:max_dim]}px, quality=#{options[:quality]}, threads=#{options[:threads]}, tracked_only=#{options[:tracked_only]}"
puts "Pre-existing .webp same-stem conflicts (will skip): #{existing_conflicts}"

unless options[:apply]
  puts "\nDry-run complete. Re-run with --apply to convert and update references."
  exit 0
end

queue = Queue.new
candidates.each { |p| queue << p }
results = []
mutex = Mutex.new
done = 0

workers = Array.new(options[:threads]) do
  Thread.new do
    loop do
      abs_src = begin
        queue.pop(true)
      rescue ThreadError
        break
      end
      res = convert_one(abs_src, max_dim: options[:max_dim], quality: options[:quality])
      mutex.synchronize do
        results << res
        done += 1
        if (done % 200).zero? || done == candidates.size
          puts "  Progress: #{done}/#{candidates.size}"
        end
      end
    end
  end
end
workers.each(&:join)

converted = results.select { |r| r[:status] == :converted }
skipped_larger = results.select { |r| r[:status] == :larger }
skipped_exists = results.select { |r| r[:status] == :exists }
errors = results.select { |r| r[:status] == :error }

orig_conv = converted.sum { |r| r[:orig_size] }
new_conv = converted.sum { |r| r[:new_size] }
saved = orig_conv - new_conv

puts "\n=== Conversion Summary ==="
puts "Converted:          #{converted.size} files"
puts "Skipped (not smaller): #{skipped_larger.size}"
puts "Skipped (.webp exists): #{skipped_exists.size}"
puts "Errors:             #{errors.size}"
errors.first(10).each { |e| puts "  ERROR #{e[:src]}: #{e[:error]}" }
puts format("Size before:        %.1f MB", orig_conv / 1_048_576.0)
puts format("Size after:         %.1f MB", new_conv / 1_048_576.0)
puts format("Space saved:        %.1f MB (-%.1f%%)", saved / 1_048_576.0, orig_conv.positive? ? (saved.to_f / orig_conv * 100) : 0)

converted_map = {}
converted.each do |r|
  converted_map[r[:src].delete_prefix("#{ROOT}/")] = r[:dest].delete_prefix("#{ROOT}/")
end

ref_stats = rewrite_references(converted_map)
puts "\n=== Reference Updates ==="
puts "Updated #{ref_stats[:replacements]} references across #{ref_stats[:files_changed]} files."
