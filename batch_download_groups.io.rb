# frozen_string_literal: true

require "open-uri"
require "fileutils"
require_relative "./groups_io.rb"
require "pry-nav"
require 'dotenv/load'

FIX_MISSING_FILENAMES = true
REPLACE_JPEG_WITH_JPG = true
CAPITIALIZE_FILE_EXTENSIONS = true

def normalize_file_extension(extension)
  extension = ".jpg" if extension == ".jpeg" && REPLACE_JPEG_WITH_JPG
  extension = extension.upcase if CAPITIALIZE_FILE_EXTENSIONS
end

def sanitize_filename(filename)
  extension = File.extname(filename)

  # If the "extension" includes things like spaces or parenthesis, then it really isn't an extension, is it?
  if /[ \(\)]+/.match?(extension)
    binding.pry
    extension = ""
  end

  basename = filename.sub(extension, "")
  extension = normalize_file_extension(extension)

  # replace + or & with "and"
  sanitized_version = basename.gsub(/\s*[\+&]\s*/, " and ")
  sanitized_version = sanitized_version.gsub("%", "percent")

  # Remove exclamation points
  sanitized_version.delete!("!")

  # Replace fancy apostrophes with standard ones
  sanitized_version.tr!("’", "'")

  # Forward slashes (or backslashes) can't be allowed in a file name
  sanitized_version.tr!("/", "-")
  sanitized_version.tr!('\\', "-")

  # replace with whitespace: ? \ / : ; | [ ] { } < > , " !
  sanitized_version.gsub!(%r{[?\\/:;\|\[\]\{\}<>,’"]}, " ")
  sanitized_version.strip!

  # replace blocks of whitespace with a single space
  sanitized_version.gsub!(/\s+/, " ")

  unless extension.downcase.match? /\.(jpe?g|png|gif|bmp)/
    unless extension.empty?
      puts "\nWTF?  Unknown Extension:
Filename:\t#{sanitized_version}
Extension:\t'#{extension}'\n"
      binding.pry
    end
  end

  sanitized_version + extension
end

def ensure_unique_filename(filename)
  if File.exist?(filename)
    puts "\tFile already exists: #{filename}"
    extension = File.extname(filename)
    basename = filename.sub(extension, "")
    index = 2

    filename = "#{basename}-#{index}#{extension}"
    if File.exist?(filename)
      index += 1
      filename = "#{basename}-#{index}#{extension}"
    end

    puts "\tGenerated unique filename: #{filename}\n"
  end

  filename
end

def download_file(href, filename)
  extension = File.extname(filename)

  if extension.downcase == ".part"
    puts "\t\tSkipping partial file: #{filename}"
  else

    # If the "extension" includes things like spaces or parenthesis, then it really isn't an extension, is it?
    if /[ \(\)]+/.match?(extension)
      extension = ""
    end

    filename = sanitize_filename(filename)
    filename = ensure_unique_filename(filename)

    open(href) do |image|
      File.open(filename, "wb") do |file|
        file.write(image.read)
      end
    end

    if extension.empty? && FIX_MISSING_FILENAMES

      begin
        # Use the file command to determine the mimetype
        # Use a capital "I" on macOS and a lowercase "i" on Linux
        # Windows users should probably set FIX_MISSING_FILENAMES to false
        arguments = /darwin/.match?(RUBY_PLATFORM) ? "-Ib" : "-ib"
        extension = "." + `file #{arguments} "#{filename}"`.delete("\n").match(%r{/(\w+);})[1]
        puts "\t\tExtension from mimetype:\t#{extension}"
        extension = normalize_file_extension(extension)
        binding.pry unless extension.downcase.match? /\.(jpe?g|png|gif)/

        File.rename(filename, filename + extension)
      rescue => e
        puts "An error has occurred:\n#{e.message}\n#{e.backtrace}\n"
        binding.pry
      end
    end
  end
end

gio_username = ENV["GIO_USERNAME"]
gio_password = ENV["GIO_PASSWORD"]

gio = GroupsIO.new(gio_username, gio_password)
group = {}

case ARGV[0]
when "list"
  puts "ID\tName"
  puts "-----\t----"
  puts gio.subscriptions.map {|subscription| "#{subscription['group_id']}\t#{subscription['group_name']}"}.join("\n")
  exit(0)
when /^\d+$/
  group = gio.subscriptions.find { |subscription| subscription["group_id"] == ARGV[0].to_i }
when /\w+/
  group = gio.subscriptions.find { |subscription| subscription["group_name"] == ARGV[0] }
else
  puts "Usage: 
Username and password are supplied by adding them to a .env file.

To install necessary Ruby gems: (these commands may need to be run with sudo)
  $ gem install bundler
  $ bundle install

To list available subscribed groups:
  $ bundle exec ruby batch_download_groups.io.rb list 

To download all photos for a group, specify the group ID number or the name:
  $ bundle exec ruby batch_download_groups.io.rb 12345   
  $ bundle exec ruby batch_download_groups.io.rb w6ek    

"
end

unless group
  puts "Group not found in subscription list: #{ARGV[0]}"
  exit(-1)
end

group_id = group["group_id"]

FileUtils.mkdir_p group["group_name"]
Dir.chdir group["group_name"]

albums = gio.get_albums(group_id)
albums.each do |album|

  puts "\nDownloading photos for album: #{album["title"]}"

  # create directory for album
  FileUtils.mkdir_p album["title"]

  # change working directory to new album directory
  Dir.chdir album["title"]

  # get a list of photos for that album
  photos = gio.get_photos(group_id, album["id"])

  # download each of the photos
  photos.each do |photo|
    puts "\t#{photo["name"]}"
    download_file(photo["download_url"], photo["name"])
  end

  # change back to parent directory
  Dir.chdir ".."
end
