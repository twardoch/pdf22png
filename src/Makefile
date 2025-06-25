PRODUCT_NAME = pdf22png
SWIFT = swiftc
BUILDDIR = build
SWIFT_FILES = $(shell find . -name "*.swift" | grep -v test-framework.swift)

.PHONY: all build clean test install format docs help

all: build

build:
	@echo "Building modular Swift version..."
	@mkdir -p $(BUILDDIR)
	@$(SWIFT) -O -o $(BUILDDIR)/$(PRODUCT_NAME) $(SWIFT_FILES)
	@echo "✅ Modular Swift build complete!"

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

install: build
	@echo "Installing pdf22png..."
	@cp $(BUILDDIR)/$(PRODUCT_NAME) /usr/local/bin/
	@echo "✅ Installed to /usr/local/bin/$(PRODUCT_NAME)"

format:
	@if command -v swift-format >/dev/null 2>&1; then \
		echo "Formatting Swift code..."; \
		swift-format format --recursive . --in-place; \
		echo "✅ Formatting complete!"; \
	else \
		echo "⚠️  swift-format not found. Install with: brew install swift-format"; \
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
	@echo "  build      - Build the application with all modules"
	@echo "  build-spm  - Build with Swift Package Manager (fallback to swiftc)"
	@echo "  clean      - Remove build artifacts"
	@echo "  test       - Run tests"
	@echo "  install    - Install to /usr/local/bin"
	@echo "  format     - Format Swift code (requires swift-format)"
	@echo "  docs       - Generate documentation (requires SPM)"
	@echo "  help       - Show this help message"