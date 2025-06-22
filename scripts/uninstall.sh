#!/usr/bin/env bash
# this_file: scripts/uninstall.sh

# Uninstallation script for pdf22png

set -euo pipefail

PRODUCT_NAME="pdf22png"
INSTALL_DIR="/usr/local/bin"
INSTALLED_PATH="${INSTALL_DIR}/${PRODUCT_NAME}"

echo "Uninstalling ${PRODUCT_NAME}..."

if [ -f "${INSTALLED_PATH}" ]; then
    echo "Found ${PRODUCT_NAME} at ${INSTALLED_PATH}."
    # Check if it was installed by Homebrew
    if command -v brew &> /dev/null && brew list --formula | grep -q "^${PRODUCT_NAME}\$" ; then
        echo "${PRODUCT_NAME} appears to be installed via Homebrew."
        echo "Please run 'brew uninstall ${PRODUCT_NAME}' to remove it."
        # Optionally, ask if user wants to proceed with Homebrew uninstall
        # read -p "Do you want to run 'brew uninstall ${PRODUCT_NAME}' now? (y/N) " choice
        # case "$choice" in
        #   y|Y ) brew uninstall ${PRODUCT_NAME};;
        #   * ) echo "Skipping Homebrew uninstall.";;
        # esac
        exit 0
    elif command -v brew &> /dev/null && brew list --cask | grep -q "^${PRODUCT_NAME}\$" ; then
        echo "${PRODUCT_NAME} appears to be installed as a Homebrew Cask."
        echo "Please run 'brew uninstall --cask ${PRODUCT_NAME}' to remove it."
        exit 0
    else
        echo "Attempting to remove ${PRODUCT_NAME} from ${INSTALLED_PATH}..."
        if sudo rm -f "${INSTALLED_PATH}"; then
            echo "${PRODUCT_NAME} removed successfully."
        else
            echo "Failed to remove ${PRODUCT_NAME}. You may need to run this script with sudo or remove it manually."
            exit 1
        fi
    fi
else
    echo "${PRODUCT_NAME} not found at ${INSTALLED_PATH} (standard location)."
    echo "If you installed it to a custom location, you may need to remove it manually."
    echo "If installed via Homebrew, try 'brew uninstall ${PRODUCT_NAME}'."
fi

# Attempt to remove from common tap if it exists (best effort)
TAP_OWNER="twardoch" # As per install script
TAP_NAME="tap"       # As per install script
FORMULA_PATH_IN_TAP="Formula/${PRODUCT_NAME}.rb" # Common pattern for taps

if command -v brew &> /dev/null; then
    TAP_DIR_STANDARD="$(brew --prefix)/Homebrew/Library/Taps/${TAP_OWNER}/${TAP_NAME}"
    TAP_DIR_ALTERNATIVE="/opt/homebrew/Library/Taps/${TAP_OWNER}/${TAP_NAME}" # For Apple Silicon default brew location

    FORMULA_IN_TAP_STANDARD="${TAP_DIR_STANDARD}/${FORMULA_PATH_IN_TAP}"
    FORMULA_IN_TAP_ALTERNATIVE="${TAP_DIR_ALTERNATIVE}/${FORMULA_PATH_IN_TAP}"

    # Check if the formula file exists within a known tap structure
    # This is a heuristic and might not cover all tap configurations.
    # A more robust check would be `brew tap | grep ...` but that's more complex to parse reliably.

    # We don't automatically untap, as the user might have other formulae from the same tap.
    # We also don't remove the formula file from the tap, as `brew uninstall` should handle that.
    # This section is more for informational purposes.
    if [ -f "${FORMULA_IN_TAP_STANDARD}" ] || [ -f "${FORMULA_IN_TAP_ALTERNATIVE}" ]; then
        echo "Note: If you installed via 'brew tap ${TAP_OWNER}/${TAP_NAME}', the tap itself ('${TAP_OWNER}/${TAP_NAME}') is not automatically removed."
        echo "You can untap it using 'brew untap ${TAP_OWNER}/${TAP_NAME}' if you no longer need any formulae from it."
    fi
fi


echo "Uninstallation process complete."
