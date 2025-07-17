#!/bin/bash

# Generate Objective-C version file from git tag information
# Usage: ./generate-version-objc.sh [output-path]

set -euo pipefail

# Default output path
OUTPUT_PATH="${1:-pdf21png/src/version.h}"

# Change to project root if running from scripts directory
if [[ "$(basename "$(pwd)")" == "scripts" ]]; then
    cd ..
fi

# Get version information
VERSION_FULL=$(./scripts/version.sh get)
VERSION_SHORT=$(./scripts/version.sh get --short)
if ./scripts/version.sh check >/dev/null 2>&1; then
    IS_RELEASE=true
else
    IS_RELEASE=false
fi
BUILD_HASH=$(git rev-parse --short HEAD)
BUILD_DATE=$(date -u +"%Y-%m-%d %H:%M:%S UTC")

# Generate Objective-C version header
cat > "$OUTPUT_PATH" << EOF
// this_file: $OUTPUT_PATH
// Auto-generated version file - DO NOT EDIT
// Generated at: $BUILD_DATE

#ifndef VERSION_H
#define VERSION_H

#define VERSION_FULL "$VERSION_FULL"
#define VERSION_SHORT "$VERSION_SHORT"
#define BUILD_HASH "$BUILD_HASH"
#define BUILD_DATE "$BUILD_DATE"
#define IS_RELEASE $IS_RELEASE

// Semantic version components (extracted from VERSION_SHORT)
#define VERSION_SEMANTIC "$VERSION_SHORT"

// Full version string for display
#define VERSION_DISPLAY (IS_RELEASE ? VERSION_FULL : VERSION_FULL " (" BUILD_HASH ")")

#endif /* VERSION_H */
EOF

echo "Generated version file: $OUTPUT_PATH"
echo "Version: $VERSION_FULL"
echo "Build: $BUILD_HASH"
echo "Is Release: $IS_RELEASE"