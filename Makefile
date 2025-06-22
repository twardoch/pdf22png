# Variables
PRODUCT_NAME = pdf22png
CC = clang
CFLAGS = -Wall -Wextra -O2 -fobjc-arc -mmacosx-version-min=10.15
LDFLAGS = -framework Foundation -framework CoreGraphics -framework AppKit
PREFIX = /usr/local
BINDIR = $(PREFIX)/bin
SRCDIR = src
TESTDIR = tests
VERSION = $(shell git describe --tags --always --dirty)

# Source files
SOURCES = $(SRCDIR)/pdf22png.m $(SRCDIR)/utils.m
OBJECTS = $(SOURCES:.m=.o)
TEST_SOURCES = $(TESTDIR)/test_pdf22png.m
TEST_OBJECTS = $(TEST_SOURCES:.m=.o)

# Targets
.PHONY: all clean install uninstall test universal release fmt lint

all: $(PRODUCT_NAME)

$(PRODUCT_NAME): $(OBJECTS)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^

%.o: %.m
	$(CC) $(CFLAGS) -c -o $@ $<

# Universal binary for Intel and Apple Silicon
universal:
	@echo "Building universal binary..."
	@scripts/build-universal.sh

install: $(PRODUCT_NAME)
	@echo "Installing $(PRODUCT_NAME) to $(BINDIR)..."
	@install -d $(BINDIR)
	@install -m 755 $(PRODUCT_NAME) $(BINDIR)/
	@echo "Installation complete!"

uninstall:
	@echo "Uninstalling $(PRODUCT_NAME)..."
	@rm -f $(BINDIR)/$(PRODUCT_NAME)
	@echo "Uninstallation complete!"

TEST_LDFLAGS = $(LDFLAGS) -framework XCTest

test: $(PRODUCT_NAME) $(TEST_OBJECTS)
	@echo "Running tests..."
	@$(CC) $(CFLAGS) $(TEST_LDFLAGS) -o test_runner $(TEST_OBJECTS) $(filter-out $(SRCDIR)/pdf22png.o,$(OBJECTS))
	@./test_runner

clean:
	@rm -f $(OBJECTS) $(TEST_OBJECTS) $(PRODUCT_NAME) test_runner
	@rm -rf *.dSYM
	@echo "Clean complete!"

fmt:
	@echo "Formatting code..."
	@clang-format -i $(SRCDIR)/*.m $(SRCDIR)/*.h $(TESTDIR)/*.m

lint:
	@echo "Linting code..."
	@oclint $(SOURCES) -- $(CFLAGS)

# Release build with version info
release:
	$(MAKE) clean
	$(MAKE) CFLAGS="$(CFLAGS) -DVERSION=\"$(VERSION)\""
	@echo "Release build complete: $(VERSION)"
