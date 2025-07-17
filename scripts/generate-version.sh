#!/bin/bash

# Generate Swift version file from git tag information
# Usage: ./generate-version.sh [output-path]

set -euo pipefail

# Default output path
OUTPUT_PATH="${1:-pdf22png/Sources/pdf22png/Version.swift}"

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

# Generate Swift version file
cat > "$OUTPUT_PATH" << EOF
// this_file: $OUTPUT_PATH
// Auto-generated version file - DO NOT EDIT
// Generated at: $BUILD_DATE

import Foundation

public struct Version {
    public static let version = "$VERSION_FULL"
    public static let build = "$BUILD_HASH"
    public static let isRelease = $IS_RELEASE
    
    // Semantic version components
    public static let semanticVersion: String = {
        // Remove pre-release and build metadata for semantic version
        let components = version.components(separatedBy: "-")
        return components.first ?? version
    }()
    
    // Full version string for display
    public static let fullVersion: String = {
        if isRelease {
            return version
        } else {
            return "\\(version) (\\(build))"
        }
    }()
    
    // Short version for command line tools
    public static let shortVersion: String = {
        return semanticVersion
    }()
    
    // Build timestamp
    public static let buildDate = "$BUILD_DATE"
}
EOF

echo "Generated version file: $OUTPUT_PATH"
echo "Version: $VERSION_FULL"
echo "Build: $BUILD_HASH"
echo "Is Release: $IS_RELEASE"