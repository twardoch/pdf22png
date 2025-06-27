#!/bin/bash

# PDF22PNG Release Script
# Automates the release process for both pdf21png and pdf22png

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PDF21PNG_VERSION=""
PDF22PNG_VERSION=""
GITHUB_REPO="twardoch/pdf22png"
RELEASE_NOTES=""
DRY_RUN=false

# Print colored output
print_error() {
    echo -e "${RED}ERROR: $1${NC}" >&2
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}→ $1${NC}"
}

# Display usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
    -1, --pdf21png-version VERSION    Version for pdf21png (e.g., 2.1.0)
    -2, --pdf22png-version VERSION    Version for pdf22png (e.g., 2.2.0)
    -b, --both-version VERSION        Use same version for both
    -m, --message MESSAGE             Release notes/message
    -d, --dry-run                     Perform dry run without creating release
    -h, --help                        Show this help message

Examples:
    $0 --both-version 2.3.0 --message "Performance improvements"
    $0 -1 2.1.1 -2 2.2.1 -m "Bug fixes"
EOF
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -1|--pdf21png-version)
                PDF21PNG_VERSION="$2"
                shift 2
                ;;
            -2|--pdf22png-version)
                PDF22PNG_VERSION="$2"
                shift 2
                ;;
            -b|--both-version)
                PDF21PNG_VERSION="$2"
                PDF22PNG_VERSION="$2"
                shift 2
                ;;
            -m|--message)
                RELEASE_NOTES="$2"
                shift 2
                ;;
            -d|--dry-run)
                DRY_RUN=true
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
}

# Validate inputs
validate_inputs() {
    if [[ -z "$PDF21PNG_VERSION" && -z "$PDF22PNG_VERSION" ]]; then
        print_error "At least one version must be specified"
        usage
        exit 1
    fi
    
    if [[ -z "$RELEASE_NOTES" ]]; then
        RELEASE_NOTES="Release ${PDF21PNG_VERSION:+pdf21png v$PDF21PNG_VERSION}${PDF21PNG_VERSION:+ }${PDF22PNG_VERSION:+pdf22png v$PDF22PNG_VERSION}"
    fi
}

# Check dependencies
check_dependencies() {
    print_info "Checking dependencies..."
    
    local deps=("git" "make" "gh" "shasum")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            print_error "$dep is required but not installed"
            exit 1
        fi
    done
    
    # Check if gh is authenticated
    if ! gh auth status &> /dev/null; then
        print_error "GitHub CLI (gh) is not authenticated. Run 'gh auth login'"
        exit 1
    fi
    
    print_success "All dependencies satisfied"
}

# Clean build directories
clean_builds() {
    print_info "Cleaning previous builds..."
    
    cd "$REPO_ROOT"
    ./build.sh --clean
    
    print_success "Build directories cleaned"
}

# Build universal binaries
build_binaries() {
    print_info "Building universal binaries..."
    
    cd "$REPO_ROOT"
    
    # Build both implementations
    if [[ -n "$PDF21PNG_VERSION" ]]; then
        print_info "Building pdf21png v$PDF21PNG_VERSION..."
        ./build.sh --only-objc --release
    fi
    
    if [[ -n "$PDF22PNG_VERSION" ]]; then
        print_info "Building pdf22png v$PDF22PNG_VERSION..."
        ./build.sh --only-swift --release
    fi
    
    print_success "Binaries built successfully"
}

# Run tests
run_tests() {
    print_info "Running tests..."
    
    cd "$REPO_ROOT"
    ./test_both.sh
    
    print_success "All tests passed"
}

# Create release artifacts
create_artifacts() {
    print_info "Creating release artifacts..."
    
    local artifact_dir="$REPO_ROOT/release_artifacts"
    mkdir -p "$artifact_dir"
    
    # Package pdf21png
    if [[ -n "$PDF21PNG_VERSION" ]]; then
        local pdf21_binary="$REPO_ROOT/pdf21png/build/pdf21png"
        if [[ -f "$pdf21_binary" ]]; then
            local pdf21_archive="$artifact_dir/pdf21png-v${PDF21PNG_VERSION}-macos-universal.tar.gz"
            tar -czf "$pdf21_archive" -C "$(dirname "$pdf21_binary")" "$(basename "$pdf21_binary")"
            
            # Generate SHA256
            shasum -a 256 "$pdf21_archive" > "$pdf21_archive.sha256"
            
            print_success "Created pdf21png archive"
        fi
    fi
    
    # Package pdf22png
    if [[ -n "$PDF22PNG_VERSION" ]]; then
        local pdf22_binary="$REPO_ROOT/pdf22png/.build/apple/Products/Release/pdf22png"
        if [[ -f "$pdf22_binary" ]]; then
            local pdf22_archive="$artifact_dir/pdf22png-v${PDF22PNG_VERSION}-macos-universal.tar.gz"
            tar -czf "$pdf22_archive" -C "$(dirname "$pdf22_binary")" "$(basename "$pdf22_binary")"
            
            # Generate SHA256
            shasum -a 256 "$pdf22_archive" > "$pdf22_archive.sha256"
            
            print_success "Created pdf22png archive"
        fi
    fi
}

