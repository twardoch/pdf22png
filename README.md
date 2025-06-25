# pdf22png

[![Version](https://img.shields.io/github/v/release/twardoch/pdf22png?label=version)](https://github.com/twardoch/pdf22png/releases/latest)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-macOS-lightgrey.svg)](https://www.apple.com/macos/)

A high-performance command-line tool for converting PDF documents to PNG images on macOS, leveraging native Core Graphics and Quartz frameworks for optimal quality and speed. Available in both Objective-C and Swift implementations with comprehensive performance benchmarks.

## Features

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
- **Native Performance**: Built with Objective-C using macOS native frameworks
- **Swift Implementation**: Modern Swift port with identical functionality
- **Performance Benchmarks**: Comprehensive benchmark suite comparing both implementations
- **Universal Binary**: Supports both Intel and Apple Silicon Macs

## Installation

### Using Homebrew (Recommended)

```bash
brew tap twardoch/homebrew-pdf22png
brew install pdf22png
```

### Building from Source

Requirements:
- macOS 10.15 or later
- Xcode Command Line Tools
- Swift 5.5 or later (for Swift implementation)

```bash
git clone https://github.com/twardoch/pdf22png.git
cd pdf22png
./build.sh
sudo make install
```

#### Build Options

The `build.sh` script provides comprehensive build options:

```bash
# Build both implementations (default)
./build.sh

# Build only Objective-C version
./build.sh --objc-only

# Build only Swift version  
./build.sh --swift-only

# Build universal binary for Objective-C
./build.sh --universal

# Clean build
./build.sh --clean

# Debug build
./build.sh --debug
```

Alternatively, use Make directly:

```bash
# Build Objective-C version
make

# Build Swift version
make swift

# Build both
make both

# Universal binary
make universal
```

## Usage

### Basic Syntax

```bash
pdf22png [OPTIONS] <input.pdf> [output.png]
```

### Quick Examples

Convert first page of a PDF:
```bash
pdf22png input.pdf output.png
```

Convert a specific page:
```bash
pdf22png -p 5 document.pdf page5.png
```

Convert all pages to individual PNGs:
```bash
pdf22png -a document.pdf
# Creates: document-001.png, document-002.png, etc.
```

Convert at 300 DPI resolution:
```bash
pdf22png -r 300 input.pdf high-res.png
```

Scale to 50% size:
```bash
pdf22png -s 50% input.pdf half-size.png
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

Example: `pdf22png -P '{basename}_p{page:04d}_of_{total}' doc.pdf`
Creates: `doc_p0001_of_10.png`, `doc_p0002_of_10.png`, etc.

### Advanced Examples

Convert with transparent background at 300 DPI:
```bash
pdf22png -t -r 300 input.pdf transparent-300dpi.png
```

Batch convert all pages to a specific directory:
```bash
pdf22png -d ./output_images -o myprefix document.pdf
# Creates: ./output_images/myprefix-001.png, etc.
```

Convert specific page ranges:
```bash
pdf22png -p 1-3,5,10-15 document.pdf
# Converts pages 1, 2, 3, 5, 10, 11, 12, 13, 14, 15
```

Use custom naming pattern with extracted text:
```bash
pdf22png -a -n -P '{basename}-{page:03d}--{text}' document.pdf
# Creates: document-001--introduction.png, document-002--chapter-one.png, etc.
```

Preview operations with dry-run mode:
```bash
pdf22png -a -D -P 'page_{page}_of_{total}' document.pdf
# Shows what files would be created without actually writing them
```

Force overwrite existing files without prompting:
```bash
pdf22png -f -a document.pdf
# Overwrites existing files without asking
```

Pipe operations:
```bash
# From stdin to stdout
cat document.pdf | pdf22png - - > output.png

# Process and pipe to ImageMagick
pdf22png -r 300 input.pdf - | convert - -resize 50% final.jpg
```

## Architecture

pdf22png is available in two implementations, each with distinct characteristics:

### Objective-C Implementation (Original)

**Binary**: `pdf22png`  
**Status**: Production-ready, optimized  
**Performance**: Baseline reference

#### Technical Stack
- **Language**: Objective-C with ARC (Automatic Reference Counting)
- **PDF Rendering**: Direct Core Graphics (`CGPDFDocument`, `CGContext`)
- **Image Output**: ImageIO framework with `CGImageDestination`
- **OCR Support**: Vision framework for text extraction fallback
- **Type Safety**: Modern `UTTypePNG` with backward compatibility
- **Memory Management**: Manual `@autoreleasepool` blocks for batch operations

#### Key Features
- Optimized rendering pipeline with minimal overhead
- Efficient memory usage (9-12 MB typical)
- Native macOS API integration
- Signal handling for graceful shutdown
- Comprehensive error reporting with troubleshooting hints

#### Code Organization
```
src/
├── pdf22png.m      # Main entry point, CLI parsing, batch processing
├── utils.m         # PDF rendering, image I/O, scale calculations
├── utils.h         # Public API declarations
├── errors.h        # Error codes and handling macros
├── memory.m        # Memory management utilities (future)
└── memory.h        # Memory pressure monitoring (future)
```

### Swift Implementation

**Binary**: `pdf22png-swift`  
**Status**: Feature-complete, performance optimized  
**Performance**: ~33% slower than Objective-C (was 10x slower)

#### Technical Stack
- **Language**: Swift 5.5+ with Swift Package Manager
- **PDF Rendering**: Core Graphics via Swift wrapper
- **CLI Framework**: Swift Argument Parser for rich CLI experience
- **Image Output**: Optimized PNG compression
- **Error Handling**: Swift-native `Error` protocol with `PDFError` enum
- **Memory Management**: ARC with optimized buffer allocation

#### Key Features
- Modern Swift idioms and type safety
- Better PNG compression (65% smaller files)
- Structured error handling with recovery suggestions
- Swift Package Manager integration
- Resource caching for improved performance

#### Code Organization
```
Sources/
├── PDF22PNGCore/
│   ├── PDFRenderer.swift    # Core rendering engine with caching
│   ├── Options.swift        # Configuration and argument types
│   ├── ScaleSpec.swift      # Scale calculation algorithms
│   ├── Utils.swift          # File I/O and helper functions
│   └── PDFError.swift       # Error definitions and handling
└── PDF22PNGCLI/
    └── PDF22PNGCommand.swift # CLI entry point and orchestration
```

### Implementation Comparison

| Feature | Objective-C | Swift |
|---------|-------------|-------|
| **Performance** | Baseline (fastest) | ~33% slower |
| **Memory Usage** | 9-12 MB | 9-12 MB |
| **File Size** | Standard | 65% smaller |
| **Binary Size** | 71 KB | 1.5 MB |
| **macOS Version** | 10.15+ | 10.15+ |
| **Dependencies** | System only | System + Swift runtime |
| **Build Time** | ~2 seconds | ~10 seconds |
| **OCR Support** | ✅ Vision framework | ✅ Vision framework |
| **Transparency** | ✅ Full support | ✅ Full support |
| **Batch Processing** | ✅ Parallel GCD | ✅ Parallel GCD |
| **Error Recovery** | ✅ Partial batch | ✅ Partial batch |

### Choosing an Implementation

**Use Objective-C (`pdf22png`) when:**
- Performance is critical
- Processing large batches of PDFs
- Running in resource-constrained environments
- Minimal binary size is required
- Integration with existing Objective-C codebases

**Use Swift (`pdf22png-swift`) when:**
- File size optimization is important
- Modern Swift integration is needed
- Type safety and error handling are priorities
- Building Swift-based workflows
- Contributing to future development

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

1. **For Speed**: Use Objective-C (`pdf22png`)
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
   pdf22png -a document.pdf -d temp/
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