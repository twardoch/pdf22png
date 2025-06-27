#!/bin/bash

# Run unit tests for pdf21png
# Simple C-based unit tests that don't require XCTest

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
SRC_DIR="$PROJECT_ROOT/pdf21png/src"
TESTS_DIR="$PROJECT_ROOT/pdf21png/Tests"
BUILD_DIR="$TESTS_DIR/build"

# Print helpers
print_info() {
    echo -e "${BLUE}→ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}" >&2
}

# Clean build directory
clean_build() {
    print_info "Cleaning build directory..."
    rm -rf "$BUILD_DIR"
    mkdir -p "$BUILD_DIR"
}

# Compile and run tests
compile_and_run() {
    print_info "Compiling unit tests..."
    
    # Compile utils.c and test_utils.c together
    clang \
        -Wall \
        -Wextra \
        -O0 \
        -g \
        -fobjc-arc \
        -framework Foundation \
        -framework CoreGraphics \
        -framework ImageIO \
        -framework Quartz \
        -framework Vision \
        -framework CoreServices \
        -framework UniformTypeIdentifiers \
        -I"$SRC_DIR" \
        -o "$BUILD_DIR/test_utils" \
        "$SRC_DIR/utils.m" \
        "$TESTS_DIR/test_utils.c"
    
    print_success "Tests compiled"
    
    print_info "Running unit tests..."
    echo ""
    
    # Run the tests
    "$BUILD_DIR/test_utils"
    local TEST_RESULT=$?
    
    echo ""
    if [ $TEST_RESULT -eq 0 ]; then
        print_success "All unit tests passed"
    else
        print_error "Some unit tests failed"
        return $TEST_RESULT
    fi
}

# Main execution
main() {
    echo ""
    echo "PDF21PNG Unit Test Runner"
    echo "========================="
    echo ""
    
    clean_build
    compile_and_run
    
    echo ""
}

# Parse arguments
if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
    echo "PDF21PNG Unit Test Runner"
    echo ""
    echo "Usage: $0"
    echo ""
    echo "Compiles and runs unit tests for pdf21png utilities"
    exit 0
fi

# Run main
main