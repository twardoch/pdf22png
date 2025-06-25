#!/bin/bash
#
# pdf22png Benchmarking Script
# Compares performance between Objective-C and Swift implementations
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BENCHMARK_DATA_DIR="$SCRIPT_DIR/data"
RESULTS_DIR="$SCRIPT_DIR/results"
OBJC_BINARY="$PROJECT_ROOT/build/pdf22png"
SWIFT_BINARY="$PROJECT_ROOT/build/pdf22png_swift"

# Create directories
mkdir -p "$BENCHMARK_DATA_DIR" "$RESULTS_DIR"

# Check for required tools
check_dependencies() {
    echo -e "${BLUE}Checking dependencies...${NC}"
    
    if ! command -v hyperfine &> /dev/null; then
        echo -e "${RED}Error: hyperfine not found. Install with: brew install hyperfine${NC}"
        exit 1
    fi
    
    if ! command -v jq &> /dev/null; then
        echo -e "${YELLOW}Warning: jq not found. Install with: brew install jq for JSON results${NC}"
    fi
    
    echo -e "${GREEN}Dependencies OK${NC}"
}

# Generate test PDFs if they don't exist
generate_test_data() {
    echo -e "${BLUE}Checking test data...${NC}"
    
    # Small test (10 pages, simple content)
    if [ ! -f "$BENCHMARK_DATA_DIR/small_10p.pdf" ]; then
        echo "Generating small test PDF (10 pages)..."
        # Use macOS's built-in tool to create a simple PDF
        cat > "$BENCHMARK_DATA_DIR/generate_small.ps" << 'EOF'
%!PS
/Helvetica findfont 24 scalefont setfont
1 1 10 {
    newpath
    72 720 moveto
    (Page ) show
    dup 3 string cvs show
    ( of 10) show
    showpage
} for
EOF
        ps2pdf "$BENCHMARK_DATA_DIR/generate_small.ps" "$BENCHMARK_DATA_DIR/small_10p.pdf"
        rm "$BENCHMARK_DATA_DIR/generate_small.ps"
    fi
    
    # Medium test (120 pages)
    if [ ! -f "$BENCHMARK_DATA_DIR/medium_120p.pdf" ]; then
        echo "Generating medium test PDF (120 pages)..."
        cat > "$BENCHMARK_DATA_DIR/generate_medium.ps" << 'EOF'
%!PS
/Helvetica findfont 18 scalefont setfont
1 1 120 {
    newpath
    72 720 moveto
    (Page ) show
    dup 3 string cvs show
    ( - Medium complexity document with mixed content) show
    72 680 moveto
    (Lorem ipsum dolor sit amet, consectetur adipiscing elit.) show
    showpage
} for
EOF
        ps2pdf "$BENCHMARK_DATA_DIR/generate_medium.ps" "$BENCHMARK_DATA_DIR/medium_120p.pdf"
        rm "$BENCHMARK_DATA_DIR/generate_medium.ps"
    fi
    
    echo -e "${GREEN}Test data ready${NC}"
}

# Run benchmarks
run_benchmarks() {
    local test_name=$1
    local pdf_file=$2
    local options=$3
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local result_file="$RESULTS_DIR/${test_name}_${timestamp}.json"
    
    echo -e "${BLUE}Running benchmark: $test_name${NC}"
    echo "PDF: $pdf_file"
    echo "Options: $options"
    
    # Check if binaries exist
    if [ ! -f "$OBJC_BINARY" ]; then
        echo -e "${RED}Error: ObjC binary not found at $OBJC_BINARY${NC}"
        echo "Build with: make clean && make"
        return 1
    fi
    
    # Prepare output directories
    local objc_output="/tmp/benchmark_objc_$$"
    local swift_output="/tmp/benchmark_swift_$$"
    mkdir -p "$objc_output" "$swift_output"
    
    # Run benchmark
    if [ -f "$SWIFT_BINARY" ]; then
        echo "Comparing ObjC vs Swift implementations..."
        hyperfine \
            --warmup 3 \
            --runs 10 \
            --export-json "$result_file" \
            --command-name "pdf22png_objc" \
            "$OBJC_BINARY -f $options -d $objc_output $pdf_file" \
            --command-name "pdf22png_swift" \
            "$SWIFT_BINARY -f $options -d $swift_output $pdf_file"
    else
        echo -e "${YELLOW}Swift binary not found. Running ObjC benchmark only.${NC}"
        hyperfine \
            --warmup 3 \
            --runs 10 \
            --export-json "$result_file" \
            --command-name "pdf22png_objc" \
            "$OBJC_BINARY -f $options -d $objc_output $pdf_file"
    fi
    
    # Clean up
    rm -rf "$objc_output" "$swift_output"
    
    # Display results
    if command -v jq &> /dev/null && [ -f "$result_file" ]; then
        echo -e "\n${GREEN}Results:${NC}"
        jq -r '.results[] | "\(.command): \(.mean) ± \(.stddev) seconds"' "$result_file"
    fi
}

