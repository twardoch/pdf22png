#!/bin/bash

# PDF22PNG Integration Tests
# Tests both pdf21png and pdf22png with various options

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TEST_PDF="${PROJECT_ROOT}/testdata/multi-page.pdf"
OUTPUT_DIR="${PROJECT_ROOT}/test_output"
FAILED_TESTS=0
PASSED_TESTS=0

# Binary paths
PDF21PNG="${PROJECT_ROOT}/pdf21png/build/pdf21png"
PDF22PNG="${PROJECT_ROOT}/pdf22png/.build/apple/Products/Release/pdf22png"
# Fallback for Linux builds
if [ ! -f "$PDF22PNG" ]; then
    PDF22PNG="${PROJECT_ROOT}/pdf22png/.build/release/pdf22png"
fi

# Print helpers
print_test() {
    echo -e "${BLUE}TEST: $1${NC}"
}

print_pass() {
    echo -e "${GREEN}✓ PASS: $1${NC}"
    ((PASSED_TESTS++))
}

print_fail() {
    echo -e "${RED}✗ FAIL: $1${NC}"
    ((FAILED_TESTS++))
}

print_info() {
    echo -e "${YELLOW}INFO: $1${NC}"
}

# Setup test environment
setup() {
    print_info "Setting up test environment..."
    
    # Clean and create output directory
    rm -rf "$OUTPUT_DIR"
    mkdir -p "$OUTPUT_DIR"
    
    # Check if binaries exist
    if [ ! -f "$PDF21PNG" ]; then
        print_fail "pdf21png binary not found at: $PDF21PNG"
        exit 1
    fi
    
    if [ ! -f "$PDF22PNG" ]; then
        print_fail "pdf22png binary not found at: $PDF22PNG"
        exit 1
    fi
    
    # Check if test PDF exists
    if [ ! -f "$TEST_PDF" ]; then
        print_fail "Test PDF not found at: $TEST_PDF"
        exit 1
    fi
    
    print_info "Test PDF: $TEST_PDF"
    print_info "Output directory: $OUTPUT_DIR"
}

# Test helper function
run_test() {
    local name="$1"
    local binary="$2"
    local args="$3"
    local expected_file="$4"
    local description="${5:-}"
    
    print_test "$name"
    if [ -n "$description" ]; then
        echo "  Description: $description"
    fi
    
    # Run the command
    if $binary $args > "$OUTPUT_DIR/test.log" 2>&1; then
        # Check if expected file was created
        if [ -f "$expected_file" ]; then
            # Check if file has content
            if [ -s "$expected_file" ]; then
                print_pass "$name"
            else
                print_fail "$name - Output file is empty"
                cat "$OUTPUT_DIR/test.log"
            fi
        else
            print_fail "$name - Expected file not created: $expected_file"
            cat "$OUTPUT_DIR/test.log"
        fi
    else
        print_fail "$name - Command failed"
        cat "$OUTPUT_DIR/test.log"
    fi
    
    echo ""
}

# Test version commands
test_versions() {
    print_info "Testing version commands..."
    
    # pdf21png version
    print_test "pdf21png --version"
    if $PDF21PNG --version > "$OUTPUT_DIR/version.log" 2>&1; then
        version=$(cat "$OUTPUT_DIR/version.log")
        if [[ "$version" == *"2.1"* ]]; then
            print_pass "pdf21png version: $version"
        else
            print_fail "pdf21png version unexpected: $version"
        fi
    else
        print_fail "pdf21png --version failed"
    fi
    
    # pdf22png version
    print_test "pdf22png --version"
    if $PDF22PNG --version > "$OUTPUT_DIR/version.log" 2>&1; then
        version=$(cat "$OUTPUT_DIR/version.log")
        if [[ "$version" == *"2.2"* ]]; then
            print_pass "pdf22png version: $version"
        else
            print_fail "pdf22png version unexpected: $version"
        fi
    else
        print_fail "pdf22png --version failed"
    fi
    
    echo ""
}

# Test basic conversions
test_basic() {
    print_info "Testing basic conversions..."
    
    # Test pdf21png basic conversion
    run_test "pdf21png basic conversion" \
        "$PDF21PNG" \
        "$TEST_PDF $OUTPUT_DIR/pdf21_basic.png" \
        "$OUTPUT_DIR/pdf21_basic.png" \
        "Convert first page with default settings"
    
    # Test pdf22png basic conversion
    run_test "pdf22png basic conversion" \
        "$PDF22PNG" \
        "$TEST_PDF $OUTPUT_DIR/pdf22_basic.png" \
        "$OUTPUT_DIR/pdf22_basic.png" \
        "Convert first page with default settings"
}

# Test page selection
test_pages() {
    print_info "Testing page selection..."
    
    # Test specific page
    run_test "pdf21png page 2" \
        "$PDF21PNG" \
        "-p 2 $TEST_PDF $OUTPUT_DIR/pdf21_page2.png" \
        "$OUTPUT_DIR/pdf21_page2.png" \
        "Convert specific page"
    
    run_test "pdf22png page 2" \
        "$PDF22PNG" \
        "--page 2 $TEST_PDF $OUTPUT_DIR/pdf22_page2.png" \
        "$OUTPUT_DIR/pdf22_page2.png" \
        "Convert specific page"
    
    # Test all pages
    run_test "pdf21png all pages" \
        "$PDF21PNG" \
        "-a $TEST_PDF" \
        "multi-page-001.png" \
        "Convert all pages to individual files"
    
    run_test "pdf22png all pages" \
        "$PDF22PNG" \
        "--all $TEST_PDF" \
        "multi-page-001.png" \
        "Convert all pages to individual files"
}

