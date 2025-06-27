#!/bin/bash

# Setup script for creating the Homebrew tap repository
# This prepares the tap structure for twardoch/homebrew-pdf22png

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
TAP_NAME="twardoch/homebrew-pdf22png"
TAP_REPO="homebrew-pdf22png"

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

# Main setup function
setup_tap() {
    echo ""
    echo "Homebrew Tap Setup"
    echo "=================="
    echo ""
    echo "This script will help you set up the Homebrew tap: $TAP_NAME"
    echo ""
    
    print_info "Step 1: Create the tap repository on GitHub"
    echo ""
    echo "1. Go to: https://github.com/new"
    echo "2. Repository name: $TAP_REPO"
    echo "3. Description: 'Homebrew tap for pdf22png - PDF to PNG converter for macOS'"
    echo "4. Public repository"
    echo "5. Initialize with README"
    echo ""
    read -p "Press Enter when you've created the repository..."
    
    print_info "Step 2: Clone the tap repository"
    echo ""
    echo "Run these commands in a separate terminal:"
    echo ""
    echo "  cd ~/Developer  # or your preferred directory"
    echo "  git clone https://github.com/twardoch/$TAP_REPO.git"
    echo "  cd $TAP_REPO"
    echo ""
    read -p "Press Enter when you've cloned the repository..."
    
    print_info "Step 3: Generating tap structure..."
    
    # Create temporary directory for tap files
    local TEMP_TAP="$PROJECT_ROOT/build/homebrew-tap"
    rm -rf "$TEMP_TAP"
    mkdir -p "$TEMP_TAP/Formula"
    
    # Copy formulas
    cp "$PROJECT_ROOT/homebrew/pdf21png.rb" "$TEMP_TAP/Formula/"
    cp "$PROJECT_ROOT/homebrew/pdf22png.rb" "$TEMP_TAP/Formula/"
    
    # Create README for the tap
    cat > "$TEMP_TAP/README.md" << 'EOF'
# homebrew-pdf22png

Homebrew tap for [pdf22png](https://github.com/twardoch/pdf22png) - PDF to PNG converter for macOS.

## Installation

```bash
# Add the tap
brew tap twardoch/pdf22png

# Install the modern Swift version (recommended)
brew install twardoch/pdf22png/pdf22png

# Or install the performance-optimized Objective-C version
brew install twardoch/pdf22png/pdf21png
```

## Available Formulas

- **pdf22png**: Modern Swift implementation with advanced features
- **pdf21png**: High-performance Objective-C implementation

## Usage

After installation, the tools will be available in your PATH:

```bash
# Convert a PDF to PNG
pdf22png input.pdf output.png

# Or use the Objective-C version
pdf21png input.pdf output.png

# See all options
pdf22png --help
pdf21png --help
```

## Updating

```bash
brew update
brew upgrade pdf22png
brew upgrade pdf21png
```

## Uninstalling

```bash
brew uninstall pdf22png
brew uninstall pdf21png
brew untap twardoch/pdf22png
```

## License

The formulas in this tap are MIT licensed. The pdf22png tools themselves are also MIT licensed.
EOF
    
    # Create .gitignore
    cat > "$TEMP_TAP/.gitignore" << 'EOF'
.DS_Store
*.swp
*~
EOF
    
    print_success "Tap structure created in: $TEMP_TAP"
    echo ""
    print_info "Step 4: Copy files to your tap repository"
    echo ""
    echo "Copy all files from $TEMP_TAP to your cloned repository:"
    echo ""
    echo "  cp -r $TEMP_TAP/* ~/Developer/$TAP_REPO/"
    echo "  cd ~/Developer/$TAP_REPO"
    echo "  git add ."
    echo "  git commit -m 'Initial tap setup with pdf21png and pdf22png formulas'"
    echo "  git push"
    echo ""
    read -p "Press Enter when you've pushed the tap repository..."
    
    print_info "Step 5: Test the tap"
    echo ""
    echo "Run these commands to test:"
    echo ""
    echo "  # Remove any existing tap"
    echo "  brew untap $TAP_NAME 2>/dev/null || true"
    echo ""
    echo "  # Add your new tap"
    echo "  brew tap $TAP_NAME"
    echo ""
    echo "  # Check that formulas are available"
    echo "  brew search twardoch/pdf22png/"
    echo ""
    
    print_success "Tap setup complete!"
    echo ""
    print_info "Next steps:"
    echo "1. Run ./release.sh to create the first release"
    echo "2. The release script will automatically update the formulas"
    echo "3. Users can then install with: brew install $TAP_NAME/pdf22png"
    echo ""
}

# Parse arguments
if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
    echo "Homebrew Tap Setup Script"
    echo ""
    echo "Usage: $0"
    echo ""
    echo "This script guides you through setting up a Homebrew tap for pdf22png."
    echo "It will help you create the repository structure and test the tap."
    exit 0
fi

# Run setup
setup_tap