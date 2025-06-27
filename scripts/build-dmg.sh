#!/bin/bash

# Build macOS .dmg disk image for pdf22png
# Creates a disk image with both binaries and documentation

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
BUILD_DIR="$PROJECT_ROOT/build/dmg"
DIST_DIR="$PROJECT_ROOT/dist"
VERSION=$("$SCRIPT_DIR/get-version.sh")
DMG_NAME="pdf22png-${VERSION}.dmg"
VOLUME_NAME="PDF to PNG Converter"

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

# Clean and create directories
setup_directories() {
    print_info "Setting up build directories..."
    
    rm -rf "$BUILD_DIR"
    mkdir -p "$BUILD_DIR/content"
    mkdir -p "$DIST_DIR"
    
    print_success "Directories created"
}

# Build binaries if needed
build_binaries() {
    print_info "Building binaries..."
    
    cd "$PROJECT_ROOT"
    
    if [ ! -f "pdf21png/build/pdf21png" ] || [ ! -f "pdf22png/.build/apple/Products/Release/pdf22png" ]; then
        print_info "Binaries not found, building..."
        make clean
        make universal
    else
        print_info "Using existing binaries"
    fi
    
    print_success "Binaries ready"
}

# Prepare DMG contents
prepare_contents() {
    print_info "Preparing DMG contents..."
    
    local CONTENT_DIR="$BUILD_DIR/content"
    
    # Create Applications symlink
    ln -s /Applications "$CONTENT_DIR/Applications"
    
    # Create bin directory
    mkdir -p "$CONTENT_DIR/bin"
    
    # Copy binaries
    # Copy pdf21png (check universal build location first)
    if [ -f "$PROJECT_ROOT/pdf21png/build/pdf21png-universal" ]; then
        cp "$PROJECT_ROOT/pdf21png/build/pdf21png-universal" "$CONTENT_DIR/bin/pdf21png"
        chmod 755 "$CONTENT_DIR/bin/pdf21png"
        print_success "Copied pdf21png (universal)"
    elif [ -f "$PROJECT_ROOT/pdf21png/build/pdf21png" ]; then
        cp "$PROJECT_ROOT/pdf21png/build/pdf21png" "$CONTENT_DIR/bin/"
        chmod 755 "$CONTENT_DIR/bin/pdf21png"
        print_success "Copied pdf21png"
    fi
    
    # Copy pdf22png (try multiple possible locations)
    if [ -f "$PROJECT_ROOT/pdf22png/build/pdf22png" ]; then
        cp "$PROJECT_ROOT/pdf22png/build/pdf22png" "$CONTENT_DIR/bin/"
    elif [ -f "$PROJECT_ROOT/pdf22png/.build/apple/Products/Release/pdf22png" ]; then
        cp "$PROJECT_ROOT/pdf22png/.build/apple/Products/Release/pdf22png" "$CONTENT_DIR/bin/"
    elif [ -f "$PROJECT_ROOT/pdf22png/.build/release/pdf22png" ]; then
        cp "$PROJECT_ROOT/pdf22png/.build/release/pdf22png" "$CONTENT_DIR/bin/"
    fi
    chmod 755 "$CONTENT_DIR/bin/pdf22png"
    print_success "Copied pdf22png"
    
    # Copy documentation
    cp "$PROJECT_ROOT/README.md" "$CONTENT_DIR/"
    cp "$PROJECT_ROOT/LICENSE" "$CONTENT_DIR/" 2>/dev/null || echo "No LICENSE file found"
    
    # Create install script
    cat > "$CONTENT_DIR/Install Command Line Tools.command" << 'EOF'
#!/bin/bash

# Installation script for PDF to PNG Converter

echo "PDF to PNG Converter Installation"
echo "================================="
echo ""
echo "This script will install pdf21png and pdf22png to /usr/local/bin"
echo ""

# Check if running with proper permissions
if [ "$EUID" -ne 0 ]; then
    echo "Please enter your password to install the tools:"
    sudo "$0" "$@"
    exit $?
fi

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Create /usr/local/bin if it doesn't exist
mkdir -p /usr/local/bin

# Copy binaries
echo "Installing pdf21png..."
cp "$SCRIPT_DIR/bin/pdf21png" /usr/local/bin/
chmod 755 /usr/local/bin/pdf21png

echo "Installing pdf22png..."
cp "$SCRIPT_DIR/bin/pdf22png" /usr/local/bin/
chmod 755 /usr/local/bin/pdf22png

echo ""
echo "✓ Installation complete!"
echo ""
echo "The following tools have been installed:"
echo "  • pdf21png - High-performance Objective-C implementation"
echo "  • pdf22png - Modern Swift implementation"
echo ""
echo "To verify installation, open a new Terminal window and run:"
echo "  pdf21png --version"
echo "  pdf22png --version"
echo ""
echo "Press Enter to close this window..."
read -r
EOF
    
    chmod +x "$CONTENT_DIR/Install Command Line Tools.command"
    
    # Create uninstall script
    cat > "$CONTENT_DIR/Uninstall Command Line Tools.command" << 'EOF'
#!/bin/bash

# Uninstallation script for PDF to PNG Converter

echo "PDF to PNG Converter Uninstallation"
echo "===================================="
echo ""
echo "This script will remove pdf21png and pdf22png from /usr/local/bin"
echo ""

# Check if running with proper permissions
if [ "$EUID" -ne 0 ]; then
    echo "Please enter your password to uninstall the tools:"
    sudo "$0" "$@"
    exit $?
fi

# Remove binaries
echo "Removing pdf21png..."
rm -f /usr/local/bin/pdf21png

echo "Removing pdf22png..."
rm -f /usr/local/bin/pdf22png

echo ""
echo "✓ Uninstallation complete!"
echo ""
echo "Press Enter to close this window..."
read -r
EOF
    
    chmod +x "$CONTENT_DIR/Uninstall Command Line Tools.command"
    
    # Create background directory (placeholder for real image)
    mkdir -p "$CONTENT_DIR/.background"
    # In a real scenario, you'd copy a designed background image here
    # touch "$CONTENT_DIR/.background/background.png"
    
    print_success "Prepared DMG contents"
}

