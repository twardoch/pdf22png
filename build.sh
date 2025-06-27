#!/bin/bash

# PDF22PNG Build Script
# Builds both Objective-C and Swift implementations

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Configuration
BUILD_DIR="build"
SWIFT_BUILD_CONFIG="release"
OBJC_OPTIMIZATION="-O2"
PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"

# Default options
BUILD_OBJC=true
BUILD_SWIFT=true
BUILD_TYPE="release"
VERBOSE=false
CLEAN=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
    --objc-only)
        BUILD_OBJC=true
        BUILD_SWIFT=false
        shift
        ;;
    --swift-only)
        BUILD_OBJC=false
        BUILD_SWIFT=true
        shift
        ;;
    --debug)
        BUILD_TYPE="debug"
        shift
        ;;
    --clean)
        CLEAN=true
        shift
        ;;
    --verbose | -v)
        VERBOSE=true
        shift
        ;;
    --help | -h)
        echo "PDF22PNG Build Script"
        echo "===================="
        echo ""
        echo "Usage: $0 [options]"
        echo ""
        echo "Options:"
        echo "  --objc-only     Build only Objective-C implementation"
        echo "  --swift-only    Build only Swift implementation"
        echo "  --debug         Build debug versions"
        echo "  --clean         Clean before building"
        echo "  --verbose, -v   Verbose output"
        echo "  --help, -h      Show this help"
        echo ""
        echo "By default, builds both implementations in release mode."
        exit 0
        ;;
    *)
        echo -e "${RED}Unknown option: $1${NC}"
        exit 1
        ;;
    esac
done

# Print header
echo -e "${BLUE}PDF22PNG Build System${NC}"
echo -e "${BLUE}====================${NC}"
echo ""

if [ "$VERBOSE" = true ]; then
    echo "Build configuration:"
    echo "  Objective-C: $BUILD_OBJC"
    echo "  Swift: $BUILD_SWIFT"
    echo "  Type: $BUILD_TYPE"
    echo "  Clean: $CLEAN"
    echo ""
fi

# Clean if requested
if [ "$CLEAN" = true ]; then
    echo -e "${YELLOW}Cleaning previous builds...${NC}"
    if [ "$BUILD_OBJC" = true ] && [ -d "pdf21png" ]; then
        cd pdf21png && make clean && cd ..
    fi
    if [ "$BUILD_SWIFT" = true ] && [ -d "pdf22png" ]; then
        cd pdf22png && make clean && cd ..
    fi
    echo -e "${GREEN}✓ Clean completed${NC}"
    echo ""
fi

# Build Objective-C implementation
if [ "$BUILD_OBJC" = true ]; then
    echo -e "${YELLOW}Building Objective-C Implementation...${NC}"
    if [ -d "pdf21png" ]; then
        cd pdf21png
        if [ "$BUILD_TYPE" = "debug" ]; then
            make debug
        else
            make
        fi
        cd ..
        echo -e "${GREEN}✓ Objective-C implementation built successfully${NC}"
    else
        echo -e "${RED}✗ pdf21png directory not found${NC}"
        exit 1
    fi
    echo ""
fi

# Build Swift implementation
if [ "$BUILD_SWIFT" = true ]; then
    echo -e "${YELLOW}Building Swift Implementation...${NC}"
    if [ -d "pdf22png" ]; then
        cd pdf22png
        if [ "$BUILD_TYPE" = "debug" ]; then
            make debug
        else
            make build
        fi
        cd ..
        echo -e "${GREEN}✓ Swift implementation built successfully${NC}"
    else
        echo -e "${RED}✗ pdf22png directory not found${NC}"
        exit 1
    fi
    echo ""
fi

# Summary
echo -e "${BLUE}Build Summary${NC}"
echo -e "${BLUE}=============${NC}"

if [ "$BUILD_OBJC" = true ]; then
    if [ -f "pdf21png/build/pdf21png" ] || [ -f "pdf21png/build/pdf21png-debug" ]; then
        echo -e "${GREEN}✓ Objective-C: pdf21png/build/pdf21png${NC}"
    else
        echo -e "${RED}✗ Objective-C build failed${NC}"
    fi
fi

if [ "$BUILD_SWIFT" = true ]; then
    if [ -f "pdf22png/.build/release/pdf22png" ] || [ -f "pdf22png/.build/debug/pdf22png" ]; then
        echo -e "${GREEN}✓ Swift: pdf22png/.build/$BUILD_TYPE/pdf22png${NC}"
    else
        echo -e "${RED}✗ Swift build failed${NC}"
    fi
fi

echo ""
echo -e "${GREEN}Build completed!${NC}"

# Show usage examples
echo ""
echo -e "${BLUE}Usage Examples:${NC}"
if [ "$BUILD_OBJC" = true ]; then
    echo "  ./pdf21png/build/pdf21png input.pdf output.png"
fi
if [ "$BUILD_SWIFT" = true ]; then
    echo "  ./pdf22png/.build/$BUILD_TYPE/pdf22png input.pdf output.png"
fi
