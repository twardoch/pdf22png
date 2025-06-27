#!/bin/bash

# Run XCTest tests for pdf21png without requiring an Xcode project
# Uses xcodebuild to compile and run the tests

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

# Compile test bundle
compile_tests() {
    print_info "Compiling test bundle..."
    
    # Compile utils.m
    clang -c \
        -fobjc-arc \
        -fmodules \
        -framework Foundation \
        -framework CoreGraphics \
        -framework ImageIO \
        -framework Quartz \
        -I"$SRC_DIR" \
        -o "$BUILD_DIR/utils.o" \
        "$SRC_DIR/utils.m"
    
    # Compile test files
    clang -c \
        -fobjc-arc \
        -fmodules \
        -framework XCTest \
        -framework Foundation \
        -framework CoreGraphics \
        -framework ImageIO \
        -framework Quartz \
        -I"$SRC_DIR" \
        -o "$BUILD_DIR/UtilsTests.o" \
        "$TESTS_DIR/UtilsTests.m"
    
    clang -c \
        -fobjc-arc \
        -fmodules \
        -framework XCTest \
        -framework Foundation \
        -framework CoreGraphics \
        -framework ImageIO \
        -framework Quartz \
        -I"$SRC_DIR" \
        -o "$BUILD_DIR/PDF21PNGTests.o" \
        "$TESTS_DIR/PDF21PNGTests.m"
    
    # Link test bundle
    clang \
        -bundle \
        -fobjc-arc \
        -fmodules \
        -framework XCTest \
        -framework Foundation \
        -framework CoreGraphics \
        -framework ImageIO \
        -framework Quartz \
        -framework Vision \
        -framework CoreServices \
        -framework UniformTypeIdentifiers \
        -o "$BUILD_DIR/PDF21PNGTests.xctest/Contents/MacOS/PDF21PNGTests" \
        "$BUILD_DIR/utils.o" \
        "$BUILD_DIR/UtilsTests.o" \
        "$BUILD_DIR/PDF21PNGTests.o"
    
    # Create bundle structure
    mkdir -p "$BUILD_DIR/PDF21PNGTests.xctest/Contents"
    
    # Create Info.plist
    cat > "$BUILD_DIR/PDF21PNGTests.xctest/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.twardoch.PDF21PNGTests</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>PDF21PNGTests</string>
    <key>CFBundlePackageType</key>
    <string>BNDL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
</dict>
</plist>
EOF
    
    print_success "Test bundle compiled"
}

# Run tests
run_tests() {
    print_info "Running tests..."
    
    # Use xcrun to run the test bundle
    xcrun xctest "$BUILD_DIR/PDF21PNGTests.xctest" || {
        print_error "Tests failed"
        return 1
    }
    
    print_success "All tests passed"
}

# Main execution
main() {
    echo ""
    echo "PDF21PNG Test Runner"
    echo "===================="
    echo ""
    
    clean_build
    compile_tests
    run_tests
    
    echo ""
    print_success "Test run complete"
}

# Parse arguments
if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
    echo "PDF21PNG Test Runner"
    echo ""
    echo "Usage: $0"
    echo ""
    echo "Compiles and runs XCTest tests for pdf21png"
    exit 0
fi

# Run main
main