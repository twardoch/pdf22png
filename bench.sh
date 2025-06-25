#!/bin/bash

# PDF22PNG Benchmark Script
# Comprehensive performance comparison between Objective-C and Swift implementations

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Configuration
BUILD_DIR="build"
BENCH_DIR="benchmarks"
TEMP_DIR="/tmp/pdf22png_bench_$$"
DEFAULT_ITERATIONS=10
DEFAULT_PDF="$BENCH_DIR/sample.pdf"

# Parse command line arguments
PDF_FILE=""
ITERATIONS=$DEFAULT_ITERATIONS
OUTPUT_CSV=""
VERBOSE=false
QUICK_MODE=false
EXTENDED_MODE=false
BUILD_FIRST=true

print_usage() {
    echo "Usage: $0 [options] [pdf_file]"
    echo "Options:"
    echo "  -i, --iterations <n>   Number of iterations per test (default: $DEFAULT_ITERATIONS)"
    echo "  -o, --output <file>    Export results to CSV file"
    echo "  -q, --quick           Quick mode (fewer tests)"
    echo "  -e, --extended        Extended mode (more comprehensive tests)"
    echo "  --no-build           Skip building binaries"
    echo "  -v, --verbose         Verbose output"
    echo "  -h, --help           Show this help message"
}

# Process arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--iterations)
            ITERATIONS="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_CSV="$2"
            shift 2
            ;;
        -q|--quick)
            QUICK_MODE=true
            shift
            ;;
        -e|--extended)
            EXTENDED_MODE=true
            shift
            ;;
        --no-build)
            BUILD_FIRST=false
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        -*)
            echo -e "${RED}Unknown option: $1${NC}"
            print_usage
            exit 1
            ;;
        *)
            PDF_FILE="$1"
            shift
            ;;
    esac
done

# Header
echo -e "${BOLD}PDF22PNG Performance Benchmark${NC}"
echo "=============================="
echo

# Ensure binaries exist or build them
if [ "$BUILD_FIRST" = true ]; then
    if [ ! -f "$BUILD_DIR/pdf22png" ] || [ ! -f "$BUILD_DIR/pdf22png-swift" ]; then
        echo -e "${YELLOW}Building implementations...${NC}"
        ./build.sh --clean >/dev/null 2>&1
        echo -e "${GREEN}✓ Build complete${NC}\n"
    fi
else
    if [ ! -f "$BUILD_DIR/pdf22png" ] || [ ! -f "$BUILD_DIR/pdf22png-swift" ]; then
        echo -e "${RED}Error: Binaries not found. Run ./build.sh first${NC}"
        exit 1
    fi
fi

# Find or create test PDF
if [ -z "$PDF_FILE" ]; then
    if [ -f "$DEFAULT_PDF" ]; then
        PDF_FILE="$DEFAULT_PDF"
    else
        echo -e "${YELLOW}Creating test PDF...${NC}"
        cd "$BENCH_DIR" && ./create_test_pdf.sh >/dev/null 2>&1
        cd ..
        PDF_FILE="$DEFAULT_PDF"
    fi
fi

if [ ! -f "$PDF_FILE" ]; then
    echo -e "${RED}Error: PDF file not found: $PDF_FILE${NC}"
    exit 1
fi

# Get PDF info
PDF_NAME=$(basename "$PDF_FILE")
PDF_PAGES=$(mdls -name kMDItemNumberOfPages "$PDF_FILE" 2>/dev/null | awk '{print $3}')
if [ -z "$PDF_PAGES" ] || [ "$PDF_PAGES" = "(null)" ]; then
    # Fallback: use pdfinfo if available
    if command -v pdfinfo >/dev/null 2>&1; then
        PDF_PAGES=$(pdfinfo "$PDF_FILE" 2>/dev/null | grep "Pages:" | awk '{print $2}')
    else
        PDF_PAGES="?"
    fi
fi

echo "Test PDF: $PDF_NAME ($PDF_PAGES pages)"
echo "Iterations: $ITERATIONS"
echo

