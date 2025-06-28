#!/bin/bash

# Memory leak detection script for pdf22png
# Uses macOS Instruments and Address Sanitizer

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
BUILD_DIR="$PROJECT_ROOT/build/leak-test"
TEST_PDF="$PROJECT_ROOT/tests/fixtures/test.pdf"
REPORT_DIR="$PROJECT_ROOT/build/leak-reports"

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

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Check if running on macOS
check_platform() {
    if [[ "$(uname)" != "Darwin" ]]; then
        print_error "This script requires macOS for Instruments"
        exit 1
    fi
}

# Create test PDF if it doesn't exist
create_test_pdf() {
    if [ ! -f "$TEST_PDF" ]; then
        print_info "Creating test PDF..."
        mkdir -p "$(dirname "$TEST_PDF")"
        
        # Create a simple test PDF using Python
        python3 << EOF
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import letter

c = canvas.Canvas("$TEST_PDF", pagesize=letter)
c.drawString(100, 750, "Test PDF for memory leak detection")
c.showPage()
c.drawString(100, 750, "Page 2")
c.showPage()
c.save()
EOF
        
        if [ ! -f "$TEST_PDF" ]; then
            print_warning "Could not create test PDF with Python. Creating minimal PDF..."
            # Create minimal PDF
            cat > "$TEST_PDF" << 'PDFEOF'
%PDF-1.4
1 0 obj << /Type /Catalog /Pages 2 0 R >> endobj
2 0 obj << /Type /Pages /Kids [3 0 R] /Count 1 >> endobj
3 0 obj << /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >> endobj
4 0 obj << /Type /Font /Subtype /Type1 /BaseFont /Helvetica >> endobj
5 0 obj << /Length 44 >> stream
BT
/F1 12 Tf
100 700 Td
(Test PDF) Tj
ET
endstream endobj
xref
0 6
0000000000 65535 f
0000000009 00000 n
0000000058 00000 n
0000000115 00000 n
0000000229 00000 n
0000000317 00000 n
trailer << /Size 6 /Root 1 0 R >>
startxref
408
%%EOF
PDFEOF
        fi
        
        print_success "Created test PDF"
    fi
}

# Build with Address Sanitizer
build_with_asan() {
    print_info "Building with Address Sanitizer..."
    
    rm -rf "$BUILD_DIR"
    mkdir -p "$BUILD_DIR"
    
    # Build pdf21png with ASAN
    print_info "Building pdf21png with ASAN..."
    cd "$PROJECT_ROOT/pdf21png"
    clang \
        -g \
        -O0 \
        -fobjc-arc \
        -fsanitize=address \
        -fno-omit-frame-pointer \
        -mmacosx-version-min=10.15 \
        -framework Foundation \
        -framework CoreGraphics \
        -framework ImageIO \
        -framework Quartz \
        -framework Vision \
        -framework CoreServices \
        -framework UniformTypeIdentifiers \
        src/pdf21png.m src/utils.m \
        -o "$BUILD_DIR/pdf21png-asan"
    
    # Build pdf22png with ASAN (Swift)
    print_info "Building pdf22png with ASAN..."
    cd "$PROJECT_ROOT/pdf22png"
    swift build \
        -c debug \
        -Xswiftc -sanitize=address \
        -Xlinker -rpath -Xlinker @executable_path
    
    cp ".build/debug/pdf22png" "$BUILD_DIR/pdf22png-asan"
    
    print_success "Built binaries with Address Sanitizer"
}

