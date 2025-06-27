#!/bin/bash

# Get version from git tags
# Uses semantic versioning based on git tags

set -euo pipefail

# Get the latest tag
if git describe --tags --abbrev=0 >/dev/null 2>&1; then
    # Get the version from the latest tag
    VERSION=$(git describe --tags --abbrev=0 | sed 's/^v//')
    
    # Check if we're on the exact tag
    if git describe --exact-match --tags >/dev/null 2>&1; then
        # We're on a release tag
        echo "$VERSION"
    else
        # We're on a commit after the tag, add commit info
        COMMITS_SINCE=$(git rev-list --count $(git describe --tags --abbrev=0)..HEAD)
        SHORT_SHA=$(git rev-parse --short HEAD)
        echo "${VERSION}-dev.${COMMITS_SINCE}+${SHORT_SHA}"
    fi
else
    # No tags found, use 0.0.0 with commit info
    COMMITS=$(git rev-list --count HEAD)
    SHORT_SHA=$(git rev-parse --short HEAD)
    echo "0.0.0-dev.${COMMITS}+${SHORT_SHA}"
fi