# Test resolution options
test_resolution() {
    print_info "Testing resolution options..."
    
    # Test high DPI
    run_test "pdf21png 300 DPI" \
        "$PDF21PNG" \
        "-r 300 $TEST_PDF $OUTPUT_DIR/pdf21_300dpi.png" \
        "$OUTPUT_DIR/pdf21_300dpi.png" \
        "Convert at 300 DPI"
    
    run_test "pdf22png 300 DPI" \
        "$PDF22PNG" \
        "--resolution 300 $TEST_PDF $OUTPUT_DIR/pdf22_300dpi.png" \
        "$OUTPUT_DIR/pdf22_300dpi.png" \
        "Convert at 300 DPI"
}

# Test scaling options
test_scaling() {
    print_info "Testing scaling options..."
    
    # Test percentage scaling
    run_test "pdf21png 50% scale" \
        "$PDF21PNG" \
        "-s 50% $TEST_PDF $OUTPUT_DIR/pdf21_50percent.png" \
        "$OUTPUT_DIR/pdf21_50percent.png" \
        "Scale to 50%"
    
    run_test "pdf22png 50% scale" \
        "$PDF22PNG" \
        "--scale 50% $TEST_PDF $OUTPUT_DIR/pdf22_50percent.png" \
        "$OUTPUT_DIR/pdf22_50percent.png" \
        "Scale to 50%"
    
    # Test fixed width
    run_test "pdf21png fixed width" \
        "$PDF21PNG" \
        "-s 800x $TEST_PDF $OUTPUT_DIR/pdf21_800w.png" \
        "$OUTPUT_DIR/pdf21_800w.png" \
        "Scale to 800px width"
    
    run_test "pdf22png fixed width" \
        "$PDF22PNG" \
        "--scale 800x $TEST_PDF $OUTPUT_DIR/pdf22_800w.png" \
        "$OUTPUT_DIR/pdf22_800w.png" \
        "Scale to 800px width"
}

# Test transparency
test_transparency() {
    print_info "Testing transparency options..."
    
    run_test "pdf21png transparent" \
        "$PDF21PNG" \
        "-t $TEST_PDF $OUTPUT_DIR/pdf21_transparent.png" \
        "$OUTPUT_DIR/pdf21_transparent.png" \
        "Convert with transparent background"
    
    run_test "pdf22png transparent" \
        "$PDF22PNG" \
        "--transparent $TEST_PDF $OUTPUT_DIR/pdf22_transparent.png" \
        "$OUTPUT_DIR/pdf22_transparent.png" \
        "Convert with transparent background"
}

# Test quality options
test_quality() {
    print_info "Testing quality options..."
    
    run_test "pdf21png quality 9" \
        "$PDF21PNG" \
        "-q 9 $TEST_PDF $OUTPUT_DIR/pdf21_q9.png" \
        "$OUTPUT_DIR/pdf21_q9.png" \
        "Maximum compression quality"
    
    run_test "pdf22png quality 9" \
        "$PDF22PNG" \
        "--quality 9 $TEST_PDF $OUTPUT_DIR/pdf22_q9.png" \
        "$OUTPUT_DIR/pdf22_q9.png" \
        "Maximum compression quality"
}

# Test error handling
test_errors() {
    print_info "Testing error handling..."
    
    # Test invalid page
    print_test "pdf21png invalid page"
    if $PDF21PNG -p 999 "$TEST_PDF" "$OUTPUT_DIR/invalid.png" > "$OUTPUT_DIR/error.log" 2>&1; then
        print_fail "pdf21png invalid page - Should have failed"
    else
        print_pass "pdf21png invalid page - Correctly failed"
    fi
    
    print_test "pdf22png invalid page"
    if $PDF22PNG --page 999 "$TEST_PDF" "$OUTPUT_DIR/invalid.png" > "$OUTPUT_DIR/error.log" 2>&1; then
        print_fail "pdf22png invalid page - Should have failed"
    else
        print_pass "pdf22png invalid page - Correctly failed"
    fi
    
    # Test nonexistent file
    print_test "pdf21png nonexistent file"
    if $PDF21PNG "nonexistent.pdf" "$OUTPUT_DIR/invalid.png" > "$OUTPUT_DIR/error.log" 2>&1; then
        print_fail "pdf21png nonexistent file - Should have failed"
    else
        print_pass "pdf21png nonexistent file - Correctly failed"
    fi
    
    print_test "pdf22png nonexistent file"
    if $PDF22PNG "nonexistent.pdf" "$OUTPUT_DIR/invalid.png" > "$OUTPUT_DIR/error.log" 2>&1; then
        print_fail "pdf22png nonexistent file - Should have failed"
    else
        print_pass "pdf22png nonexistent file - Correctly failed"
    fi
    
    echo ""
}

# Summary
print_summary() {
    echo ""
    echo "========================================"
    echo "Integration Test Summary"
    echo "========================================"
    echo -e "${GREEN}Passed: $PASSED_TESTS${NC}"
    echo -e "${RED}Failed: $FAILED_TESTS${NC}"
    echo ""
    
    if [ $FAILED_TESTS -eq 0 ]; then
        echo -e "${GREEN}✓ All tests passed!${NC}"
        return 0
    else
        echo -e "${RED}✗ Some tests failed${NC}"
        return 1
    fi
}

# Main test execution
main() {
    echo "PDF22PNG Integration Tests"
    echo "=========================="
    echo ""
    
    setup
    test_versions
    test_basic
    test_pages
    test_resolution
    test_scaling
    test_transparency
    test_quality
    test_errors
    
    print_summary
}

# Run tests
main