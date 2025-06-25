#!/bin/bash
# Test script for Objective-C version of pdf22png

set -e

echo "Testing pdf22png Objective-C implementation..."

# Create a simple test PDF using PostScript
cat > test.ps << 'EOF'
%!PS-Adobe-3.0
%%BoundingBox: 0 0 612 792
%%Pages: 2
%%EndComments

%%Page: 1 1
/Helvetica findfont 40 scalefont setfont
100 400 moveto
(Test Page 1) show
showpage

%%Page: 2 2  
/Helvetica findfont 40 scalefont setfont
100 400 moveto
(Test Page 2) show
showpage

%%EOF
EOF

# Convert PS to PDF
ps2pdf test.ps test.pdf

# Build if not already built
if [ ! -f ./build/pdf22png-objc ]; then
    echo "Building Objective-C version..."
    make objc
fi

echo ""
echo "Running tests..."
echo "==============="

# Test 1: Basic conversion
echo "Test 1: Basic single page conversion"
./build/pdf22png-objc test.pdf test-output.png
if [ -f test-output.png ]; then
    echo "✓ Basic conversion successful"
    rm test-output.png
else
    echo "✗ Basic conversion failed"
fi

# Test 2: Specific page
echo ""
echo "Test 2: Convert page 2"
./build/pdf22png-objc -p 2 test.pdf test-page2.png
if [ -f test-page2.png ]; then
    echo "✓ Page selection successful"
    rm test-page2.png
else
    echo "✗ Page selection failed"
fi

# Test 3: Scaling
echo ""
echo "Test 3: Scale to 200%"
./build/pdf22png-objc -s 200% test.pdf test-scaled.png
if [ -f test-scaled.png ]; then
    echo "✓ Scaling successful"
    rm test-scaled.png
else
    echo "✗ Scaling failed"
fi

# Test 4: DPI setting
echo ""
echo "Test 4: Convert at 300 DPI"
./build/pdf22png-objc -r 300 test.pdf test-300dpi.png
if [ -f test-300dpi.png ]; then
    echo "✓ DPI setting successful"
    rm test-300dpi.png
else
    echo "✗ DPI setting failed"
fi

# Test 5: Batch mode
echo ""
echo "Test 5: Batch conversion"
mkdir -p test-batch
./build/pdf22png-objc -a -d test-batch test.pdf
if [ -f test-batch/test-001.png ] && [ -f test-batch/test-002.png ]; then
    echo "✓ Batch conversion successful"
    rm -rf test-batch
else
    echo "✗ Batch conversion failed"
fi

# Test 6: Dry run
echo ""
echo "Test 6: Dry run mode"
./build/pdf22png-objc -D test.pdf test-dryrun.png > /dev/null 2>&1
if [ ! -f test-dryrun.png ]; then
    echo "✓ Dry run successful (no file created)"
else
    echo "✗ Dry run failed (file was created)"
    rm test-dryrun.png
fi

# Test 7: stdin/stdout
echo ""
echo "Test 7: stdin to stdout"
cat test.pdf | ./build/pdf22png-objc - - > test-stdio.png 2>/dev/null
if [ -f test-stdio.png ] && [ -s test-stdio.png ]; then
    echo "✓ stdin/stdout successful"
    rm test-stdio.png
else
    echo "✗ stdin/stdout failed"
fi

# Test 8: Help
echo ""
echo "Test 8: Help message"
if ./build/pdf22png-objc -h 2>&1 | grep -q "Usage:"; then
    echo "✓ Help message displayed"
else
    echo "✗ Help message failed"
fi

# Cleanup
rm -f test.ps test.pdf

echo ""
echo "==============="
echo "Tests complete!"