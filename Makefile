# PDF22PNG Master Makefile
# Orchestrates building both Objective-C and Swift implementations

# Build directories
BUILD_DIR = build
VERSION = $(shell git describe --tags --always --dirty)

# Default target builds both
all: objc swift

$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)

# Objective-C implementation
objc: | $(BUILD_DIR)
	@echo "========================================="
	@echo "Building Objective-C Implementation"
	@echo "========================================="
	$(MAKE) -C objc

# Swift implementation  
swift: | $(BUILD_DIR)
	@echo "========================================="
	@echo "Building Swift Implementation"
	@echo "========================================="
	cd swift && ./build.sh

# Build both
both: objc swift
	@echo "========================================="
	@echo "Both implementations built successfully!"
	@echo "========================================="

# Universal binary for Objective-C
universal:
	$(MAKE) -C objc universal

# Run tests
test: test-objc test-swift

test-objc:
	@echo "Running Objective-C tests..."
	$(MAKE) -C objc test

test-swift:
	@echo "Running Swift tests..."
	cd swift && swift test

# Run benchmarks
benchmark: all
	cd benchmarks && ./run_benchmarks.sh

# Clean everything
clean:
	$(MAKE) -C objc clean
	cd swift && ./build.sh --clean
	rm -rf $(BUILD_DIR)

# Clean all including dependencies
clean-all: clean
	rm -rf swift/.build
	rm -rf swift/Package.resolved

# Install both implementations
install: install-objc install-swift

install-objc: objc
	$(MAKE) -C objc install

install-swift: swift
	sudo install -m 755 $(BUILD_DIR)/pdf22png-swift /usr/local/bin/pdf22png-swift

# Install both with different names
install-both: install-objc install-swift
	@echo "Both implementations installed:"
	@echo "  - Objective-C: /usr/local/bin/pdf22png"
	@echo "  - Swift: /usr/local/bin/pdf22png-swift"

# Development helpers
dev-objc:
	$(MAKE) -C objc CFLAGS="-Wall -Wextra -O0 -g -fobjc-arc -mmacosx-version-min=10.15 -I./include"

dev-swift:
	cd swift && ./build.sh --debug

# Release build
release:
	$(MAKE) -C objc clean
	$(MAKE) -C objc CFLAGS="-Wall -Wextra -O2 -fobjc-arc -mmacosx-version-min=10.15 -I./include -DVERSION=\\\"$(VERSION)\\\""
	cd swift && ./build.sh --clean && ./build.sh
	@echo "Release build complete: $(VERSION)"

# Help
help:
	@echo "PDF22PNG Build System"
	@echo "===================="
	@echo ""
	@echo "Targets:"
	@echo "  all          - Build both implementations (default)"
	@echo "  objc         - Build Objective-C implementation only"
	@echo "  swift        - Build Swift implementation only"
	@echo "  both         - Build both implementations"
	@echo "  universal    - Build universal binary for Objective-C"
	@echo "  test         - Run all tests"
	@echo "  test-objc    - Run Objective-C tests"
	@echo "  test-swift   - Run Swift tests"
	@echo "  benchmark    - Run performance benchmarks"
	@echo "  clean        - Clean build artifacts"
	@echo "  clean-all    - Clean everything including dependencies"
	@echo "  install      - Install both implementations"
	@echo "  install-objc - Install Objective-C implementation"
	@echo "  install-swift- Install Swift implementation"
	@echo "  dev-objc     - Build Objective-C with debug symbols"
	@echo "  dev-swift    - Build Swift in debug mode"
	@echo "  release      - Build release versions"
	@echo "  help         - Show this help message"

.PHONY: all objc swift both universal test test-objc test-swift benchmark clean clean-all install install-objc install-swift install-both dev-objc dev-swift release help