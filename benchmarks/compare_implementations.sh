#!/bin/bash

# Simple performance comparison script for ObjC vs Swift implementations

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "PDF22PNG Implementation Comparison"
echo "=================================="
echo

# Check if PDF file is provided
if [ $# -eq 0 ]; then
    PDF_FILE="sample.pdf"
else
    PDF_FILE="$1"
fi

if [ ! -f "$PDF_FILE" ]; then
    echo "Error: PDF file not found: $PDF_FILE"
    exit 1
fi

echo "Testing with: $PDF_FILE"
echo

# Create temp directory
TEMP_DIR=$(mktemp -d)
echo "Output directory: $TEMP_DIR"
echo

# Function to measure time
measure_time() {
    local start=$(date +%s.%N)
    "$@"
    local end=$(date +%s.%N)
    echo "$end - $start" | bc
}

# Test 1: Single page conversion
echo -e "${YELLOW}Test 1: Single Page Conversion${NC}"
echo "=============================="

echo -e "\n${BLUE}Objective-C Implementation:${NC}"
OBJC_TIME=$(measure_time ../build/pdf22png -f -p 1 "$PDF_FILE" "$TEMP_DIR/objc_page1.png" 2>&1)
echo "Time: ${OBJC_TIME}s"

echo -e "\n${BLUE}Swift Implementation:${NC}"
SWIFT_TIME=$(measure_time ../build/pdf22png-swift -f -p 1 "$PDF_FILE" "$TEMP_DIR/swift_page1.png" 2>&1)
echo "Time: ${SWIFT_TIME}s"

# Compare file sizes
OBJC_SIZE=$(ls -l "$TEMP_DIR/objc_page1.png" | awk '{print $5}')
SWIFT_SIZE=$(ls -l "$TEMP_DIR/swift_page1.png" | awk '{print $5}')
echo -e "\nFile sizes:"
echo "  ObjC:  $(echo "scale=2; $OBJC_SIZE/1024" | bc) KB"
echo "  Swift: $(echo "scale=2; $SWIFT_SIZE/1024" | bc) KB"

# Test 2: All pages conversion
echo -e "\n${YELLOW}Test 2: All Pages Conversion${NC}"
echo "=============================="

echo -e "\n${BLUE}Objective-C Implementation:${NC}"
mkdir -p "$TEMP_DIR/objc_all"
OBJC_ALL_TIME=$(measure_time ../build/pdf22png -f -a "$PDF_FILE" -d "$TEMP_DIR/objc_all" 2>&1)
echo "Time: ${OBJC_ALL_TIME}s"

echo -e "\n${BLUE}Swift Implementation:${NC}"
mkdir -p "$TEMP_DIR/swift_all"
SWIFT_ALL_TIME=$(measure_time ../build/pdf22png-swift -f -a "$PDF_FILE" -d "$TEMP_DIR/swift_all" 2>&1)
echo "Time: ${SWIFT_ALL_TIME}s"

# Count output files
OBJC_COUNT=$(ls -1 "$TEMP_DIR/objc_all"/*.png 2>/dev/null | wc -l | tr -d ' ')
SWIFT_COUNT=$(ls -1 "$TEMP_DIR/swift_all"/*.png 2>/dev/null | wc -l | tr -d ' ')
echo -e "\nPages converted:"
echo "  ObjC:  $OBJC_COUNT"
echo "  Swift: $SWIFT_COUNT"

# Test 3: High DPI conversion
echo -e "\n${YELLOW}Test 3: High DPI (300) Conversion${NC}"
echo "=================================="

echo -e "\n${BLUE}Objective-C Implementation:${NC}"
OBJC_DPI_TIME=$(measure_time ../build/pdf22png -f -p 1 -r 300 "$PDF_FILE" "$TEMP_DIR/objc_300dpi.png" 2>&1)
echo "Time: ${OBJC_DPI_TIME}s"

echo -e "\n${BLUE}Swift Implementation:${NC}"
SWIFT_DPI_TIME=$(measure_time ../build/pdf22png-swift -f -p 1 -r 300 "$PDF_FILE" "$TEMP_DIR/swift_300dpi.png" 2>&1)
echo "Time: ${SWIFT_DPI_TIME}s"

# Summary
echo -e "\n${GREEN}Summary${NC}"
echo "======="
echo

# Calculate speedup
if command -v bc >/dev/null 2>&1; then
    SPEEDUP_SINGLE=$(echo "scale=2; $OBJC_TIME / $SWIFT_TIME" | bc)
    SPEEDUP_ALL=$(echo "scale=2; $OBJC_ALL_TIME / $SWIFT_ALL_TIME" | bc)
    SPEEDUP_DPI=$(echo "scale=2; $OBJC_DPI_TIME / $SWIFT_DPI_TIME" | bc)
    
    echo "Performance Comparison (ObjC/Swift ratio):"
    echo "  Single page:  ${SPEEDUP_SINGLE}x"
    echo "  All pages:    ${SPEEDUP_ALL}x"
    echo "  High DPI:     ${SPEEDUP_DPI}x"
    echo
    echo "(Values > 1.0 mean Swift is faster)"
fi

# Memory usage estimate (very rough)
echo -e "\nMemory Usage (RSS):"
OBJC_MEM=$(../build/pdf22png -p 1 "$PDF_FILE" "$TEMP_DIR/mem_test.png" 2>&1 & ps aux | grep pdf22png | grep -v grep | awk '{print $6}' | head -1)
SWIFT_MEM=$(../build/pdf22png-swift -p 1 "$PDF_FILE" "$TEMP_DIR/mem_test2.png" 2>&1 & ps aux | grep pdf22png-swift | grep -v grep | awk '{print $6}' | head -1)

# Clean up
rm -rf "$TEMP_DIR"

echo -e "\n${GREEN}Comparison complete!${NC}"