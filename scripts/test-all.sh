#!/bin/bash

# Comprehensive test suite for pdf22png
# Runs all tests including unit tests, integration tests, and validation

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TEST_OUTPUT_DIR="$PROJECT_ROOT/test_output"
FAILED_TESTS=0
PASSED_TESTS=0

# Test options
RUN_UNIT_TESTS=true
RUN_INTEGRATION_TESTS=true
RUN_PERFORMANCE_TESTS=false
RUN_MEMORY_TESTS=false
VERBOSE=false
CLEAN=false

# Print helpers
print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

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

print_error() {
    echo -e "${RED}ERROR: $1${NC}" >&2
}

usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
    -u, --unit-only          Run only unit tests
    -i, --integration-only   Run only integration tests
    -p, --performance        Include performance tests
    -m, --memory            Include memory tests
    -v, --verbose           Verbose output
    -c, --clean            Clean test artifacts before running
    -h, --help             Show this help message

Examples:
    $0                      # Run all tests
    $0 --unit-only          # Run only unit tests
    $0 --performance        # Include performance tests
    $0 --verbose --clean    # Verbose output with clean artifacts
EOF
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -u|--unit-only)
                RUN_UNIT_TESTS=true
                RUN_INTEGRATION_TESTS=false
                shift
                ;;
            -i|--integration-only)
                RUN_UNIT_TESTS=false
                RUN_INTEGRATION_TESTS=true
                shift
                ;;
            -p|--performance)
                RUN_PERFORMANCE_TESTS=true
                shift
                ;;
            -m|--memory)
                RUN_MEMORY_TESTS=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -c|--clean)
                CLEAN=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
}

# Setup test environment
setup_test_environment() {
    print_info "Setting up test environment..."
    
    cd "$PROJECT_ROOT"
    
    # Clean test artifacts if requested
    if [[ "$CLEAN" == true ]]; then
        print_info "Cleaning test artifacts..."
        rm -rf "$TEST_OUTPUT_DIR"
        rm -rf pdf21png/build
        rm -rf pdf22png/.build
    fi
    
    # Create test output directory
    mkdir -p "$TEST_OUTPUT_DIR"
    
    # Check if test PDF exists
    if [[ ! -f "testdata/test.pdf" ]]; then
        print_error "Test PDF not found at testdata/test.pdf"
        exit 1
    fi
    
    print_info "Test environment ready"
}

# Build projects
build_projects() {
    print_info "Building projects..."
    
    # Generate version files
    make generate-version
    
    # Build both implementations
    if ! make all; then
        print_error "Build failed"
        exit 1
    fi
    
    print_info "Build completed successfully"
}

# Run unit tests
run_unit_tests() {
    if [[ "$RUN_UNIT_TESTS" != true ]]; then
        return 0
    fi
    
    print_header "UNIT TESTS"
    
    # Swift unit tests
    print_info "Running Swift unit tests..."
    cd "$PROJECT_ROOT/pdf22png"
    
    if swift test; then
        print_pass "Swift unit tests"
    else
        print_fail "Swift unit tests"
    fi
    
    # Objective-C unit tests (if they exist)
    cd "$PROJECT_ROOT/pdf21png"
    if [[ -f "Tests/run-unit-tests.sh" ]]; then
        print_info "Running Objective-C unit tests..."
        if ./Tests/run-unit-tests.sh; then
            print_pass "Objective-C unit tests"
        else
            print_fail "Objective-C unit tests"
        fi
    fi
    
    cd "$PROJECT_ROOT"
}

# Run integration tests
run_integration_tests() {
    if [[ "$RUN_INTEGRATION_TESTS" != true ]]; then
        return 0
    fi
    
    print_header "INTEGRATION TESTS"
    
    # Run existing integration tests
    if [[ -f "tests/integration_test.sh" ]]; then
        print_info "Running integration tests..."
        if ./tests/integration_test.sh; then
            print_pass "Integration tests"
        else
            print_fail "Integration tests"
        fi
    fi
    
    # Run cross-implementation tests
    print_info "Running cross-implementation compatibility tests..."
    if run_compatibility_tests; then
        print_pass "Cross-implementation compatibility"
    else
        print_fail "Cross-implementation compatibility"
    fi
}

# Run compatibility tests between implementations
run_compatibility_tests() {
    local test_pdf="testdata/test.pdf"
    local objc_output="$TEST_OUTPUT_DIR/objc_test.png"
    local swift_output="$TEST_OUTPUT_DIR/swift_test.png"
    
    # Test basic conversion
    print_test "Basic conversion compatibility"
    
    # Convert with both implementations
    if ./pdf21png/build/pdf21png "$test_pdf" "$objc_output" 2>/dev/null && \
       ./pdf22png/.build/apple/Products/Release/pdf22png "$test_pdf" "$swift_output" 2>/dev/null; then
        
        # Check if both files exist and have reasonable size
        if [[ -f "$objc_output" && -f "$swift_output" ]]; then
            local objc_size=$(stat -f%z "$objc_output" 2>/dev/null || stat -c%s "$objc_output" 2>/dev/null)
            local swift_size=$(stat -f%z "$swift_output" 2>/dev/null || stat -c%s "$swift_output" 2>/dev/null)
            
            if [[ "$objc_size" -gt 1000 && "$swift_size" -gt 1000 ]]; then
                return 0
            fi
        fi
    fi
    
    return 1
}

