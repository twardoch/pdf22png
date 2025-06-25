# Variables
PRODUCT_NAME = pdf22png
SWIFT = xcrun swift
PREFIX = /usr/local
BINDIR = $(PREFIX)/bin
BUILDDIR = build
SWIFT_BUILDDIR = .build
VERSION = $(shell git describe --tags --always --dirty)

# Default target
.PHONY: all clean install uninstall test universal release fmt lint

all: build

build:
	@echo "Building Swift version (standalone implementation)..."
	@echo "Note: Using standalone Swift implementation to avoid SPM dependencies"
	@$(MAKE) -C ../pdf22png-swift-standalone build
	@mkdir -p $(BUILDDIR)
	@cp ../pdf22png-swift-standalone/build/$(PRODUCT_NAME) $(BUILDDIR)/$(PRODUCT_NAME)
	@echo "Swift build complete!"

test:
	@echo "Testing standalone Swift implementation..."
	@$(MAKE) -C ../pdf22png-swift-standalone test

clean:
	@echo "Cleaning Swift build..."
	@$(MAKE) -C ../pdf22png-swift-standalone clean
	@rm -rf $(SWIFT_BUILDDIR) $(BUILDDIR)
	@echo "Swift clean complete!"

# Universal binary target
universal:
	@echo "Building universal binary (standalone Swift)..."
	@$(MAKE) -C ../pdf22png-swift-standalone universal
	@mkdir -p $(BUILDDIR)
	@cp ../pdf22png-swift-standalone/build/$(PRODUCT_NAME)-universal $(BUILDDIR)/$(PRODUCT_NAME)-universal
	@echo "Universal Swift build complete!"

# Install target
install: build
	@echo "Installing $(PRODUCT_NAME) (Swift) to $(BINDIR)..."
	@install -d $(BINDIR)
	@install -m 755 $(BUILDDIR)/$(PRODUCT_NAME) $(BINDIR)/$(PRODUCT_NAME)
	@echo "Installation complete!"

uninstall:
	@echo "Uninstalling $(PRODUCT_NAME)..."
	@rm -f $(BINDIR)/$(PRODUCT_NAME)
	@echo "Uninstallation complete!"

fmt:
	@echo "Formatting Swift code..."
	@if command -v swift-format >/dev/null 2>&1; then \
		swift-format -i Sources/**/*.swift Tests/**/*.swift; \
	else \
		echo "swift-format not installed, skipping Swift formatting"; \
	fi

lint:
	@echo "Linting Swift code..."
	@if command -v swiftlint >/dev/null 2>&1; then \
		swiftlint; \
	else \
		echo "SwiftLint not installed, skipping Swift linting"; \
	fi

# Release build with version info
release:
	@echo "Building Swift release (standalone): $(VERSION)"
	@$(MAKE) -C ../pdf22png-swift-standalone release
	@mkdir -p $(BUILDDIR)
	@cp ../pdf22png-swift-standalone/build/$(PRODUCT_NAME) $(BUILDDIR)/$(PRODUCT_NAME)
	@echo "Swift release build complete: $(VERSION)"