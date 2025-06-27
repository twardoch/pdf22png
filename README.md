# pdf22png

[![Version](https://img.shields.io/github/v/release/twardoch/pdf22png?label=version)](https://github.com/twardoch/pdf22png/releases/latest)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-macOS-lightgrey.svg)](https://www.apple.com/macos/)

A high-performance command-line tool for converting PDF documents to PNG images on macOS, available in two complementary implementations:

- **pdf21png** - The mature, stable, performance-optimized Objective-C implementation (v2.1)
- **pdf22png** - The modern, feature-rich Swift implementation with the latest capabilities (v2.2)

## Why Two Implementations?

We provide two implementations to serve different needs:

- **pdf21png** (Objective-C): Choose this for maximum performance, stability, and minimal resource usage. This is the mature implementation that has been optimized over time.
- **pdf22png** (Swift): Choose this for modern features, better error messages, and ongoing development. This is where new features are added first.

## Features

### Common Features (Both Implementations)
- **Single & Batch Conversion**: Convert individual pages or entire PDF documents
- **Flexible Scaling Options**: 
  - Resolution control (DPI)
  - Percentage scaling
  - Fixed dimensions (width/height fitting)
  - Scale factors
- **Transparent background support**
- **PNG compression quality control**
- **Read from files or stdin**
- **Write to files, stdout, or batch output directories**

### pdf21png (Objective-C) Exclusive Features
- **Highest Performance**: Optimized for speed with minimal overhead
- **File Locking**: POSIX locks for concurrent operations
- **OCR Support**: Vision framework integration for text extraction
- **Memory Efficiency**: Optimized memory usage (9-12 MB typical)
- **Universal Binary**: Native support for Intel and Apple Silicon

### pdf22png (Swift) Exclusive Features
- **Modern Architecture**: Built with Swift's latest features
- **Enhanced Error Messages**: Detailed troubleshooting hints
- **ArgumentParser Integration**: Better command-line interface
- **Type Safety**: Swift's strong typing prevents many errors
- **Future Features**: New capabilities added here first

## Installation

### Using Homebrew (Recommended)

```bash
# Install both implementations
brew tap twardoch/homebrew-pdf22png
brew install pdf21png pdf22png

# Or install individually
brew install pdf21png    # Objective-C version
brew install pdf22png    # Swift version
```

### Building from Source

Requirements:
- macOS 10.15 or later (macOS 11+ for pdf22png)
- Xcode Command Line Tools
- Swift 5.7 or later (for pdf22png only)

```bash
git clone https://github.com/twardoch/pdf22png.git
cd pdf22png
./build.sh
```

#### Build Options

```bash
# Build both implementations (default)
./build.sh

# Build only pdf21png (Objective-C)
./build.sh --objc-only

# Build only pdf22png (Swift)  
./build.sh --swift-only

# Debug builds
./build.sh --debug

# Clean build
./build.sh --clean
```

## Usage

### Basic Examples

```bash
# Convert first page (both tools have same basic syntax)
pdf21png input.pdf output.png
pdf22png input.pdf output.png

# Convert a specific page
pdf21png -p 5 document.pdf page5.png
pdf22png -p 5 document.pdf page5.png

# Convert all pages
pdf21png -a document.pdf
pdf22png -a document.pdf

# Convert at 300 DPI
pdf21png -r 300 input.pdf high-res.png
pdf22png -r 300 input.pdf high-res.png
```

### Advanced Examples

```bash
# Scale to 50% size
pdf21png -s 50% input.pdf half-size.png

# Fit to 800x600 pixels
pdf22png -s 800x600 input.pdf fitted.png

# Transparent background
pdf21png -t input.pdf transparent.png

# Batch convert with custom naming
pdf22png -a -P '{basename}_page_{page:03d}' document.pdf

# Pipe operations
cat document.pdf | pdf21png - - > output.png
```

## Performance Comparison

Based on benchmark results (120-page PDF at 4096x4096):
- **pdf21png**: 17.0s real time, 3.5m CPU time
- **pdf22png**: 21.7s real time, 4.6m CPU time

Both implementations have been optimized for performance, with pdf21png having a slight edge due to lower overhead.

## Options Reference

| Option | Long Form | Description | Default |
|--------|-----------|-------------|---------|
| `-p <n>` | `--page` | Page number or range to convert | 1 |
| `-a` | `--all` | Convert all pages | disabled |
| `-r <dpi>` | `--resolution` | Set output DPI | 144 |
| `-s <spec>` | `--scale` | Scale specification (see below) | 100% |
| `-t` | `--transparent` | Preserve transparency | disabled |
| `-q <0-9>` | `--quality` | PNG compression quality | 6 |
| `-o <path>` | `--output` | Output file/prefix or `-` for stdout | - |
| `-d <dir>` | `--directory` | Output directory for batch mode | . |
| `-v` | `--verbose` | Enable verbose logging | disabled |
| `-h` | `--help` | Show help message | - |

### Scale Specifications

- **Percentage**: `150%` (1.5x scale)
- **Factor**: `2.0` (2x scale)
- **Fixed width**: `800x` (800px wide, height auto)
- **Fixed height**: `x600` (600px high, width auto)
- **Fit within**: `800x600` (fit within 800x600 box)

## Choosing Between Implementations

### Use pdf21png when:
- Performance is critical
- Processing large batches of PDFs
- Memory usage must be minimized
- You need file locking for concurrent operations
- Stability is more important than new features

### Use pdf22png when:
- You want the latest features
- Better error messages are helpful
- You prefer modern Swift architecture
- You're contributing new features
- Type safety is important

## Migration Guide

If you're currently using the old `pdf22png` command:
1. Both new tools maintain backward compatibility with existing scripts
2. For performance-critical applications, switch to `pdf21png`
3. For new development, consider `pdf22png` for future features

## Architecture

The project maintains two separate, self-contained implementations:

```
pdf22png/
├── pdf21png/          # Objective-C implementation
│   ├── src/           # Source files
│   ├── build/         # Build output
│   └── Makefile       # Build system
├── pdf22png/          # Swift implementation
│   ├── Sources/       # Swift sources
│   ├── Tests/         # Unit tests
│   └── Package.swift  # Swift Package Manager
└── build.sh           # Unified build script
```

## Contributing

We welcome contributions to both implementations:

- **pdf21png**: Focus on performance optimizations and stability
- **pdf22png**: New features and modern Swift patterns

Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

MIT License - see [LICENSE](LICENSE) for details.

## Acknowledgments

Built with native macOS frameworks for optimal performance and compatibility.