# Create temp directory
mkdir -p "$TEMP_DIR"
trap "rm -rf $TEMP_DIR" EXIT

# Function to run a single benchmark
run_benchmark() {
    local impl=$1
    local test_name=$2
    local cmd=$3
    local output_file="$TEMP_DIR/bench_${impl}_${test_name}.txt"
    
    echo -n "  • $test_name: "
    
    # Warm-up run
    eval "$cmd" >/dev/null 2>&1
    
    # Timed runs
    local total_time=0
    local min_time=999999
    local max_time=0
    local times=()
    
    for i in $(seq 1 $ITERATIONS); do
        # Time the command
        local start=$(perl -MTime::HiRes=time -e 'printf "%.6f\n", time')
        eval "$cmd" >/dev/null 2>&1
        local end=$(perl -MTime::HiRes=time -e 'printf "%.6f\n", time')
        
        # Calculate elapsed time
        local elapsed=$(echo "$end - $start" | bc)
        times+=($elapsed)
        total_time=$(echo "$total_time + $elapsed" | bc)
        
        # Track min/max
        if (( $(echo "$elapsed < $min_time" | bc -l) )); then
            min_time=$elapsed
        fi
        if (( $(echo "$elapsed > $max_time" | bc -l) )); then
            max_time=$elapsed
        fi
        
        # Show progress
        if [ "$VERBOSE" = true ]; then
            printf "\n    Run %d: %.3fs" $i $elapsed
        else
            printf "."
        fi
    done
    
    # Calculate average
    local avg_time=$(echo "scale=6; $total_time / $ITERATIONS" | bc)
    
    # Calculate standard deviation
    local sum_sq_diff=0
    for t in "${times[@]}"; do
        local diff=$(echo "$t - $avg_time" | bc)
        local sq_diff=$(echo "$diff * $diff" | bc)
        sum_sq_diff=$(echo "$sum_sq_diff + $sq_diff" | bc)
    done
    local variance=$(echo "scale=6; $sum_sq_diff / $ITERATIONS" | bc)
    local std_dev=$(echo "scale=6; sqrt($variance)" | bc)
    
    # Save results
    echo "$test_name|$avg_time|$min_time|$max_time|$std_dev" > "$output_file"
    
    # Display results
    printf " avg: ${GREEN}%.3fs${NC} (±%.3fs)\n" $avg_time $std_dev
}

# Define test configurations
declare -a TESTS

if [ "$QUICK_MODE" = true ]; then
    TESTS=(
        "single_page|Single Page (144 DPI)|-f -p 1 \"$PDF_FILE\" \"$TEMP_DIR/out.png\""
        "high_dpi|Single Page (300 DPI)|-f -p 1 -r 300 \"$PDF_FILE\" \"$TEMP_DIR/out.png\""
    )
elif [ "$EXTENDED_MODE" = true ]; then
    TESTS=(
        "single_page|Single Page (144 DPI)|-f -p 1 \"$PDF_FILE\" \"$TEMP_DIR/out.png\""
        "single_72dpi|Single Page (72 DPI)|-f -p 1 -r 72 \"$PDF_FILE\" \"$TEMP_DIR/out.png\""
        "single_150dpi|Single Page (150 DPI)|-f -p 1 -r 150 \"$PDF_FILE\" \"$TEMP_DIR/out.png\""
        "single_300dpi|Single Page (300 DPI)|-f -p 1 -r 300 \"$PDF_FILE\" \"$TEMP_DIR/out.png\""
        "single_600dpi|Single Page (600 DPI)|-f -p 1 -r 600 \"$PDF_FILE\" \"$TEMP_DIR/out.png\""
        "single_2x|Single Page (2x scale)|-f -p 1 -s 2.0 \"$PDF_FILE\" \"$TEMP_DIR/out.png\""
        "single_50pct|Single Page (50%)|-f -p 1 -s 50% \"$PDF_FILE\" \"$TEMP_DIR/out.png\""
        "single_trans|Single Page (Transparent)|-f -p 1 -t \"$PDF_FILE\" \"$TEMP_DIR/out.png\""
        "batch_all|All Pages Batch|-f -a \"$PDF_FILE\" -d \"$TEMP_DIR/batch\""
        "quality_0|PNG Quality 0|-f -p 1 -q 0 \"$PDF_FILE\" \"$TEMP_DIR/out.png\""
        "quality_9|PNG Quality 9|-f -p 1 -q 9 \"$PDF_FILE\" \"$TEMP_DIR/out.png\""
    )
