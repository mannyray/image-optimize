#!/usr/bin/env ruby

require 'fileutils'
require 'set'
require 'image_optim'
require_relative 'settings'



def list_image_files(directory)
  Dir.glob("#{directory}/**/*.{jpg,jpeg,png,JPEG,PNG,JPG}", File::FNM_CASEFOLD).select { |f| File.file?(f) }
end

def relative_path(file, base_dir)
  file.sub(/^#{Regexp.escape(base_dir)}\/?/, '')
end

def parse_accepted_file(file_path)
  accepted = {}
  if File.exist?(file_path)
    File.readlines(file_path).each do |line|
      path, status = line.strip.split(/\s+/, 2)
      accepted[path] = status
    end
  end
  accepted
end

# Main script logic

abort("Usage: ruby sync_and_optimize.rb <relative_path_to_directory>") if ARGV.empty?

original_path = File.expand_path(ARGV[0])
abort("Directory #{original_path} does not exist.") unless Dir.exist?(original_path)

backup_path = original_path + "_backup"
FileUtils.mkdir_p(backup_path)

# Get .jpg/.png files from both directories
original_files = list_image_files(original_path)
backup_files   = list_image_files(backup_path)

# Relative paths
original_rel = original_files.map { |f| relative_path(f, original_path) }.to_set
backup_rel   = backup_files.map   { |f| relative_path(f, backup_path) }.to_set

# Step 2: Copy new image files from original to backup
(original_rel - backup_rel).each do |rel_path|
  src = File.join(original_path, rel_path)
  dest = File.join(backup_path, rel_path)
  FileUtils.mkdir_p(File.dirname(dest))
  FileUtils.cp(src, dest)
end

# Step 3: Parse accepted.txt if exists
accepted_file = File.join(backup_path, "results.txt")
accepted_status = parse_accepted_file(accepted_file)

# Step 4: Copy not accepted files from backup to original
not_accepted_files = backup_rel.select { |rel_path| accepted_status[rel_path] != "accepted" }

not_accepted_files.each do |rel_path|
  src = File.join(backup_path, rel_path)
  dest = File.join(original_path, rel_path)
  FileUtils.mkdir_p(File.dirname(dest))
  FileUtils.cp(src, dest)
end

# Step 5: Optimize new and not accepted images
files_to_optimize = (original_rel - backup_rel).to_a + not_accepted_files
files_to_optimize.map! { |rel| File.join(original_path, rel) }
files_to_optimize.uniq!

if files_to_optimize.any?
  puts "Optimizing #{files_to_optimize.size} image(s)..."
  image_optim = ImageOptim.new(COMPRESION_OPTIONS) # Adjust options as needed
  image_optim.optimize_images!(files_to_optimize)
else
  puts "No images to optimize."
end

puts "Done."
