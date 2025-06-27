#!/bin/bash

# Build macOS .pkg installer for pdf22png
# Creates a package that installs both pdf21png and pdf22png to /usr/local/bin

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
BUILD_DIR="$PROJECT_ROOT/build/pkg"
DIST_DIR="$PROJECT_ROOT/dist"
VERSION=$("$SCRIPT_DIR/get-version.sh")
PKG_NAME="pdf22png-${VERSION}.pkg"
IDENTIFIER="com.twardoch.pdf22png"
INSTALL_LOCATION="/usr/local/bin"

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
    mkdir -p "$BUILD_DIR/root$INSTALL_LOCATION"
    mkdir -p "$BUILD_DIR/scripts"
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

# Copy binaries to package root
copy_binaries() {
    print_info "Copying binaries to package root..."
    
    # Copy pdf21png
    if [ -f "$PROJECT_ROOT/pdf21png/build/pdf21png" ]; then
        cp "$PROJECT_ROOT/pdf21png/build/pdf21png" "$BUILD_DIR/root$INSTALL_LOCATION/"
        chmod 755 "$BUILD_DIR/root$INSTALL_LOCATION/pdf21png"
        print_success "Copied pdf21png"
    else
        print_error "pdf21png binary not found"
        exit 1
    fi
    
    # Copy pdf22png (try both possible locations)
    if [ -f "$PROJECT_ROOT/pdf22png/.build/apple/Products/Release/pdf22png" ]; then
        cp "$PROJECT_ROOT/pdf22png/.build/apple/Products/Release/pdf22png" "$BUILD_DIR/root$INSTALL_LOCATION/"
    elif [ -f "$PROJECT_ROOT/pdf22png/.build/release/pdf22png" ]; then
        cp "$PROJECT_ROOT/pdf22png/.build/release/pdf22png" "$BUILD_DIR/root$INSTALL_LOCATION/"
    else
        print_error "pdf22png binary not found"
        exit 1
    fi
    
    chmod 755 "$BUILD_DIR/root$INSTALL_LOCATION/pdf22png"
    print_success "Copied pdf22png"
}

# Create pre/post install scripts
create_scripts() {
    print_info "Creating installer scripts..."
    
    # Create postinstall script
    cat > "$BUILD_DIR/scripts/postinstall" << 'EOF'
#!/bin/bash

# Post-installation script for pdf22png

echo "PDF22PNG has been installed successfully!"
echo ""
echo "Two tools are now available:"
echo "  • pdf21png - High-performance Objective-C implementation"
echo "  • pdf22png - Modern Swift implementation with advanced features"
echo ""
echo "To get started:"
echo "  pdf21png --help"
echo "  pdf22png --help"
echo ""
echo "For more information, visit: https://github.com/twardoch/pdf22png"

exit 0
EOF
    
    chmod 755 "$BUILD_DIR/scripts/postinstall"
    print_success "Created installer scripts"
}

# Build the package
build_package() {
    print_info "Building package..."
    
    # Create component package
    pkgbuild \
        --root "$BUILD_DIR/root" \
        --identifier "$IDENTIFIER" \
        --version "$VERSION" \
        --scripts "$BUILD_DIR/scripts" \
        --install-location "/" \
        "$BUILD_DIR/pdf22png-component.pkg"
    
    print_success "Built component package"
    
    # Create distribution XML
    cat > "$BUILD_DIR/distribution.xml" << EOF
<?xml version="1.0" encoding="utf-8"?>
<installer-gui-script minSpecVersion="2.0">
    <title>PDF to PNG Converter</title>
    <organization>com.twardoch</organization>
    <domains enable_anywhere="false" enable_currentUserHome="false" enable_localSystem="true"/>
    <options customize="never" require-scripts="true" rootVolumeOnly="true"/>
    <license language="en" mime-type="text/plain">MIT License

Copyright (c) $(date +%Y) Adam Twardoch

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.</license>
    <welcome language="en" mime-type="text/plain">Welcome to the PDF to PNG Converter installer.

This will install two command-line tools:
• pdf21png - High-performance Objective-C implementation
• pdf22png - Modern Swift implementation with advanced features

Both tools will be installed to /usr/local/bin and will be available system-wide.</welcome>
    <conclusion language="en" mime-type="text/plain">PDF to PNG Converter has been successfully installed!

The following tools are now available in your terminal:
• pdf21png - High-performance PDF to PNG converter
• pdf22png - Modern PDF to PNG converter with advanced features

To get started, open Terminal and run:
  pdf21png --help
  pdf22png --help

Thank you for installing PDF to PNG Converter!</conclusion>
    <background file="background.png" mime-type="image/png" scaling="proportional" alignment="bottomleft"/>
    <pkg-ref id="$IDENTIFIER">
        <bundle-version/>
    </pkg-ref>
    <choices-outline>
        <line choice="default">
            <line choice="$IDENTIFIER"/>
        </line>
    </choices-outline>
    <choice id="default"/>
    <choice id="$IDENTIFIER" visible="false">
        <pkg-ref id="$IDENTIFIER"/>
    </choice>
    <pkg-ref id="$IDENTIFIER" version="$VERSION" onConclusion="none">pdf22png-component.pkg</pkg-ref>
</installer-gui-script>
EOF
    
    # Build distribution package
    productbuild \
        --distribution "$BUILD_DIR/distribution.xml" \
        --package-path "$BUILD_DIR" \
        --version "$VERSION" \
        "$DIST_DIR/$PKG_NAME"
    
    print_success "Built distribution package: $PKG_NAME"
}

# Verify the package
verify_package() {
    print_info "Verifying package..."
    
    # Check package info
    if pkgutil --check-signature "$DIST_DIR/$PKG_NAME" >/dev/null 2>&1; then
        print_success "Package is signed"
    else
        print_warning "Package is not signed (this is normal for local builds)"
    fi
    
    # Get package info
    print_info "Package contents:"
    pkgutil --payload-files "$DIST_DIR/$PKG_NAME" | head -10
    
    print_success "Package verification complete"
}

# Main execution
main() {
    echo ""
    echo "PDF22PNG Package Builder"
    echo "========================"
    echo "Version: $VERSION"
    echo ""
    
    setup_directories
    build_binaries
    copy_binaries
    create_scripts
    build_package
    verify_package
    
    echo ""
    print_success "Package built successfully!"
    echo ""
    echo "Package location: $DIST_DIR/$PKG_NAME"
    echo "Size: $(du -h "$DIST_DIR/$PKG_NAME" | cut -f1)"
    echo ""
    echo "To install: sudo installer -pkg \"$DIST_DIR/$PKG_NAME\" -target /"
}

# Parse arguments
if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
    echo "PDF22PNG Package Builder"
    echo ""
    echo "Usage: $0 [--sign]"
    echo ""
    echo "Options:"
    echo "  --sign    Sign the package (requires Developer ID Installer certificate)"
    echo "  --help    Show this help message"
    exit 0
fi

# Run main
main