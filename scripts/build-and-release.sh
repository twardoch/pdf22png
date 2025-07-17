#!/bin/bash

# Comprehensive build, test, and release script for pdf22png
# Handles the complete CI/CD pipeline locally

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
RELEASE_DIR="$PROJECT_ROOT/release"
ARTIFACTS_DIR="$PROJECT_ROOT/artifacts"

# Build options
BUILD_ONLY=false
TEST_ONLY=false
RELEASE_ONLY=false
SKIP_TESTS=false
CLEAN_BUILD=false
VERBOSE=false
DRY_RUN=false
UPLOAD_ARTIFACTS=false

# Release options
RELEASE_VERSION=""
RELEASE_NOTES=""
CREATE_TAG=false
PUSH_TAG=false

# Print helpers
print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}ERROR: $1${NC}" >&2
}

print_info() {
    echo -e "${YELLOW}→ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}WARNING: $1${NC}"
}

usage() {
    cat << EOF
Usage: $0 [OPTIONS] [COMMAND]

Commands:
    build                 Build both implementations (default)
    test                  Run comprehensive test suite
    release               Create release artifacts
    all                   Build, test, and release (default)

Options:
    -b, --build-only      Only build, don't test or release
    -t, --test-only       Only run tests
    -r, --release-only    Only create release artifacts
    -s, --skip-tests      Skip test execution
    -c, --clean           Clean build artifacts before building
    -v, --verbose         Verbose output
    -d, --dry-run         Dry run mode (no actual changes)
    -u, --upload          Upload artifacts to GitHub releases
    
    Release options:
    --version VERSION     Set release version
    --notes NOTES         Release notes
    --tag                 Create git tag
    --push                Push tag to remote
    
    -h, --help            Show this help message

Examples:
    $0                              # Build, test, and create artifacts
    $0 --build-only --clean         # Clean build only
    $0 --test-only --verbose        # Run tests with verbose output
    $0 release --version 1.0.0      # Create release with version
    $0 --version 1.0.0 --tag --push # Full release with git tag
EOF
}

# Parse command line arguments
parse_args() {
    local command=""
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            build|test|release|all)
                command="$1"
                shift
                ;;
            -b|--build-only)
                BUILD_ONLY=true
                shift
                ;;
            -t|--test-only)
                TEST_ONLY=true
                shift
                ;;
            -r|--release-only)
                RELEASE_ONLY=true
                shift
                ;;
            -s|--skip-tests)
                SKIP_TESTS=true
                shift
                ;;
            -c|--clean)
                CLEAN_BUILD=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -u|--upload)
                UPLOAD_ARTIFACTS=true
                shift
                ;;
            --version)
                RELEASE_VERSION="$2"
                shift 2
                ;;
            --notes)
                RELEASE_NOTES="$2"
                shift 2
                ;;
            --tag)
                CREATE_TAG=true
                shift
                ;;
            --push)
                PUSH_TAG=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
    
    # Set default command
    if [[ -z "$command" ]]; then
        command="all"
    fi
    
    # Handle exclusive modes
    if [[ "$BUILD_ONLY" == true ]]; then
        command="build"
    elif [[ "$TEST_ONLY" == true ]]; then
        command="test"
    elif [[ "$RELEASE_ONLY" == true ]]; then
        command="release"
    fi
    
    echo "$command"
}

# Check dependencies
check_dependencies() {
    print_info "Checking dependencies..."
    
    local deps=("git" "make")
    
    # Add optional dependencies
    if [[ "$UPLOAD_ARTIFACTS" == true ]]; then
        deps+=("gh")
    fi
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            print_error "$dep is required but not installed"
            exit 1
        fi
    done
    
    # Check Swift and Objective-C compilers
    if ! command -v swift >/dev/null 2>&1; then
        print_error "Swift compiler not found. Install Xcode Command Line Tools."
        exit 1
    fi
    
    if ! command -v clang >/dev/null 2>&1; then
        print_error "Clang compiler not found. Install Xcode Command Line Tools."
        exit 1
    fi
    
    # Check GitHub CLI authentication if uploading
    if [[ "$UPLOAD_ARTIFACTS" == true ]]; then
        if ! gh auth status >/dev/null 2>&1; then
            print_error "GitHub CLI (gh) is not authenticated. Run 'gh auth login'"
            exit 1
        fi
    fi
    
    print_success "All dependencies satisfied"
}

