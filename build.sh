#!/bin/bash

# PDF22PNG Build Script
# Wrapper around the unified Makefile for backward compatibility

set -e

cd "$(dirname "$0")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Default options
BUILD_TARGET="all"
MAKE_ARGS=""
SHOW_HELP=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
    --objc-only|--only-objc)
        BUILD_TARGET="pdf21png"
        shift
        ;;
    --swift-only|--only-swift)
        BUILD_TARGET="pdf22png"
        shift
        ;;
    --debug)
        print_warning "Debug builds not yet implemented in Makefile"
        print_info "Building release versions..."
        shift
        ;;
    --release)
        # Default behavior
        shift
        ;;
    --clean)
        echo -e "${YELLOW}Cleaning build artifacts...${NC}"
        make clean
        echo -e "${GREEN}✓ Clean completed${NC}"
        exit 0
        ;;
    --verbose|-v)
        MAKE_ARGS="$MAKE_ARGS VERBOSE=1"
        shift
        ;;
    --help|-h)
        SHOW_HELP=true
        shift
        ;;
    *)
        echo -e "${RED}Unknown option: $1${NC}"
        echo "Use --help for usage information"
        exit 1
        ;;
    esac
done

# Show help if requested
if [ "$SHOW_HELP" = true ]; then
    echo "PDF22PNG Build Script"
    echo "===================="
    echo ""
    echo "This script is a wrapper around the unified Makefile."
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --objc-only, --only-objc    Build only pdf21png (Objective-C)"
    echo "  --swift-only, --only-swift  Build only pdf22png (Swift)"
    echo "  --clean                     Clean build artifacts"
    echo "  --verbose, -v               Verbose output"
    echo "  --help, -h                  Show this help"
    echo ""
    echo "Examples:"
    echo "  $0                  # Build both implementations"
    echo "  $0 --objc-only      # Build only Objective-C version"
    echo "  $0 --swift-only     # Build only Swift version"
    echo "  $0 --clean          # Clean all build artifacts"
    echo ""
    echo "For more control, use the Makefile directly:"
    echo "  make help           # Show all Makefile targets"
    echo ""
    exit 0
fi

# Print header
echo -e "${BLUE}PDF22PNG Build System${NC}"
echo -e "${BLUE}====================${NC}"
echo ""

# Check dependencies first
echo -e "${YELLOW}Checking dependencies...${NC}"
if ! make check-deps > /dev/null 2>&1; then
    echo -e "${RED}✗ Missing dependencies${NC}"
    echo ""
    echo "Run './scripts/install-deps.sh' to check and install dependencies"
    exit 1
fi
echo -e "${GREEN}✓ Dependencies satisfied${NC}"
echo ""

# Build using Makefile
echo -e "${YELLOW}Building target: $BUILD_TARGET${NC}"
if make $BUILD_TARGET $MAKE_ARGS; then
    echo ""
    echo -e "${GREEN}✓ Build completed successfully!${NC}"
    
    # Show what was built
    echo ""
    echo -e "${BLUE}Build Results:${NC}"
    
    if [ "$BUILD_TARGET" = "all" ] || [ "$BUILD_TARGET" = "pdf21png" ]; then
        if [ -f "pdf21png/build/pdf21png" ]; then
            echo -e "${GREEN}✓ pdf21png (Objective-C): pdf21png/build/pdf21png${NC}"
        fi
    fi
    
    if [ "$BUILD_TARGET" = "all" ] || [ "$BUILD_TARGET" = "pdf22png" ]; then
        if [ -f "pdf22png/.build/apple/Products/Release/pdf22png" ]; then
            echo -e "${GREEN}✓ pdf22png (Swift): pdf22png/.build/apple/Products/Release/pdf22png${NC}"
        elif [ -f "pdf22png/.build/release/pdf22png" ]; then
            echo -e "${GREEN}✓ pdf22png (Swift): pdf22png/.build/release/pdf22png${NC}"
        fi
    fi
    
    echo ""
    echo -e "${BLUE}Next Steps:${NC}"
    echo "  make test       # Run tests"
    echo "  make install    # Install to /usr/local/bin"
    echo "  make help       # Show all available targets"
else
    echo ""
    echo -e "${RED}✗ Build failed${NC}"
    echo "Check the error messages above for details"
    exit 1
fi