# Create the DMG
create_dmg() {
    print_info "Creating DMG..."
    
    # Create temporary DMG
    local TEMP_DMG="$BUILD_DIR/temp.dmg"
    
    # Calculate size (add 50% buffer for better compatibility)
    local SIZE=$(du -sm "$BUILD_DIR/content" | cut -f1)
    local DMG_SIZE=$((SIZE * 150 / 100))
    
    # Ensure minimum size of 10MB
    if [ "$DMG_SIZE" -lt 10 ]; then
        DMG_SIZE=10
    fi
    
    # Create DMG
    hdiutil create \
        -volname "$VOLUME_NAME" \
        -srcfolder "$BUILD_DIR/content" \
        -ov \
        -format UDZO \
        -size ${DMG_SIZE}m \
        "$DIST_DIR/$DMG_NAME"
    
    print_success "Created DMG: $DMG_NAME"
}

# Create a styled DMG with custom layout (optional, requires create-dmg tool)
create_styled_dmg() {
    print_info "Checking for create-dmg tool..."
    
    if command -v create-dmg >/dev/null 2>&1; then
        print_info "Using create-dmg for styled disk image..."
        
        create-dmg \
            --volname "$VOLUME_NAME" \
            --volicon "$PROJECT_ROOT/assets/VolumeIcon.icns" \
            --background "$PROJECT_ROOT/assets/DMGBackground.png" \
            --window-pos 200 120 \
            --window-size 600 400 \
            --icon-size 100 \
            --icon "bin" 150 200 \
            --icon "Install Command Line Tools.command" 300 200 \
            --icon "Applications" 450 200 \
            --hide-extension "Install Command Line Tools.command" \
            --hide-extension "Uninstall Command Line Tools.command" \
            --app-drop-link 450 200 \
            "$DIST_DIR/$DMG_NAME" \
            "$BUILD_DIR/content"
        
        print_success "Created styled DMG"
    else
        print_warning "create-dmg not found, creating basic DMG"
        print_info "Install with: brew install create-dmg"
        create_dmg
    fi
}

# Verify the DMG
verify_dmg() {
    print_info "Verifying DMG..."
    
    # Verify DMG
    if hdiutil verify "$DIST_DIR/$DMG_NAME" >/dev/null 2>&1; then
        print_success "DMG verification passed"
    else
        print_error "DMG verification failed"
        exit 1
    fi
    
    # Get DMG info
    print_info "DMG contents:"
    hdiutil imageinfo "$DIST_DIR/$DMG_NAME" | grep -E "(Format:|Size:|Compressed:|Checksum:)" || true
    
    print_success "DMG verification complete"
}

# Main execution
main() {
    echo ""
    echo "PDF22PNG DMG Builder"
    echo "===================="
    echo "Version: $VERSION"
    echo ""
    
    setup_directories
    build_binaries
    prepare_contents
    
    # Try styled DMG first, fallback to basic
    if command -v create-dmg >/dev/null 2>&1; then
        create_styled_dmg
    else
        create_dmg
    fi
    
    verify_dmg
    
    echo ""
    print_success "DMG built successfully!"
    echo ""
    echo "DMG location: $DIST_DIR/$DMG_NAME"
    echo "Size: $(du -h "$DIST_DIR/$DMG_NAME" | cut -f1)"
    echo ""
    echo "To mount: hdiutil attach \"$DIST_DIR/$DMG_NAME\""
}

# Parse arguments
if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
    echo "PDF22PNG DMG Builder"
    echo ""
    echo "Usage: $0"
    echo ""
    echo "Creates a disk image containing:"
    echo "  • pdf21png and pdf22png binaries"
    echo "  • Installation and uninstallation scripts"
    echo "  • Documentation"
    echo ""
    echo "For styled DMG with custom background:"
    echo "  brew install create-dmg"
    exit 0
fi

# Run main
main