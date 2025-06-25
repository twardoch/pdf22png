# Variables
PRODUCT_NAME = pdf22png
CC = clang
CFLAGS = -Wall -Wextra -O2 -fobjc-arc -mmacosx-version-min=10.15
LDFLAGS = -framework Foundation -framework CoreGraphics -framework AppKit -framework Vision
PREFIX = /usr/local
BINDIR = $(PREFIX)/bin
SRCDIR = src
TESTDIR = tests
BUILDDIR = build
VERSION = $(shell git describe --tags --always --dirty)

# Source files
SOURCES = $(SRCDIR)/pdf22png.m $(SRCDIR)/utils.m
OBJECTS = $(SOURCES:.m=.o)
TEST_SOURCES = $(TESTDIR)/test_runner.m
TEST_OBJECTS = $(TEST_SOURCES:.m=.o)

# Targets
.PHONY: all clean install uninstall test universal release fmt lint

all: $(BUILDDIR)/$(PRODUCT_NAME)

$(BUILDDIR)/$(PRODUCT_NAME): $(OBJECTS) | $(BUILDDIR)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^

$(BUILDDIR):
	@mkdir -p $(BUILDDIR)

%.o: %.m
	$(CC) $(CFLAGS) -c -o $@ $<

# Universal binary for Intel and Apple Silicon
universal:
	@echo "Building universal binary..."
	@scripts/build-universal.sh

install: $(BUILDDIR)/$(PRODUCT_NAME)
	@echo "Installing $(PRODUCT_NAME) to $(BINDIR)..."
	@install -d $(BINDIR)
	@install -m 755 $(BUILDDIR)/$(PRODUCT_NAME) $(BINDIR)/
	@echo "Installation complete!"

uninstall:
	@echo "Uninstalling $(PRODUCT_NAME)..."
	@rm -f $(BINDIR)/$(PRODUCT_NAME)
	@echo "Uninstallation complete!"

test: $(BUILDDIR)/$(PRODUCT_NAME) $(TEST_OBJECTS)
	@echo "Running tests..."
	@$(CC) $(CFLAGS) $(LDFLAGS) -o $(BUILDDIR)/test_runner $(TEST_OBJECTS) $(filter-out $(SRCDIR)/pdf22png.o,$(OBJECTS))
	@$(BUILDDIR)/test_runner

clean:
	@rm -f $(OBJECTS) $(TEST_OBJECTS)
	@rm -rf $(BUILDDIR) *.dSYM
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
	$(MAKE) CFLAGS="$(CFLAGS) -DVERSION=\\"$(VERSION)\\""
	@echo "Release build complete: $(VERSION)"
