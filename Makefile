# pdf22png - Streamlined Swift Build System

PRODUCT_NAME = pdf22png
VERSION = $(shell git describe --tags --always --dirty)
PREFIX ?= /usr/local

.PHONY: all clean install uninstall test universal release fmt lint

all: build

# Build targets
build:
	@echo "Building $(PRODUCT_NAME)..."
	@$(MAKE) -C src build

release:
	@echo "Building $(PRODUCT_NAME) release: $(VERSION)"
	@$(MAKE) -C src release

universal:
	@echo "Building universal binary..."
	@$(MAKE) -C src universal

# Test targets
test:
	@echo "Running tests..."
	@$(MAKE) -C src test

# Install targets
install: build install-man
	@echo "Installing $(PRODUCT_NAME)..."
	@$(MAKE) -C src install PREFIX=$(PREFIX)

install-man:
	@echo "Installing man page..."
	@mkdir -p $(PREFIX)/share/man/man1
	@cp docs/pdf22png.1 $(PREFIX)/share/man/man1/
	@echo "Man page installed. Use 'man pdf22png' to view."

uninstall:
	@echo "Uninstalling $(PRODUCT_NAME)..."
	@$(MAKE) -C src uninstall PREFIX=$(PREFIX)
	@rm -f $(PREFIX)/share/man/man1/pdf22png.1
	@echo "Man page removed."

# Clean targets
clean:
	@echo "Cleaning build..."
	@$(MAKE) -C src clean

# Code quality targets
fmt:
	@echo "Formatting code..."
	@$(MAKE) -C src fmt

lint:
	@echo "Linting code..."
	@$(MAKE) -C src lint

# Show build information
info:
	@echo "Product: $(PRODUCT_NAME)"
	@echo "Version: $(VERSION)"
	@echo "Prefix: $(PREFIX)"
	@echo "Swift version: $(shell swift --version | head -n1)"