else
    TESTS=(
        "single_page|Single Page (144 DPI)|-f -p 1 \"$PDF_FILE\" \"$TEMP_DIR/out.png\""
        "single_300dpi|Single Page (300 DPI)|-f -p 1 -r 300 \"$PDF_FILE\" \"$TEMP_DIR/out.png\""
        "single_2x|Single Page (2x scale)|-f -p 1 -s 2.0 \"$PDF_FILE\" \"$TEMP_DIR/out.png\""
        "single_trans|Single Page (Transparent)|-f -p 1 -t \"$PDF_FILE\" \"$TEMP_DIR/out.png\""
        "batch_all|All Pages Batch|-f -a \"$PDF_FILE\" -d \"$TEMP_DIR/batch\""
    )
fi

# Run benchmarks for each implementation
echo -e "${BLUE}Objective-C Implementation${NC}"
echo "--------------------------"
for test in "${TESTS[@]}"; do
    IFS='|' read -r test_id test_name test_cmd <<< "$test"
    run_benchmark "objc" "$test_id" "$BUILD_DIR/pdf22png $test_cmd"
done
echo

echo -e "${BLUE}Swift Implementation${NC}"
echo "--------------------"
for test in "${TESTS[@]}"; do
    IFS='|' read -r test_id test_name test_cmd <<< "$test"
    run_benchmark "swift" "$test_id" "$BUILD_DIR/pdf22png-swift $test_cmd"
done
echo

# Analyze results
echo -e "${BOLD}Performance Comparison${NC}"
echo "====================="
echo

# CSV header for export
if [ -n "$OUTPUT_CSV" ]; then
    echo "Test,ObjC_Avg,ObjC_Min,ObjC_Max,ObjC_StdDev,Swift_Avg,Swift_Min,Swift_Max,Swift_StdDev,Speedup" > "$OUTPUT_CSV"
fi

# Compare each test
for test in "${TESTS[@]}"; do
    IFS='|' read -r test_id test_name test_cmd <<< "$test"
    
    # Read results
    objc_file="$TEMP_DIR/bench_objc_${test_id}.txt"
    swift_file="$TEMP_DIR/bench_swift_${test_id}.txt"
    
    if [ -f "$objc_file" ] && [ -f "$swift_file" ]; then
        IFS='|' read -r _ objc_avg objc_min objc_max objc_std < "$objc_file"
        IFS='|' read -r _ swift_avg swift_min swift_max swift_std < "$swift_file"
        
        # Calculate speedup
        if (( $(echo "$swift_avg > 0" | bc -l) )); then
            speedup=$(echo "scale=2; $objc_avg / $swift_avg" | bc)
            
            # Determine which is faster
            if (( $(echo "$speedup > 1" | bc -l) )); then
                faster="${GREEN}Swift is $(echo "scale=1; 1/$speedup" | bc)x faster${NC}"
            elif (( $(echo "$speedup < 1" | bc -l) )); then
                faster="${YELLOW}ObjC is $(echo "scale=1; $speedup" | bc)x faster${NC}"
            else
                faster="${CYAN}Equal performance${NC}"
            fi
            
            # Display comparison
            printf "%-25s ObjC: %6.3fs  Swift: %6.3fs  %s\n" "$test_name:" $objc_avg $swift_avg "$faster"
            
            # Export to CSV if requested
            if [ -n "$OUTPUT_CSV" ]; then
                echo "$test_name,$objc_avg,$objc_min,$objc_max,$objc_std,$swift_avg,$swift_min,$swift_max,$swift_std,$speedup" >> "$OUTPUT_CSV"
            fi
        fi
    fi
