#!/bin/bash

echo "Fixing Info.plist duplicate build issue..."

# Path to the project.pbxproj file
PROJECT_FILE="HuntandCrawl.xcodeproj/project.pbxproj"

# 1. Create a backup
cp "$PROJECT_FILE" "${PROJECT_FILE}.bak"
echo "Created backup at ${PROJECT_FILE}.bak"

# 2. Remove any duplicate INFOPLIST_FILE entries
# This preserves only the PLIST_FILE_OUTPUT_FORMAT entry and removes the INFOPLIST_FILE entry if both exist
sed -i '' '/INFOPLIST_FILE/d; /PRODUCT_BUNDLE_IDENTIFIER/d; /GENERATE_INFOPLIST_FILE = YES/d' "$PROJECT_FILE"

# 3. Add the proper INFOPLIST_FILE and GENERATE_INFOPLIST_FILE settings to all build configurations
sed -i '' 's/buildSettings = {/buildSettings = {\n\t\t\t\tINFOPLIST_FILE = "HuntandCrawl\/Info.plist";\n\t\t\t\tGENERATE_INFOPLIST_FILE = NO;/g' "$PROJECT_FILE"

echo "Applied fixes to $PROJECT_FILE"
echo "Cleaning project..."

# 4. Clean the project and derived data
xcodebuild clean -scheme HuntandCrawl
rm -rf ~/Library/Developer/Xcode/DerivedData/HuntandCrawl-*

echo "Done! Please close and reopen Xcode, then try building again."
