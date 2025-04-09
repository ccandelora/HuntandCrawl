#!/bin/bash

echo "Manually fixing the project.pbxproj file..."

# Temp file for editing
TEMP_FILE=$(mktemp)
PROJECT_FILE="HuntandCrawl.xcodeproj/project.pbxproj"

# Create a backup
cp "$PROJECT_FILE" "${PROJECT_FILE}.manual.bak"
echo "Created backup at ${PROJECT_FILE}.manual.bak"

# 1. First find and extract the Copy Files build phase section
COPY_PHASE=$(grep -A 50 "/* Copy Files */" "$PROJECT_FILE" | sed -n '/files = (/,/);/p')
echo "Found Copy Files phase"

# 2. Look for Info.plist references in the Copy Files phase
if echo "$COPY_PHASE" | grep -q "Info.plist"; then
    echo "Found Info.plist in Copy Files phase, will remove it"
    # We'll handle this in the full edit below
fi

# 3. Find the Build Configuration section
BUILD_CONFIG=$(grep -A 20 "buildSettings = {" "$PROJECT_FILE" | head -20)
echo "Found Build Configuration section"

# 4. Check if it has both INFOPLIST_FILE and GENERATE_INFOPLIST_FILE
if echo "$BUILD_CONFIG" | grep -q "INFOPLIST_FILE" && echo "$BUILD_CONFIG" | grep -q "GENERATE_INFOPLIST_FILE = YES"; then
    echo "Found conflicting INFOPLIST_FILE and GENERATE_INFOPLIST_FILE settings"
    # We'll handle this in the full edit below
fi

# 5. Now perform the targeted edit to fix all issues
cat "$PROJECT_FILE" | awk '
BEGIN { in_copy_phase = 0; line_with_infoplist = 0; should_skip = 0; fixing_buildSettings = 0; }
{
    # Check if we are entering the Copy Files phase
    if ($0 ~ /\/\* Copy Files \*\//) { in_copy_phase = 1; }
    
    # If we are in Copy Files phase, look for Info.plist references
    if (in_copy_phase && $0 ~ /Info\.plist/) { should_skip = 1; }
    
    # End of copy phase
    if (in_copy_phase && $0 ~ /\);/) { in_copy_phase = 0; }
    
    # Check for buildSettings blocks
    if ($0 ~ /buildSettings = {/) { fixing_buildSettings = 1; }
    
    # Check for GENERATE_INFOPLIST_FILE = YES
    if (fixing_buildSettings && $0 ~ /GENERATE_INFOPLIST_FILE = YES/) {
        print "\t\t\t\tGENERATE_INFOPLIST_FILE = NO;";
        should_skip = 1;
    }
    
    # Check for INFOPLIST_FILE
    if (fixing_buildSettings && $0 ~ /INFOPLIST_FILE = /) {
        print "\t\t\t\tINFOPLIST_FILE = \"HuntandCrawl/Info.plist\";";
        should_skip = 1;
    }
    
    # End of buildSettings block
    if (fixing_buildSettings && $0 ~ /};/) { fixing_buildSettings = 0; }
    
    # Print line if it should not be skipped
    if (!should_skip) { print $0; }
    
    # Reset skip flag for next line
    should_skip = 0;
}' > "$TEMP_FILE"

# Apply the changes
mv "$TEMP_FILE" "$PROJECT_FILE"
echo "Applied manual fixes to $PROJECT_FILE"

# Clean the project and derived data
echo "Cleaning project..."
xcodebuild clean -scheme HuntandCrawl
rm -rf ~/Library/Developer/Xcode/DerivedData/HuntandCrawl-*

echo "Done! Please close and reopen Xcode, then follow these steps:"
echo "1. Select the Info tab in your project settings"
echo "2. Set 'Info.plist File' to 'HuntandCrawl/Info.plist' explicitly"
echo "3. Uncheck 'Generate Info.plist File' if it's checked"
echo "4. Clean and build the project" 