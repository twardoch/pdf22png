# pdf22png - Dual Implementation Build System
# This Makefile dispatches to individual implementations in subdirectories

PRODUCT_NAME = pdf22png
VERSION = $(shell git describe --tags --always --dirty)

.PHONY: all clean install uninstall test universal release fmt lint
.PHONY: objc objc-build swift swift-build swift-test swift-clean
.PHONY: install-objc install-swift universal-objc universal-swift

all: swift-build

# Objective-C targets
objc: objc-build

objc-build:
	@echo "Building Objective-C implementation..."
	@$(MAKE) -C pdf22png-objc build

# Swift targets
swift: swift-build

swift-build:
	@echo "Building Swift implementation..."
	@$(MAKE) -C pdf22png-swift build

swift-test:
	@echo "Running Swift tests..."
	@$(MAKE) -C pdf22png-swift test

swift-clean:
	@echo "Cleaning Swift build..."
	@$(MAKE) -C pdf22png-swift clean

# Universal binary targets
universal: universal-swift

universal-objc:
	@echo "Building universal binary (Objective-C)..."
	@$(MAKE) -C pdf22png-objc universal

universal-swift:
	@echo "Building universal binary (Swift)..."
	@$(MAKE) -C pdf22png-swift universal

# Install targets
install: install-swift

install-objc:
	@echo "Installing $(PRODUCT_NAME) (Objective-C)..."
	@$(MAKE) -C pdf22png-objc install

install-swift:
	@echo "Installing $(PRODUCT_NAME) (Swift)..."
	@$(MAKE) -C pdf22png-swift install

uninstall:
	@echo "Uninstalling $(PRODUCT_NAME)..."
	@$(MAKE) -C pdf22png-objc uninstall
	@$(MAKE) -C pdf22png-swift uninstall

# Test targets
test: swift-test test-objc

test-objc:
	@echo "Running Objective-C tests..."
	@$(MAKE) -C pdf22png-objc test

# Clean targets
clean: clean-objc swift-clean

clean-objc:
	@echo "Cleaning Objective-C build..."
	@$(MAKE) -C pdf22png-objc clean

fmt:
	@echo "Formatting code..."
	@$(MAKE) -C pdf22png-objc fmt
	@$(MAKE) -C pdf22png-swift fmt

lint:
	@echo "Linting code..."
	@$(MAKE) -C pdf22png-objc lint
	@$(MAKE) -C pdf22png-swift lint

# Release build with version info
release: release-swift

release-objc:
	@echo "Building Objective-C release: $(VERSION)"
	@$(MAKE) -C pdf22png-objc release

release-swift:
	@echo "Building Swift release: $(VERSION)"
	@$(MAKE) -C pdf22png-swift release