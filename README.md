# pdf22png

[![Version](https://img.shields.io/github/v/release/twardoch/pdf22png?label=version)](https://github.com/twardoch/pdf22png/releases/latest)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-macOS-lightgrey.svg)](https://www.apple.com/macos/)

A high-performance command-line tool for converting PDF documents to PNG images on macOS, leveraging native Core Graphics and Quartz frameworks for optimal quality and speed. Available in both Swift and Objective-C implementations with identical functionality.

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
- **Native Performance**: Available in both Swift and Objective-C implementations
- **Universal Binary**: Supports both Intel and Apple Silicon Macs
- **Dual Implementation**: Choose between modern Swift or classic Objective-C versions

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

```bash
git clone https://github.com/twardoch/pdf22png.git
cd pdf22png
./build.sh
```

The build script provides several options:
```bash
./build.sh --help  # Show all options
./build.sh -t swift  # Build Swift version only
./build.sh -t objc   # Build Objective-C version only
./build.sh -u        # Build universal binary
./build.sh -i        # Install after building
./build.sh -c        # Clean before building
```

You can combine options:
```bash
# Build and install universal binaries for both implementations
./build.sh -u -i

# Clean, build and install Swift version only
./build.sh -c -t swift -i
```

### Choosing Between Implementations

Both Swift and Objective-C versions provide identical functionality. The Swift version is the default and recommended for most users:

- **Swift version**: Modern implementation using Swift Concurrency for better performance in batch operations
- **Objective-C version**: Classic implementation using Grand Central Dispatch, provided for compatibility

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

pdf22png is available in two implementations:

### Swift Implementation (Default)
- **Swift 5.7+** with modern language features
- **Swift Argument Parser** for command-line interface
- **Swift Concurrency** (async/await, TaskGroup) for parallel processing
- **Core Graphics** for PDF rendering
- **Vision** framework for OCR capabilities
- **ImageIO** for PNG output

Swift codebase organization:
- `Package.swift` - Swift Package Manager manifest
- `Sources/pdf22png/main.swift` - Main program entry point and CLI
- `Sources/pdf22png/Models.swift` - Core data structures
- `Sources/pdf22png/Utilities.swift` - Utility functions and helpers
- `Tests/pdf22pngTests/` - XCTest-based unit tests

### Objective-C Implementation
- **Objective-C** with ARC (Automatic Reference Counting)
- **getopt_long** for command-line parsing
- **Grand Central Dispatch** for parallel processing
- **Core Graphics** for PDF rendering
- **Vision** framework for OCR capabilities
- **ImageIO** for PNG output

Objective-C codebase organization:
- `src/pdf22png.m` - Main program logic and argument parsing
- `src/utils.m` - Utility functions for scaling, rendering, and I/O
- `src/errors.h` - Error codes and handling
- `tests/` - Custom test runner with unit tests

## Performance

pdf22png is optimized for performance:
- Parallel processing for batch conversions (Swift Concurrency or GCD)
- Efficient memory management with automatic reference counting
- Native Core Graphics rendering for best quality
- Built-in error recovery for robust batch processing
- Context-aware text extraction with OCR fallback
- Minimal dependencies (only macOS system frameworks)

## Contributing

Contributions are welcome! Please feel free to submit issues, feature requests, or pull requests.

### Development

To build from source:
```bash
make
```

To run tests:
```bash
make test
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