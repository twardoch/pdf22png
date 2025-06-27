#!/bin/bash
# Test both Objective-C and Swift implementations
# Change to script directory

set -e

# Use default test PDF if none provided
if [ -z "$1" ]; then
    PDF=$(realpath "./testdata/test.pdf")
else
    PDF=$(realpath "$1")
fi

cd "$(dirname "$0")"

./build.sh

PDF_DIR=$(dirname $PDF)
PDF_NAME=$(basename $PDF)
PNG_DIR_OC="$PDF_DIR/$PDF_NAME-oc"
PNG_DIR_SW="$PDF_DIR/$PDF_NAME-sw"

echo "ObjC: $PNG_DIR_OC"
time ./pdf22png-objc/build/pdf22png -s "4096x4096" -d "$PNG_DIR_OC" "$PDF"
echo "Swift: $PNG_DIR_SW"
time ./pdf22png-swift/.build/release/pdf22png-swift -s "4096x4096" -d "$PNG_DIR_SW" "$PDF"
