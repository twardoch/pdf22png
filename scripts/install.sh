#!/usr/bin/env bash
# this_file: scripts/install.sh

set -euo pipefail

REPO_URL="https://github.com/twardoch/pdf22png.git"
INSTALL_DIR="/usr/local/bin"

# Default to installing both
INSTALL_PDF21PNG=true
INSTALL_PDF22PNG=true

# Function to display usage
usage() {
  echo "Usage: $0 [OPTIONS]"
  echo "Install pdf21png and/or pdf22png binaries."
  echo ""
  echo "Options:"
  echo "  --pdf21png-only   Install only pdf21png (Objective-C version)"
  echo "  --pdf22png-only   Install only pdf22png (Swift version)"
  echo "  --no-brew         Do not use Homebrew, build from source"
  echo "  -h, --help        Display this help message"
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
    --no-brew)
      NO_BREW=true
      shift
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "Unknown option: $arg"
      usage
      ;;
  esac
done

install_via_homebrew() {
  echo "Homebrew detected. Attempting to install via Homebrew..."
  brew tap twardoch/pdf22png

  if [ "$INSTALL_PDF21PNG" = true ]; then
    echo "Installing pdf21png..."
    brew install pdf21png || {
      echo "Homebrew installation of pdf21png failed. You might need to update your Homebrew tap or formula."
      echo "Attempting to build pdf21png from source instead."
      return 1 # Indicate failure to Homebrew install
    }
  fi

  if [ "$INSTALL_PDF22PNG" = true ]; then
    echo "Installing pdf22png..."
    brew install pdf22png || {
      echo "Homebrew installation of pdf22png failed. You might need to update your Homebrew tap or formula."
      echo "Attempting to build pdf22png from source instead."
      return 1 # Indicate failure to Homebrew install
    }
  fi
  return 0 # Indicate success
}

install_from_source() {
  echo "Building from source..."

  # Create a temporary directory for cloning and building
  TMP_DIR=$(mktemp -d -t pdf22png_install_XXXXXX)
  echo "Cloning repository to $TMP_DIR"
  git clone "${REPO_URL}" "${TMP_DIR}"
  cd "${TMP_DIR}"

  # Build both tools
  echo "Building both pdf21png and pdf22png..."
  ./build.sh

  # Install selected binaries
  if [ "$INSTALL_PDF21PNG" = true ]; then
    echo "Installing pdf21png to ${INSTALL_DIR}"
    sudo cp "${TMP_DIR}/pdf21png/build/pdf21png" "${INSTALL_DIR}/pdf21png"
    sudo chmod +x "${INSTALL_DIR}/pdf21png"
  fi

  if [ "$INSTALL_PDF22PNG" = true ]; then
    echo "Installing pdf22png to ${INSTALL_DIR}"
    sudo cp "${TMP_DIR}/pdf22png/.build/release/pdf22png" "${INSTALL_DIR}/pdf22png"
    sudo chmod +x "${INSTALL_DIR}/pdf22png"
  fi

  # Cleanup
  echo "Cleaning up temporary files..."
  cd -
  rm -rf "${TMP_DIR}"
}

# Main installation logic
if [ -z "${NO_BREW}" ] && command -v brew &> /dev/null; then
  if ! install_via_homebrew; then
    echo "Homebrew installation failed or was skipped. Falling back to source build."
    install_from_source
  fi
else
  echo "Homebrew not found or --no-brew flag used. Building from source."
  install_from_source
fi

echo "Installation complete!"

if [ "$INSTALL_PDF21PNG" = true ]; then
  echo "Run 'pdf21png --help' to get started with the Objective-C version."
fi

if [ "$INSTALL_PDF22PNG" = true ]; then
  echo "Run 'pdf22png --help' to get started with the Swift version."
fi