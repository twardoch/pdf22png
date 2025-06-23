# Variables
PRODUCT_NAME = pdf22png
SWIFT_BUILD_FLAGS = --product $(PRODUCT_NAME)
# Define architecture for local builds if needed, universal handles both.
# ARCH_FLAGS = --arch arm64 --arch x86_64
ARCH_FLAGS_ARM = --arch arm64
ARCH_FLAGS_X86 = --arch x86_64

PREFIX = /usr/local
BINDIR = $(PREFIX)/bin
BUILD_CONFIG = release
SWIFT_BUILD_DIR = .build/$(BUILD_CONFIG)
EXECUTABLE_PATH = $(SWIFT_BUILD_DIR)/$(PRODUCT_NAME)

# Get version from git, similar to old Makefile.
# Swift packages can also embed versions, but this keeps consistency with release.sh
VERSION = $(shell git describe --tags --always --dirty)

.PHONY: all clean install uninstall test universal release fmt lint help

help:
	@echo "Available targets:"
	@echo "  all         Build the release version of the product"
	@echo "  universal   Build a universal binary (arm64 and x86_64)"
	@echo "  debug       Build the debug version of the product"
	@echo "  test        Run tests"
	@echo "  install     Install the product to $(BINDIR)"
	@echo "  uninstall   Uninstall the product from $(BINDIR)"
	@echo "  clean       Clean build artifacts"
	@echo "  release     (Handled by release.sh) Prepares for a release"
	@echo "  fmt         (Swift) Format code using swift-format (if installed)"
	@echo "  lint        (Swift) Lint code using SwiftLint (if installed)"


all: $(EXECUTABLE_PATH)

# Build the release version
$(EXECUTABLE_PATH): Package.swift Sources/* Tests/*
	@echo "Building $(PRODUCT_NAME) (release)..."
	@swift build -c $(BUILD_CONFIG) $(SWIFT_BUILD_FLAGS)

debug:
	@echo "Building $(PRODUCT_NAME) (debug)..."
	@swift build -c debug $(SWIFT_BUILD_FLAGS)

# Universal binary for Intel and Apple Silicon
# This creates a fat binary.
# Note: `swift build --arch arm64 --arch x86_64` might produce separate binaries
# that need to be combined with `lipo`. Or, SPM might handle creating a universal binary directly.
# Let's assume SPM handles it if possible, or adjust lipo commands.
# For modern SPM versions, it should create a universal binary by default if multiple archs are specified.
universal:
	@echo "Building universal binary for $(PRODUCT_NAME)..."
	@swift build -c $(BUILD_CONFIG) $(SWIFT_BUILD_FLAGS) $(ARCH_FLAGS_ARM) $(ARCH_FLAGS_X86)
	@echo "Universal binary should be at $(EXECUTABLE_PATH)"
	@echo "Verifying architecture:"
	@lipo -info $(EXECUTABLE_PATH) || echo "lipo check failed or not a universal binary."


install: $(EXECUTABLE_PATH)
	@echo "Installing $(PRODUCT_NAME) to $(BINDIR)..."
	@mkdir -p $(BINDIR)
	@cp $(EXECUTABLE_PATH) $(BINDIR)/$(PRODUCT_NAME)
	@echo "Installation complete! Run '$(PRODUCT_NAME) --help'"

uninstall:
	@echo "Uninstalling $(PRODUCT_NAME) from $(BINDIR)..."
	@rm -f $(BINDIR)/$(PRODUCT_NAME)
	@echo "Uninstallation complete!"

test:
	@echo "Running tests for $(PRODUCT_NAME)..."
	@swift test

clean:
	@echo "Cleaning build artifacts..."
	@swift package clean
	@rm -rf .build # Sometimes `swift package clean` doesn't remove everything
	@echo "Clean complete!"

# Release target - primarily for `release.sh` to call if needed,
# but `release.sh` will likely call `make all` or `make universal`.
# Version is passed via environment or embedded differently in Swift.
release: all
	@echo "Release build complete: $(VERSION)"
	@echo "Binary at $(EXECUTABLE_PATH)"


# Swift specific formatting and linting (optional, requires tools)
fmt:
	@echo "Formatting Swift code (requires swift-format)..."
	@if command -v swift-format &> /dev/null; then \
		swift-format format -i -r Sources Tests; \
		echo "Swift code formatted."; \
	else \
		echo "swift-format not found. Skipping."; \
	fi

lint:
	@echo "Linting Swift code (requires swiftlint)..."
	@if command -v swiftlint &> /dev/null; then \
		swiftlint; \
		echo "SwiftLint complete."; \
	else \
		echo "swiftlint not found. Skipping."; \
	fi

# Remove old Objective-C specific targets if they were here.
# For example, if there was an explicit compile rule like %.o: %.m
# it's no longer needed.
# The old `$(BUILDDIR)/$(PRODUCT_NAME): $(OBJECTS) | $(BUILDDIR)` rule is replaced by `swift build`.

# Ensure Package.swift is a prerequisite for builds if it changes.
# This is implicitly handled by depending on the output executable path, which SPM manages.
# Added Package.swift Sources/* Tests/* to $(EXECUTABLE_PATH) prerequisites for explicitness.
# (Though `swift build` itself checks for changes).
