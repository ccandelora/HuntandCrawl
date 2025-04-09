#!/bin/bash

echo "Starting complete rebuild process..."

# Step 1: Clean the project
echo "Step 1: Cleaning project..."
xcodebuild clean -scheme HuntandCrawl

# Step 2: Remove DerivedData
echo "Step 2: Removing DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData/HuntandCrawl-*

# Step 3: Create a build.xcconfig file with correct settings
echo "Step 3: Setting up build configuration..."
cat > HuntandCrawl.xcconfig << EOL
GENERATE_INFOPLIST_FILE = NO
INFOPLIST_FILE = HuntandCrawl/Info.plist
PRODUCT_BUNDLE_IDENTIFIER = com.huntandcrawl.app
SWIFT_VERSION = 5.0
IPHONEOS_DEPLOYMENT_TARGET = 17.0
EOL

echo "Created HuntandCrawl.xcconfig with proper settings"

# Step 4: Build the project
echo "Step 4: Building project..."
xcodebuild build -scheme HuntandCrawl -sdk iphonesimulator -xcconfig HuntandCrawl.xcconfig

echo "Rebuild process complete. Please close and reopen Xcode."
echo "If issues persist, try product > clean build folder in Xcode and then build again." 