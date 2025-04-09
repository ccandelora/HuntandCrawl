#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'HuntandCrawl.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the main target
target = project.targets.find { |t| t.name == 'HuntandCrawl' }
if target.nil?
  puts "❌ Cannot find the 'HuntandCrawl' target"
  exit 1
end

puts "✅ Found target: #{target.name}"

# Find the Info.plist file reference
info_plist_ref = nil
project.files.each do |file|
  if file.path.end_with?('Info.plist')
    info_plist_ref = file
    puts "✅ Found Info.plist reference: #{file.path}"
    break
  end
end

if info_plist_ref.nil?
  puts "❌ Cannot find Info.plist file reference"
  exit 1
end

# Remove Info.plist from Copy Bundle Resources build phase
resource_build_phase = target.resources_build_phase
resource_build_phase.files.each do |build_file|
  if build_file.file_ref == info_plist_ref
    puts "🔄 Removing Info.plist from Copy Bundle Resources phase"
    resource_build_phase.remove_build_file(build_file)
  end
end

# Ensure proper INFOPLIST_FILE setting in all build configurations
target.build_configurations.each do |config|
  puts "🔄 Updating build settings for configuration: #{config.name}"
  
  # Set the Info.plist file path
  config.build_settings['INFOPLIST_FILE'] = 'HuntandCrawl/Info.plist'
  
  # Make sure we're not trying to generate an Info.plist
  config.build_settings['GENERATE_INFOPLIST_FILE'] = 'NO'
  
  # Set the bundle identifier
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.huntandcrawl.app'
end

# Save the changes
project.save

puts "✅ Project modified successfully"
