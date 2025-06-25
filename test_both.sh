#!/bin/bash
# Test both Objective-C and Swift implementations

set -e

echo "Building Objective-C implementation..."
make clean
make

echo -e "\nBuilding Swift implementation..."
make swift

echo -e "\nGenerating test PDF..."
cat > /tmp/test.ps << 'EOF'
%!PS
/Helvetica findfont 24 scalefont setfont
newpath
72 720 moveto
(Test Page for pdf22png) show
72 680 moveto
(This is a test document) show
showpage
EOF

ps2pdf /tmp/test.ps /tmp/test.pdf
rm /tmp/test.ps

echo -e "\nTesting Objective-C implementation..."
./build/pdf22png -v /tmp/test.pdf /tmp/test_objc.png
ls -la /tmp/test_objc.png

echo -e "\nTesting Swift implementation..."
./build/pdf22png_swift -v /tmp/test.pdf /tmp/test_swift.png
ls -la /tmp/test_swift.png

echo -e "\nComparing output files..."
if command -v compare &> /dev/null; then
    # ImageMagick compare
    compare -metric AE /tmp/test_objc.png /tmp/test_swift.png /tmp/diff.png 2>&1 || true
    echo "Difference visualization saved to /tmp/diff.png"
else
    echo "Install ImageMagick to compare images visually"
fi

echo -e "\nFile sizes:"
ls -lh /tmp/test_objc.png /tmp/test_swift.png

echo -e "\nCleanup..."
rm -f /tmp/test.pdf /tmp/test_objc.png /tmp/test_swift.png /tmp/diff.png

echo -e "\nTest complete!"