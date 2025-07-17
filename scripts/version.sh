#!/bin/bash

# Version management script for pdf22png
# Provides semver-compatible versioning based on git tags

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

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

usage() {
    cat << EOF
Usage: $0 [OPTIONS] [COMMAND]

Commands:
    get                    Get current version (default)
    set VERSION            Set version by creating a git tag
    bump [major|minor|patch]  Bump version by semantic level
    check                  Check if current commit is tagged
    changelog             Generate changelog since last tag
    validate VERSION      Validate semver format

Options:
    -s, --short           Short version format (no pre-release info)
    -f, --format FORMAT   Custom format string
    -h, --help            Show this help message

Format placeholders:
    {version}    - Full version (e.g., 1.2.3)
    {major}      - Major version number
    {minor}      - Minor version number  
    {patch}      - Patch version number
    {prerelease} - Pre-release info (e.g., dev.5+abc123)
    {build}      - Build metadata (e.g., abc123)
    {tag}        - Git tag (e.g., v1.2.3)

Examples:
    $0 get                    # Get current version
    $0 get --short            # Get version without pre-release
    $0 set 1.0.0              # Tag current commit as v1.0.0
    $0 bump patch             # Increment patch version
    $0 --format '{major}.{minor}.{patch}' get
EOF
}

# Parse semantic version
parse_semver() {
    local version="$1"
    
    # Remove 'v' prefix if present
    version="${version#v}"
    
    # Parse major.minor.patch
    if [[ "$version" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)(.*)$ ]]; then
        SEMVER_MAJOR="${BASH_REMATCH[1]}"
        SEMVER_MINOR="${BASH_REMATCH[2]}"
        SEMVER_PATCH="${BASH_REMATCH[3]}"
        SEMVER_PRERELEASE="${BASH_REMATCH[4]}"
        return 0
    else
        return 1
    fi
}

# Get current version from git
get_version() {
    local short_format=false
    local format=""
    
    # Parse options
    while [[ $# -gt 0 ]]; do
        case $1 in
            -s|--short)
                short_format=true
                shift
                ;;
            -f|--format)
                format="$2"
                shift 2
                ;;
            *)
                break
                ;;
        esac
    done
    
    # Get the latest tag
    local latest_tag
    if latest_tag=$(git describe --tags --abbrev=0 2>/dev/null); then
        # Parse the tag to get version components
        if parse_semver "$latest_tag"; then
            # Check if we're on the exact tag
            if git describe --exact-match --tags >/dev/null 2>&1; then
                # We're on a release tag
                local version="${SEMVER_MAJOR}.${SEMVER_MINOR}.${SEMVER_PATCH}"
                local prerelease=""
                local build=""
                local tag="$latest_tag"
            else
                # We're on a commit after the tag, add pre-release info
                local commits_since=$(git rev-list --count "$latest_tag"..HEAD)
                local short_sha=$(git rev-parse --short HEAD)
                local version="${SEMVER_MAJOR}.${SEMVER_MINOR}.${SEMVER_PATCH}"
                local prerelease="dev.${commits_since}"
                local build="$short_sha"
                local tag="$latest_tag"
            fi
        else
            print_error "Invalid semver format in tag: $latest_tag"
            return 1
        fi
    else
        # No tags found, use 0.0.0 with commit info
        local commits=$(git rev-list --count HEAD)
        local short_sha=$(git rev-parse --short HEAD)
        local version="0.0.0"
        local prerelease="dev.${commits}"
        local build="$short_sha"
        local tag=""
    fi
    
    # Format output
    if [[ -n "$format" ]]; then
        # Custom format
        local output="$format"
        output="${output//\{version\}/$version}"
        output="${output//\{major\}/$SEMVER_MAJOR}"
        output="${output//\{minor\}/$SEMVER_MINOR}"
        output="${output//\{patch\}/$SEMVER_PATCH}"
        output="${output//\{prerelease\}/$prerelease}"
        output="${output//\{build\}/$build}"
        output="${output//\{tag\}/$tag}"
        echo "$output"
    elif [[ "$short_format" == true ]]; then
        # Short format - just version
        echo "$version"
    else
        # Full format with pre-release info
        local full_version="$version"
        if [[ -n "$prerelease" ]]; then
            full_version="${full_version}-${prerelease}"
            if [[ -n "$build" ]]; then
                full_version="${full_version}+${build}"
            fi
        fi
        echo "$full_version"
    fi
}

