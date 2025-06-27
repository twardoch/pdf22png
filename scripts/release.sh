#!/bin/bash

# Release script for pdf22png
# Creates release artifacts and updates Homebrew formulas

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
DIST_DIR="$PROJECT_ROOT/dist"
VERSION=""
DRY_RUN=false

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

# Show usage
usage() {
    echo "PDF22PNG Release Script"
    echo ""
    echo "Usage: $0 [-d|--dry-run] <version>"
    echo ""
    echo "Arguments:"
    echo "  version     Version to release (e.g., v2.3.1)"
    echo ""
    echo "Options:"
    echo "  -d, --dry-run    Perform a dry run without creating the release"
    echo "  -h, --help       Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 v2.3.1"
    echo "  $0 --dry-run v2.3.2"
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        v*)
            VERSION="$1"
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            usage
            ;;
    esac
done

if [ -z "$VERSION" ]; then
    print_error "Version is required"
    usage
fi

# Verify git state
check_git_state() {
    print_info "Checking git state..."
    
    # Check for uncommitted changes
    if ! git diff --quiet || ! git diff --cached --quiet; then
        print_error "Uncommitted changes detected. Please commit or stash them first."
        exit 1
    fi
    
    # Check if on main branch
    local BRANCH=$(git branch --show-current)
    if [ "$BRANCH" != "main" ]; then
        print_warning "Not on main branch (current: $BRANCH)"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    print_success "Git state OK"
}

# Build release artifacts
build_artifacts() {
    print_info "Building release artifacts..."
    
    cd "$PROJECT_ROOT"
    
    # Clean previous builds
    make clean
    
    # Build distribution packages
    make dist
    
    # Build universal binaries
    make universal
    
    print_success "Built all artifacts"
}

