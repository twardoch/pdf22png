#!/usr/bin/env bash
# this_file: scripts/uninstall.sh

# Uninstallation script for pdf21png and pdf22png

set -euo pipefail

INSTALL_DIR="/usr/local/bin"

BINARIES=("pdf21png" "pdf22png")

echo "Uninstalling pdf21png and pdf22png..."

for PRODUCT_NAME in "${BINARIES[@]}"; do
  INSTALLED_PATH="${INSTALL_DIR}/${PRODUCT_NAME}"

  echo "\nChecking for ${PRODUCT_NAME}..."
  if [ -f "${INSTALLED_PATH}" ]; then
      echo "Found ${PRODUCT_NAME} at ${INSTALLED_PATH}."
      # Check if it was installed by Homebrew
      if command -v brew &> /dev/null && brew list --formula | grep -q "^${PRODUCT_NAME}\""; then
          echo "${PRODUCT_NAME} appears to be installed via Homebrew."
          echo "Please run 'brew uninstall ${PRODUCT_NAME}' to remove it."
      elif command -v brew &> /dev/null && brew list --cask | grep -q "^${PRODUCT_NAME}\""; then
          echo "${PRODUCT_NAME} appears to be installed as a Homebrew Cask."
          echo "Please run 'brew uninstall --cask ${PRODUCT_NAME}' to remove it."
      else
          echo "Attempting to remove ${PRODUCT_NAME} from ${INSTALLED_PATH}..."
          if sudo rm -f "${INSTALLED_PATH}"; then
              echo "${PRODUCT_NAME} removed successfully."
          else
              echo "Failed to remove ${PRODUCT_NAME}. You may need to run this script with sudo or remove it manually."
              # Do not exit, continue to try and uninstall other binary
          fi
      fi
  else
      echo "${PRODUCT_NAME} not found at ${INSTALLED_PATH} (standard location)."
      echo "If you installed it to a custom location, you may need to remove it manually."
      echo "If installed via Homebrew, try 'brew uninstall ${PRODUCT_NAME}'."
  fi
done

# Attempt to remove from common tap if it exists (best effort)
TAP_OWNER="twardoch"
TAP_NAME="pdf22png"

if command -v brew &> /dev/null; then
    TAP_DIR_STANDARD="$(brew --prefix)/Homebrew/Library/Taps/${TAP_OWNER}/${TAP_NAME}"
    TAP_DIR_ALTERNATIVE="/opt/homebrew/Library/Taps/${TAP_OWNER}/${TAP_NAME}" # For Apple Silicon default brew location

    if [ -d "${TAP_DIR_STANDARD}" ] || [ -d "${TAP_DIR_ALTERNATIVE}" ]; then
        echo "\nNote: If you installed via 'brew tap ${TAP_OWNER}/${TAP_NAME}', the tap itself ('${TAP_OWNER}/${TAP_NAME}') is not automatically removed."
        echo "You can untap it using 'brew untap ${TAP_OWNER}/${TAP_NAME}' if you no longer need any formulae from it."
    fi
fi

echo "\nUninstallation process complete."