# Setup environment
setup_environment() {
    print_info "Setting up environment..."
    
    cd "$PROJECT_ROOT"
    
    # Clean artifacts if requested
    if [[ "$CLEAN_BUILD" == true ]]; then
        print_info "Cleaning build artifacts..."
        make clean
        rm -rf "$RELEASE_DIR" "$ARTIFACTS_DIR"
    fi
    
    # Create directories
    mkdir -p "$RELEASE_DIR" "$ARTIFACTS_DIR"
    
    # Get version information
    local version=$(./scripts/version.sh get)
    print_info "Current version: $version"
    
    # Set release version if not provided
    if [[ -z "$RELEASE_VERSION" ]]; then
        RELEASE_VERSION=$(./scripts/version.sh get --short)
    fi
    
    print_info "Release version: $RELEASE_VERSION"
    print_success "Environment setup complete"
}

# Build projects
build_projects() {
    print_header "BUILDING PROJECTS"
    
    print_info "Generating version files..."
    make generate-version
    
    print_info "Building pdf21png (Objective-C)..."
    if [[ "$VERBOSE" == true ]]; then
        make pdf21png
    else
        make pdf21png >/dev/null 2>&1
    fi
    
    print_info "Building pdf22png (Swift)..."
    if [[ "$VERBOSE" == true ]]; then
        make pdf22png
    else
        make pdf22png >/dev/null 2>&1
    fi
    
    # Verify builds
    if [[ ! -f "pdf21png/build/pdf21png" ]]; then
        print_error "pdf21png build failed"
        exit 1
    fi
    
    if [[ ! -f "pdf22png/.build/apple/Products/Release/pdf22png" ]]; then
        print_error "pdf22png build failed"
        exit 1
    fi
    
    print_success "Build completed successfully"
}

# Run tests
run_tests() {
    print_header "RUNNING TESTS"
    
    local test_args=()
    
    if [[ "$VERBOSE" == true ]]; then
        test_args+=("--verbose")
    fi
    
    if [[ "$CLEAN_BUILD" == true ]]; then
        test_args+=("--clean")
    fi
    
    if ./scripts/test-all.sh "${test_args[@]}"; then
        print_success "All tests passed"
    else
        print_error "Some tests failed"
        exit 1
    fi
}