# Create release tarballs
create_tarballs() {
    print_info "Creating release tarballs..."
    
    local RELEASE_DIR="$DIST_DIR/release-$VERSION"
    rm -rf "$RELEASE_DIR"
    mkdir -p "$RELEASE_DIR"
    
    # Create pdf21png tarball
    local PDF21_DIR="$RELEASE_DIR/pdf21png-$VERSION"
    mkdir -p "$PDF21_DIR"
    cp "pdf21png/build/pdf21png-universal" "$PDF21_DIR/pdf21png"
    cp "README.md" "$PDF21_DIR/"
    cp "LICENSE" "$PDF21_DIR/" 2>/dev/null || true
    
    cd "$RELEASE_DIR"
    tar czf "pdf21png-$VERSION-macos-universal.tar.gz" "pdf21png-$VERSION"
    rm -rf "pdf21png-$VERSION"
    
    # Create pdf22png tarball
    local PDF22_DIR="$RELEASE_DIR/pdf22png-$VERSION"
    mkdir -p "$PDF22_DIR"
    cp "$PROJECT_ROOT/pdf22png/build/pdf22png" "$PDF22_DIR/pdf22png"
    cp "$PROJECT_ROOT/README.md" "$PDF22_DIR/"
    cp "$PROJECT_ROOT/LICENSE" "$PDF22_DIR/" 2>/dev/null || true
    
    tar czf "pdf22png-$VERSION-macos-universal.tar.gz" "pdf22png-$VERSION"
    rm -rf "pdf22png-$VERSION"
    
    # Copy installers
    cp "$DIST_DIR"/*.pkg "$RELEASE_DIR/" 2>/dev/null || true
    cp "$DIST_DIR"/*.dmg "$RELEASE_DIR/" 2>/dev/null || true
    
    cd "$PROJECT_ROOT"
    print_success "Created release tarballs"
}

# Generate checksums
generate_checksums() {
    print_info "Generating checksums..."
    
    cd "$DIST_DIR/release-$VERSION"
    
    # Generate SHA256 checksums
    shasum -a 256 *.tar.gz *.pkg *.dmg > "SHA256SUMS.txt" 2>/dev/null || \
    shasum -a 256 *.tar.gz > "SHA256SUMS.txt"
    
    # Display checksums
    echo ""
    echo "SHA256 Checksums:"
    echo "================="
    cat "SHA256SUMS.txt"
    echo ""
    
    cd "$PROJECT_ROOT"
    print_success "Generated checksums"
}

# Update Homebrew formulas
update_formulas() {
    print_info "Updating Homebrew formulas..."
    
    cd "$DIST_DIR/release-$VERSION"
    
    # Get checksums
    local PDF21_SHA=$(shasum -a 256 "pdf21png-$VERSION-macos-universal.tar.gz" | cut -d' ' -f1)
    local PDF22_SHA=$(shasum -a 256 "pdf22png-$VERSION-macos-universal.tar.gz" | cut -d' ' -f1)
    
    cd "$PROJECT_ROOT"
    
    # Update pdf21png formula
    local PDF21_FORMULA="homebrew/pdf21png.rb"
    if [ -f "$PDF21_FORMULA" ]; then
        # Update version
        sed -i '' "s/version \".*\"/version \"${VERSION#v}\"/" "$PDF21_FORMULA"
        
        # Update URL
        sed -i '' "s|url \".*\"|url \"https://github.com/twardoch/pdf22png/releases/download/$VERSION/pdf21png-$VERSION-macos-universal.tar.gz\"|" "$PDF21_FORMULA"
        
        # Update SHA256
        sed -i '' "s/sha256 \".*\"/sha256 \"$PDF21_SHA\"/" "$PDF21_FORMULA"
        
        print_success "Updated pdf21png formula"
    fi
    
    # Update pdf22png formula
    local PDF22_FORMULA="homebrew/pdf22png.rb"
    if [ -f "$PDF22_FORMULA" ]; then
        # Update version
        sed -i '' "s/version \".*\"/version \"${VERSION#v}\"/" "$PDF22_FORMULA"
        
        # Update URL
        sed -i '' "s|url \".*\"|url \"https://github.com/twardoch/pdf22png/releases/download/$VERSION/pdf22png-$VERSION-macos-universal.tar.gz\"|" "$PDF22_FORMULA"
        
        # Update SHA256
        sed -i '' "s/sha256 \".*\"/sha256 \"$PDF22_SHA\"/" "$PDF22_FORMULA"
        
        print_success "Updated pdf22png formula"
    fi
}

# Create git tag
create_tag() {
    if [ "$DRY_RUN" = true ]; then
        print_info "[DRY RUN] Would create tag: $VERSION"
        return
    fi
    
    print_info "Creating git tag..."
    
    # Create annotated tag
    git tag -a "$VERSION" -m "Release $VERSION"
    
    print_success "Created tag: $VERSION"
    print_info "Push the tag with: git push origin $VERSION"
}

# Create release notes
create_release_notes() {
    print_info "Creating release notes..."
    
    local NOTES_FILE="$DIST_DIR/release-$VERSION/RELEASE_NOTES.md"
    
    cat > "$NOTES_FILE" << EOF
# PDF22PNG Release $VERSION

## What's New

See [CHANGELOG.md](https://github.com/twardoch/pdf22png/blob/main/CHANGELOG.md) for detailed changes.

## Installation

### Homebrew (Recommended)

\`\`\`bash
brew tap twardoch/pdf22png
brew install pdf22png  # Swift version
brew install pdf21png  # Objective-C version
\`\`\`

### Package Installer

Download and run \`pdf22png-$VERSION.pkg\`

### Disk Image

Download and mount \`pdf22png-$VERSION.dmg\`, then run the installer script.

### Manual Installation

Download the appropriate tarball and extract to \`/usr/local/bin\`:

\`\`\`bash
tar xzf pdf22png-$VERSION-macos-universal.tar.gz
sudo cp pdf22png-$VERSION/pdf22png /usr/local/bin/
\`\`\`

## Checksums

\`\`\`
$(cat "$DIST_DIR/release-$VERSION/SHA256SUMS.txt")
\`\`\`

## Requirements

- macOS 10.15 (Catalina) or later
- Universal binary supports both Intel and Apple Silicon

## Documentation

- [README](https://github.com/twardoch/pdf22png/blob/main/README.md)
- [Usage Guide](https://github.com/twardoch/pdf22png/blob/main/docs/USAGE.md)
EOF
    
    print_success "Created release notes"
}

# Main release process
main() {
    echo ""
    echo "PDF22PNG Release Process"
    echo "========================"
    echo "Version: $VERSION"
    echo "Dry Run: $DRY_RUN"
    echo ""
    
    check_git_state
    build_artifacts
    create_tarballs
    generate_checksums
    update_formulas
    create_release_notes
    
    if [ "$DRY_RUN" = false ]; then
        create_tag
    fi
    
    echo ""
    print_success "Release preparation complete!"
    echo ""
    echo "Release artifacts in: $DIST_DIR/release-$VERSION/"
    echo ""
    echo "Next steps:"
    echo "1. Review the updated formula files"
    echo "2. Commit formula updates: git add homebrew/*.rb && git commit -m 'Update formulas for $VERSION'"
    echo "3. Push commits: git push"
    echo "4. Push tag: git push origin $VERSION"
    echo "5. GitHub Actions will create the release"
    echo "6. Update the Homebrew tap repository"
    echo ""
    
    if [ "$DRY_RUN" = true ]; then
        print_warning "This was a dry run. No tag was created."
    fi
}

# Run main
main