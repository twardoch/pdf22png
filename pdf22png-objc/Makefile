# Variables
PRODUCT_NAME = pdf22png
CC = clang
PREFIX = /usr/local
BINDIR = $(PREFIX)/bin
BUILDDIR = build
SRCDIR = src
VERSION = $(shell git describe --tags --always --dirty 2>/dev/null || echo "1.0.0")

# Compiler flags
CFLAGS = -Wall -Wextra -O2 -fobjc-arc -std=c99
OBJCFLAGS = -Wall -Wextra -O2 -fobjc-arc
FRAMEWORKS = -framework Foundation -framework CoreGraphics -framework Quartz -framework ImageIO -framework PDFKit
UNIVERSAL_FLAGS = -arch arm64 -arch x86_64

# Source files
OBJC_SOURCES = $(SRCDIR)/pdf22png.m $(SRCDIR)/utils.m
OBJECTS = $(OBJC_SOURCES:.m=.o)

# Default target
.PHONY: all clean install uninstall test universal release fmt lint

all: build

%.o: %.m
	@echo "Compiling $<..."
	@$(CC) $(OBJCFLAGS) -c $< -o $@ $(FRAMEWORKS)

build: $(OBJECTS)
	@echo "Building Objective-C implementation..."
	@mkdir -p $(BUILDDIR)
	@$(CC) $(OBJCFLAGS) -o $(BUILDDIR)/$(PRODUCT_NAME) $(OBJECTS) $(FRAMEWORKS)
	@echo "Objective-C build complete!"

# Universal binary target
universal:
	@echo "Building universal binary (Objective-C)..."
	@mkdir -p $(BUILDDIR)
	@$(CC) $(OBJCFLAGS) $(UNIVERSAL_FLAGS) -o $(BUILDDIR)/$(PRODUCT_NAME)-universal $(OBJC_SOURCES) $(FRAMEWORKS)
	@echo "Universal Objective-C build complete!"

# Install target
install: build
	@echo "Installing $(PRODUCT_NAME) (Objective-C) to $(BINDIR)..."
	@install -d $(BINDIR)
	@install -m 755 $(BUILDDIR)/$(PRODUCT_NAME) $(BINDIR)/$(PRODUCT_NAME)
	@echo "Installation complete!"

uninstall:
	@echo "Uninstalling $(PRODUCT_NAME)..."
	@rm -f $(BINDIR)/$(PRODUCT_NAME)
	@echo "Uninstallation complete!"

clean:
	@echo "Cleaning Objective-C build..."
	@rm -f $(OBJECTS)
	@rm -rf $(BUILDDIR)
	@echo "Objective-C clean complete!"

test: build
	@echo "Running Objective-C tests..."
	@if [ -f Tests/test_runner.m ]; then \
		$(CC) $(OBJCFLAGS) -o $(BUILDDIR)/test_runner Tests/test_runner.m $(OBJECTS) $(FRAMEWORKS) && \
		./$(BUILDDIR)/test_runner; \
	else \
		echo "No test runner found, skipping tests"; \
	fi

fmt:
	@echo "Formatting Objective-C code..."
	@if command -v clang-format >/dev/null 2>&1; then \
		clang-format -i $(SRCDIR)/*.m $(SRCDIR)/*.h; \
	else \
		echo "clang-format not installed, skipping formatting"; \
	fi

lint:
	@echo "Linting Objective-C code..."
	@if command -v clang-tidy >/dev/null 2>&1; then \
		clang-tidy $(SRCDIR)/*.m -- $(OBJCFLAGS) $(FRAMEWORKS); \
	else \
		echo "clang-tidy not installed, skipping linting"; \
	fi

# Release build with version info
release:
	@echo "Building Objective-C release: $(VERSION)"
	@mkdir -p $(BUILDDIR)
	@$(CC) $(OBJCFLAGS) $(UNIVERSAL_FLAGS) -DVERSION=\"$(VERSION)\" -o $(BUILDDIR)/$(PRODUCT_NAME) $(OBJC_SOURCES) $(FRAMEWORKS)
	@echo "Objective-C release build complete: $(VERSION)"