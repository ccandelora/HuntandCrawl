#!/usr/bin/env ruby

# This script directly modifies the Xcode project structure
# to remove Info.plist from Copy Bundle Resources phase
# and fix Info.plist settings

require 'tempfile'

PROJECT_FILE = "HuntandCrawl.xcodeproj/project.pbxproj"

puts "===== RUBY SCRIPT TO FIX INFO.PLIST ISSUES ====="
puts "Reading project file..."

# Open the project file
project_data = File.read(PROJECT_FILE)

# Make a backup
File.write("#{PROJECT_FILE}.ruby.bak", project_data)
puts "Created backup at #{PROJECT_FILE}.ruby.bak"

# Parse the project file data
puts "Analyzing project structure..."

# Track if we're in a relevant section
in_copy_resources_section = false
in_build_file_section = false
in_build_settings_section = false

# Track any Info.plist file references we find
info_plist_file_refs = []
info_plist_build_files = []

# First pass - identify all Info.plist references
project_data.each_line do |line|
  # Find copy resources section
  if line.include?("/* Copy Bundle Resources */")
    in_copy_resources_section = true
  elsif in_copy_resources_section && line.include?("files = (")
    # We're now in the files list of the copy resources section
  elsif in_copy_resources_section && line.include?(");")
    # End of the files list
    in_copy_resources_section = false
  elsif in_copy_resources_section && line.include?("Info.plist")
    # Found Info.plist in copy resources
    ref_id = line.scan(/[A-F0-9]{24}/).first
    info_plist_build_files << ref_id if ref_id
  end

  # Find any Info.plist file references
  if line.include?("Info.plist")
    ref_id = line.scan(/[A-F0-9]{24}/).first
    info_plist_file_refs << ref_id if ref_id
  end
end

puts "Found Info.plist file references: #{info_plist_file_refs.uniq.join(', ')}"
puts "Found Info.plist build files: #{info_plist_build_files.uniq.join(', ')}"

# Create a new temporary file with our modifications
temp_file = Tempfile.new('pbxproj')

in_copy_resources_section = false
in_build_settings_section = false
skip_line = false
build_settings_added = false

# Second pass - implement fixes
project_data.each_line do |line|
  skip_line = false

  # Check if we're entering a Copy Bundle Resources section
  if line.include?("/* Copy Bundle Resources */")
    in_copy_resources_section = true
    temp_file.puts(line)
    next
  end

  # Check if we're exiting a Copy Bundle Resources section
  if in_copy_resources_section && line.include?(");")
    in_copy_resources_section = false
    temp_file.puts(line)
    next
  end

  # Skip any Info.plist lines in Copy Bundle Resources
  if in_copy_resources_section && (
      line.include?("Info.plist") ||
      info_plist_build_files.any? { |ref| line.include?(ref) })
    skip_line = true
  end

  # Check if we're entering a build settings section
  if line.include?("buildSettings = {")
    in_build_settings_section = true
    build_settings_added = false
    # Add our build settings right after the opening brace
    temp_file.puts(line)
    temp_file.puts("\t\t\t\tINFOPLIST_FILE = \"HuntandCrawl/Info.plist\";")
    temp_file.puts("\t\t\t\tGENERATE_INFOPLIST_FILE = NO;")
    build_settings_added = true
    next
  end

  # Check if we're exiting a build settings section
  if in_build_settings_section && line.include?("};")
    in_build_settings_section = false
    temp_file.puts(line)
    next
  end

  # Skip existing INFOPLIST_FILE and GENERATE_INFOPLIST_FILE lines
  if in_build_settings_section && (
      line.include?("INFOPLIST_FILE =") ||
      line.include?("GENERATE_INFOPLIST_FILE ="))
    skip_line = true
  end

  # Skip any ProcessInfoPlistFile references
  if line.include?("ProcessInfoPlistFile")
    skip_line = true
  end

  # Write the line if we're not skipping it
  temp_file.puts(line) unless skip_line
end

temp_file.close

# Apply our changes to the original file
FileUtils.cp(temp_file.path, PROJECT_FILE)
temp_file.unlink

puts "Changes applied to project file."
puts "Now run the following commands:"
puts "1. Clean the project: xcodebuild clean -scheme HuntandCrawl"
puts "2. Remove derived data: rm -rf ~/Library/Developer/Xcode/DerivedData/HuntandCrawl-*"
puts "3. Close Xcode completely and reopen the project"