# Create release artifacts
create_release_artifacts() {
    print_header "CREATING RELEASE ARTIFACTS"
    
    local version="$RELEASE_VERSION"
    local build_date=$(date -u +"%Y-%m-%d %H:%M:%S UTC")
    
    # Create universal binaries
    print_info "Creating universal binaries..."
    
    # pdf21png
    local pdf21png_binary="pdf21png/build/pdf21png"
    if [[ -f "$pdf21png_binary" ]]; then
        local pdf21png_universal="$ARTIFACTS_DIR/pdf21png"
        cp "$pdf21png_binary" "$pdf21png_universal"
        
        # Create tarball
        local pdf21png_tarball="$ARTIFACTS_DIR/pdf21png-v${version}-macos-universal.tar.gz"
        tar -czf "$pdf21png_tarball" -C "$ARTIFACTS_DIR" "pdf21png"
        
        # Generate checksum
        if command -v shasum >/dev/null 2>&1; then
            shasum -a 256 "$pdf21png_tarball" > "$pdf21png_tarball.sha256"
        fi
        
        print_success "pdf21png artifact created"
    fi
    
    # pdf22png
    local pdf22png_binary="pdf22png/.build/apple/Products/Release/pdf22png"
    if [[ -f "$pdf22png_binary" ]]; then
        local pdf22png_universal="$ARTIFACTS_DIR/pdf22png"
        cp "$pdf22png_binary" "$pdf22png_universal"
        
        # Create tarball
        local pdf22png_tarball="$ARTIFACTS_DIR/pdf22png-v${version}-macos-universal.tar.gz"
        tar -czf "$pdf22png_tarball" -C "$ARTIFACTS_DIR" "pdf22png"
        
        # Generate checksum
        if command -v shasum >/dev/null 2>&1; then
            shasum -a 256 "$pdf22png_tarball" > "$pdf22png_tarball.sha256"
        fi
        
        print_success "pdf22png artifact created"
    fi
    
    # Create release notes
    local release_notes_file="$ARTIFACTS_DIR/RELEASE_NOTES.md"
    cat > "$release_notes_file" << EOF
# Release v${version}

$(if [[ -n "$RELEASE_NOTES" ]]; then echo "$RELEASE_NOTES"; else echo "Release v${version}"; fi)

## Changes

$(./scripts/version.sh changelog)

## Build Information

- Build Date: $build_date
- Git Commit: $(git rev-parse HEAD)
- Git Tag: $(git describe --tags --exact-match 2>/dev/null || echo "none")

## Installation

### Using Homebrew

\`\`\`bash
brew tap twardoch/homebrew-pdf22png
brew install pdf22png
\`\`\`

### Manual Installation

Download the appropriate archive for your system and extract it:

\`\`\`bash
# For pdf22png (Swift implementation)
tar -xzf pdf22png-v${version}-macos-universal.tar.gz
sudo cp pdf22png /usr/local/bin/

# For pdf21png (Objective-C implementation)
tar -xzf pdf21png-v${version}-macos-universal.tar.gz
sudo cp pdf21png /usr/local/bin/
\`\`\`

## Verification

Verify the downloads using SHA256 checksums:

\`\`\`bash
shasum -a 256 -c pdf22png-v${version}-macos-universal.tar.gz.sha256
shasum -a 256 -c pdf21png-v${version}-macos-universal.tar.gz.sha256
\`\`\`
EOF
    
    print_success "Release artifacts created"
    
    # List artifacts
    print_info "Created artifacts:"
    ls -la "$ARTIFACTS_DIR"
}

# Create git tag
create_git_tag() {
    if [[ "$CREATE_TAG" != true ]]; then
        return 0
    fi
    
    print_info "Creating git tag..."
    
    local tag="v$RELEASE_VERSION"
    
    # Check if tag already exists
    if git rev-parse "$tag" >/dev/null 2>&1; then
        print_warning "Tag $tag already exists"
        return 0
    fi
    
    # Create tag
    if [[ "$DRY_RUN" == true ]]; then
        print_info "DRY RUN: Would create tag $tag"
    else
        local tag_message="Release $tag"
        if [[ -n "$RELEASE_NOTES" ]]; then
            tag_message="$tag_message

$RELEASE_NOTES"
        fi
        
        git tag -a "$tag" -m "$tag_message"
        print_success "Created tag $tag"
    fi
    
    # Push tag
    if [[ "$PUSH_TAG" == true ]]; then
        print_info "Pushing tag to remote..."
        if [[ "$DRY_RUN" == true ]]; then
            print_info "DRY RUN: Would push tag $tag"
        else
            git push origin "$tag"
            print_success "Pushed tag $tag"
        fi
    fi
}

# Upload artifacts to GitHub
upload_artifacts() {
    if [[ "$UPLOAD_ARTIFACTS" != true ]]; then
        return 0
    fi
    
    print_info "Uploading artifacts to GitHub..."
    
    local tag="v$RELEASE_VERSION"
    
    # Check if release exists
    if gh release view "$tag" >/dev/null 2>&1; then
        print_warning "Release $tag already exists"
        return 0
    fi
    
    if [[ "$DRY_RUN" == true ]]; then
        print_info "DRY RUN: Would upload artifacts for $tag"
        return 0
    fi
    
    # Create release
    local release_title="Release $tag"
    local release_notes=""
    
    if [[ -f "$ARTIFACTS_DIR/RELEASE_NOTES.md" ]]; then
        release_notes=$(cat "$ARTIFACTS_DIR/RELEASE_NOTES.md")
    else
        release_notes="Release $tag"
    fi
    
    gh release create "$tag" \
        --title "$release_title" \
        --notes "$release_notes" \
        "$ARTIFACTS_DIR"/*.tar.gz \
        "$ARTIFACTS_DIR"/*.sha256
    
    print_success "Artifacts uploaded to GitHub"
}

# Print summary
print_summary() {
    print_header "SUMMARY"
    
    echo "Version: $RELEASE_VERSION"
    echo "Build Date: $(date -u +"%Y-%m-%d %H:%M:%S UTC")"
    echo "Git Commit: $(git rev-parse --short HEAD)"
    
    if [[ -d "$ARTIFACTS_DIR" ]]; then
        echo "Artifacts:"
        ls -la "$ARTIFACTS_DIR" | grep -E '\.(tar\.gz|sha256)$' | awk '{print "  " $9}'
    fi
    
    if [[ "$CREATE_TAG" == true ]]; then
        echo "Git Tag: v$RELEASE_VERSION"
    fi
    
    if [[ "$UPLOAD_ARTIFACTS" == true ]]; then
        echo "GitHub Release: Created"
    fi
    
    print_success "Build and release completed successfully"
}

# Main execution
main() {
    local command=$(parse_args "$@")
    
    print_header "PDF22PNG BUILD AND RELEASE"
    
    check_dependencies
    setup_environment
    
    case "$command" in
        build)
            build_projects
            ;;
        test)
            run_tests
            ;;
        release)
            create_release_artifacts
            create_git_tag
            upload_artifacts
            ;;
        all)
            build_projects
            if [[ "$SKIP_TESTS" != true ]]; then
                run_tests
            fi
            create_release_artifacts
            create_git_tag
            upload_artifacts
            ;;
        *)
            print_error "Unknown command: $command"
            usage
            exit 1
            ;;
    esac
    
    print_summary
}

# Run main function
main "$@"