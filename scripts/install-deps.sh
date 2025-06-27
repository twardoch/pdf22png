#!/usr/bin/env bash
# PDF22PNG Dependency Installation Script
# Ensures all required dependencies are installed for building pdf21png and pdf22png

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Platform detection
PLATFORM="$(uname -s)"
ARCH="$(uname -m)"

# Print colored output
print_error() {
    echo -e "${RED}ERROR: $1${NC}" >&2
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_info() {
    echo -e "${BLUE}→ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Check if running on macOS
check_macos() {
    if [[ "$PLATFORM" != "Darwin" ]]; then
        print_error "This script is designed for macOS only"
        print_info "Detected platform: $PLATFORM"
        exit 1
    fi
    print_success "Running on macOS"
}

# Check macOS version
check_macos_version() {
    local os_version=$(sw_vers -productVersion)
    local major_version=$(echo "$os_version" | cut -d. -f1)
    local minor_version=$(echo "$os_version" | cut -d. -f2)
    
    print_info "macOS version: $os_version"
    
    # pdf21png requires macOS 10.15+
    if [[ $major_version -lt 10 ]] || ([[ $major_version -eq 10 ]] && [[ $minor_version -lt 15 ]]); then
        print_warning "pdf21png requires macOS 10.15 or later"
    fi
    
    # pdf22png requires macOS 11.0+
    if [[ $major_version -lt 11 ]]; then
        print_warning "pdf22png (Swift) requires macOS 11.0 or later"
    fi
}

# Check for Xcode Command Line Tools
check_xcode_clt() {
    print_info "Checking for Xcode Command Line Tools..."
    
    if xcode-select -p &> /dev/null; then
        local clt_path=$(xcode-select -p)
        print_success "Xcode Command Line Tools installed at: $clt_path"
        return 0
    else
        print_warning "Xcode Command Line Tools not found"
        return 1
    fi
}

# Install Xcode Command Line Tools
install_xcode_clt() {
    print_info "Installing Xcode Command Line Tools..."
    print_info "This will open a dialog window. Please follow the installation prompts."
    
    # Trigger the installation
    xcode-select --install &> /dev/null || true
    
    # Wait for installation
    print_info "Waiting for installation to complete..."
    print_info "Press Enter once the installation is finished..."
    read -r
    
    # Verify installation
    if check_xcode_clt; then
        print_success "Xcode Command Line Tools installed successfully"
    else
        print_error "Failed to install Xcode Command Line Tools"
        exit 1
    fi
}

# Check for specific command
check_command() {
    local cmd=$1
    local name=${2:-$cmd}
    
    if command -v "$cmd" &> /dev/null; then
        local version=$($cmd --version 2>&1 | head -n1 || echo "version unknown")
        print_success "$name found: $version"
        return 0
    else
        print_warning "$name not found"
        return 1
    fi
}

# Check for Homebrew
check_homebrew() {
    print_info "Checking for Homebrew..."
    
    if command -v brew &> /dev/null; then
        local brew_version=$(brew --version | head -n1)
        print_success "Homebrew found: $brew_version"
        return 0
    else
        print_warning "Homebrew not found"
        print_info "While not required, Homebrew makes installation easier"
        print_info "Install Homebrew from: https://brew.sh"
        return 1
    fi
}

# Check build dependencies
check_build_deps() {
    print_info "Checking build dependencies..."
    
    local all_good=true
    
    # Check for make
    if ! check_command "make" "Make"; then
        all_good=false
    fi
    
    # Check for git
    if ! check_command "git" "Git"; then
        all_good=false
    fi
    
    # Check for clang (for Objective-C)
    if ! check_command "clang" "Clang compiler"; then
        all_good=false
    fi
    
    # Check for swift
    if ! check_command "swift" "Swift compiler"; then
        all_good=false
    fi
    
    # Check for swift-format (optional)
    if ! check_command "swift-format" "swift-format" 2>/dev/null; then
        print_info "swift-format is optional but recommended for development"
    fi
    
    # Check for swiftlint (optional)
    if ! check_command "swiftlint" "SwiftLint" 2>/dev/null; then
        print_info "SwiftLint is optional but recommended for development"
    fi
    
    if [[ "$all_good" == true ]]; then
        print_success "All required build dependencies are installed"
    else
        print_error "Some build dependencies are missing"
        return 1
    fi
}

# Install optional tools via Homebrew
install_optional_tools() {
    if ! command -v brew &> /dev/null; then
        return
    fi
    
    echo ""
    print_info "Optional development tools can be installed via Homebrew:"
    echo "  • swift-format - Code formatting for Swift"
    echo "  • swiftlint - Linting for Swift code"
    echo "  • gh - GitHub CLI for releases"
    echo ""
    
    read -p "Install optional development tools? [y/N] " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Installing optional tools..."
        
        # Install swift-format
        if ! command -v swift-format &> /dev/null; then
            brew install swift-format || print_warning "Failed to install swift-format"
        fi
        
        # Install swiftlint
        if ! command -v swiftlint &> /dev/null; then
            brew install swiftlint || print_warning "Failed to install swiftlint"
        fi
        
        # Install GitHub CLI
        if ! command -v gh &> /dev/null; then
            brew install gh || print_warning "Failed to install GitHub CLI"
        fi
        
        print_success "Optional tools installation complete"
    fi
}

# Main dependency check
main() {
    echo ""
    echo "PDF22PNG Dependency Checker"
    echo "=========================="
    echo ""
    
    # Check platform
    check_macos
    check_macos_version
    
    echo ""
    
    # Check for Xcode CLT
    if ! check_xcode_clt; then
        echo ""
        read -p "Install Xcode Command Line Tools? [Y/n] " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            install_xcode_clt
        else
            print_error "Xcode Command Line Tools are required to build pdf22png"
            exit 1
        fi
    fi
    
    echo ""
    
    # Check for Homebrew (optional)
    check_homebrew
    
    echo ""
    
    # Check build dependencies
    if check_build_deps; then
        echo ""
        print_success "All required dependencies are satisfied!"
        
        # Offer to install optional tools
        install_optional_tools
        
        echo ""
        print_info "You're ready to build pdf22png!"
        print_info "Run 'make' in the project root to build both tools"
    else
        echo ""
        print_error "Missing dependencies detected"
        print_info "Install Xcode Command Line Tools to get all required dependencies"
        exit 1
    fi
}

# Show usage if --help is passed
if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
    echo "PDF22PNG Dependency Installation Script"
    echo ""
    echo "Usage: $0"
    echo ""
    echo "This script checks for and helps install required dependencies:"
    echo "  • Xcode Command Line Tools (required)"
    echo "  • Clang compiler (for pdf21png)"
    echo "  • Swift compiler (for pdf22png)"
    echo "  • Make and Git (for building)"
    echo ""
    echo "Optional tools (via Homebrew):"
    echo "  • swift-format - Code formatting"
    echo "  • swiftlint - Code linting"
    echo "  • gh - GitHub CLI"
    exit 0
fi

# Run main function
main