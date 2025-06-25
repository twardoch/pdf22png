# pdf22png

[![Version](https://img.shields.io/github/v/release/twardoch/pdf22png?label=version)](https://github.com/twardoch/pdf22png/releases/latest)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-macOS-lightgrey.svg)](https://www.apple.com/macos/)

A high-performance command-line tool for converting PDF documents to PNG images on macOS, available in two separate, self-contained implementations: a performance-optimized Objective-C version and a modern Swift version with advanced features.

## Features

- **Dual Implementation Architecture**: Choose between Objective-C (performance) or Swift (modern features)
- **Single & Batch Conversion**: Convert individual pages or entire PDF documents
- **Flexible Scaling Options**: 
  - Resolution control (DPI)
  - Percentage scaling
  - Fixed dimensions (width/height fitting)
  - Scale factors
- **Advanced Options**:
  - Page range selection (e.g., `1-5,10,15-20`)
  - Text extraction and OCR for smart naming
  - Dry-run mode for operation preview
  - File overwrite protection with prompts
  - Transparent background support
  - PNG compression quality control
  - Enhanced error messages with troubleshooting hints
  - Verbose logging for debugging
- **I/O Flexibility**:
  - Read from files or stdin
  - Write to files, stdout, or batch output directories
  - Customizable output naming patterns
- **Self-Contained Implementations**: Each version is completely independent
- **Universal Binary Support**: Supports both Intel and Apple Silicon Macs

## Installation

### Using Homebrew (Recommended)

```bash
brew tap twardoch/homebrew-pdf22png
brew install pdf22png
```

### Building from Source

Requirements:
- macOS 10.15 or later (macOS 11+ for Swift implementation)
- Xcode Command Line Tools
- Swift 5.7 or later (for Swift implementation only)

```bash
git clone https://github.com/twardoch/pdf22png.git
cd pdf22png
./build.sh
```

#### Build Options

The unified `build.sh` script builds both implementations:

```bash
# Build both implementations (default)
./build.sh

# Build only Objective-C version
./build.sh --objc-only

# Build only Swift version  
./build.sh --swift-only

# Debug builds
./build.sh --debug

# Clean build
./build.sh --clean

# Verbose output
./build.sh --verbose
```

Each implementation can also be built independently:

```bash
# Objective-C implementation
cd pdf22png-objc && make

# Swift implementation  
cd pdf22png-swift && make
```

#### Installation

Each implementation can be installed independently:

```bash
# Install Objective-C version
cd pdf22png-objc && make install

# Install Swift version
cd pdf22png-swift && make install

# Install both (different binary names)
cd pdf22png-objc && make install
cd ../pdf22png-swift && make install
```

## Usage

### Binary Locations

After building, the binaries are located at:
- **Objective-C**: `pdf22png-objc/build/pdf22png`
- **Swift**: `pdf22png-swift/.build/release/pdf22png-swift`

### Basic Syntax

```bash
# Objective-C implementation
./pdf22png-objc/build/pdf22png [OPTIONS] <input.pdf> [output.png]

# Swift implementation
./pdf22png-swift/.build/release/pdf22png-swift [OPTIONS] <input.pdf> [output.png]
```

Both implementations share the same command-line interface and options.

### Quick Examples

Convert first page of a PDF:
```bash
# Using Objective-C implementation
./pdf22png-objc/build/pdf22png input.pdf output.png

# Using Swift implementation
./pdf22png-swift/.build/release/pdf22png-swift input.pdf output.png
```

Convert all pages to individual PNGs:
```bash
./pdf22png-objc/build/pdf22png -a document.pdf
# Creates: document-001.png, document-002.png, etc.
```

Convert at 300 DPI resolution:
```bash
./pdf22png-objc/build/pdf22png -r 300 input.pdf high-res.png
```

Scale to 50% size:
```bash
./pdf22png-objc/build/pdf22png -s 50% input.pdf half-size.png
```

Convert a specific page:
```bash
./pdf22png-objc/build/pdf22png -p 5 document.pdf page5.png
```

### Options

| Option | Long Form | Description | Default |
|--------|-----------|-------------|---------|
| `-p <n>` | `--page` | Convert specific page number or range | 1 |
| `-a` | `--all` | Convert all pages | disabled |
| `-r <dpi>` | `--resolution` | Set output DPI (e.g., 300) | 144 |
| `-s <spec>` | `--scale` | Scale specification (see below) | 100% |
| `-t` | `--transparent` | Preserve transparency | disabled |
| `-q <0-9>` | `--quality` | PNG compression quality | 6 |
| `-o <path>` | `--output` | Output file/prefix or `-` for stdout | - |
| `-d <dir>` | `--directory` | Output directory for batch mode | . |
| `-n` | `--name` | Include extracted text in filenames | disabled |
| `-P <pattern>` | `--pattern` | Custom naming pattern for batch mode | - |
| `-D` | `--dry-run` | Preview operations without writing files | disabled |
| `-f` | `--force` | Force overwrite existing files without prompting | disabled |
| `-v` | `--verbose` | Enable verbose logging | disabled |
| `-h` | `--help` | Show help message | - |

### Scale Specifications

The `-s/--scale` option accepts various formats:

- **Percentage**: `150%` (1.5x scale)
- **Factor**: `2.0` (2x scale)
- **Fixed width**: `800x` (800px wide, height auto)
- **Fixed height**: `x600` (600px high, width auto)
- **Fit within**: `800x600` (fit within 800x600 box)

### Page Ranges

The `-p/--page` option supports flexible page selection:

- **Single page**: `-p 5`
- **Range**: `-p 5-10`
- **Multiple selections**: `-p 1,3,5-10,15`
- **Mix and match**: `-p 1-3,7,10-15`

### Custom Naming Patterns

Use `-P/--pattern` with placeholders for batch conversions:

- `{basename}` or `{name}` - Input filename without extension
- `{page}` - Page number with automatic padding
- `{page:03d}` - Page number with custom padding (e.g., 001, 002)
- `{text}` - Extracted text from page (requires -n flag)
- `{date}` - Current date in YYYYMMDD format
- `{time}` - Current time in HHMMSS format
- `{total}` - Total page count

Example: `./pdf22png-objc/build/pdf22png -P '{basename}_p{page:04d}_of_{total}' doc.pdf`
Creates: `doc_p0001_of_10.png`, `doc_p0002_of_10.png`, etc.

### Advanced Examples

Convert with transparent background at 300 DPI:
```bash
./pdf22png-objc/build/pdf22png -t -r 300 input.pdf transparent-300dpi.png
```

Batch convert all pages to a specific directory:
```bash
./pdf22png-objc/build/pdf22png -d ./output_images -o myprefix document.pdf
# Creates: ./output_images/myprefix-001.png, etc.
```

Convert specific page ranges:
```bash
./pdf22png-objc/build/pdf22png -p 1-3,5,10-15 document.pdf
# Converts pages 1, 2, 3, 5, 10, 11, 12, 13, 14, 15
```

Use custom naming pattern with extracted text:
```bash
./pdf22png-objc/build/pdf22png -a -n -P '{basename}-{page:03d}--{text}' document.pdf
# Creates: document-001--introduction.png, document-002--chapter-one.png, etc.
```

Preview operations with dry-run mode:
```bash
./pdf22png-objc/build/pdf22png -a -D -P 'page_{page}_of_{total}' document.pdf
# Shows what files would be created without actually writing them
```

Force overwrite existing files without prompting:
```bash
./pdf22png-objc/build/pdf22png -f -a document.pdf
# Overwrites existing files without asking
```

Pipe operations:
```bash
# From stdin to stdout
cat document.pdf | ./pdf22png-objc/build/pdf22png - - > output.png

# Process and pipe to ImageMagick
./pdf22png-objc/build/pdf22png -r 300 input.pdf - | convert - -resize 50% final.jpg
```

## Architecture

pdf22png features two completely separate, self-contained implementations:

### Directory Structure

```
pdf22png/
├── pdf22png-objc/          # Objective-C Implementation
│   ├── build/              # Build output
│   ├── pdf22png.m          # Main implementation
│   ├── utils.m             # Utility functions
│   ├── *.h                 # Header files
│   ├── Makefile            # Build system
│   └── README.md           # Implementation-specific docs
├── pdf22png-swift/         # Swift Implementation  
│   ├── .build/             # Swift build output
│   ├── Sources/            # Swift source code
│   ├── Package.swift       # Swift package definition
│   ├── Makefile            # Build system wrapper
│   └── README.md           # Implementation-specific docs
├── build.sh                # Unified build script
└── README.md               # This file
```

### Objective-C Implementation (`pdf22png-objc/`)

**Binary**: `pdf22png-objc/build/pdf22png`  
**Status**: Production-ready, performance-optimized  
**Performance**: Baseline reference

#### Technical Stack
- **Language**: Objective-C with ARC (Automatic Reference Counting)
- **PDF Rendering**: Direct Core Graphics (`CGPDFDocument`, `CGContext`)
- **Image Output**: ImageIO framework with `CGImageDestination`
- **OCR Support**: Vision framework for text extraction
- **File Locking**: POSIX file locking for concurrent access
- **Memory Management**: Optimized with `@autoreleasepool` blocks

#### Key Features
- Maximum performance with minimal overhead
- Efficient memory usage (9-12 MB typical)
- Native macOS API integration
- File locking for concurrent operations
- Comprehensive error reporting with troubleshooting hints

### Swift Implementation (`pdf22png-swift/`)

**Binary**: `pdf22png-swift/.build/release/pdf22png-swift`  
**Status**: Modern, simplified implementation  
**Performance**: Focused on reliability and ease of use

#### Technical Stack
- **Language**: Swift 5.7+ with Swift Package Manager
- **PDF Rendering**: PDFKit and Core Graphics
- **CLI Framework**: Swift Argument Parser
- **Image Output**: Core Graphics with optimized PNG compression
- **Error Handling**: Swift-native error types
- **Build System**: Swift Package Manager with ArgumentParser dependency

#### Key Features
- Modern Swift idioms and type safety
- Simplified, maintainable codebase
- Rich command-line interface with ArgumentParser
- Comprehensive error handling
- Single-file implementation for easier maintenance

### Implementation Comparison

| Feature | Objective-C | Swift |
|---------|-------------|-------|
| **Performance** | Optimized (fastest) | Good (reliable) |
| **Memory Usage** | 9-12 MB | Similar |
| **Binary Size** | ~71 KB | ~1.5 MB |
| **macOS Version** | 10.15+ | 11.0+ |
| **Dependencies** | System frameworks only | System + ArgumentParser |
| **Build Time** | ~2 seconds | ~60 seconds |
| **Complexity** | Full-featured | Simplified |
| **Maintenance** | Traditional C/ObjC | Modern Swift |
| **File Locking** | ✅ POSIX locking | ❌ Not implemented |
| **OCR Support** | ✅ Vision framework | ❌ Not implemented |
| **Transparency** | ✅ Full support | ✅ Full support |
| **Batch Processing** | ✅ Advanced features | ✅ Basic support |

### Choosing an Implementation

**Use Objective-C (`pdf22png-objc`) when:**
- Maximum performance is required
- Processing large batches of PDFs
- Need file locking for concurrent access
- OCR text extraction is needed
- Working with legacy systems
- Binary size matters

**Use Swift (`pdf22png-swift`) when:**
- Modern Swift development environment
- Prefer type-safe, maintainable code
- Simple conversion needs
- Learning or extending the codebase
- Integration with Swift projects

## Building and Development

### Unified Build System

The top-level `build.sh` script manages both implementations:

```bash
# Build both implementations
./build.sh

# Build specific implementation
./build.sh --objc-only
./build.sh --swift-only

# Build options
./build.sh --debug          # Debug builds
./build.sh --clean          # Clean before building
./build.sh --verbose        # Detailed output
./build.sh --help           # Show all options
```

### Individual Build Systems

Each implementation has its own complete build system:

#### Objective-C (`pdf22png-objc/`)
```bash
cd pdf22png-objc
make                        # Release build
make debug                  # Debug build
make universal              # Universal binary (Intel + Apple Silicon)
make install                # Install to /usr/local/bin/pdf22png
make clean                  # Clean build artifacts
make test                   # Run basic functionality test
```

#### Swift (`pdf22png-swift/`)
```bash
cd pdf22png-swift
make                        # Release build (calls swift build -c release)
make debug                  # Debug build
swift build -c release     # Direct Swift build
swift test                  # Run tests (if available)
make install                # Install to /usr/local/bin/pdf22png-swift
make clean                  # Clean build artifacts
```

### Development Workflow

1. **Choose Implementation**: Decide whether to work on Objective-C or Swift version
2. **Navigate to Directory**: `cd pdf22png-objc` or `cd pdf22png-swift`
3. **Make Changes**: Edit source files in the respective directory
4. **Build**: Use `make` or the top-level `./build.sh`
5. **Test**: Run the binary with test PDFs
6. **Install**: Use `make install` for system-wide installation

### Testing

Each implementation can be tested independently:

```bash
# Test Objective-C implementation
cd pdf22png-objc && make test

# Test Swift implementation  
cd pdf22png-swift && make test

# Manual testing
./pdf22png-objc/build/pdf22png --help
./pdf22png-swift/.build/release/pdf22png-swift --help
```

## Performance

Both implementations are optimized for performance with different strengths:

### Shared Optimizations
- Parallel processing for batch conversions using Grand Central Dispatch
- Efficient memory management with autoreleasepool usage
- Native Core Graphics rendering for best quality
- Built-in error recovery for robust batch processing
- Context-aware text extraction with OCR fallback
- Minimal dependencies (only macOS system frameworks)

### Performance Characteristics

#### Speed Comparison
Based on comprehensive benchmarks across various scenarios:

| Test Scenario | Objective-C | Swift | Difference |
|---------------|-------------|-------|------------|
| **Single Page (144 DPI)** | 0.006s | 0.008s | Swift 33% slower |
| **Single Page (300 DPI)** | 0.008s | 0.010s | Swift 25% slower |
| **High Resolution (600 DPI)** | 0.032s | 0.048s | Swift 50% slower |
| **Batch (10 pages)** | 0.061s | 0.089s | Swift 46% slower |
| **With Transparency** | 0.007s | 0.009s | Swift 29% slower |
| **Memory Usage** | 9-12 MB | 9-12 MB | Similar |

#### File Size Comparison
Swift implementation produces significantly smaller files:

| Resolution | Objective-C | Swift | Savings |
|------------|-------------|-------|---------|
| 144 DPI | 198 KB | 69 KB | 65% smaller |
| 300 DPI | 856 KB | 298 KB | 65% smaller |
| 600 DPI | 3.2 MB | 1.1 MB | 66% smaller |

### Performance Analysis

**Objective-C Advantages:**
- Direct Core Graphics calls with minimal overhead
- Optimized for speed over file size
- Better performance at high resolutions
- Faster batch processing

**Swift Advantages:**
- Superior PNG compression algorithm
- Better file size optimization
- Consistent compression ratios
- Modern caching strategies

### Benchmarking Your Workload

Run comprehensive benchmarks on your specific PDFs:

```bash
# Quick benchmark (2 tests)
./bench.sh -q your-document.pdf

# Standard benchmark (5 tests)
./bench.sh your-document.pdf

# Extended benchmark (11 tests)
./bench.sh -e your-document.pdf

# Export results for analysis
./bench.sh -o results.csv your-document.pdf
```

### Performance Recommendations

1. **For Speed**: Use Objective-C (`pdf22png-objc`)
   - High-volume batch processing
   - Time-critical operations
   - Server-side processing

2. **For File Size**: Use Swift (`pdf22png-swift`)
   - Web delivery of images
   - Storage-constrained environments
   - Network bandwidth optimization

3. **Hybrid Approach**: 
   ```bash
   # Fast conversion with ObjC, then optimize with image tools
   ./pdf22png-objc/build/pdf22png -a document.pdf -d temp/
   # Post-process with image optimization tools
   ```

### Real-World Performance Tips

1. **Batch Processing**: Both implementations benefit from processing multiple pages in a single run
2. **Resolution Selection**: Use 144 DPI for screen display, 300 DPI for print
3. **Transparency**: Disable transparency when not needed for ~15% speed improvement
4. **Quality Settings**: Lower PNG quality (`-q 0-4`) for faster processing

## Contributing

Contributions are welcome! Please feel free to submit issues, feature requests, or pull requests.

### Development

#### Building

Use the provided build script for easy compilation:

```bash
# Build both implementations with optimizations
./build.sh

# Build with debug symbols
./build.sh --debug

# Clean and rebuild
./build.sh --clean

# Build universal binary (Intel + Apple Silicon)
./build.sh --universal
```

#### Testing

Run the test suite:
```bash
make test
```

#### Benchmarking

The `bench.sh` script provides comprehensive performance comparisons:

```bash
# Run standard benchmarks
./bench.sh

# Quick benchmarks (fewer tests)
./bench.sh -q

# Extended benchmarks (comprehensive)
./bench.sh -e

# Export results to CSV
./bench.sh -o results.csv

# Use specific PDF
./bench.sh /path/to/test.pdf

# More iterations for accuracy
./bench.sh -i 20

# Verbose output
./bench.sh -v
```

For quick performance testing:
```bash
cd benchmarks && ./compare_implementations.sh
```

### Releasing

To create a new release:
```bash
# Automatic versioning (increments minor version)
./release.sh

# Specify version explicitly
./release.sh --v 2.1.0
```

This will:
1. Build the universal binary
2. Run tests
3. Create and push a git tag
4. Trigger GitHub Actions to build and publish release artifacts

See [TODO.md](TODO.md) for planned features and improvements.

## License

pdf22png is released under the MIT License. See [LICENSE](LICENSE) for details.

## Author

- Created by [Adam Twardoch](https://github.com/twardoch)
- Developed using Anthropic software

## See Also

- [Usage Guide](docs/USAGE.md) - Detailed usage instructions
- [Examples](docs/EXAMPLES.md) - More usage examples
- [API Documentation](docs/API.md) - Function reference
- [Changelog](CHANGELOG.md) - Version history