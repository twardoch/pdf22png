#!/usr/bin/env bash
# this_file: build.sh

set -euo pipefail

# Default configuration
BUILD_TYPE="all" # all, swift, objc
INSTALL=false
UNIVERSAL=false
CLEAN=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Print usage
usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -t, --type <all|swift|objc>  Build type (default: all)"
    echo "  -i, --install                Install after building"
    echo "  -u, --universal              Build universal binary"
    echo "  -c, --clean                  Clean before building"
    echo "  -h, --help                   Show this help message"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
    -t | --type)
        BUILD_TYPE="$2"
        shift 2
        ;;
    -i | --install)
        INSTALL=true
        shift
        ;;
    -u | --universal)
        UNIVERSAL=true
        shift
        ;;
    -c | --clean)
        CLEAN=true
        shift
        ;;
    -h | --help)
        usage
        exit 0
        ;;
    *)
        echo "Unknown option: $1"
        usage
        exit 1
        ;;
    esac
done

# Check if Xcode Command Line Tools are installed
if ! xcode-select -p &>/dev/null; then
    echo -e "${RED}Error: Xcode Command Line Tools not found${NC}"
    echo "Please install them using: xcode-select --install"
    exit 1
fi

# Clean if requested
if [ "$CLEAN" = true ]; then
    echo -e "${YELLOW}Cleaning build artifacts...${NC}"
    if [ "$BUILD_TYPE" = "all" ] || [ "$BUILD_TYPE" = "swift" ]; then
        (cd pdf22png-swift && make clean)
    fi
    if [ "$BUILD_TYPE" = "all" ] || [ "$BUILD_TYPE" = "objc" ]; then
        (cd pdf22png-objc && make clean)
    fi
fi

# Build function
build() {
    local type=$1
    local universal=$2

    echo -e "${YELLOW}Building $type implementation...${NC}"

    if [ "$universal" = true ]; then
        if [ "$type" = "swift" ]; then
            (cd pdf22png-swift && make universal)
        else
            (cd pdf22png-objc && make universal)
        fi
    else
        if [ "$type" = "swift" ]; then
            (cd pdf22png-swift && make build)
        else
            (cd pdf22png-objc && make build)
        fi
    fi
}

# Build based on type
# Note: Swift build currently falls back to Objective-C due to SWBBuildService.framework issue
case $BUILD_TYPE in
all)
    build "swift" "$UNIVERSAL"
    build "objc" "$UNIVERSAL"
    ;;
swift | objc)
    build "$BUILD_TYPE" "$UNIVERSAL"
    ;;
*)
    echo -e "${RED}Error: Invalid build type: $BUILD_TYPE${NC}"
    usage
    exit 1
    ;;
esac

# Install if requested
if [ "$INSTALL" = true ]; then
    echo -e "${YELLOW}Installing...${NC}"
    if [ "$BUILD_TYPE" = "all" ] || [ "$BUILD_TYPE" = "swift" ]; then
        (cd pdf22png-swift && sudo make install)
    fi
    if [ "$BUILD_TYPE" = "all" ] || [ "$BUILD_TYPE" = "objc" ]; then
        (cd pdf22png-objc && sudo make install)
    fi
fi

echo -e "${GREEN}Build completed successfully!${NC}"
