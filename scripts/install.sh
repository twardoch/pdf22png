#!/usr/bin/env bash
# this_file: scripts/install.sh

set -euo pipefail

REPO="twardoch/pdf22png"
INSTALL_DIR="/usr/local/bin"

echo "Installing pdf22png..."

# Check if Homebrew is installed
if command -v brew &> /dev/null; then
    echo "Homebrew detected. Installing via Homebrew..."
    brew tap twardoch/tap
    brew install pdf22png
else
    echo "Building from source..."

    # Clone repo
    git clone "https://github.com/${REPO}.git" /tmp/pdf22png
    cd /tmp/pdf22png

    # Build
    make

    # Install
    sudo make install

    # Cleanup
    cd -
    rm -rf /tmp/pdf22png
fi

echo "Installation complete! Run 'pdf22png --help' to get started."
