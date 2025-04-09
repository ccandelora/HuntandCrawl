#!/bin/bash

# This script completely resolves the multiple Info.plist files issue
# by removing all Info.plist references from Copy Bundle Resources phase
# and ensuring there's only one Info.plist generation method

echo "===== COMPLETE INFO.PLIST FIX ====="

# Create backup
TIMESTAMP=$(date +%Y%m%d%H%M%S)
echo "Creating backup..."
mkdir -p "backups/backup_$TIMESTAMP"
cp -r HuntandCrawl "backups/backup_$TIMESTAMP/"
cp -r HuntandCrawl.xcodeproj "backups/backup_$TIMESTAMP/"
echo "Backup created in backups/backup_$TIMESTAMP"

# Path to project file
PROJECT_FILE="HuntandCrawl.xcodeproj/project.pbxproj"
cp "$PROJECT_FILE" "${PROJECT_FILE}.complete.bak"

echo "Extracting file references from project..."
# Extract all Info.plist file references (these are the file IDs in the project)
INFO_PLIST_REFS=$(grep -n "Info.plist" "$PROJECT_FILE" | grep -o "[A-Z0-9]\{24\}" | sort | uniq)

if [ -n "$INFO_PLIST_REFS" ]; then
    echo "Found Info.plist references:"
    echo "$INFO_PLIST_REFS"

    # For each Info.plist reference, remove it from the Copy Bundle Resources build phase
    for REF in $INFO_PLIST_REFS; do
        echo "Removing reference $REF from Copy Bundle Resources phase"
        sed -i '' "/$REF.*Copy Bundle Resources/d" "$PROJECT_FILE"
    done
else
    echo "No Info.plist references found in the project."
fi

echo "Removing any redundant Info.plist entries..."
# Remove all Info.plist build file references
sed -i '' '/Info\.plist.*PBXBuildFile/d' "$PROJECT_FILE"

echo "Cleaning build settings..."
# Remove all existing INFOPLIST_FILE settings
sed -i '' '/INFOPLIST_FILE/d' "$PROJECT_FILE"

# Remove all GENERATE_INFOPLIST_FILE settings
sed -i '' '/GENERATE_INFOPLIST_FILE/d' "$PROJECT_FILE"

# Remove any ProcessInfoPlistFile references
sed -i '' '/ProcessInfoPlistFile/d' "$PROJECT_FILE"

echo "Adding correct build settings..."
# Add the correct settings to all buildSettings sections
sed -i '' 's/buildSettings = {/buildSettings = {\n\t\t\t\tINFOPLIST_FILE = "HuntandCrawl\/Info.plist";\n\t\t\t\tGENERATE_INFOPLIST_FILE = NO;/g' "$PROJECT_FILE"

echo "Ensuring single Info.plist file..."
# Make sure there's only one Info.plist file in the main directory
if [ -f "HuntandCrawl/SupportFiles/Info.plist" ]; then
    echo "Removing SupportFiles/Info.plist..."
    rm "HuntandCrawl/SupportFiles/Info.plist"
fi

if [ -f "HuntandCrawl/Info-minimal.plist" ]; then
    echo "Removing Info-minimal.plist..."
    rm "HuntandCrawl/Info-minimal.plist"
fi

echo "Creating build.xcconfig with proper settings..."
# Create an xcconfig file with the correct settings
cat > "HuntandCrawl.xcconfig" << EOL
GENERATE_INFOPLIST_FILE = NO
INFOPLIST_FILE = HuntandCrawl/Info.plist
PRODUCT_BUNDLE_IDENTIFIER = com.huntandcrawl.app
SWIFT_VERSION = 5.0
IPHONEOS_DEPLOYMENT_TARGET = 17.0
EOL

echo "Cleaning project and derived data..."
# Clean the project and derived data
xcodebuild clean -scheme HuntandCrawl
rm -rf ~/Library/Developer/Xcode/DerivedData/HuntandCrawl-*

echo "=== FIX APPLIED SUCCESSFULLY ==="
echo ""
echo "NEXT STEPS:"
echo "1. Close Xcode completely"
echo "2. Reopen the project with: open -a Xcode HuntandCrawl.xcodeproj"
echo "3. Go to Project Settings > Build Settings > Packaging"
echo "4. Set 'Info.plist File' to 'HuntandCrawl/Info.plist'"
echo "5. Make sure 'Generate Info.plist File' is set to 'No'"
echo "6. Clean the build folder (Product > Clean Build Folder)"
echo "7. Build the project"
echo ""
echo "If this still doesn't work, check if Info.plist is in Copy Bundle Resources:"
echo "1. Go to Project Settings > Build Phases > Copy Bundle Resources"
echo "2. Check if Info.plist is listed there"
echo "3. If it is, remove it by clicking the - button"
echo ""
