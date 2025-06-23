#!/usr/bin/env bash
# this_file: scripts/build-universal.sh

# Build script for creating a universal binary for pdf22png

set -euo pipefail

PRODUCT_NAME="pdf22png"
SRCDIR="src"
BUILD_DIR="build/universal" # Temporary build directory

# Clean previous universal build products if any
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"
mkdir -p "build" # Ensure build directory exists
rm -f "build/${PRODUCT_NAME}" # Remove previous universal binary from build dir

# Get CFLAGS and LDFLAGS from Makefile (basic parsing, might need improvement for complex Makefiles)
# This is a simplified approach. A more robust way would be to have `make print-cflags` target.
CFLAGS_FROM_MAKEFILE=$(make -s print-cflags 2>/dev/null || grep -E '^CFLAGS' Makefile | head -1 | cut -d'=' -f2- | xargs)
LDFLAGS_FROM_MAKEFILE=$(make -s print-ldflags 2>/dev/null || grep -E '^LDFLAGS' Makefile | head -1 | cut -d'=' -f2- | xargs)

# Source files (assuming they are listed in Makefile or known)
# For simplicity, let's assume pdf22png.m and utils.m
# A more robust way: parse SOURCES from Makefile
SOURCES_FROM_MAKEFILE=$(grep -E '^SOURCES\s*=' Makefile | sed -E 's/SOURCES\s*=\s*//' | sed "s~\$(SRCDIR)~$SRCDIR~g" | sed "s~\$(TESTDIR)~~g") # remove test dir if present
# If SOURCES are like $(SRCDIR)/file1.m $(SRCDIR)/file2.m, this works.
# If it's more complex, manual definition might be needed here.
# Let's hardcode for now based on our project.
MAIN_SOURCE="${SRCDIR}/pdf22png.m"
UTIL_SOURCE="${SRCDIR}/utils.m"

echo "Building for x86_64..."
eval "clang ${CFLAGS_FROM_MAKEFILE} -arch x86_64 -c \"${MAIN_SOURCE}\" -o \"${BUILD_DIR}/${PRODUCT_NAME}_main_x86_64.o\""
eval "clang ${CFLAGS_FROM_MAKEFILE} -arch x86_64 -c \"${UTIL_SOURCE}\" -o \"${BUILD_DIR}/${PRODUCT_NAME}_utils_x86_64.o\""
eval "clang ${LDFLAGS_FROM_MAKEFILE} -arch x86_64 -o \"${BUILD_DIR}/${PRODUCT_NAME}_x86_64\" \
    \"${BUILD_DIR}/${PRODUCT_NAME}_main_x86_64.o\" \
    \"${BUILD_DIR}/${PRODUCT_NAME}_utils_x86_64.o\""

echo "Building for arm64..."
eval "clang ${CFLAGS_FROM_MAKEFILE} -arch arm64 -c \"${MAIN_SOURCE}\" -o \"${BUILD_DIR}/${PRODUCT_NAME}_main_arm64.o\""
eval "clang ${CFLAGS_FROM_MAKEFILE} -arch arm64 -c \"${UTIL_SOURCE}\" -o \"${BUILD_DIR}/${PRODUCT_NAME}_utils_arm64.o\""
eval "clang ${LDFLAGS_FROM_MAKEFILE} -arch arm64 -o \"${BUILD_DIR}/${PRODUCT_NAME}_arm64\" \
    \"${BUILD_DIR}/${PRODUCT_NAME}_main_arm64.o\" \
    \"${BUILD_DIR}/${PRODUCT_NAME}_utils_arm64.o\""

echo "Creating universal binary..."
lipo -create -output "build/${PRODUCT_NAME}" \
    "${BUILD_DIR}/${PRODUCT_NAME}_x86_64" \
    "${BUILD_DIR}/${PRODUCT_NAME}_arm64"

echo "Verifying universal binary..."
lipo -info "build/${PRODUCT_NAME}"

# Optional: Create dSYM
# echo "Creating dSYM for universal binary..."
# dsymutil "${PRODUCT_NAME}" -o "${PRODUCT_NAME}.dSYM"

echo "Universal binary 'build/${PRODUCT_NAME}' created successfully."
echo "Build artifacts are in '${BUILD_DIR}'."
echo "To clean up build artifacts, run 'make clean'."

# Note: The Makefile's `clean` target might need to be updated to remove this `build/universal` directory too.
# Or this script can clean up its own build dir:
# rm -rf "${BUILD_DIR}"
# echo "Cleaned up temporary universal build directory: ${BUILD_DIR}"
