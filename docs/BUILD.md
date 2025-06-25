# Building pdf22png

This guide covers building pdf22png from source for both the Swift and Objective-C implementations.

## Prerequisites

### General Requirements
- macOS 10.15 (Catalina) or later
- Xcode Command Line Tools
- Git

### Swift Version Requirements
- Swift 5.7 or later
- Swift Package Manager (included with Xcode)

### Objective-C Version Requirements
- Clang compiler (included with Xcode Command Line Tools)
- GNU Make

## Quick Start

```bash
# Clone the repository
git clone https://github.com/twardoch/pdf22png.git
cd pdf22png

# Build default (Swift) version
make

# Build Objective-C version
make objc

# Build both versions
make swift objc
```

## Detailed Build Instructions

### Swift Version

#### Using Make (Recommended)
```bash
# Build release version
make swift

# Clean Swift build
make swift-clean

# Run Swift tests
make swift-test
```

#### Using Swift Package Manager Directly
```bash
# Build debug version
swift build

# Build release version
swift build -c release

# Run tests
swift test

# Clean
swift package clean
```

### Objective-C Version

#### Using Make
```bash
# Build release version
make objc

# Clean Objective-C build
make clean-objc

# Run Objective-C tests
make test-objc
```

#### Manual Compilation
```bash
# Compile object files
clang -Wall -Wextra -O2 -fobjc-arc -mmacosx-version-min=10.15 -c src/pdf22png.m -o src/pdf22png.o
clang -Wall -Wextra -O2 -fobjc-arc -mmacosx-version-min=10.15 -c src/utils.m -o src/utils.o

# Link executable
clang -framework Foundation -framework CoreGraphics -framework AppKit -framework Vision \
      -o build/pdf22png src/pdf22png.o src/utils.o
```

## Universal Binary

### Building for Intel and Apple Silicon

#### Swift Universal Binary
```bash
make universal
# or
make universal-swift
```

#### Objective-C Universal Binary
```bash
make universal-objc
```

#### Manual Universal Binary
```bash
# Build for each architecture
swift build -c release --arch arm64
swift build -c release --arch x86_64

# Combine using lipo
lipo -create \
     .build/arm64-apple-macosx/release/pdf22png \
     .build/x86_64-apple-macosx/release/pdf22png \
     -output pdf22png-universal
```

## Build Configurations

### Debug Builds

#### Swift Debug
```bash
swift build
# Binary at: .build/debug/pdf22png
```

#### Objective-C Debug
```bash
make objc CFLAGS="-g -O0 -DDEBUG"
```

### Release Builds

#### Swift Release
```bash
make swift
# or
swift build -c release
```

#### Objective-C Release
```bash
make objc
# Optimized with -O2 by default
```

## Installation

### System-wide Installation

```bash
# Install Swift version (default)
sudo make install

# Install Objective-C version
sudo make install-objc

# Install to custom prefix
make install PREFIX=/usr/local
```

### Local Installation

```bash
# Copy to local bin directory
cp build/pdf22png ~/bin/

# Or create a symlink
ln -s $(pwd)/build/pdf22png ~/bin/pdf22png
```

## Build Troubleshooting

### Common Issues

#### Swift Build Errors

1. **Missing Swift toolchain**
   ```
   Error: swift command not found
   ```
   Solution: Install Xcode or Xcode Command Line Tools

2. **Package resolution failed**
   ```
   Error: Failed to resolve dependencies
   ```
   Solution: 
   ```bash
   swift package update
   swift package resolve
   ```

3. **Minimum deployment target**
   ```
   Error: Compiling for macOS 10.14, but module requires 10.15
   ```
   Solution: Update Package.swift platform requirement

#### Objective-C Build Errors

1. **Missing frameworks**
   ```
   ld: framework not found Vision
   ```
   Solution: Update macOS and Xcode Command Line Tools

2. **ARC errors**
   ```
   error: 'release' is unavailable in ARC
   ```
   Solution: Ensure `-fobjc-arc` flag is present

3. **Architecture mismatch**
   ```
   ld: symbol(s) not found for architecture x86_64
   ```
   Solution: Build universal binary or specify architecture

### Verifying the Build

```bash
# Check version
./build/pdf22png --version

# Run help
./build/pdf22png --help

# Test basic conversion
./build/pdf22png test.pdf output.png
```

## Build System Details

### Makefile Targets

| Target | Description |
|--------|-------------|
| `all` | Build Swift version (default) |
| `swift` | Build Swift release version |
| `objc` | Build Objective-C version |
| `universal` | Build Swift universal binary |
| `universal-objc` | Build ObjC universal binary |
| `test` | Run all tests |
| `clean` | Clean all builds |
| `install` | Install Swift version |
| `install-objc` | Install ObjC version |

### Build Artifacts

```
build/
├── pdf22png           # Swift executable
├── pdf22png-objc      # Objective-C executable
├── pdf22png-universal # Universal binary
└── test_runner        # Test executable
```

### Dependencies

#### Swift Dependencies
- swift-argument-parser (via Swift Package Manager)

#### System Frameworks
Both versions require:
- Foundation
- CoreGraphics
- AppKit (for PDFDocument)
- Vision (for OCR)
- ImageIO

## Advanced Building

### Cross-compilation

While pdf22png is macOS-only, you can build for different macOS versions:

```bash
# Target older macOS
swift build -c release \
  -Xswiftc -target -Xswiftc x86_64-apple-macos10.15

# Objective-C for older macOS
make objc CFLAGS="-mmacosx-version-min=10.14"
```

### Custom Optimizations

#### Swift Optimizations
```bash
swift build -c release \
  -Xswiftc -O \
  -Xswiftc -whole-module-optimization
```

#### Objective-C Optimizations
```bash
make objc CFLAGS="-O3 -flto -march=native"
```

### Static Analysis

#### Swift
```bash
# If SwiftLint is installed
swiftlint
```

#### Objective-C
```bash
# Using clang static analyzer
scan-build make objc

# Using oclint
make lint
```