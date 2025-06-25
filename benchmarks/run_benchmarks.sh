#!/bin/bash

set -e

echo "PDF22PNG Benchmark Build and Run Script"
echo "======================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if we're in the right directory
if [ ! -f "../src/pdf22png.m" ]; then
    echo -e "${RED}Error: This script must be run from the benchmarks directory${NC}"
    exit 1
fi

# Parse command line arguments
PDF_FILE=""
ITERATIONS=10
OUTPUT_FILE=""
BUILD_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
    -p | --pdf)
        PDF_FILE="$2"
        shift 2
        ;;
    -i | --iterations)
        ITERATIONS="$2"
        shift 2
        ;;
    -o | --output)
        OUTPUT_FILE="$2"
        shift 2
        ;;
    --build-only)
        BUILD_ONLY=true
        shift
        ;;
    -h | --help)
        echo "Usage: $0 [options]"
        echo "Options:"
        echo "  -p, --pdf <file>      PDF file to benchmark"
        echo "  -i, --iterations <n>  Number of iterations (default: 10)"
        echo "  -o, --output <file>   Output CSV file for results"
        echo "  --build-only          Only build, don't run benchmarks"
        echo "  -h, --help            Show this help message"
        exit 0
        ;;
    *)
        echo -e "${RED}Unknown option: $1${NC}"
        exit 1
        ;;
    esac
done

# Step 1: Build Objective-C benchmark
echo -e "\n${YELLOW}Building Objective-C benchmark...${NC}"
clang -o benchmark_objc \
    -framework Foundation \
    -framework CoreGraphics \
    -framework ImageIO \
    -framework Quartz \
    -framework Vision \
    -framework CoreServices \
    -framework UniformTypeIdentifiers \
    -I../src \
    benchmark.m \
    benchmark_objc.m \
    benchmark_runner.m \
    ../src/utils.m \
    -fobjc-arc \
    -O2

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Objective-C benchmark built successfully${NC}"
else
    echo -e "${RED}✗ Failed to build Objective-C benchmark${NC}"
    exit 1
fi

# Step 2: Build Swift benchmark using current src/ implementation
echo -e "\n${YELLOW}Building Swift implementation...${NC}"

# Build the Swift package from root directory
cd ..
swift build -c release

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Swift package built successfully${NC}"
else
    echo -e "${RED}✗ Failed to build Swift package${NC}"
    cd benchmarks
    exit 1
fi

cd benchmarks

# Build combined benchmark with Swift support
echo -e "\n${YELLOW}Building combined Swift/ObjC benchmark...${NC}"

# Create a module map for Swift
cat >module.modulemap <<EOF
module PDF22PNGCore {
    header "../.build/release/PDF22PNGCore.swiftmodule"
    export *
}
EOF

# Build with Swift support
swiftc -c BenchmarkSwift.swift \
    -I ../.build/release \
    -L ../.build/release \
    -module-name pdf22png \
    -emit-objc-header \
    -emit-objc-header-path pdf22png-Swift.h \
    -O

clang -o benchmark_combined \
    -framework Foundation \
    -framework CoreGraphics \
    -framework ImageIO \
    -framework Quartz \
    -framework Vision \
    -framework CoreServices \
    -framework UniformTypeIdentifiers \
    -I../src \
    -I. \
    benchmark.m \
    benchmark_objc.m \
    benchmark_runner.m \
    BenchmarkSwift.o \
    ../src/utils.m \
    ../.build/release/libPDF22PNGCore.a \
    -fobjc-arc \
    -O2 \
    -lstdc++

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Combined benchmark built successfully${NC}"
else
    echo -e "${RED}✗ Failed to build combined benchmark${NC}"
    echo "Note: This might be due to Swift/ObjC interop issues. The ObjC-only benchmark is still available."
fi

if [ "$BUILD_ONLY" = true ]; then
    echo -e "\n${GREEN}Build completed successfully!${NC}"
    exit 0
fi

# Step 3: Run benchmarks
if [ -z "$PDF_FILE" ]; then
    # Look for a sample PDF
    if [ -f "../test.pdf" ]; then
        PDF_FILE="../test.pdf"
    elif [ -f "sample.pdf" ]; then
        PDF_FILE="sample.pdf"
    else
        echo -e "${RED}Error: No PDF file specified and no test.pdf found${NC}"
        echo "Please provide a PDF file using -p or --pdf option"
        exit 1
    fi
fi

if [ ! -f "$PDF_FILE" ]; then
    echo -e "${RED}Error: PDF file not found: $PDF_FILE${NC}"
    exit 1
fi

echo -e "\n${YELLOW}Running benchmarks...${NC}"
echo "PDF file: $PDF_FILE"
echo "Iterations: $ITERATIONS"

# Prepare output options
OUTPUT_OPTS=""
if [ -n "$OUTPUT_FILE" ]; then
    OUTPUT_OPTS="-o $OUTPUT_FILE"
fi

# Run the benchmark
if [ -f "./benchmark_combined" ]; then
    echo -e "\n${GREEN}Running combined Swift/ObjC benchmark...${NC}"
    ./benchmark_combined "$PDF_FILE" -i "$ITERATIONS" $OUTPUT_OPTS
else
    echo -e "\n${GREEN}Running ObjC-only benchmark...${NC}"
    ./benchmark_objc "$PDF_FILE" -i "$ITERATIONS" $OUTPUT_OPTS
fi

echo -e "\n${GREEN}Benchmark completed!${NC}"

# Clean up temporary files
rm -f module.modulemap pdf22png-Swift.h BenchmarkSwift.o

if [ -n "$OUTPUT_FILE" ]; then
    echo -e "Results exported to: ${YELLOW}$OUTPUT_FILE${NC}"
fi
