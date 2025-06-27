# PDF22PNG Objective-C Implementation Makefile

# Build configuration
BUILD_DIR = build
INSTALL_PREFIX = /usr/local
VERSION = $(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")

# Compiler settings
CC = clang
CFLAGS = -Wall -Wextra -O2 -fobjc-arc -mmacosx-version-min=10.15
DEBUG_CFLAGS = -Wall -Wextra -O0 -g -fobjc-arc -mmacosx-version-min=10.15
FRAMEWORKS = -framework Foundation -framework CoreGraphics -framework ImageIO \
             -framework Quartz -framework Vision -framework CoreServices \
             -framework UniformTypeIdentifiers

# Source files
SOURCES = src/pdf22png.m src/utils.m
HEADERS = src/pdf22png.h src/utils.h src/errors.h
TARGET = pdf22png

# Default target
all: $(BUILD_DIR)/$(TARGET)

$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)

# Main build target
$(BUILD_DIR)/$(TARGET): $(SOURCES) $(HEADERS) | $(BUILD_DIR)
	@echo "Building PDF22PNG Objective-C implementation..."
	$(CC) $(CFLAGS) $(FRAMEWORKS) -DVERSION=\"$(VERSION)\" $(SOURCES) -o $@
	@echo "✓ Built: $@"

# Debug build
debug: $(BUILD_DIR)/$(TARGET)-debug

$(BUILD_DIR)/$(TARGET)-debug: $(SOURCES) $(HEADERS) | $(BUILD_DIR)
	@echo "Building debug version..."
	$(CC) $(DEBUG_CFLAGS) $(FRAMEWORKS) -DVERSION=\"$(VERSION)\" $(SOURCES) -o $@
	@echo "✓ Debug build: $@"

# Universal binary
universal: $(BUILD_DIR)/$(TARGET)-universal

$(BUILD_DIR)/$(TARGET)-universal: $(SOURCES) $(HEADERS) | $(BUILD_DIR)
	@echo "Building universal binary..."
	$(CC) $(CFLAGS) $(FRAMEWORKS) -DVERSION=\"$(VERSION)\" \
		-arch x86_64 -arch arm64 $(SOURCES) -o $@
	@echo "✓ Universal binary: $@"

# Install
install: $(BUILD_DIR)/$(TARGET)
	@echo "Installing to $(INSTALL_PREFIX)/bin/$(TARGET)..."
	sudo install -m 755 $(BUILD_DIR)/$(TARGET) $(INSTALL_PREFIX)/bin/$(TARGET)
	@echo "✓ Installed: $(INSTALL_PREFIX)/bin/$(TARGET)"

# Uninstall
uninstall:
	@echo "Removing $(INSTALL_PREFIX)/bin/$(TARGET)..."
	sudo rm -f $(INSTALL_PREFIX)/bin/$(TARGET)
	@echo "✓ Uninstalled"

# Clean
clean:
	rm -rf $(BUILD_DIR)
	rm -f *.o

# Test (basic functionality test)
test: $(BUILD_DIR)/$(TARGET)
	@echo "Running basic functionality test..."
	@$(BUILD_DIR)/$(TARGET) --help > /dev/null && echo "✓ Help command works"

# Help
help:
	@echo "PDF22PNG Objective-C Build System"
	@echo "================================="
	@echo ""
	@echo "Targets:"
	@echo "  all        - Build release version (default)"
	@echo "  debug      - Build debug version"
	@echo "  universal  - Build universal binary (Intel + Apple Silicon)"
	@echo "  install    - Install to $(INSTALL_PREFIX)/bin"
	@echo "  uninstall  - Remove from $(INSTALL_PREFIX)/bin"
	@echo "  test       - Run basic functionality test"
	@echo "  clean      - Clean build artifacts"
	@echo "  help       - Show this help"

.PHONY: all debug universal install uninstall clean test help 