# Run tests with ASAN
run_asan_tests() {
    print_info "Running Address Sanitizer tests..."
    
    mkdir -p "$REPORT_DIR"
    local ASAN_LOG="$REPORT_DIR/asan-report.log"
    
    # Test pdf21png
    print_info "Testing pdf21png with ASAN..."
    ASAN_OPTIONS="log_path=$REPORT_DIR/pdf21png-asan" \
    MallocScribble=1 \
    MallocPreScribble=1 \
    "$BUILD_DIR/pdf21png-asan" "$TEST_PDF" "$BUILD_DIR/test-output-21.png" 2>&1 | tee "$ASAN_LOG"
    
    # Test pdf22png
    print_info "Testing pdf22png with ASAN..."
    ASAN_OPTIONS="log_path=$REPORT_DIR/pdf22png-asan" \
    MallocScribble=1 \
    MallocPreScribble=1 \
    "$BUILD_DIR/pdf22png-asan" "$TEST_PDF" "$BUILD_DIR/test-output-22.png" 2>&1 | tee -a "$ASAN_LOG"
    
    # Check for leaks in log
    if grep -q "ERROR: AddressSanitizer" "$ASAN_LOG" 2>/dev/null; then
        print_error "Address Sanitizer found issues!"
        return 1
    else
        print_success "No issues found by Address Sanitizer"
    fi
}

# Run with Instruments (requires Xcode)
run_instruments_test() {
    print_info "Running Instruments leak detection..."
    
    if ! command -v instruments >/dev/null 2>&1; then
        print_warning "Instruments not found. Install Xcode for detailed leak detection."
        return
    fi
    
    mkdir -p "$REPORT_DIR"
    
    # Run pdf21png with Instruments
    print_info "Testing pdf21png with Instruments..."
    instruments -t Leaks \
        -D "$REPORT_DIR/pdf21png-leaks.trace" \
        "$PROJECT_ROOT/pdf21png/build/pdf21png" \
        "$TEST_PDF" "$BUILD_DIR/test-instruments-21.png" \
        2>&1 | tee "$REPORT_DIR/instruments-21.log" || true
    
    # Run pdf22png with Instruments
    print_info "Testing pdf22png with Instruments..."
    instruments -t Leaks \
        -D "$REPORT_DIR/pdf22png-leaks.trace" \
        "$PROJECT_ROOT/pdf22png/build/pdf22png" \
        "$TEST_PDF" "$BUILD_DIR/test-instruments-22.png" \
        2>&1 | tee "$REPORT_DIR/instruments-22.log" || true
    
    print_success "Instruments analysis complete. Check $REPORT_DIR for detailed reports."
}

# Run valgrind-style checks using leaks command
run_leaks_check() {
    print_info "Running leaks command check..."
    
    # Build normal binaries if not present
    if [ ! -f "$PROJECT_ROOT/pdf21png/build/pdf21png" ]; then
        cd "$PROJECT_ROOT"
        make pdf21png
    fi
    
    if [ ! -f "$PROJECT_ROOT/pdf22png/.build/release/pdf22png" ]; then
        cd "$PROJECT_ROOT"
        make pdf22png
    fi
    
    # Test pdf21png
    print_info "Checking pdf21png for leaks..."
    MallocStackLogging=1 \
    leaks --atExit -- "$PROJECT_ROOT/pdf21png/build/pdf21png" \
        "$TEST_PDF" "$BUILD_DIR/test-leaks-21.png" \
        2>&1 | tee "$REPORT_DIR/leaks-21.log"
    
    # Test pdf22png
    print_info "Checking pdf22png for leaks..."
    MallocStackLogging=1 \
    leaks --atExit -- "$PROJECT_ROOT/pdf22png/.build/release/pdf22png" \
        "$TEST_PDF" "$BUILD_DIR/test-leaks-22.png" \
        2>&1 | tee "$REPORT_DIR/leaks-22.log"
    
    # Check results
    if grep -q "0 leaks for 0 total leaked bytes" "$REPORT_DIR/leaks-21.log" && \
       grep -q "0 leaks for 0 total leaked bytes" "$REPORT_DIR/leaks-22.log"; then
        print_success "No memory leaks detected!"
    else
        print_warning "Potential memory leaks found. Check logs for details."
    fi
}

