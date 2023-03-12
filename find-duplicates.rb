#!/bin/ruby
# Find duplicate files in a directory
# Usage: ruby find-duplicates.rb <directory>
require 'digest'
require 'optparse'

options = { :verbose => false }
OptionParser.new do |opts|
  opts.banner = "Usage: find-duplicates.rb [options]"

  opts.on("-h", "--help", "Show this help message") do
    puts opts
    exit
  end

  opts.on("-l", "--low", "Low comparison level (faster)") do
    options[:low] = true
  end

  opts.on("-d", "--deep", "High comparison level (slower)") do
    options[:high] = true
  end
end.parse!

def find_duplicates(directory)
  files_dict = Hash.new
  Dir.glob("#{directory}/**/*") do |file|
    begin
      # **/* means all files in all subdirectories
      if File.directory?(file)
        find_duplicates(file) # recursive call
      else
        file_name = File.basename(file)
        file_path = File.dirname(file)
        file_ctime = File.ctime(file)
        if options[:high]
          file_hash = Digest::SHA256.file(file).hexdigest
          if files_dict.has_key?(file_hash)
            if files_dict[file_hash][0] == file_name
              if files_dict[file_hash][2] > file_ctime
                puts "Duplicate file found: #{file_name}"
                puts "Original: #{files_dict[file_hash][1]}/#{files_dict[file_hash][0]}"
                puts "Duplicate: #{file_path}/#{file_name}"
                print "Delete duplicate? (y/n): "
                delete = gets.chomp
                if delete == "y"
                  File.delete(file)
                  puts "Deleted: #{file_path}/#{file_name}"
                end
              else
                puts "Duplicate file found: #{file_name}"
                puts "Original: #{file_path}/#{file_name}"
                puts "Duplicate: #{files_dict[file_hash][1]}/#{files_dict[file_hash][0]}"
                print "Delete duplicate? (y/n): "
                delete = gets.chomp
                if delete == "y"
                  File.delete("#{files_dict[file_hash][1]}/#{files_dict[file_hash][0]}")
                  puts "Deleted: #{files_dict[file_hash][1]}/#{files_dict[file_hash][0]}"
                end
              end
            else
              files_dict[file_hash] = [file_name, file_path, file_ctime]
            end
          end
        end
        if options[:low]
          if files_dict.has_key?(file_name)
            if files_dict[file_name][1] > file_ctime
              puts "Duplicate file found: #{file_name}"
              puts "Original: #{files_dict[file_name][0]}/#{files_dict[file_name][1]}"
              puts "Duplicate: #{file_path}/#{file_name}"
              print "Delete duplicate? (y/n): "
              delete = gets.chomp
              if delete == "y"
                File.delete(file)
                puts "Deleted: #{file_path}/#{file_name}"
              end
            else
              puts "Duplicate file found: #{file_name}"
              puts "Original: #{file_path}/#{file_name}"
              puts "Duplicate: #{files_dict[file_name][0]}/#{files_dict[file_name][1]}"
              print "Delete duplicate? (y/n): "
              delete = gets.chomp
              if delete == "y"
                File.delete("#{files_dict[file_name][0]}/#{files_dict[file_name][1]}")
                puts "Deleted: #{files_dict[file_name][0]}/#{files_dict[file_name][1]}"
              end
            end
          else
            files_dict[file_name] = [file_path, file_ctime]
          end
        end
      end
    rescue StandardError => e
      puts "Error: #{e.message}"
    end
  end
end

directory = ARGV[0] # get the directory from the command line argument
find_duplicates(directory)