done

# Overall summary
echo
echo -e "${BOLD}Summary${NC}"
echo "======="

# Calculate overall performance
total_objc=0
total_swift=0
test_count=0

for test in "${TESTS[@]}"; do
    IFS='|' read -r test_id _ _ <<< "$test"
    objc_file="$TEMP_DIR/bench_objc_${test_id}.txt"
    swift_file="$TEMP_DIR/bench_swift_${test_id}.txt"
    
    if [ -f "$objc_file" ] && [ -f "$swift_file" ]; then
        IFS='|' read -r _ objc_avg _ _ _ < "$objc_file"
        IFS='|' read -r _ swift_avg _ _ _ < "$swift_file"
        total_objc=$(echo "$total_objc + $objc_avg" | bc)
        total_swift=$(echo "$total_swift + $swift_avg" | bc)
        test_count=$((test_count + 1))
    fi
done

if [ $test_count -gt 0 ]; then
    avg_objc=$(echo "scale=3; $total_objc / $test_count" | bc)
    avg_swift=$(echo "scale=3; $total_swift / $test_count" | bc)
    overall_speedup=$(echo "scale=2; $avg_swift / $avg_objc" | bc)
    
    echo "Average times across all tests:"
    echo "  • Objective-C: ${GREEN}${avg_objc}s${NC}"
    echo "  • Swift:       ${GREEN}${avg_swift}s${NC}"
    echo
    echo -n "Overall: Swift is "
    if (( $(echo "$overall_speedup > 1" | bc -l) )); then
        echo -e "${YELLOW}$(echo "scale=1; $overall_speedup" | bc)x slower${NC} than Objective-C"
    else
        echo -e "${GREEN}$(echo "scale=1; 1/$overall_speedup" | bc)x faster${NC} than Objective-C"
    fi
fi

# File size comparison
echo
echo -e "${BOLD}Output Quality${NC}"
echo "=============="

# Compare file sizes for single page test
if [ -f "$TEMP_DIR/out.png" ]; then
    # Run both to get output files
    $BUILD_DIR/pdf22png -f -p 1 "$PDF_FILE" "$TEMP_DIR/objc_out.png" >/dev/null 2>&1
    $BUILD_DIR/pdf22png-swift -f -p 1 "$PDF_FILE" "$TEMP_DIR/swift_out.png" >/dev/null 2>&1
    
    if [ -f "$TEMP_DIR/objc_out.png" ] && [ -f "$TEMP_DIR/swift_out.png" ]; then
        objc_size=$(ls -l "$TEMP_DIR/objc_out.png" | awk '{print $5}')
        swift_size=$(ls -l "$TEMP_DIR/swift_out.png" | awk '{print $5}')
        
        echo "File sizes (single page, 144 DPI):"
        printf "  • Objective-C: %'d bytes\n" $objc_size
        printf "  • Swift:       %'d bytes\n" $swift_size
        
        if [ $objc_size -gt $swift_size ]; then
            savings=$(echo "scale=1; 100 * ($objc_size - $swift_size) / $objc_size" | bc)
            echo -e "  ${GREEN}Swift produces ${savings}% smaller files${NC}"
        elif [ $swift_size -gt $objc_size ]; then
            increase=$(echo "scale=1; 100 * ($swift_size - $objc_size) / $objc_size" | bc)
            echo -e "  ${YELLOW}Swift produces ${increase}% larger files${NC}"
        else
            echo -e "  ${CYAN}Both produce identical file sizes${NC}"
        fi
    fi
fi

# Export notification
if [ -n "$OUTPUT_CSV" ]; then
    echo
    echo -e "${GREEN}✓ Results exported to: $OUTPUT_CSV${NC}"
fi

echo
echo -e "${BOLD}Benchmark completed!${NC}"