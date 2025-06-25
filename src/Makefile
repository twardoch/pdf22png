PRODUCT_NAME = pdf22png
SWIFT = swiftc
BUILDDIR = build
SWIFT_FILES = $(shell find . -name "*.swift" | grep -v test-framework.swift)
JOBS := $(shell sysctl -n hw.ncpu 2>/dev/null || echo 4)
SWIFT_FLAGS = -O -whole-module-optimization -num-threads $(JOBS)

.PHONY: all build clean test install format docs help lint quick-build test-all

all: build

build:
	@echo "Building modular Swift version..."
	@mkdir -p $(BUILDDIR)
	@$(SWIFT) $(SWIFT_FLAGS) -o $(BUILDDIR)/$(PRODUCT_NAME) $(SWIFT_FILES)
	@echo "✅ Modular Swift build complete!"

quick-build:
	@echo "Quick incremental build..."
	@mkdir -p $(BUILDDIR)
	@$(SWIFT) -O -o $(BUILDDIR)/$(PRODUCT_NAME) $(SWIFT_FILES)
	@echo "✅ Quick build complete!"

# Try SPM build first, fallback to swiftc if SPM fails
build-spm:
	@echo "Attempting Swift Package Manager build..."
	@swift build -c release 2>/dev/null || $(MAKE) build
	@echo "Build complete!"

clean:
	@echo "Cleaning build artifacts..."
	@rm -rf $(BUILDDIR) .build $(PRODUCT_NAME)
	@echo "✅ Clean complete!"

test: build
	@echo "Testing modular Swift implementation..."
	@../Tests/test-framework.swift
	@echo "✅ Tests complete!"

test-all: build
	@echo "Running all test suites..."
	@../Tests/test-framework.swift
	@echo "✅ All tests complete!"

install: build
	@echo "Installing pdf22png..."
	@cp $(BUILDDIR)/$(PRODUCT_NAME) /usr/local/bin/
	@echo "✅ Installed to /usr/local/bin/$(PRODUCT_NAME)"

format:
	@if command -v swift-format >/dev/null 2>&1; then \
		echo "Formatting Swift code..."; \
		swift-format format --recursive . --in-place; \
		swift-format format --recursive ../Tests --in-place; \
		echo "✅ Formatting complete!"; \
	else \
		echo "⚠️  swift-format not found. Install with: brew install swift-format"; \
	fi

fmt: format

lint:
	@if command -v swiftlint >/dev/null 2>&1; then \
		echo "Linting Swift code..."; \
		cd .. && swiftlint lint; \
		echo "✅ Linting complete!"; \
	else \
		echo "⚠️  SwiftLint not found. Install with: brew install swiftlint"; \
	fi

docs:
	@if command -v swift >/dev/null 2>&1; then \
		echo "Generating documentation..."; \
		swift package generate-documentation 2>/dev/null || echo "⚠️  Documentation generation requires SPM structure"; \
	else \
		echo "⚠️  Swift not found in PATH"; \
	fi

help:
	@echo "pdf22png Makefile Commands:"
	@echo ""
	@echo "Build targets:"
	@echo "  build        - Build with optimizations (parallel compilation)"
	@echo "  quick-build  - Fast incremental build"
	@echo "  build-spm    - Build with Swift Package Manager (fallback to swiftc)"
	@echo ""
	@echo "Quality targets:"
	@echo "  lint         - Run SwiftLint code analysis"
	@echo "  format       - Format Swift code (requires swift-format)"
	@echo "  fmt          - Alias for format"
	@echo ""
	@echo "Test targets:"
	@echo "  test         - Run tests"
	@echo "  test-all     - Run all test suites"
	@echo ""
	@echo "Other targets:"
	@echo "  clean        - Remove build artifacts"
	@echo "  install      - Install to /usr/local/bin"
	@echo "  docs         - Generate documentation (requires SPM)"
	@echo "  help         - Show this help message"