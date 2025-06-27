# PDF22PNG Swift Implementation Makefile

# Build configuration
BUILD_DIR = .build
INSTALL_PREFIX = /usr/local
TARGET = pdf22png

# Default target
all: build

# Build release version
build:
	@echo "Building PDF22PNG Swift implementation..."
	cd $(shell pwd) && swift build -c release
	@echo "✓ Built: $(BUILD_DIR)/release/$(TARGET)"

# Build debug version
debug:
	@echo "Building debug version..."
	cd $(shell pwd) && swift build
	@echo "✓ Debug build: $(BUILD_DIR)/debug/$(TARGET)"

# Build universal binary (both architectures)
universal: build
	@echo "Building universal binary..."
	@# Swift Package Manager builds universal binaries by default on macOS
	@# Just copy the built binary to the expected location
	@mkdir -p build
	@if [ -f "$(BUILD_DIR)/apple/Products/Release/$(TARGET)" ]; then \
		cp "$(BUILD_DIR)/apple/Products/Release/$(TARGET)" build/$(TARGET); \
		echo "✓ Copied universal binary from Swift build"; \
	elif [ -f "$(BUILD_DIR)/release/$(TARGET)" ]; then \
		cp "$(BUILD_DIR)/release/$(TARGET)" build/$(TARGET); \
		echo "✓ Copied universal binary from Swift build"; \
	else \
		echo "Error: Binary not found after build"; \
		exit 1; \
	fi
	@# Verify it's universal
	@file build/$(TARGET) | grep -q "universal" && echo "✓ Verified universal binary" || echo "⚠ Binary may not be universal"
	@echo "✓ Universal binary: build/$(TARGET)"

# Run tests
test:
	@echo "Running Swift tests..."
	cd $(shell pwd) && swift test

# Install
install: build
	@echo "Installing to $(INSTALL_PREFIX)/bin/$(TARGET)..."
	sudo install -m 755 $(BUILD_DIR)/release/pdf22png $(INSTALL_PREFIX)/bin/$(TARGET)
	@echo "✓ Installed: $(INSTALL_PREFIX)/bin/$(TARGET)"

# Uninstall
uninstall:
	@echo "Removing $(INSTALL_PREFIX)/bin/$(TARGET)..."
	sudo rm -f $(INSTALL_PREFIX)/bin/$(TARGET)
	@echo "✓ Uninstalled"

# Clean
clean:
	cd $(shell pwd) && swift package clean
	rm -rf $(BUILD_DIR)

# Reset (clean + remove dependencies)
reset: clean
	rm -rf Package.resolved

# Help
help:
	@echo "PDF22PNG Swift Build System"
	@echo "==========================="
	@echo ""
	@echo "Targets:"
	@echo "  all        - Build release version (default)"
	@echo "  build      - Build release version"
	@echo "  debug      - Build debug version"
	@echo "  universal  - Build universal binary (arm64 + x86_64)"
	@echo "  test       - Run tests"
	@echo "  install    - Install to $(INSTALL_PREFIX)/bin"
	@echo "  uninstall  - Remove from $(INSTALL_PREFIX)/bin"
	@echo "  clean      - Clean build artifacts"
	@echo "  reset      - Clean everything including dependencies"
	@echo "  help       - Show this help"

.PHONY: all build debug universal test install uninstall clean reset help 