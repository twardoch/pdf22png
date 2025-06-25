# Variables
PRODUCT_NAME = pdf22png
CC = clang
SWIFT = swift
CFLAGS = -Wall -Wextra -O2 -fobjc-arc -mmacosx-version-min=10.15
LDFLAGS = -framework Foundation -framework CoreGraphics -framework AppKit -framework Vision
PREFIX = /usr/local
BINDIR = $(PREFIX)/bin
SRCDIR = src
TESTDIR = tests
BUILDDIR = build
SWIFT_BUILDDIR = .build
VERSION = $(shell git describe --tags --always --dirty)

# Source files
SOURCES = $(SRCDIR)/pdf22png.m $(SRCDIR)/utils.m
OBJECTS = $(SOURCES:.m=.o)
TEST_SOURCES = $(TESTDIR)/test_runner.m
TEST_OBJECTS = $(TEST_SOURCES:.m=.o)

# Default target builds Swift version
.PHONY: all clean install uninstall test universal release fmt lint
.PHONY: objc objc-build swift swift-build swift-test swift-clean
.PHONY: install-objc install-swift universal-objc universal-swift

all: swift-build

# Objective-C targets
objc: objc-build

objc-build: $(BUILDDIR)/$(PRODUCT_NAME)-objc

$(BUILDDIR)/$(PRODUCT_NAME)-objc: $(OBJECTS) | $(BUILDDIR)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^

$(BUILDDIR):
	@mkdir -p $(BUILDDIR)

%.o: %.m
	$(CC) $(CFLAGS) -c -o $@ $<

# Swift targets
swift: swift-build

swift-build:
	@echo "Building Swift version..."
	@$(SWIFT) build -c release
	@mkdir -p $(BUILDDIR)
	@cp $(SWIFT_BUILDDIR)/release/$(PRODUCT_NAME) $(BUILDDIR)/$(PRODUCT_NAME)
	@echo "Swift build complete!"

swift-test:
	@echo "Running Swift tests..."
	@$(SWIFT) test

swift-clean:
	@echo "Cleaning Swift build..."
	@$(SWIFT) package clean
	@rm -rf $(SWIFT_BUILDDIR)

# Universal binary targets
universal: universal-swift

universal-objc:
	@echo "Building universal binary (Objective-C)..."
	@scripts/build-universal.sh objc

universal-swift:
	@echo "Building universal binary (Swift)..."
	@$(SWIFT) build -c release --arch arm64 --arch x86_64
	@mkdir -p $(BUILDDIR)
	@cp $(SWIFT_BUILDDIR)/apple/Products/Release/$(PRODUCT_NAME) $(BUILDDIR)/$(PRODUCT_NAME)-universal
	@echo "Universal Swift build complete!"

# Install targets
install: install-swift

install-objc: $(BUILDDIR)/$(PRODUCT_NAME)-objc
	@echo "Installing $(PRODUCT_NAME) (Objective-C) to $(BINDIR)..."
	@install -d $(BINDIR)
	@install -m 755 $(BUILDDIR)/$(PRODUCT_NAME)-objc $(BINDIR)/$(PRODUCT_NAME)
	@echo "Installation complete!"

install-swift: swift-build
	@echo "Installing $(PRODUCT_NAME) (Swift) to $(BINDIR)..."
	@install -d $(BINDIR)
	@install -m 755 $(BUILDDIR)/$(PRODUCT_NAME) $(BINDIR)/
	@echo "Installation complete!"

uninstall:
	@echo "Uninstalling $(PRODUCT_NAME)..."
	@rm -f $(BINDIR)/$(PRODUCT_NAME)
	@echo "Uninstallation complete!"

# Test targets
test: swift-test test-objc

test-objc: $(BUILDDIR)/$(PRODUCT_NAME)-objc $(TEST_OBJECTS)
	@echo "Running Objective-C tests..."
	@$(CC) $(CFLAGS) $(LDFLAGS) -o $(BUILDDIR)/test_runner $(TEST_OBJECTS) $(filter-out $(SRCDIR)/pdf22png.o,$(OBJECTS))
	@$(BUILDDIR)/test_runner

# Clean targets
clean: clean-objc swift-clean

clean-objc:
	@rm -f $(OBJECTS) $(TEST_OBJECTS)
	@rm -rf $(BUILDDIR) *.dSYM
	@echo "Objective-C clean complete!"

fmt:
	@echo "Formatting Objective-C code..."
	@clang-format -i $(SRCDIR)/*.m $(SRCDIR)/*.h $(TESTDIR)/*.m
	@echo "Formatting Swift code..."
	@if command -v swift-format >/dev/null 2>&1; then \
		swift-format -i Sources/**/*.swift Tests/**/*.swift; \
	else \
		echo "swift-format not installed, skipping Swift formatting"; \
	fi

lint:
	@echo "Linting Objective-C code..."
	@oclint $(SOURCES) -- $(CFLAGS)
	@echo "Linting Swift code..."
	@if command -v swiftlint >/dev/null 2>&1; then \
		swiftlint; \
	else \
		echo "SwiftLint not installed, skipping Swift linting"; \
	fi

# Release build with version info
release: release-swift

release-objc:
	$(MAKE) clean-objc
	$(MAKE) objc-build CFLAGS="$(CFLAGS) -DVERSION=\\"$(VERSION)\\""
	@echo "Objective-C release build complete: $(VERSION)"

release-swift:
	@echo "Building Swift release: $(VERSION)"
	@$(SWIFT) build -c release --arch arm64 --arch x86_64
	@mkdir -p $(BUILDDIR)
	@cp $(SWIFT_BUILDDIR)/apple/Products/Release/$(PRODUCT_NAME) $(BUILDDIR)/$(PRODUCT_NAME)
	@echo "Swift release build complete: $(VERSION)"
