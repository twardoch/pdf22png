# PDF22PNG - Objective-C Implementation

High-performance PDF to PNG converter built with native macOS frameworks.

## Features

- **Native Performance**: Built with Objective-C using Core Graphics and Quartz
- **Single & Batch Conversion**: Convert individual pages or entire documents
- **Flexible Scaling**: DPI, percentage, dimensions, and scale factors
- **Advanced Features**:
  - Text extraction and OCR with Vision framework
  - File locking for concurrent operations
  - Transparent background support
  - Custom naming patterns
  - Dry-run mode
  - Progress reporting

## Building

```bash
make                    # Build release version
make debug             # Build debug version
make universal         # Build universal binary (Intel + Apple Silicon)
```

## Installation

```bash
make install           # Install to /usr/local/bin/pdf22png
make uninstall         # Remove installation
```

## Usage

```bash
# Convert single page
./build/pdf22png input.pdf output.png

# Convert all pages
./build/pdf22png -a document.pdf

# Convert at 300 DPI
./build/pdf22png -r 300 input.pdf high-res.png

# Batch with custom naming
./build/pdf22png -a -P '{basename}_page_{page:03d}' document.pdf
```

## Implementation Details

- **Language**: Objective-C with ARC
- **Frameworks**: Foundation, CoreGraphics, ImageIO, Quartz, Vision
- **Memory Management**: Optimized with @autoreleasepool blocks
- **Concurrency**: GCD for parallel batch processing
- **File Safety**: POSIX file locking for concurrent access

## Performance

This implementation is optimized for speed and memory efficiency:
- Direct Core Graphics API usage
- Minimal overhead
- Efficient memory usage (9-12 MB typical)
- Fast batch processing with parallel execution 