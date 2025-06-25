# PDF22PNG Makefile
# Builds the Objective-C implementation from src/

# Build directories
BUILD_DIR = build
VERSION = $(shell git describe --tags --always --dirty)

# Compiler flags
OBJC_FLAGS = -Wall -Wextra -O2 -fobjc-arc -mmacosx-version-min=10.15
FRAMEWORKS = -framework Foundation -framework CoreGraphics -framework ImageIO -framework Quartz -framework Vision -framework CoreServices -framework UniformTypeIdentifiers

# Source files
OBJC_SOURCES = src/pdf22png.m src/utils.m
OBJC_HEADERS = src/pdf22png.h src/utils.h src/errors.h

# Default target builds Objective-C (Swift is optional)
all: objc

$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)

# Objective-C implementation (primary)
objc: $(BUILD_DIR)/pdf22png

$(BUILD_DIR)/pdf22png: $(OBJC_SOURCES) $(OBJC_HEADERS) | $(BUILD_DIR)
	@echo "========================================="
	@echo "Building Objective-C Implementation"
	@echo "========================================="
	clang $(OBJC_FLAGS) $(FRAMEWORKS) -Isrc $(OBJC_SOURCES) -o $@
	@echo "✓ Objective-C binary built: $@"

# Swift implementation (optional - may have dependency issues)
swift: $(BUILD_DIR)/pdf22png-swift

$(BUILD_DIR)/pdf22png-swift: | $(BUILD_DIR)
	@echo "========================================="
	@echo "Building Swift Implementation (Optional)"
	@echo "========================================="
	@echo "Note: Swift build may fail due to complex dependencies"
	-swift build -c release 2>/dev/null && cp .build/release/pdf22png $@ || echo "Swift build failed - using Objective-C only"

# Build both (Objective-C + Swift if possible)
both: objc swift
	@echo "========================================="
	@echo "Build completed! Objective-C is ready."
	@if [ -f "$(BUILD_DIR)/pdf22png-swift" ]; then \
		echo "Swift implementation also built successfully!"; \
	else \
		echo "Swift implementation failed - Objective-C only."; \
	fi
	@echo "========================================="

# Universal binary for Objective-C
universal: | $(BUILD_DIR)
	@echo "Building universal binary..."
	clang $(OBJC_FLAGS) $(FRAMEWORKS) -Isrc $(OBJC_SOURCES) -arch x86_64 -arch arm64 -o $(BUILD_DIR)/pdf22png-universal
	@echo "✓ Universal binary built: $(BUILD_DIR)/pdf22png-universal"

# Run tests
test: test-objc

test-objc:
	@echo "Running Objective-C tests..."
	@if [ -f "Tests/test_runner.m" ]; then \
		clang $(OBJC_FLAGS) $(FRAMEWORKS) -Isrc Tests/test_runner.m $(OBJC_SOURCES) -o $(BUILD_DIR)/test_runner && \
		$(BUILD_DIR)/test_runner; \
	else \
		echo "No Objective-C tests found"; \
	fi

test-swift:
	@echo "Running Swift tests (optional)..."
	-swift test 2>/dev/null || echo "Swift tests not available"

# Run benchmarks
benchmark: objc
	cd benchmarks && ./run_benchmarks.sh

# Clean everything
clean:
	rm -rf $(BUILD_DIR)
	rm -rf .build

# Clean all including dependencies
clean-all: clean
	rm -f Package.resolved

# Install Objective-C implementation
install: objc
	sudo install -m 755 $(BUILD_DIR)/pdf22png /usr/local/bin/pdf22png
	@echo "Installed: /usr/local/bin/pdf22png"

# Install Swift if available
install-swift: swift
	@if [ -f "$(BUILD_DIR)/pdf22png-swift" ]; then \
		sudo install -m 755 $(BUILD_DIR)/pdf22png-swift /usr/local/bin/pdf22png-swift && \
		echo "Installed: /usr/local/bin/pdf22png-swift"; \
	else \
		echo "Swift implementation not available for installation"; \
	fi

# Install both if available
install-both: install install-swift

# Development helpers
dev-objc: | $(BUILD_DIR)
	clang -Wall -Wextra -O0 -g -fobjc-arc -mmacosx-version-min=10.15 $(FRAMEWORKS) -Isrc $(OBJC_SOURCES) -o $(BUILD_DIR)/pdf22png-debug
	@echo "✓ Debug build: $(BUILD_DIR)/pdf22png-debug"

dev-swift:
	@echo "Building Swift in development mode..."
	-swift build || echo "Swift development build failed"

# Release build
release: clean
	$(MAKE) objc OBJC_FLAGS="$(OBJC_FLAGS) -DVERSION=\\\"$(VERSION)\\\""
	-$(MAKE) swift
	@echo "Release build complete: $(VERSION)"

# Help
help:
	@echo "PDF22PNG Build System"
	@echo "===================="
	@echo ""
	@echo "Primary targets:"
	@echo "  all          - Build Objective-C implementation (default)"
	@echo "  objc         - Build Objective-C implementation only"
	@echo "  swift        - Build Swift implementation (optional)"
	@echo "  both         - Build both implementations if possible"
	@echo "  universal    - Build universal binary for Objective-C"
	@echo ""
	@echo "Testing:"
	@echo "  test         - Run Objective-C tests"
	@echo "  test-objc    - Run Objective-C tests"
	@echo "  test-swift   - Run Swift tests (if available)"
	@echo "  benchmark    - Run performance benchmarks"
	@echo ""
	@echo "Installation:"
	@echo "  install      - Install Objective-C implementation"
	@echo "  install-swift- Install Swift implementation (if built)"
	@echo "  install-both - Install both implementations"
	@echo ""
	@echo "Development:"
	@echo "  dev-objc     - Build Objective-C with debug symbols"
	@echo "  dev-swift    - Build Swift in debug mode"
	@echo "  release      - Build release versions"
	@echo ""
	@echo "Cleanup:"
	@echo "  clean        - Clean build artifacts"
	@echo "  clean-all    - Clean everything including dependencies"
	@echo "  help         - Show this help message"

.PHONY: all objc swift both universal test test-objc test-swift benchmark clean clean-all install install-swift install-both dev-objc dev-swift release help