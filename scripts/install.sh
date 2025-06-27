#!/usr/bin/env bash
# PDF22PNG Installation Script
# Intelligently installs pdf21png and/or pdf22png using Homebrew or from source

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

REPO_URL="https://github.com/twardoch/pdf22png.git"
INSTALL_DIR="/usr/local/bin"
HOMEBREW_TAP="twardoch/pdf22png"

# Default to installing both
INSTALL_PDF21PNG=true
INSTALL_PDF22PNG=true
FORCE_SOURCE=false
INTERACTIVE=true

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

# Function to display usage
usage() {
  echo "PDF22PNG Installation Script"
  echo ""
  echo "Usage: $0 [OPTIONS]"
  echo ""
  echo "This script intelligently installs pdf21png and/or pdf22png, preferring"
  echo "Homebrew when available for the easiest installation experience."
  echo ""
  echo "Options:"
  echo "  --pdf21png-only   Install only pdf21png (high-performance Objective-C)"
  echo "  --pdf22png-only   Install only pdf22png (modern Swift version)"
  echo "  --from-source     Force building from source instead of using Homebrew"
  echo "  --non-interactive Skip confirmation prompts"
  echo "  -h, --help        Display this help message"
  echo ""
  echo "Examples:"
  echo "  $0                      # Install both tools via Homebrew"
  echo "  $0 --pdf22png-only      # Install only the Swift version"
  echo "  $0 --from-source        # Build from source even if Homebrew exists"
  exit 1
}

# Parse arguments
for arg in "$@"; do
  case $arg in
    --pdf21png-only)
      INSTALL_PDF21PNG=true
      INSTALL_PDF22PNG=false
      shift
      ;;
    --pdf22png-only)
      INSTALL_PDF21PNG=false
      INSTALL_PDF22PNG=true
      shift
      ;;
    --from-source)
      FORCE_SOURCE=true
      shift
      ;;
    --non-interactive)
      INTERACTIVE=false
      shift
      ;;
    -h|--help)
      usage
      ;;
    *)
      print_error "Unknown option: $arg"
      usage
      ;;
  esac
done

# Check if Homebrew is available
check_homebrew() {
  if command -v brew &> /dev/null; then
    print_success "Homebrew detected"
    return 0
  else
    print_warning "Homebrew not found"
    return 1
  fi
}

# Confirm installation
confirm_installation() {
  if [ "$INTERACTIVE" = false ]; then
    return 0
  fi
  
  echo ""
  echo "Installation Summary:"
  echo "-------------------"
  
  if [ "$INSTALL_PDF21PNG" = true ] && [ "$INSTALL_PDF22PNG" = true ]; then
    echo "• Installing: Both pdf21png and pdf22png"
  elif [ "$INSTALL_PDF21PNG" = true ]; then
    echo "• Installing: pdf21png only (Objective-C)"
  else
    echo "• Installing: pdf22png only (Swift)"
  fi
  
  if [ "$FORCE_SOURCE" = true ]; then
    echo "• Method: Building from source"
  elif check_homebrew; then
    echo "• Method: Homebrew (recommended)"
  else
    echo "• Method: Building from source (Homebrew not available)"
  fi
  
  echo ""
  read -p "Continue with installation? [Y/n] " -n 1 -r
  echo ""
  if [[ ! $REPLY =~ ^[Yy]$ ]] && [[ ! -z $REPLY ]]; then
    echo "Installation cancelled."
    exit 0
  fi
}

install_via_homebrew() {
  print_info "Installing via Homebrew..."
  
  # Add the tap
  print_info "Adding Homebrew tap: $HOMEBREW_TAP"
  if ! brew tap "$HOMEBREW_TAP" 2>/dev/null; then
    print_warning "Failed to add Homebrew tap. It may not exist yet."
    print_info "Once the tap is available, you can install with:"
    echo "    brew tap $HOMEBREW_TAP"
    if [ "$INSTALL_PDF21PNG" = true ]; then
      echo "    brew install pdf21png"
    fi
    if [ "$INSTALL_PDF22PNG" = true ]; then
      echo "    brew install pdf22png"
    fi
    return 1
  fi

  local success=true

  if [ "$INSTALL_PDF21PNG" = true ]; then
    print_info "Installing pdf21png..."
    if brew install "$HOMEBREW_TAP/pdf21png"; then
      print_success "pdf21png installed successfully"
    else
      print_warning "Failed to install pdf21png via Homebrew"
      success=false
    fi
  fi

  if [ "$INSTALL_PDF22PNG" = true ]; then
    print_info "Installing pdf22png..."
    if brew install "$HOMEBREW_TAP/pdf22png"; then
      print_success "pdf22png installed successfully"
    else
      print_warning "Failed to install pdf22png via Homebrew"
      success=false
    fi
  fi
  
  if [ "$success" = true ]; then
    return 0
  else
    print_warning "Some installations failed. Falling back to source build."
    return 1
  fi
}

