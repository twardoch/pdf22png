#!/usr/bin/env bash
# PDF22PNG Uninstallation Script
# Intelligently removes pdf21png and/or pdf22png, detecting installation method

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

INSTALL_DIR="/usr/local/bin"
HOMEBREW_TAP="twardoch/pdf22png"

# Default to uninstalling both
UNINSTALL_PDF21PNG=true
UNINSTALL_PDF22PNG=true
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
  echo "PDF22PNG Uninstallation Script"
  echo ""
  echo "Usage: $0 [OPTIONS]"
  echo ""
  echo "This script intelligently removes pdf21png and/or pdf22png,"
  echo "detecting whether they were installed via Homebrew or manually."
  echo ""
  echo "Options:"
  echo "  --pdf21png-only   Remove only pdf21png"
  echo "  --pdf22png-only   Remove only pdf22png"
  echo "  --non-interactive Skip confirmation prompts"
  echo "  -h, --help        Display this help message"
  echo ""
  echo "Examples:"
  echo "  $0                      # Remove both tools"
  echo "  $0 --pdf22png-only      # Remove only the Swift version"
  exit 1
}

# Parse arguments
for arg in "$@"; do
  case $arg in
    --pdf21png-only)
      UNINSTALL_PDF21PNG=true
      UNINSTALL_PDF22PNG=false
      shift
      ;;
    --pdf22png-only)
      UNINSTALL_PDF21PNG=false
      UNINSTALL_PDF22PNG=true
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

# Check if installed via Homebrew
check_homebrew_installation() {
  local tool=$1
  
  if command -v brew &> /dev/null; then
    if brew list --formula 2>/dev/null | grep -q "^${tool}$"; then
      return 0
    fi
  fi
  return 1
}

# Confirm uninstallation
confirm_uninstallation() {
  if [ "$INTERACTIVE" = false ]; then
    return 0
  fi
  
  echo ""
  echo "Uninstallation Summary:"
  echo "---------------------"
  
  if [ "$UNINSTALL_PDF21PNG" = true ] && [ "$UNINSTALL_PDF22PNG" = true ]; then
    echo "• Removing: Both pdf21png and pdf22png"
  elif [ "$UNINSTALL_PDF21PNG" = true ]; then
    echo "• Removing: pdf21png only"
  else
    echo "• Removing: pdf22png only"
  fi
  
  echo ""
  read -p "Continue with uninstallation? [Y/n] " -n 1 -r
  echo ""
  if [[ ! $REPLY =~ ^[Yy]$ ]] && [[ ! -z $REPLY ]]; then
    echo "Uninstallation cancelled."
    exit 0
  fi
}

# Uninstall via Homebrew
uninstall_homebrew() {
  local tool=$1
  print_info "Uninstalling $tool via Homebrew..."
  
  if brew uninstall "$tool" 2>/dev/null; then
    print_success "$tool uninstalled via Homebrew"
    return 0
  else
    print_warning "Failed to uninstall $tool via Homebrew"
    return 1
  fi
}

# Uninstall manually
uninstall_manual() {
  local tool=$1
  local path="${INSTALL_DIR}/${tool}"
  
  if [ -f "$path" ]; then
    print_info "Removing $tool from $path..."
    
    if sudo rm -f "$path"; then
      print_success "$tool removed successfully"
      return 0
    else
      print_error "Failed to remove $tool. Try running with sudo."
      return 1
    fi
  else
    print_info "$tool not found at $path"
    return 1
  fi
}

# Uninstall a single tool
uninstall_tool() {
  local tool=$1
  
  print_info "Checking installation method for $tool..."
  
  if check_homebrew_installation "$tool"; then
    print_info "$tool was installed via Homebrew"
    uninstall_homebrew "$tool"
  elif [ -f "${INSTALL_DIR}/${tool}" ]; then
    print_info "$tool was installed manually"
    uninstall_manual "$tool"
  else
    # Check if it's in PATH but not in standard location
    if command -v "$tool" &> /dev/null; then
      local actual_path=$(which "$tool")
      print_warning "$tool found at non-standard location: $actual_path"
      print_info "You may need to remove it manually"
    else
      print_info "$tool is not installed"
    fi
  fi
}

# Clean up Homebrew tap
cleanup_tap() {
  if command -v brew &> /dev/null; then
    if brew tap | grep -q "^${HOMEBREW_TAP}$"; then
      echo ""
      print_info "Homebrew tap '${HOMEBREW_TAP}' is still present"
      
      if [ "$INTERACTIVE" = true ]; then
        read -p "Remove the tap as well? [y/N] " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
          if brew untap "$HOMEBREW_TAP" 2>/dev/null; then
            print_success "Tap removed"
          else
            print_warning "Failed to remove tap"
          fi
        fi
      else
        print_info "To remove the tap, run: brew untap $HOMEBREW_TAP"
      fi
    fi
  fi
}

# Main uninstallation flow
main() {
  echo ""
  echo "PDF22PNG Uninstallation Script"
  echo "============================"
  
  # Confirm what will be uninstalled
  confirm_uninstallation
  
  local something_removed=false
  
  # Uninstall pdf21png if requested
  if [ "$UNINSTALL_PDF21PNG" = true ]; then
    uninstall_tool "pdf21png"
    something_removed=true
  fi
  
  # Uninstall pdf22png if requested
  if [ "$UNINSTALL_PDF22PNG" = true ]; then
    uninstall_tool "pdf22png"
    something_removed=true
  fi
  
  # Offer to clean up tap
  if [ "$something_removed" = true ]; then
    cleanup_tap
  fi
  
  echo ""
  print_success "Uninstallation complete!"
  echo ""
  
  # Check if anything remains
  local remaining=false
  if [ "$UNINSTALL_PDF21PNG" = false ] && command -v pdf21png &> /dev/null; then
    echo "pdf21png is still installed"
    remaining=true
  fi
  if [ "$UNINSTALL_PDF22PNG" = false ] && command -v pdf22png &> /dev/null; then
    echo "pdf22png is still installed"
    remaining=true
  fi
  
  if [ "$remaining" = false ]; then
    echo "All PDF to PNG tools have been removed from your system."
  fi
}

# Run main function
main