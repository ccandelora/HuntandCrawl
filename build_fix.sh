#!/bin/bash

echo "Starting build fix script..."

# Clean the project
echo "Cleaning project..."
xcodebuild clean -scheme HuntandCrawl

# Remove DerivedData
echo "Removing DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData/HuntandCrawl-*

# Fix common Xcode build issues
echo "Running common fixes..."

# Make sure the Info.plist issue is fixed
if grep -q "INFOPLIST_FILE" HuntandCrawl.xcodeproj/project.pbxproj; then
    echo "Fixing Info.plist reference in project.pbxproj..."
    sed -i '' 's/INFOPLIST_FILE = ".*";/INFOPLIST_FILE = "HuntandCrawl\/Info.plist";/g' HuntandCrawl.xcodeproj/project.pbxproj
fi

echo "Build fix script completed. Please open the project in Xcode and try building again."
