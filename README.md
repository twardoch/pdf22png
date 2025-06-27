# PDF to PNG Converter for macOS

Convert PDF documents to high-quality PNG images with two powerful command-line tools optimized for macOS.

## Quick Install

```bash
# Install the modern Swift version (recommended)
brew install twardoch/pdf22png/pdf22png

# Or install the performance-optimized Objective-C version
brew install twardoch/pdf22png/pdf21png
```

## Overview

This project provides two implementations of a PDF to PNG converter:

- **`pdf22png`** - Modern Swift implementation with the latest features (recommended for most users)
- **`pdf21png`** - High-performance Objective-C implementation for maximum speed

Both tools share the same command-line interface and can be used interchangeably.

## Features

- 🖼️ **High-Quality Conversion** - Leverages macOS native Core Graphics for optimal rendering
- 📄 **Flexible Page Selection** - Convert single pages, ranges, or entire documents
- 🎯 **Precise Scaling Control** - DPI settings, percentage scaling, or fixed dimensions
- 🎨 **Transparency Support** - Preserve transparent backgrounds in PDFs
- ⚡ **Batch Processing** - Convert multiple PDFs efficiently
- 🔧 **Fine-Tuning Options** - Control PNG compression and output quality

## Installation

### Homebrew (Recommended)

The easiest way to install is via Homebrew:

```bash
# Install the modern Swift version (recommended for most users)
brew install twardoch/pdf22png/pdf22png

# Or install the high-performance Objective-C version
brew install twardoch/pdf22png/pdf21png

# Install both versions
brew install twardoch/pdf22png/pdf22png twardoch/pdf22png/pdf21png
```

### Building from Source

Requirements:
- macOS 10.15 or later (11.0+ for Swift version)
- Xcode Command Line Tools

```bash
git clone https://github.com/twardoch/pdf22png.git
cd pdf22png

# Build both versions
./build.sh

# Install to /usr/local/bin
sudo make install
```

### Manual Download

Pre-built universal binaries are available from the [releases page](https://github.com/twardoch/pdf22png/releases).

## Quick Start

### Basic Usage

```bash
# Convert first page of a PDF to PNG
pdf22png input.pdf output.png

# Convert page 5 at 300 DPI
pdf22png -p 5 -r 300 document.pdf page5.png

# Convert all pages with transparent background
pdf22png -a -t document.pdf

# Scale output to 50% size
pdf22png -s 50% large.pdf smaller.png
```

### Common Examples

```bash
# High-resolution conversion for print
pdf22png -r 600 poster.pdf print-ready.png

# Create thumbnails at fixed width
pdf22png -s 200x presentation.pdf thumb.png

# Batch convert all PDFs in a directory
for pdf in *.pdf; do
    pdf22png -a "$pdf"
done

# Extract specific page with transparency
pdf22png -p 3 -t -q 9 manual.pdf page3.png
```

## Command Options

| Option | Long Form | Description | Default |
|--------|-----------|-------------|---------|
| `-p <n>` | `--page` | Page number to convert | 1 |
| `-a` | `--all` | Convert all pages | disabled |
| `-r <dpi>` | `--resolution` | Output resolution in DPI | 144 |
| `-s <spec>` | `--scale` | Scale specification (see below) | 100% |
| `-t` | `--transparent` | Preserve transparency | disabled |
| `-q <0-9>` | `--quality` | PNG compression (0=none, 9=max) | 6 |
| `-o <path>` | `--output` | Output file or `-` for stdout | - |
| `-d <dir>` | `--directory` | Output directory for batch mode | . |
| `-v` | `--verbose` | Enable verbose logging | disabled |
| `-h` | `--help` | Show help message | - |

### Scale Specifications

- **Percentage**: `150%` or `0.5` (50%)
- **Fixed width**: `800x` (800px wide, maintain aspect ratio)
- **Fixed height**: `x600` (600px tall, maintain aspect ratio)
- **Fit within**: `800x600` (fit within box, maintain aspect ratio)

## Which Version Should I Use?

### Quick Decision Guide

- **Most users**: Install `pdf22png` (Swift version) for the best balance of features and performance
- **Performance critical**: Install `pdf21png` (Objective-C version) for maximum speed
- **Not sure**: Install `pdf22png` - it's the recommended default

### Detailed Comparison

| Aspect | pdf21png (Objective-C) | pdf22png (Swift) |
|--------|------------------------|------------------|
| **Performance** | ⚡ Fastest possible | 🚀 Very fast |
| **Memory Usage** | Minimal | Efficient |
| **macOS Version** | 10.15+ | 11.0+ |
| **Best For** | Large batches, servers | Desktop use, automation |
| **Development** | Stable, maintenance mode | Active development |

## Advanced Usage

### Pipeline Integration

```bash
# Convert and pipe to ImageMagick for further processing
pdf22png -r 300 input.pdf - | convert - -resize 50% output.jpg

# Extract text from specific page (requires OCR tools)
pdf22png -p 2 -r 300 document.pdf - | tesseract stdin stdout
```

### Batch Processing

```bash
# Convert all PDFs to PNGs in a separate directory
mkdir -p output
for pdf in *.pdf; do
    pdf22png -a -d output "$pdf"
done

# Custom naming pattern
pdf22png -a -o "page" document.pdf
# Creates: page-001.png, page-002.png, etc.
```

### Scripting

```bash
#!/bin/bash
# Convert PDF to thumbnails

INPUT="$1"
BASENAME=$(basename "$INPUT" .pdf)

# Create high-res and thumbnail versions
pdf22png -r 300 "$INPUT" "${BASENAME}-highres.png"
pdf22png -s 150x "$INPUT" "${BASENAME}-thumb.png"
```

## Troubleshooting

### Installation Issues

If Homebrew installation fails:
```bash
# Update Homebrew and retry
brew update
brew tap twardoch/pdf22png
brew install pdf22png

# Or build from source
git clone https://github.com/twardoch/pdf22png.git
cd pdf22png
./build.sh
```

### Common Problems

- **"Command not found"**: Ensure `/usr/local/bin` is in your PATH
- **"PDF is encrypted"**: This tool doesn't support encrypted PDFs
- **Poor quality output**: Increase DPI with `-r 300` or higher
- **Large file sizes**: Adjust compression with `-q 7` or `-q 8`

## Migration from Old Versions

If you previously used `pdf22png` before version 2.0:

- The Objective-C implementation is now `pdf21png`
- The Swift implementation is now `pdf22png` 
- All command options remain unchanged
- Your scripts will work but now use the Swift version

To use the original Objective-C version:
```bash
# Simply replace pdf22png with pdf21png
pdf21png [your existing options]
```

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## License

MIT License. See [LICENSE](LICENSE) for details.