# Validate semver format
validate_semver() {
    local version="$1"
    
    # Remove 'v' prefix if present
    version="${version#v}"
    
    # Check semver format
    if [[ "$version" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)(\-[0-9A-Za-z\-\.]+)?(\+[0-9A-Za-z\-\.]+)?$ ]]; then
        return 0
    else
        return 1
    fi
}

# Set version by creating a git tag
set_version() {
    local version="$1"
    
    # Validate version format
    if ! validate_semver "$version"; then
        print_error "Invalid semver format: $version"
        print_error "Expected format: MAJOR.MINOR.PATCH[-PRERELEASE][+BUILD]"
        return 1
    fi
    
    # Add 'v' prefix if not present
    if [[ "$version" != v* ]]; then
        version="v$version"
    fi
    
    # Check if tag already exists
    if git rev-parse "$version" >/dev/null 2>&1; then
        print_error "Tag $version already exists"
        return 1
    fi
    
    # Create annotated tag
    git tag -a "$version" -m "Release $version"
    
    print_success "Created tag $version"
    print_info "Don't forget to push the tag: git push origin $version"
}

# Bump version by semantic level
bump_version() {
    local level="$1"
    
    # Get current version
    local current_version
    if ! current_version=$(get_version --short); then
        print_error "Could not determine current version"
        return 1
    fi
    
    # Parse current version
    if ! parse_semver "$current_version"; then
        print_error "Could not parse current version: $current_version"
        return 1
    fi
    
    # Increment version based on level
    case "$level" in
        major)
            SEMVER_MAJOR=$((SEMVER_MAJOR + 1))
            SEMVER_MINOR=0
            SEMVER_PATCH=0
            ;;
        minor)
            SEMVER_MINOR=$((SEMVER_MINOR + 1))
            SEMVER_PATCH=0
            ;;
        patch)
            SEMVER_PATCH=$((SEMVER_PATCH + 1))
            ;;
        *)
            print_error "Invalid bump level: $level"
            print_error "Valid levels: major, minor, patch"
            return 1
            ;;
    esac
    
    local new_version="${SEMVER_MAJOR}.${SEMVER_MINOR}.${SEMVER_PATCH}"
    
    print_info "Bumping version from $current_version to $new_version"
    set_version "$new_version"
}

# Check if current commit is tagged
check_tagged() {
    if git describe --exact-match --tags >/dev/null 2>&1; then
        local tag=$(git describe --exact-match --tags)
        echo "true"
        return 0
    else
        echo "false"
        return 1
    fi
}

# Generate changelog since last tag
generate_changelog() {
    local latest_tag
    if latest_tag=$(git describe --tags --abbrev=0 2>/dev/null); then
        print_info "Changes since $latest_tag:"
        git log --oneline --no-merges "$latest_tag"..HEAD
    else
        print_info "Changes since beginning:"
        git log --oneline --no-merges
    fi
}

# Parse command line arguments
main() {
    local command="get"
    local short_format=false
    local format=""
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -s|--short)
                short_format=true
                shift
                ;;
            -f|--format)
                format="$2"
                shift 2
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            get|set|bump|check|changelog|validate)
                command="$1"
                shift
                break
                ;;
            *)
                print_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
    
    # Execute command
    case "$command" in
        get)
            if [[ "$short_format" == true ]]; then
                get_version --short
            elif [[ -n "$format" ]]; then
                get_version --format "$format"
            else
                get_version
            fi
            ;;
        set)
            if [[ $# -eq 0 ]]; then
                print_error "Version required for set command"
                usage
                exit 1
            fi
            set_version "$1"
            ;;
        bump)
            if [[ $# -eq 0 ]]; then
                print_error "Bump level required (major|minor|patch)"
                usage
                exit 1
            fi
            bump_version "$1"
            ;;
        check)
            check_tagged
            ;;
        changelog)
            generate_changelog
            ;;
        validate)
            if [[ $# -eq 0 ]]; then
                print_error "Version required for validate command"
                usage
                exit 1
            fi
            if validate_semver "$1"; then
                print_success "Valid semver format: $1"
            else
                print_error "Invalid semver format: $1"
                exit 1
            fi
            ;;
        *)
            print_error "Unknown command: $command"
            usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"