# Run performance tests
run_performance_tests() {
    if [[ "$RUN_PERFORMANCE_TESTS" != true ]]; then
        return 0
    fi
    
    print_header "PERFORMANCE TESTS"
    
    # Run benchmarks if available
    if [[ -f "bench.sh" ]]; then
        print_info "Running performance benchmarks..."
        if ./bench.sh; then
            print_pass "Performance benchmarks"
        else
            print_fail "Performance benchmarks"
        fi
    fi
    
    # Simple performance test
    print_info "Running simple performance test..."
    local start_time=$(date +%s)
    
    if ./pdf22png/.build/apple/Products/Release/pdf22png -a "testdata/test.pdf" -d "$TEST_OUTPUT_DIR/perf_test" >/dev/null 2>&1; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        
        print_info "Performance test completed in ${duration}s"
        
        if [[ "$duration" -lt 30 ]]; then
            print_pass "Performance test (${duration}s)"
        else
            print_fail "Performance test too slow (${duration}s)"
        fi
    else
        print_fail "Performance test failed"
    fi
}

# Run memory tests
run_memory_tests() {
    if [[ "$RUN_MEMORY_TESTS" != true ]]; then
        return 0
    fi
    
    print_header "MEMORY TESTS"
    
    # Use leaks tool if available on macOS
    if command -v leaks >/dev/null 2>&1; then
        print_info "Running memory leak detection..."
        if [[ -f "scripts/check-memory-leaks.sh" ]]; then
            if ./scripts/check-memory-leaks.sh; then
                print_pass "Memory leak detection"
            else
                print_fail "Memory leak detection"
            fi
        fi
    fi
    
    # Simple memory usage test
    print_info "Running memory usage test..."
    if run_memory_usage_test; then
        print_pass "Memory usage test"
    else
        print_fail "Memory usage test"
    fi
}

# Run memory usage test
run_memory_usage_test() {
    local test_pdf="testdata/test.pdf"
    local output_dir="$TEST_OUTPUT_DIR/memory_test"
    
    mkdir -p "$output_dir"
    
    # Monitor memory usage during batch conversion
    local max_memory=0
    
    # Start conversion in background
    ./pdf22png/.build/apple/Products/Release/pdf22png -a "$test_pdf" -d "$output_dir" >/dev/null 2>&1 &
    local pid=$!
    
    # Monitor memory usage
    while kill -0 "$pid" 2>/dev/null; do
        if command -v ps >/dev/null 2>&1; then
            local memory=$(ps -o rss= -p "$pid" 2>/dev/null | tr -d ' ')
            if [[ -n "$memory" && "$memory" -gt "$max_memory" ]]; then
                max_memory=$memory
            fi
        fi
        sleep 0.1
    done
    
    wait "$pid"
    local exit_code=$?
    
    if [[ "$exit_code" -eq 0 ]]; then
        print_info "Maximum memory usage: ${max_memory}KB"
        # Consider test passed if memory usage is reasonable (< 500MB)
        if [[ "$max_memory" -lt 500000 ]]; then
            return 0
        fi
    fi
    
    return 1
}

# Run validation tests
run_validation_tests() {
    print_header "VALIDATION TESTS"
    
    # Test version information
    print_test "Version information"
    local version=$(./scripts/version.sh get)
    if [[ -n "$version" ]]; then
        print_pass "Version information: $version"
    else
        print_fail "Version information"
    fi
    
    # Test build artifacts
    print_test "Build artifacts"
    if [[ -f "pdf21png/build/pdf21png" && -f "pdf22png/.build/apple/Products/Release/pdf22png" ]]; then
        print_pass "Build artifacts"
    else
        print_fail "Build artifacts"
    fi
    
    # Test help commands
    print_test "Help commands"
    if ./pdf21png/build/pdf21png --help >/dev/null 2>&1 && \
       ./pdf22png/.build/apple/Products/Release/pdf22png --help >/dev/null 2>&1; then
        print_pass "Help commands"
    else
        print_fail "Help commands"
    fi
}

# Print test summary
print_summary() {
    echo ""
    print_header "TEST SUMMARY"
    echo -e "${GREEN}Passed: $PASSED_TESTS${NC}"
    echo -e "${RED}Failed: $FAILED_TESTS${NC}"
    echo ""
    
    if [[ $FAILED_TESTS -eq 0 ]]; then
        echo -e "${GREEN}✓ All tests passed!${NC}"
        return 0
    else
        echo -e "${RED}✗ Some tests failed${NC}"
        return 1
    fi
}

# Clean up test artifacts
cleanup() {
    if [[ "$CLEAN" == true ]]; then
        print_info "Cleaning up test artifacts..."
        rm -rf "$TEST_OUTPUT_DIR"
    fi
}

# Main execution
main() {
    parse_args "$@"
    
    print_header "PDF22PNG COMPREHENSIVE TEST SUITE"
    
    setup_test_environment
    build_projects
    run_unit_tests
    run_integration_tests
    run_performance_tests
    run_memory_tests
    run_validation_tests
    
    local exit_code=0
    if ! print_summary; then
        exit_code=1
    fi
    
    cleanup
    exit $exit_code
}

# Trap cleanup on exit
trap cleanup EXIT

# Run main function
main "$@"