#!/bin/bash

# Multi-platform release script for pdf22png
# Creates release artifacts for multiple platforms and architectures

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
MULTIPLATFORM_DIR="$PROJECT_ROOT/multiplatform"
ARTIFACTS_DIR="$PROJECT_ROOT/artifacts"

# Platform configuration
declare -A PLATFORMS=(
    ["macos-x86_64"]="x86_64-apple-macos"
    ["macos-arm64"]="arm64-apple-macos"
    ["macos-universal"]="universal-apple-macos"
)

# Build options
VERSION=""
CLEAN_BUILD=false
VERBOSE=false
DRY_RUN=false
PLATFORMS_TO_BUILD=""

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
Usage: $0 [OPTIONS]

Options:
    -v, --version VERSION     Release version (required)
    -p, --platforms PLATFORMS Comma-separated list of platforms to build
                             Available: macos-x86_64, macos-arm64, macos-universal
                             Default: macos-universal
    -c, --clean              Clean build artifacts before building
    --verbose                Verbose output
    --dry-run                Dry run mode (no actual changes)
    -h, --help               Show this help message

Examples:
    $0 --version 1.0.0
    $0 --version 1.0.0 --platforms macos-x86_64,macos-arm64
    $0 --version 1.0.0 --clean --verbose
EOF
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -v|--version)
                VERSION="$2"
                shift 2
                ;;
            -p|--platforms)
                PLATFORMS_TO_BUILD="$2"
                shift 2
                ;;
            -c|--clean)
                CLEAN_BUILD=true
                shift
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            --dry-run)
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
    
    # Validate required options
    if [[ -z "$VERSION" ]]; then
        print_error "Version is required"
        usage
        exit 1
    fi
    
    # Set default platforms
    if [[ -z "$PLATFORMS_TO_BUILD" ]]; then
        PLATFORMS_TO_BUILD="macos-universal"
    fi
}

# Setup environment
setup_environment() {
    print_info "Setting up multiplatform build environment..."
    
    cd "$PROJECT_ROOT"
    
    # Clean artifacts if requested
    if [[ "$CLEAN_BUILD" == true ]]; then
        print_info "Cleaning build artifacts..."
        make clean
        rm -rf "$MULTIPLATFORM_DIR" "$ARTIFACTS_DIR"
    fi
    
    # Create directories
    mkdir -p "$MULTIPLATFORM_DIR" "$ARTIFACTS_DIR"
    
    # Validate version format
    if ! ./scripts/version.sh validate "$VERSION"; then
        print_error "Invalid version format: $VERSION"
        exit 1
    fi
    
    print_success "Environment setup complete"
}

# Build for specific platform
build_platform() {
    local platform="$1"
    local target="${PLATFORMS[$platform]}"
    
    print_info "Building for platform: $platform ($target)"
    
    local platform_dir="$MULTIPLATFORM_DIR/$platform"
    mkdir -p "$platform_dir"
    
    case "$platform" in
        macos-x86_64)
            build_macos_x86_64 "$platform_dir"
            ;;
        macos-arm64)
            build_macos_arm64 "$platform_dir"
            ;;
        macos-universal)
            build_macos_universal "$platform_dir"
            ;;
        *)
            print_error "Unsupported platform: $platform"
            return 1
            ;;
    esac
    
    print_success "Built for platform: $platform"
}

# Build for macOS x86_64
build_macos_x86_64() {
    local output_dir="$1"
    
    print_info "Building macOS x86_64 binaries..."
    
    # Set architecture-specific flags
    export CFLAGS="-arch x86_64"
    export CXXFLAGS="-arch x86_64"
    export LDFLAGS="-arch x86_64"
    
    # Build pdf21png
    if [[ "$VERBOSE" == true ]]; then
        make pdf21png
    else
        make pdf21png >/dev/null 2>&1
    fi
    
    # Copy binary
    cp "pdf21png/build/pdf21png" "$output_dir/pdf21png"
    
    # Build pdf22png
    cd pdf22png
    if [[ "$VERBOSE" == true ]]; then
        swift build -c release --arch x86_64
    else
        swift build -c release --arch x86_64 >/dev/null 2>&1
    fi
    
    # Copy binary
    cp ".build/release/pdf22png" "$output_dir/pdf22png"
    
    cd ..
    
    # Clean up environment
    unset CFLAGS CXXFLAGS LDFLAGS
}

# Build for macOS ARM64
build_macos_arm64() {
    local output_dir="$1"
    
    print_info "Building macOS ARM64 binaries..."
    
    # Set architecture-specific flags
    export CFLAGS="-arch arm64"
    export CXXFLAGS="-arch arm64"
    export LDFLAGS="-arch arm64"
    
    # Build pdf21png
    if [[ "$VERBOSE" == true ]]; then
        make pdf21png
    else
        make pdf21png >/dev/null 2>&1
    fi
    
    # Copy binary
    cp "pdf21png/build/pdf21png" "$output_dir/pdf21png"
    
    # Build pdf22png
    cd pdf22png
    if [[ "$VERBOSE" == true ]]; then
        swift build -c release --arch arm64
    else
        swift build -c release --arch arm64 >/dev/null 2>&1
    fi
    
    # Copy binary
    cp ".build/release/pdf22png" "$output_dir/pdf22png"
    
    cd ..
    
    # Clean up environment
    unset CFLAGS CXXFLAGS LDFLAGS
}