# Update Homebrew formulas
update_homebrew_formulas() {
    print_info "Updating Homebrew formulas..."
    
    # Update pdf21png formula
    if [[ -n "$PDF21PNG_VERSION" ]]; then
        local pdf21_archive="$REPO_ROOT/release_artifacts/pdf21png-v${PDF21PNG_VERSION}-macos-universal.tar.gz"
        if [[ -f "$pdf21_archive" ]]; then
            local sha256=$(shasum -a 256 "$pdf21_archive" | awk '{print $1}')
            local formula="$REPO_ROOT/homebrew/pdf21png.rb"
            
            # Update formula (this is a simplified version - real implementation would use sed or similar)
            print_info "Update $formula with:"
            print_info "  URL: https://github.com/$GITHUB_REPO/releases/download/v$PDF21PNG_VERSION/pdf21png-v${PDF21PNG_VERSION}-macos-universal.tar.gz"
            print_info "  SHA256: $sha256"
        fi
    fi
    
    # Update pdf22png formula
    if [[ -n "$PDF22PNG_VERSION" ]]; then
        local pdf22_archive="$REPO_ROOT/release_artifacts/pdf22png-v${PDF22PNG_VERSION}-macos-universal.tar.gz"
        if [[ -f "$pdf22_archive" ]]; then
            local sha256=$(shasum -a 256 "$pdf22_archive" | awk '{print $1}')
            local formula="$REPO_ROOT/homebrew/pdf22png.rb"
            
            print_info "Update $formula with:"
            print_info "  URL: https://github.com/$GITHUB_REPO/releases/download/v$PDF22PNG_VERSION/pdf22png-v${PDF22PNG_VERSION}-macos-universal.tar.gz"
            print_info "  SHA256: $sha256"
        fi
    fi
}

# Create GitHub release
create_github_release() {
    if [[ "$DRY_RUN" == true ]]; then
        print_info "DRY RUN: Would create GitHub release"
        return
    fi
    
    print_info "Creating GitHub release..."
    
    # Determine tag name
    local tag=""
    if [[ -n "$PDF21PNG_VERSION" && -n "$PDF22PNG_VERSION" ]]; then
        tag="v${PDF22PNG_VERSION}"  # Use pdf22png version as primary
    elif [[ -n "$PDF21PNG_VERSION" ]]; then
        tag="pdf21png-v${PDF21PNG_VERSION}"
    else
        tag="pdf22png-v${PDF22PNG_VERSION}"
    fi
    
    # Create release
    gh release create "$tag" \
        --title "Release $tag" \
        --notes "$RELEASE_NOTES" \
        release_artifacts/*.tar.gz
    
    print_success "GitHub release created: $tag"
}

# Main release process
main() {
    parse_args "$@"
    validate_inputs
    
    print_info "Starting release process..."
    print_info "pdf21png version: ${PDF21PNG_VERSION:-not releasing}"
    print_info "pdf22png version: ${PDF22PNG_VERSION:-not releasing}"
    print_info "Release notes: $RELEASE_NOTES"
    
    if [[ "$DRY_RUN" == true ]]; then
        print_info "Running in DRY RUN mode"
    fi
    
    # Execute release steps
    check_dependencies
    clean_builds
    build_binaries
    run_tests
    create_artifacts
    update_homebrew_formulas
    create_github_release
    
    print_success "Release process completed successfully!"
    
    # Cleanup
    if [[ "$DRY_RUN" == false ]]; then
        print_info "Remember to:"
        print_info "1. Push updated Homebrew formulas"
        print_info "2. Update the Homebrew tap"
        print_info "3. Test installation via Homebrew"
    fi
}

# Run main function
main "$@"