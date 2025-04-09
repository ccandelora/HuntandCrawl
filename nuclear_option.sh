#!/bin/bash

# NUCLEAR OPTION: Completely remove all Info.plist configurations and 
# rebuild them from scratch with absolute paths

echo "🧨 NUCLEAR OPTION FOR INFO.PLIST ISSUES 🧨"
echo "This script will completely reconfigure your project's Info.plist handling"
echo "This is a last resort after other solutions have failed"

# Create a backup
TIMESTAMP=$(date +%Y%m%d%H%M%S)
BACKUP_DIR="nuclear_backup_$TIMESTAMP"
mkdir -p "$BACKUP_DIR"
cp -r HuntandCrawl "$BACKUP_DIR"
cp -r HuntandCrawl.xcodeproj "$BACKUP_DIR"
echo "✅ Created backup in $BACKUP_DIR"

# Path to project
PROJECT_PATH="/Users/ccandelora/Sites/native_apps/cruise/HuntandCrawl"
PROJECT_FILE="HuntandCrawl.xcodeproj/project.pbxproj"

# Set absolute paths for consistent behavior
ABSOLUTE_INFO_PLIST="$PROJECT_PATH/HuntandCrawl/Info.plist"

# Step 1: Completely remove all Info.plist references from project.pbxproj
echo "🔨 Removing all Info.plist references from project..."
grep -l "Info.plist" "$PROJECT_FILE" > /dev/null

# Use perl for more reliable regex replacement across multiple lines
perl -0777 -i -pe 's/(\/\* Begin PBXBuildFile section \*\/.*?)(.*?Info\.plist.*?)(\n[^\n]*)/\1\3/gs' "$PROJECT_FILE"
perl -0777 -i -pe 's/(\/\* Begin PBXFileReference section \*\/.*?)(.*?Info\.plist.*?)(\n[^\n]*)/\1\3/gs' "$PROJECT_FILE"
perl -0777 -i -pe 's/(\/\* Copy Bundle Resources \*\/.*?files = \()(.*?)(\);)/\1\3/gs' "$PROJECT_FILE"

# Step 2: Remove all Info.plist build settings
echo "🔨 Removing all Info.plist build settings..."
sed -i '' '/INFOPLIST_FILE/d' "$PROJECT_FILE"
sed -i '' '/GENERATE_INFOPLIST_FILE/d' "$PROJECT_FILE"
sed -i '' '/ProcessInfoPlistFile/d' "$PROJECT_FILE"

# Step 3: Add the absolute path to Info.plist in all build configurations
echo "🔨 Adding absolute Info.plist path to all build configurations..."
sed -i '' "s/buildSettings = {/buildSettings = {\n\t\t\t\tINFOPLIST_FILE = \"$ABSOLUTE_INFO_PLIST\";\n\t\t\t\tGENERATE_INFOPLIST_FILE = NO;/g" "$PROJECT_FILE"

# Step 4: Create .xcconfig file with absolute paths
echo "🔨 Creating .xcconfig file with absolute paths..."

cat > "$PROJECT_PATH/NuclearFix.xcconfig" << EOL
// Nuclear fix for Info.plist issues
GENERATE_INFOPLIST_FILE = NO
INFOPLIST_FILE = $ABSOLUTE_INFO_PLIST
PRODUCT_BUNDLE_IDENTIFIER = com.huntandcrawl.app
SWIFT_VERSION = 5.0
IPHONEOS_DEPLOYMENT_TARGET = 17.0
EOL

echo "✅ Created NuclearFix.xcconfig with absolute paths"

# Step 5: Clean everything
echo "🧹 Cleaning project..."
xcodebuild clean -scheme HuntandCrawl
rm -rf ~/Library/Developer/Xcode/DerivedData/HuntandCrawl-*
  
echo "✅ NUCLEAR OPTION COMPLETED"
echo ""
echo "📋 NEXT STEPS:"
echo "1. CLOSE XCODE COMPLETELY"
echo "2. Open the project with: open -a Xcode $PROJECT_PATH/HuntandCrawl.xcodeproj"
echo "3. In Xcode, go to Project settings > Info"
echo "4. Set Configurations > Use XCConfig > select $PROJECT_PATH/NuclearFix.xcconfig for both Debug and Release"
echo "5. Go to Build Settings > Packaging"
echo "6. Verify that Info.plist File is set to absolute path: $ABSOLUTE_INFO_PLIST"
echo "7. Clean and Build (Product > Clean Build Folder)"
echo ""
echo "If this doesn't work, you may need to create a brand new project and migrate your code." 