# Generate summary report
generate_report() {
    print_info "Generating summary report..."
    
    local SUMMARY="$REPORT_DIR/SUMMARY.md"
    
    cat > "$SUMMARY" << EOF
# Memory Leak Detection Report

Date: $(date)

## Test Environment
- macOS Version: $(sw_vers -productVersion)
- Xcode Version: $(xcodebuild -version 2>/dev/null | head -1 || echo "Not installed")

## Results Summary

### Address Sanitizer
EOF
    
    if [ -f "$REPORT_DIR/asan-report.log" ]; then
        if grep -q "ERROR: AddressSanitizer" "$REPORT_DIR/asan-report.log"; then
            echo "❌ Issues detected" >> "$SUMMARY"
        else
            echo "✅ No issues detected" >> "$SUMMARY"
        fi
    else
        echo "⚠️  Not run" >> "$SUMMARY"
    fi
    
    cat >> "$SUMMARY" << EOF

### Leaks Command
EOF
    
    if [ -f "$REPORT_DIR/leaks-21.log" ]; then
        echo "#### pdf21png" >> "$SUMMARY"
        grep "total leaked bytes" "$REPORT_DIR/leaks-21.log" | tail -1 >> "$SUMMARY" || echo "No results" >> "$SUMMARY"
    fi
    
    if [ -f "$REPORT_DIR/leaks-22.log" ]; then
        echo "#### pdf22png" >> "$SUMMARY"
        grep "total leaked bytes" "$REPORT_DIR/leaks-22.log" | tail -1 >> "$SUMMARY" || echo "No results" >> "$SUMMARY"
    fi
    
    cat >> "$SUMMARY" << EOF

## Detailed Reports

- Address Sanitizer logs: \`$REPORT_DIR/*-asan.*\`
- Leaks command logs: \`$REPORT_DIR/leaks-*.log\`
- Instruments traces: \`$REPORT_DIR/*.trace\`

## Recommendations

1. Run this check regularly during development
2. Include in CI/CD pipeline
3. Fix any detected leaks immediately
4. Consider using static analysis tools

EOF
    
    print_success "Summary report generated: $SUMMARY"
    
    # Display summary
    echo ""
    cat "$SUMMARY"
}

# Main execution
main() {
    echo ""
    echo "PDF22PNG Memory Leak Detection"
    echo "=============================="
    echo ""
    
    check_platform
    create_test_pdf
    
    # Parse options
    local RUN_ASAN=true
    local RUN_INSTRUMENTS=false
    local RUN_LEAKS=true
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --asan-only)
                RUN_INSTRUMENTS=false
                RUN_LEAKS=false
                shift
                ;;
            --instruments)
                RUN_INSTRUMENTS=true
                shift
                ;;
            --leaks-only)
                RUN_ASAN=false
                RUN_INSTRUMENTS=false
                shift
                ;;
            --all)
                RUN_ASAN=true
                RUN_INSTRUMENTS=true
                RUN_LEAKS=true
                shift
                ;;
            *)
                shift
                ;;
        esac
    done
    
    mkdir -p "$REPORT_DIR"
    
    if [ "$RUN_ASAN" = true ]; then
        build_with_asan
        run_asan_tests || true
    fi
    
    if [ "$RUN_INSTRUMENTS" = true ]; then
        run_instruments_test || true
    fi
    
    if [ "$RUN_LEAKS" = true ]; then
        run_leaks_check || true
    fi
    
    generate_report
    
    echo ""
    print_success "Memory leak detection complete!"
    echo ""
    echo "Reports saved to: $REPORT_DIR"
}

# Show help
if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
    echo "PDF22PNG Memory Leak Detection"
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --asan-only      Run only Address Sanitizer tests"
    echo "  --leaks-only     Run only leaks command tests"
    echo "  --instruments    Include Instruments analysis (requires Xcode)"
    echo "  --all            Run all available tests"
    echo "  --help           Show this help message"
    echo ""
    echo "Default: Runs Address Sanitizer and leaks command tests"
    exit 0
fi

# Run main
main "$@"