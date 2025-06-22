
Based on the current repository structure, I can see that `pdf22png` is a macOS-specific tool written in Objective-C for converting PDF files to PNG images. Let me provide a comprehensive description and reorganization plan.

## 1. Project Description

**pdf22png** is a lightweight, high-performance macOS command-line tool that converts PDF documents to PNG images with precision rendering. Built using native macOS frameworks (likely Core Graphics/Quartz), it provides efficient PDF-to-image conversion with support for various resolution settings, page ranges, and output customization options.

### 1.1. Key Features:
- Native macOS implementation for optimal performance
- Page-by-page or batch conversion
- Customizable DPI/resolution settings
- Support for multi-page PDFs
- Minimal dependencies (macOS frameworks only)
- Fast processing using Core Graphics

## 2. Detailed Repository Reorganization Plan

### 2.1. **Directory Structure**

```
pdf22png/
├── .github/
│   ├── workflows/
│   │   ├── build.yml         # CI/CD for building and testing
│   │   ├── release.yml       # Automated releases
│   │   └── homebrew.yml      # Update Homebrew formula on release
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.md
│   │   └── feature_request.md
│   └── FUNDING.yml
├── src/
│   ├── pdf22png.m           # Main implementation (renamed from pdfupng.m)
│   ├── pdf22png.h           # Header file
│   ├── utils.m              # Utility functions
│   └── utils.h
├── tests/
│   ├── test_pdf22png.m      # Unit tests
│   └── fixtures/            # Test PDF files
├── scripts/
│   ├── install.sh           # Installation script
│   ├── uninstall.sh         # Uninstallation script
│   └── build-universal.sh   # Build universal binary
├── homebrew/
│   └── pdf22png.rb          # Homebrew formula template
├── docs/
│   ├── USAGE.md
│   ├── EXAMPLES.md
│   └── API.md
├── .gitignore
├── .gitattributes
├── .editorconfig
├── LICENSE                  # MIT or Apache 2.0
├── README.md
├── CHANGELOG.md
├── TODO.md
├── PROGRESS.md
├── Makefile                 # Enhanced Makefile
├── CMakeLists.txt          # Alternative build system
└── pdf22png.xcodeproj/     # Xcode project (optional)
```

### 2.2. **Enhanced .gitignore**
```gitignore
# this_file: .gitignore

# macOS
.DS_Store
.AppleDouble
.LSOverride
._*
.Spotlight-V100
.Trashes

# Xcode
*.xcworkspace
xcuserdata/
*.xcscmblueprint
*.xccheckout
DerivedData/
*.moved-aside
*.pbxuser
!default.pbxuser
*.mode1v3
!default.mode1v3
*.mode2v3
!default.mode2v3
*.perspectivev3
!default.perspectivev3

# Build products
build/
*.o
*.a
*.dylib
pdf22png
*.dSYM/

# CMake
CMakeCache.txt
CMakeFiles/
cmake_install.cmake
Makefile.cmake

# Testing
test-results/
coverage/
*.gcov
*.gcda
*.gcno

# IDEs
.vscode/
.idea/
*.swp
*.swo
*~
.cursorindexingignore

# Distribution
dist/
*.tar.gz
*.zip
*.dmg

# Documentation
docs/_build/
*.pdf
```

### 2.3. **Modern Makefile**
```makefile
# this_file: Makefile

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
	$(CC) $(CFLAGS) -c -o $@ $

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

test: $(PRODUCT_NAME) $(TEST_OBJECTS)
	@echo "Running tests..."
	@$(CC) $(CFLAGS) $(LDFLAGS) -o test_runner $(TEST_OBJECTS) $(filter-out $(SRCDIR)/pdf22png.o,$(OBJECTS))
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
```

### 2.4. **Homebrew Formula Structure**
```ruby
# this_file: homebrew/pdf22png.rb

class Pdf22png < Formula
  desc "High-performance PDF to PNG converter for macOS"
  homepage "https://github.com/twardoch/pdf22png"
  url "https://github.com/twardoch/pdf22png/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "YOUR_SHA256_HERE"
  license "MIT"
  head "https://github.com/twardoch/pdf22png.git", branch: "main"

  depends_on :macos

  def install
    system "make", "PREFIX=#{prefix}"
    system "make", "install", "PREFIX=#{prefix}"
  end

  test do
    # Create a simple test PDF
    (testpath/"test.pdf").write <<~EOS
      %PDF-1.4
      1 0 obj << /Type /Catalog /Pages 2 0 R >> endobj
      2 0 obj << /Type /Pages /Kids [3 0 R] /Count 1 >> endobj
      3 0 obj << /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] >> endobj
      xref
      0 4
      0000000000 65535 f
      0000000009 00000 n
      0000000058 00000 n
      0000000115 00000 n
      trailer << /Size 4 /Root 1 0 R >>
      startxref
      190
      %%EOF
    EOS

    system "#{bin}/pdf22png", "test.pdf", "output.png"
    assert_predicate testpath/"output.png", :exist?
  end
end
```

### 2.5. **GitHub Actions Workflows**

**Build Workflow (.github/workflows/build.yml)**:
```yaml
# this_file: .github/workflows/build.yml

name: Build and Test

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: macos-latest
    strategy:
      matrix:
        os: [macos-12, macos-13, macos-14]
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Build
      run: make
    
    - name: Run tests
      run: make test
    
    - name: Build universal binary
      run: make universal
    
    - name: Upload artifacts
      uses: actions/upload-artifact@v4
      with:
        name: pdf22png-${{ matrix.os }}
        path: pdf22png
```

**Release Workflow (.github/workflows/release.yml)**:
```yaml
# this_file: .github/workflows/release.yml

name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    runs-on: macos-latest
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Build universal binary
      run: make universal
    
    - name: Create archive
      run: |
        mkdir -p dist
        cp pdf22png dist/
        cp README.md LICENSE docs/USAGE.md dist/
        cd dist && tar -czf pdf22png-${{ github.ref_name }}-macos.tar.gz *
    
    - name: Create Release
      uses: softprops/action-gh-release@v1
      with:
        files: dist/*.tar.gz
        generate_release_notes: true
    
    - name: Update Homebrew formula
      run: |
        # Update SHA256 in formula
        SHA256=$(shasum -a 256 dist/*.tar.gz | cut -d' ' -f1)
        sed -i '' "s/sha256 \".*\"/sha256 \"$SHA256\"/" homebrew/pdf22png.rb
        sed -i '' "s|url \".*\"|url \"https://github.com/twardoch/pdf22png/archive/refs/tags/${{ github.ref_name }}.tar.gz\"|" homebrew/pdf22png.rb
```


