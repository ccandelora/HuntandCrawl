#!/bin/bash

echo "Fixing Info.plist in Copy Bundle Resources build phase..."

# Path to the project.pbxproj file
PROJECT_FILE="HuntandCrawl.xcodeproj/project.pbxproj"

# Create a backup
cp "$PROJECT_FILE" "${PROJECT_FILE}.copy_phase.bak"
echo "Created backup at ${PROJECT_FILE}.copy_phase.bak"

# Find the lines that include Info.plist in a PBXBuildFile section
INFO_PLIST_BUILD_FILE_LINE=$(grep -n "Info.plist.*PBXBuildFile" "$PROJECT_FILE" | cut -d: -f1)
if [ -n "$INFO_PLIST_BUILD_FILE_LINE" ]; then
    # Get the identifier (like AABBCCDD112233) for the Info.plist build file
    INFO_PLIST_ID=$(sed -n "${INFO_PLIST_BUILD_FILE_LINE}p" "$PROJECT_FILE" | grep -o "[A-F0-9]\{24\}" | head -n 1)
    echo "Found Info.plist build file with ID: $INFO_PLIST_ID"
    
    # Find and remove this ID from the Copy Bundle Resources section
    sed -i '' "/$INFO_PLIST_ID/d" "$PROJECT_FILE"
    echo "Removed Info.plist from Copy Bundle Resources phase"
else
    echo "Could not find Info.plist in build files"
fi

# Let's also make sure there are no duplicate INFOPLIST_FILE entries
echo "Fixing INFOPLIST_FILE entries..."
sed -i '' 's/INFOPLIST_FILE = "[^"]*";/INFOPLIST_FILE = "HuntandCrawl\/Info.plist";/g' "$PROJECT_FILE"

echo "Applying fix for GENERATE_INFOPLIST_FILE..."
sed -i '' 's/GENERATE_INFOPLIST_FILE = YES;/GENERATE_INFOPLIST_FILE = NO;/g' "$PROJECT_FILE"

echo "Fixing ProcessInfoPlistFile references..."
sed -i '' '/ProcessInfoPlistFile/d' "$PROJECT_FILE"

echo "Applied fixes to $PROJECT_FILE"
echo "Cleaning project..."

# Clean the project and derived data
xcodebuild clean -scheme HuntandCrawl
rm -rf ~/Library/Developer/Xcode/DerivedData/HuntandCrawl-*

echo "Done! Please close and reopen Xcode, then try building again." 