install_from_source() {
  print_info "Building from source..."

  # Check for required tools
  if ! command -v git &> /dev/null; then
    print_error "git is required but not installed"
    exit 1
  fi
  
  if ! command -v make &> /dev/null; then
    print_error "make is required but not installed"
    exit 1
  fi

  # Create a temporary directory for cloning and building
  TMP_DIR=$(mktemp -d -t pdf22png_install_XXXXXX)
  print_info "Cloning repository to temporary directory..."
  
  if ! git clone "${REPO_URL}" "${TMP_DIR}" 2>/dev/null; then
    print_error "Failed to clone repository"
    rm -rf "${TMP_DIR}"
    exit 1
  fi
  
  cd "${TMP_DIR}"

  # Build using the unified Makefile
  print_info "Building tools..."
  
  local build_targets=""
  if [ "$INSTALL_PDF21PNG" = true ] && [ "$INSTALL_PDF22PNG" = true ]; then
    build_targets="all"
  elif [ "$INSTALL_PDF21PNG" = true ]; then
    build_targets="pdf21png"
  else
    build_targets="pdf22png"
  fi
  
  if ! make $build_targets; then
    print_error "Build failed"
    cd - > /dev/null
    rm -rf "${TMP_DIR}"
    exit 1
  fi

  # Install selected binaries
  print_info "Installing binaries to ${INSTALL_DIR}..."
  
  if [ "$INSTALL_PDF21PNG" = true ] && [ -f "${TMP_DIR}/pdf21png/build/pdf21png" ]; then
    print_info "Installing pdf21png..."
    sudo cp "${TMP_DIR}/pdf21png/build/pdf21png" "${INSTALL_DIR}/pdf21png"
    sudo chmod +x "${INSTALL_DIR}/pdf21png"
    print_success "pdf21png installed to ${INSTALL_DIR}"
  fi

  if [ "$INSTALL_PDF22PNG" = true ] && [ -f "${TMP_DIR}/pdf22png/.build/apple/Products/Release/pdf22png" ]; then
    print_info "Installing pdf22png..."
    sudo cp "${TMP_DIR}/pdf22png/.build/apple/Products/Release/pdf22png" "${INSTALL_DIR}/pdf22png"
    sudo chmod +x "${INSTALL_DIR}/pdf22png"
    print_success "pdf22png installed to ${INSTALL_DIR}"
  fi

  # Cleanup
  print_info "Cleaning up temporary files..."
  cd - > /dev/null
  rm -rf "${TMP_DIR}"
}

# Verify installation
verify_installation() {
  local verified=true
  
  if [ "$INSTALL_PDF21PNG" = true ]; then
    if command -v pdf21png &> /dev/null; then
      print_success "pdf21png is available in PATH"
    else
      print_warning "pdf21png installed but not found in PATH"
      verified=false
    fi
  fi
  
  if [ "$INSTALL_PDF22PNG" = true ]; then
    if command -v pdf22png &> /dev/null; then
      print_success "pdf22png is available in PATH"
    else
      print_warning "pdf22png installed but not found in PATH"
      verified=false
    fi
  fi
  
  if [ "$verified" = false ]; then
    print_info "Make sure ${INSTALL_DIR} is in your PATH"
    print_info "You can add it by running:"
    echo "    echo 'export PATH=\"${INSTALL_DIR}:\$PATH\"' >> ~/.zshrc"
    echo "    source ~/.zshrc"
  fi
}

# Main installation flow
main() {
  echo ""
  echo "PDF22PNG Installation Script"
  echo "=========================="
  
  # Show what will be installed
  confirm_installation
  
  # Determine installation method
  if [ "$FORCE_SOURCE" = true ]; then
    print_info "Building from source (--from-source specified)"
    install_from_source
  elif check_homebrew > /dev/null 2>&1; then
    if ! install_via_homebrew; then
      print_info "Falling back to source installation..."
      install_from_source
    fi
  else
    print_info "Homebrew not available, building from source..."
    install_from_source
  fi
  
  echo ""
  print_success "Installation complete!"
  echo ""
  
  # Verify and provide usage instructions
  verify_installation
  
  echo ""
  if [ "$INSTALL_PDF21PNG" = true ]; then
    echo "Get started with: pdf21png --help"
  fi
  
  if [ "$INSTALL_PDF22PNG" = true ]; then
    echo "Get started with: pdf22png --help"
  fi
  
  echo ""
  echo "For more information, visit: https://github.com/twardoch/pdf22png"
}

# Run main function
main