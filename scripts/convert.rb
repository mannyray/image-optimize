#!/usr/bin/env ruby

# Usage:
#   ruby convert_file_status.rb input.txt output.txt

input_path = ARGV[0]
output_path = ARGV[1]

unless input_path && output_path
  puts "Usage: ruby #{__FILE__} input.txt output.txt"
  exit 1
end

begin
  current_status = nil
  output_lines = []

  File.foreach(input_path) do |line|
    line = line.strip
    next if line.empty?

    case line
    when '--- Accepted Files ---'
      current_status = 'accepted'
    when '--- Rejected Files ---'
      current_status = 'not accepted'
    else
      output_lines << "#{line} #{current_status}" if current_status
    end
  end

  File.open(output_path, 'w') do |file|
    file.puts(output_lines)
  end

  puts "Output written to #{output_path}"

rescue Errno::ENOENT
  puts "File not found: #{input_path}"
  exit 1
rescue => e
  puts "An error occurred: #{e.message}"
  exit 1
end
