# PDF22PNG Project Makefile
# Unified build system for both pdf21png (Objective-C) and pdf22png (Swift)

# Default target
.DEFAULT_GOAL := all

# Directories
PDF21PNG_DIR := pdf21png
PDF22PNG_DIR := pdf22png
INSTALL_PREFIX := /usr/local/bin

# Build targets
.PHONY: all clean install uninstall test release check-deps help

# Build both implementations
all: pdf21png pdf22png
	@echo "✓ Both implementations built successfully"

# Build pdf21png (Objective-C)
pdf21png: check-deps-objc
	@echo "→ Building pdf21png (Objective-C)..."
	@$(MAKE) -C $(PDF21PNG_DIR)
	@echo "✓ pdf21png built successfully"

# Build pdf22png (Swift)
pdf22png: check-deps-swift
	@echo "→ Building pdf22png (Swift)..."
	@$(MAKE) -C $(PDF22PNG_DIR)
	@echo "✓ pdf22png built successfully"

# Build only Objective-C version
objc: pdf21png

# Build only Swift version
swift: pdf22png

# Clean all build artifacts
clean:
	@echo "→ Cleaning build artifacts..."
	@$(MAKE) -C $(PDF21PNG_DIR) clean
	@$(MAKE) -C $(PDF22PNG_DIR) clean
	@rm -rf release_artifacts
	@echo "✓ Build artifacts cleaned"

# Install both tools
install: install-pdf21png install-pdf22png
	@echo "✓ Both tools installed successfully"

# Install pdf21png
install-pdf21png: pdf21png
	@echo "→ Installing pdf21png to $(INSTALL_PREFIX)..."
	@$(MAKE) -C $(PDF21PNG_DIR) install
	@echo "✓ pdf21png installed"

# Install pdf22png
install-pdf22png: pdf22png
	@echo "→ Installing pdf22png to $(INSTALL_PREFIX)..."
	@$(MAKE) -C $(PDF22PNG_DIR) install
	@echo "✓ pdf22png installed"

# Uninstall both tools
uninstall:
	@echo "→ Uninstalling pdf21png and pdf22png..."
	@rm -f $(INSTALL_PREFIX)/pdf21png
	@rm -f $(INSTALL_PREFIX)/pdf22png
	@echo "✓ Both tools uninstalled"

# Run tests for both implementations
test: test-pdf21png test-pdf22png
	@echo "✓ All tests passed"

# Test pdf21png
test-pdf21png: pdf21png
	@echo "→ Testing pdf21png..."
	@./test_both.sh --only-objc

# Test pdf22png
test-pdf22png: pdf22png
	@echo "→ Testing pdf22png..."
	@./test_both.sh --only-swift

# Run benchmarks
benchmark: all
	@echo "→ Running benchmarks..."
	@./bench.sh

# Create release artifacts
release: all test
	@echo "→ Creating release artifacts..."
	@./release.sh --dry-run
	@echo "✓ Release artifacts created (dry run)"

# Check dependencies
check-deps: check-deps-objc check-deps-swift

# Check Objective-C dependencies
check-deps-objc:
	@echo "→ Checking Objective-C dependencies..."
	@command -v clang >/dev/null 2>&1 || { echo "ERROR: clang not found. Install Xcode Command Line Tools."; exit 1; }
	@echo "✓ Objective-C dependencies satisfied"

# Check Swift dependencies
check-deps-swift:
	@echo "→ Checking Swift dependencies..."
	@command -v swift >/dev/null 2>&1 || { echo "ERROR: swift not found. Install Xcode Command Line Tools."; exit 1; }
	@echo "✓ Swift dependencies satisfied"

# Universal binary builds
universal: universal-pdf21png universal-pdf22png
	@echo "✓ Universal binaries built"

# Build universal binary for pdf21png
universal-pdf21png:
	@echo "→ Building universal binary for pdf21png..."
	@$(MAKE) -C $(PDF21PNG_DIR) universal

# Build universal binary for pdf22png
universal-pdf22png:
	@echo "→ Building universal binary for pdf22png..."
	@$(MAKE) -C $(PDF22PNG_DIR) universal

# Development setup
dev-setup:
	@echo "→ Setting up development environment..."
	@./scripts/dev-setup.sh

# Format code
format:
	@echo "→ Formatting code..."
	@if [ -d "$(PDF22PNG_DIR)" ]; then \
		cd $(PDF22PNG_DIR) && swift-format -i -r Sources/ Tests/; \
	fi
	@echo "✓ Code formatted"

# Lint code
lint:
	@echo "→ Linting code..."
	@if [ -d "$(PDF22PNG_DIR)" ]; then \
		cd $(PDF22PNG_DIR) && swiftlint; \
	fi
	@echo "✓ Linting complete"

# Help target
help:
	@echo "PDF22PNG Project Makefile"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Main targets:"
	@echo "  all              Build both pdf21png and pdf22png (default)"
	@echo "  pdf21png         Build only pdf21png (Objective-C)"
	@echo "  pdf22png         Build only pdf22png (Swift)"
	@echo "  clean            Remove all build artifacts"
	@echo "  install          Install both tools to $(INSTALL_PREFIX)"
	@echo "  uninstall        Remove both tools from $(INSTALL_PREFIX)"
	@echo "  test             Run tests for both implementations"
	@echo "  release          Create release artifacts"
	@echo ""
	@echo "Additional targets:"
	@echo "  objc             Alias for pdf21png"
	@echo "  swift            Alias for pdf22png"
	@echo "  universal        Build universal binaries"
	@echo "  benchmark        Run performance benchmarks"
	@echo "  check-deps       Check build dependencies"
	@echo "  dev-setup        Set up development environment"
	@echo "  format           Format Swift code"
	@echo "  lint             Lint Swift code"
	@echo "  help             Show this help message"
	@echo ""
	@echo "Examples:"
	@echo "  make                    # Build both tools"
	@echo "  make pdf22png          # Build only Swift version"
	@echo "  make test              # Run all tests"
	@echo "  make install           # Install both tools"