# Memory usage test
test_memory_usage() {
    local test_name=$1
    local pdf_file=$2
    local options=$3
    
    echo -e "\n${BLUE}Testing memory usage: $test_name${NC}"
    
    if [ "$(uname)" = "Darwin" ]; then
        # macOS specific memory measurement
        local objc_output="/tmp/benchmark_objc_mem_$$"
        mkdir -p "$objc_output"
        
        echo "Running ObjC implementation..."
        /usr/bin/time -l $OBJC_BINARY -f $options -d $objc_output $pdf_file 2>&1 | grep "maximum resident set size"
        
        if [ -f "$SWIFT_BINARY" ]; then
            local swift_output="/tmp/benchmark_swift_mem_$$"
            mkdir -p "$swift_output"
            echo "Running Swift implementation..."
            /usr/bin/time -l $SWIFT_BINARY -f $options -d $swift_output $pdf_file 2>&1 | grep "maximum resident set size"
            rm -rf "$swift_output"
        fi
        
        rm -rf "$objc_output"
    fi
}

# Main benchmark suite
run_benchmark_suite() {
    echo -e "${GREEN}=== pdf22png Benchmark Suite ===${NC}"
    echo "Date: $(date)"
    echo "System: $(uname -mrs)"
    echo "CPU: $(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo "Unknown")"
    echo ""
    
    # Test 1: Small PDF, default settings
    run_benchmarks "small_default" "$BENCHMARK_DATA_DIR/small_10p.pdf" "-a -r 144"
    test_memory_usage "small_default" "$BENCHMARK_DATA_DIR/small_10p.pdf" "-a -r 144"
    
    # Test 2: Small PDF, high resolution
    run_benchmarks "small_highres" "$BENCHMARK_DATA_DIR/small_10p.pdf" "-a -r 300"
    test_memory_usage "small_highres" "$BENCHMARK_DATA_DIR/small_10p.pdf" "-a -r 300"
    
    # Test 3: Medium PDF, default settings
    if [ -f "$BENCHMARK_DATA_DIR/medium_120p.pdf" ]; then
        run_benchmarks "medium_default" "$BENCHMARK_DATA_DIR/medium_120p.pdf" "-a -r 144"
        test_memory_usage "medium_default" "$BENCHMARK_DATA_DIR/medium_120p.pdf" "-a -r 144"
    fi
    
    # Test 4: Page range processing
    run_benchmarks "range_processing" "$BENCHMARK_DATA_DIR/medium_120p.pdf" "-p 1-10,50-60,100-110 -r 144"
    
    echo -e "\n${GREEN}Benchmark suite completed!${NC}"
    echo "Results saved in: $RESULTS_DIR"
}

# Parse command line arguments
case "${1:-}" in
    --help|-h)
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  run      Run the full benchmark suite (default)"
        echo "  data     Generate test data only"
        echo "  clean    Clean benchmark results"
        echo ""
        exit 0
        ;;
    data)
        check_dependencies
        generate_test_data
        ;;
    clean)
        echo "Cleaning benchmark results..."
        rm -rf "$RESULTS_DIR"/*
        echo "Done."
        ;;
    run|"")
        check_dependencies
        generate_test_data
        run_benchmark_suite
        ;;
    *)
        echo "Unknown command: $1"
        echo "Use --help for usage information"
        exit 1
        ;;
esac