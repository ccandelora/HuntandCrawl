#!/bin/bash

echo "======================="
echo "XCODE PROJECT SAFE FIX"
echo "======================="

# Check if we can install the xcodeproj gem
echo "Checking for Ruby gems..."
if ! command -v gem &> /dev/null; then
    echo "Ruby gems not found. Cannot proceed."
    exit 1
fi

# Check if xcodeproj gem is installed
if ! gem list -i xcodeproj &> /dev/null; then
    echo "Installing xcodeproj gem..."
    sudo gem install xcodeproj
fi

# Create a backup
TIMESTAMP=$(date +%Y%m%d%H%M%S)
BACKUP_DIR="safe_backup_$TIMESTAMP"
mkdir -p "$BACKUP_DIR"
cp -r HuntandCrawl "$BACKUP_DIR"
cp -r HuntandCrawl.xcodeproj "$BACKUP_DIR"
echo "✅ Created backup in $BACKUP_DIR"

# Create Ruby script to safely modify project
cat > fix_project.rb << 'EOL'
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
EOL

# Make the script executable
chmod +x fix_project.rb

# Run the script
echo "Modifying project using Ruby xcodeproj gem..."
ruby fix_project.rb

# Additional steps
echo "Cleaning project..."
xcodebuild clean -scheme HuntandCrawl
rm -rf ~/Library/Developer/Xcode/DerivedData/HuntandCrawl-*

echo "✅ SAFE FIX COMPLETED"
echo ""
echo "NEXT STEPS:"
echo "1. Close Xcode completely"
echo "2. Open the project again: open -a Xcode HuntandCrawl.xcodeproj"
echo "3. Go to Product > Clean Build Folder"
echo "4. Try building the project"
echo ""
echo "If this still fails, try opening your project file, right-click on Info.plist in the Project Navigator,"
echo "select 'Show in Finder', then drag it back into your project with 'Create folder references' selected."
echo "Then go to target settings and ensure INFOPLIST_FILE is set to 'HuntandCrawl/Info.plist'." 