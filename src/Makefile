PRODUCT_NAME = pdf22png
SWIFT = xcrun swiftc
BUILDDIR = build
SOURCE = src/main.swift

.PHONY: all clean test

all: build

build:
	@echo "Building standalone Swift version..."
	@mkdir -p $(BUILDDIR)
	@$(SWIFT) -O -o $(BUILDDIR)/$(PRODUCT_NAME) $(SOURCE)
	@echo "Standalone Swift build complete!"

clean:
	@echo "Cleaning build directory..."
	@rm -rf $(BUILDDIR)
	@echo "Clean complete!"

test: build
	@echo "Testing standalone Swift implementation..."
	@./test-framework.swift