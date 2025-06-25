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

# Parse command line arguments
BUILD_OBJC=true
BUILD_SWIFT=true
BUILD_UNIVERSAL=false
CLEAN_FIRST=false
VERBOSE=false

print_usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  --objc-only     Build only Objective-C implementation"
    echo "  --swift-only    Build only Swift implementation"
    echo "  --universal     Build universal binary for Objective-C"
    echo "  --clean         Clean before building"
    echo "  --debug         Build with debug symbols"
    echo "  --verbose       Verbose output"
    echo "  -h, --help      Show this help message"
}

# Process arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --objc-only)
            BUILD_SWIFT=false
            shift
            ;;
        --swift-only)
            BUILD_OBJC=false
            shift
            ;;
        --universal)
            BUILD_UNIVERSAL=true
            shift
            ;;
        --clean)
            CLEAN_FIRST=true
            shift
            ;;
        --debug)
            SWIFT_BUILD_CONFIG="debug"
            OBJC_OPTIMIZATION="-O0 -g"
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            print_usage
            exit 1
            ;;
    esac
done

# Header
echo -e "${BOLD}PDF22PNG Build System${NC}"
echo "===================="
echo

# Clean if requested
if [ "$CLEAN_FIRST" = true ]; then
    echo -e "${YELLOW}Cleaning previous builds...${NC}"
    cd "$PROJECT_ROOT"
    make clean-all >/dev/null 2>&1 || true
    echo -e "${GREEN}✓ Clean complete${NC}\n"
fi

# Create build directory
mkdir -p "$BUILD_DIR"

# Build Objective-C implementation
if [ "$BUILD_OBJC" = true ]; then
    echo -e "${BLUE}Building Objective-C Implementation${NC}"
    echo "-----------------------------------"
    
    cd "$PROJECT_ROOT"
    
    if [ "$BUILD_UNIVERSAL" = true ]; then
        echo "Target: Universal Binary (Intel + Apple Silicon)"
        if [ "$VERBOSE" = true ]; then
            make -C objc universal
        else
            make -C objc universal >/dev/null 2>&1
        fi
        echo -e "${GREEN}✓ Universal binary created${NC}"
    else
        echo "Target: Native Architecture"
        echo -n "  • Compiling Objective-C sources... "
        if [ "$VERBOSE" = true ]; then
            echo
            make objc
        else
            make objc >/dev/null 2>&1
        fi
        echo -e "${GREEN}✓${NC}"
    fi
    
    # Check binary
    if [ -f "$BUILD_DIR/pdf22png" ]; then
        SIZE=$(ls -lh "$BUILD_DIR/pdf22png" | awk '{print $5}')
        echo -e "  ${GREEN}✓ Success:${NC} $BUILD_DIR/pdf22png ($SIZE)"
    else
        echo -e "  ${RED}✗ Failed to build Objective-C version${NC}"
        exit 1
    fi
    echo
fi

# Build Swift implementation
if [ "$BUILD_SWIFT" = true ]; then
    echo -e "${BLUE}Building Swift Implementation${NC}"
    echo "------------------------------"
    echo "Configuration: $SWIFT_BUILD_CONFIG"
    
    cd "$PROJECT_ROOT"
    
    echo -n "  • Building Swift Package... "
    if [ "$VERBOSE" = true ]; then
        echo
        make swift
    else
        make swift >/dev/null 2>&1
    fi
    echo -e "${GREEN}✓${NC}"
    
    # Check binary
    if [ -f "$BUILD_DIR/pdf22png-swift" ]; then
        SIZE=$(ls -lh "$BUILD_DIR/pdf22png-swift" | awk '{print $5}')
        echo -e "  ${GREEN}✓ Success:${NC} $BUILD_DIR/pdf22png-swift ($SIZE)"
    else
        echo -e "  ${RED}✗ Failed to build Swift version${NC}"
        exit 1
    fi
    echo
fi

# Summary
echo -e "${BOLD}Build Summary${NC}"
echo "============="

if [ -f "$BUILD_DIR/pdf22png" ]; then
    VERSION=$("$BUILD_DIR/pdf22png" --version 2>/dev/null | head -1 || echo "Unknown")
    echo -e "  ${GREEN}✓${NC} Objective-C: $VERSION"
fi

if [ -f "$BUILD_DIR/pdf22png-swift" ]; then
    VERSION=$("$BUILD_DIR/pdf22png-swift" --version 2>/dev/null | head -1 || echo "Unknown")
    echo -e "  ${GREEN}✓${NC} Swift:       $VERSION"
fi

echo
echo -e "${BOLD}Next Steps:${NC}"
echo "  • Run benchmarks: ./bench.sh"
echo "  • Install system-wide: sudo make install-both"
echo "  • Test conversion: ./build/pdf22png input.pdf output.png"
echo
echo -e "${GREEN}Build completed successfully!${NC}"