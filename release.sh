#!/bin/bash

# release.sh - Build, tag, and release pdf22png
# Usage: ./release.sh [--v A.B.C]

set -euo pipefail

# Color output for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Function to get the latest git tag version
get_latest_version() {
    local latest_tag=$(git tag -l "v*" | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -n1)
    if [[ -n "$latest_tag" ]]; then
        echo "${latest_tag#v}"
    else
        echo ""
    fi
}

# Function to increment version
increment_version() {
    local version=$1
    local part=$2  # major, minor, patch
    
    IFS='.' read -r major minor patch <<< "$version"
    
    case $part in
        major)
            ((major++))
            minor=0
            patch=0
            ;;
        minor)
            ((minor++))
            patch=0
            ;;
        patch)
            ((patch++))
            ;;
    esac
    
    echo "$major.$minor.$patch"
}

# Function to validate version format
validate_version() {
    local version=$1
    if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        print_error "Invalid version format: $version"
        print_error "Version must be in format A.B.C (e.g., 1.0.0)"
        exit 1
    fi
}

# Parse command line arguments
VERSION=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --v)
            VERSION="$2"
            validate_version "$VERSION"
            shift 2
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Usage: $0 [--v A.B.C]"
            exit 1
            ;;
    esac
done

# Determine version
if [[ -z "$VERSION" ]]; then
    LATEST=$(get_latest_version)
    if [[ -z "$LATEST" ]]; then
        VERSION="1.0.0"
        print_info "No existing versions found. Using default version: $VERSION"
    else
        VERSION=$(increment_version "$LATEST" "minor")
        print_info "Latest version: v$LATEST"
        print_info "New version: v$VERSION"
    fi
else
    print_info "Using specified version: v$VERSION"
fi

# Check if we're in the correct directory
if [[ ! -f "Makefile" ]] || [[ ! -d "src" ]]; then
    print_error "Must be run from the pdf22png project root directory"
    exit 1
fi

# Check for uncommitted changes
if ! git diff-index --quiet HEAD --; then
    print_warning "You have uncommitted changes. Do you want to continue? (y/N)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        print_info "Aborting release"
        exit 0
    fi
fi

# Check if tag already exists
if git rev-parse "v$VERSION" >/dev/null 2>&1; then
    print_error "Tag v$VERSION already exists"
    exit 1
fi

# Clean any existing builds
print_info "Cleaning previous builds..."
make clean >/dev/null 2>&1 || true

# Build the project
print_info "Building pdf22png..."
if ! make; then
    print_error "Build failed"
    exit 1
fi
print_success "Build completed"

# Run tests if they exist
if [[ -f "tests/test_pdf22png.m" ]]; then
    print_info "Running tests..."
    if ! make test; then
        print_error "Tests failed"
        exit 1
    fi
    print_success "Tests passed"
fi

# Update version in README if version badge exists
if grep -q "shields.io.*version" README.md 2>/dev/null; then
    print_info "Updating version badge in README..."
    sed -i '' "s/version-v[0-9.]*-/version-v$VERSION-/g" README.md
    git add README.md
fi

# Commit any version changes
if ! git diff-index --quiet HEAD --; then
    print_info "Committing version changes..."
    git commit -m "Release v$VERSION"
fi

# Create and push tag
print_info "Creating tag v$VERSION..."
git tag -a "v$VERSION" -m "Release v$VERSION"

# Push commits and tags
print_info "Pushing to remote..."
if ! git push; then
    print_error "Failed to push commits"
    exit 1
fi

if ! git push origin "v$VERSION"; then
    print_error "Failed to push tag"
    exit 1
fi

print_success "Successfully released v$VERSION"
print_info "GitHub Actions will now build and create the release artifacts"
print_info "Check the Actions tab on GitHub for build progress"