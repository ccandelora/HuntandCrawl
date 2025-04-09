#!/bin/bash

echo "Applying final fix for Info.plist issue..."

# Create a backup directory for the entire project
TIMESTAMP=$(date +%Y%m%d%H%M%S)
BACKUP_DIR="HuntandCrawl_backup_$TIMESTAMP"
mkdir -p "$BACKUP_DIR"

# Copy important files to backup
cp -r HuntandCrawl "$BACKUP_DIR/"
cp -r HuntandCrawl.xcodeproj "$BACKUP_DIR/"
echo "Created backup in $BACKUP_DIR"

# Move the existing Info.plist to a new location to avoid conflicts
echo "Moving Info.plist to new location"
mkdir -p "HuntandCrawl/SupportFiles"
cp "HuntandCrawl/Info.plist" "HuntandCrawl/SupportFiles/Info.plist"

# Create a new minimal Info.plist in the root to avoid build system conflicts
echo "Creating new Info.plist"
cat > "HuntandCrawl/Info-minimal.plist" << EOL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.huntandcrawl.app</string>
</dict>
</plist>
EOL

# Clean up the project.pbxproj file
echo "Fixing project.pbxproj..."
PROJECT_FILE="HuntandCrawl.xcodeproj/project.pbxproj"
cp "$PROJECT_FILE" "${PROJECT_FILE}.final.bak"

# Remove any Info.plist from Copy Bundle Resources phases
sed -i '' '/Info.plist.*PBXBuildFile/d' "$PROJECT_FILE" 
sed -i '' '/Info.plist.*fileRef/d' "$PROJECT_FILE"

# Update all build configuration sections
sed -i '' 's/INFOPLIST_FILE = "[^"]*";/INFOPLIST_FILE = "HuntandCrawl\/SupportFiles\/Info.plist";/g' "$PROJECT_FILE"
sed -i '' 's/GENERATE_INFOPLIST_FILE = YES;/GENERATE_INFOPLIST_FILE = NO;/g' "$PROJECT_FILE"
sed -i '' '/ProcessInfoPlistFile/d' "$PROJECT_FILE"

# Add the new Info-minimal.plist to the project
# This part would normally be done in Xcode itself, as it's complex to do in a script

# Clean the build and derived data
echo "Cleaning build..."
xcodebuild clean -scheme HuntandCrawl
rm -rf ~/Library/Developer/Xcode/DerivedData/HuntandCrawl-*

echo "Done! Please follow these steps:"
echo "1. Close and reopen Xcode"
echo "2. In the project settings, update the Info.plist path to be 'HuntandCrawl/SupportFiles/Info.plist'"
echo "3. Remove any references to the old Info.plist from the Copy Bundle Resources phase"
echo "4. Clean and build the project"
echo ""
echo "If this doesn't work, the best solution may be to create a new project and move your code over" 