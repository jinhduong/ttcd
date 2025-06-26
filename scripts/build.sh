#!/bin/bash

# Build script for ttcd with environment variables
# Usage: ./scripts/build.sh [build|test|archive|run]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

# Load environment variables from .env file if it exists
if [ -f .env ]; then
    echo -e "${BLUE}📁 Loading environment variables from .env file...${NC}"
    source .env
else
    echo -e "${YELLOW}⚠️  No .env file found. Using system environment variables or Xcode scheme.${NC}"
fi

# Note about local storage
echo -e "${GREEN}📁 Using local storage for session data${NC}"
echo -e "${GREEN}   Data will be stored in ~/Library/Application Support/ttcd/${NC}"

# Default to build if no argument provided
ACTION=${1:-build}

case $ACTION in
    "build")
        echo -e "${GREEN}🔨 Building ttcd...${NC}"
        xcodebuild -project ttcd.xcodeproj -scheme ttcd -destination 'platform=macOS' build
        echo -e "${GREEN}✅ Build completed!${NC}"
        ;;
    
    "test")
        echo -e "${GREEN}🧪 Running tests...${NC}"
        xcodebuild -project ttcd.xcodeproj -scheme ttcd -destination 'platform=macOS' test
        echo -e "${GREEN}✅ Tests completed!${NC}"
        ;;
    
    "archive")
        echo -e "${GREEN}📦 Creating archive...${NC}"
        xcodebuild -project ttcd.xcodeproj -scheme ttcd -archivePath build/ttcd.xcarchive archive
        echo -e "${GREEN}✅ Archive created at build/ttcd.xcarchive${NC}"
        ;;
    
    "run")
        echo -e "${GREEN}🚀 Building and running ttcd...${NC}"
        xcodebuild -project ttcd.xcodeproj -scheme ttcd -destination 'platform=macOS' build
        
        # Find the built app
        BUILT_APP=$(find ~/Library/Developer/Xcode/DerivedData -name "ttcd.app" -type d 2>/dev/null | head -1)
        if [ -n "$BUILT_APP" ]; then
            echo -e "${GREEN}🚀 Starting ttcd...${NC}"
            open "$BUILT_APP"
        else
            echo -e "${RED}❌ Could not find built app. Please check build output.${NC}"
            exit 1
        fi
        ;;
    
    "clean")
        echo -e "${YELLOW}🧹 Cleaning build artifacts...${NC}"
        xcodebuild -project ttcd.xcodeproj -scheme ttcd clean
        rm -rf build/
        echo -e "${GREEN}✅ Clean completed!${NC}"
        ;;
    
    *)
        echo -e "${RED}❌ Unknown action: $ACTION${NC}"
        echo "Usage: $0 [build|test|archive|run|clean]"
        echo ""
        echo "Actions:"
        echo "  build   - Build the app (default)"
        echo "  test    - Run tests"
        echo "  archive - Create archive for distribution" 
        echo "  run     - Build and run the app"
        echo "  clean   - Clean build artifacts"
        exit 1
        ;;
esac 