# Build for macOS Universal
build_macos_universal() {
    local output_dir="$1"
    
    print_info "Building macOS Universal binaries..."
    
    # Use the existing universal build targets
    if [[ "$VERBOSE" == true ]]; then
        make universal
    else
        make universal >/dev/null 2>&1
    fi
    
    # Copy binaries
    cp "pdf21png/build/pdf21png" "$output_dir/pdf21png"
    
    # Find Swift binary (try both possible locations)
    if [[ -f "pdf22png/.build/apple/Products/Release/pdf22png" ]]; then
        cp "pdf22png/.build/apple/Products/Release/pdf22png" "$output_dir/pdf22png"
    elif [[ -f "pdf22png/.build/release/pdf22png" ]]; then
        cp "pdf22png/.build/release/pdf22png" "$output_dir/pdf22png"
    else
        print_error "Swift binary not found"
        return 1
    fi
}

# Create platform-specific archives
create_platform_archives() {
    print_info "Creating platform-specific archives..."
    
    local platforms_array
    IFS=',' read -ra platforms_array <<< "$PLATFORMS_TO_BUILD"
    
    for platform in "${platforms_array[@]}"; do
        local platform_dir="$MULTIPLATFORM_DIR/$platform"
        
        if [[ ! -d "$platform_dir" ]]; then
            print_warning "Platform directory not found: $platform_dir"
            continue
        fi
        
        print_info "Creating archive for $platform..."
        
        # Create individual archives for each tool
        for tool in pdf21png pdf22png; do
            if [[ -f "$platform_dir/$tool" ]]; then
                local archive="$ARTIFACTS_DIR/${tool}-v${VERSION}-${platform}.tar.gz"
                
                if [[ "$DRY_RUN" == true ]]; then
                    print_info "DRY RUN: Would create $archive"
                else
                    tar -czf "$archive" -C "$platform_dir" "$tool"
                    
                    # Generate checksum
                    if command -v shasum >/dev/null 2>&1; then
                        shasum -a 256 "$archive" > "$archive.sha256"
                    fi
                    
                    print_success "Created $archive"
                fi
            fi
        done
        
        # Create combined archive
        local combined_archive="$ARTIFACTS_DIR/pdf22png-tools-v${VERSION}-${platform}.tar.gz"
        
        if [[ "$DRY_RUN" == true ]]; then
            print_info "DRY RUN: Would create $combined_archive"
        else
            tar -czf "$combined_archive" -C "$platform_dir" .
            
            # Generate checksum
            if command -v shasum >/dev/null 2>&1; then
                shasum -a 256 "$combined_archive" > "$combined_archive.sha256"
            fi
            
            print_success "Created $combined_archive"
        fi
    done
}

# Generate release metadata
generate_release_metadata() {
    print_info "Generating release metadata..."
    
    local metadata_file="$ARTIFACTS_DIR/release-metadata.json"
    local build_date=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local git_commit=$(git rev-parse HEAD)
    local git_tag=$(git describe --tags --exact-match 2>/dev/null || echo "none")
    
    cat > "$metadata_file" << EOF
{
  "version": "$VERSION",
  "build_date": "$build_date",
  "git_commit": "$git_commit",
  "git_tag": "$git_tag",
  "platforms": [
$(IFS=','; for platform in $PLATFORMS_TO_BUILD; do echo "    \"$platform\""; done | sed '$!s/$/,/')
  ],
  "artifacts": [
$(find "$ARTIFACTS_DIR" -name "*.tar.gz" -exec basename {} \; | sed 's/^/    "/' | sed 's/$/"/' | sed '$!s/$/,/')
  ]
}
EOF
    
    print_success "Generated release metadata"
}

# Print summary
print_summary() {
    print_header "MULTIPLATFORM RELEASE SUMMARY"
    
    echo "Version: $VERSION"
    echo "Build Date: $(date -u +"%Y-%m-%d %H:%M:%S UTC")"
    echo "Git Commit: $(git rev-parse --short HEAD)"
    echo "Platforms: $PLATFORMS_TO_BUILD"
    echo ""
    
    if [[ -d "$ARTIFACTS_DIR" ]]; then
        echo "Artifacts created:"
        ls -la "$ARTIFACTS_DIR" | grep -E '\.(tar\.gz|sha256|json)$' | awk '{print "  " $9 " (" $5 " bytes)"}'
    fi
    
    echo ""
    print_success "Multiplatform release completed successfully"
}

# Main execution
main() {
    parse_args "$@"
    
    print_header "PDF22PNG MULTIPLATFORM RELEASE"
    
    setup_environment
    
    # Build for each platform
    local platforms_array
    IFS=',' read -ra platforms_array <<< "$PLATFORMS_TO_BUILD"
    
    for platform in "${platforms_array[@]}"; do
        if [[ -n "${PLATFORMS[$platform]:-}" ]]; then
            build_platform "$platform"
        else
            print_error "Unknown platform: $platform"
            exit 1
        fi
    done
    
    # Create archives
    create_platform_archives
    
    # Generate metadata
    generate_release_metadata
    
    print_summary
}

# Run main function
main "$@"