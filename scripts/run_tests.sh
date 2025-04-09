#!/bin/bash

# Run Tests Script for Hunt and Crawl App
# This script runs all tests and generates a coverage report

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo "${YELLOW}Starting tests for Hunt and Crawl App...${NC}"

# Check if a simulator name was provided
if [ -z "$1" ]; then
    SIMULATOR="iPhone 16"
else
    SIMULATOR="$1"
fi

echo "${YELLOW}Using simulator: ${SIMULATOR}${NC}"

# Create directory for reports if it doesn't exist
mkdir -p reports

# Run the tests with code coverage
xcodebuild clean test \
    -scheme HuntandCrawl \
    -sdk iphonesimulator \
    -destination "platform=iOS Simulator,name=${SIMULATOR}" \
    -enableCodeCoverage YES \
    -resultBundlePath "./reports/TestResults.xcresult" | xcpretty

# Check if tests were successful
if [ $? -eq 0 ]; then
    echo "${GREEN}✅ Tests completed successfully!${NC}"
    
    # Generate HTML coverage report using xcresultparser if available
    if command -v xcrun xcresulttool &> /dev/null; then
        echo "${YELLOW}Generating coverage report...${NC}"
        
        # Extract coverage data
        xcrun xccov view --report --only-targets ./reports/TestResults.xcresult > ./reports/coverage_summary.txt
        
        echo "${GREEN}✅ Coverage report generated in ./reports/coverage_summary.txt${NC}"
        
        # Print summary
        echo "${YELLOW}Test Coverage Summary:${NC}"
        cat ./reports/coverage_summary.txt
    else
        echo "${YELLOW}xcresulttool not available. Coverage report not generated.${NC}"
    fi
else
    echo "${RED}❌ Tests failed.${NC}"
    exit 1
fi

# Print instructions for viewing detailed results
echo ""
echo "${YELLOW}To view detailed test results in Xcode:${NC}"
echo "1. Open the HuntandCrawl project in Xcode"
echo "2. Go to Window > Organizer"
echo "3. Select the 'Tests' tab"
echo "4. Find the latest test run"
echo ""
echo "${YELLOW}Or run:${NC} open ./reports/TestResults.xcresult"

exit 0 