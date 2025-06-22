# pdf22png

A high-performance command-line tool for converting PDF documents to PNG images on macOS, leveraging native Core Graphics and Quartz frameworks for optimal quality and speed.

## Features

- **Single & Batch Conversion**: Convert individual pages or entire PDF documents
- **Flexible Scaling Options**: 
  - Resolution control (DPI)
  - Percentage scaling
  - Fixed dimensions (width/height fitting)
  - Scale factors
- **Advanced Options**:
  - Transparent background support
  - PNG compression quality control
  - Verbose logging for debugging
- **I/O Flexibility**:
  - Read from files or stdin
  - Write to files, stdout, or batch output directories
  - Customizable output naming patterns
- **Native Performance**: Built with Objective-C using macOS native frameworks
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

```bash
git clone https://github.com/twardoch/pdf22png.git
cd pdf22png
make
sudo make install
```

To build a universal binary for both Intel and Apple Silicon:

```bash
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
| `-p <n>` | `--page` | Convert specific page number | 1 |
| `-a` | `--all` | Convert all pages | disabled |
| `-r <dpi>` | `--resolution` | Set output DPI (e.g., 300) | 144 |
| `-s <spec>` | `--scale` | Scale specification (see below) | 100% |
| `-t` | `--transparent` | Preserve transparency | disabled |
| `-q <0-9>` | `--quality` | PNG compression quality | 6 |
| `-o <path>` | `--output` | Output file/prefix or `-` for stdout | - |
| `-d <dir>` | `--directory` | Output directory for batch mode | . |
| `-v` | `--verbose` | Enable verbose logging | disabled |
| `-h` | `--help` | Show help message | - |

### Scale Specifications

The `-s/--scale` option accepts various formats:

- **Percentage**: `150%` (1.5x scale)
- **Factor**: `2.0` (2x scale)
- **Fixed width**: `800x` (800px wide, height auto)
- **Fixed height**: `x600` (600px high, width auto)
- **Fit within**: `800x600` (fit within 800x600 box)

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

Pipe operations:
```bash
# From stdin to stdout
cat document.pdf | pdf22png - - > output.png

# Process and pipe to ImageMagick
pdf22png -r 300 input.pdf - | convert - -resize 50% final.jpg
```

## Architecture

pdf22png is built using:
- **Objective-C** with ARC (Automatic Reference Counting)
- **Core Graphics** for PDF rendering
- **Quartz** framework for image processing
- **ImageIO** for PNG output
- Native macOS APIs for optimal performance

The codebase is organized into:
- `src/pdf22png.m` - Main program logic and argument parsing
- `src/utils.m` - Utility functions for scaling, rendering, and I/O
- `tests/` - XCTest-based unit tests

## Performance

pdf22png is optimized for performance:
- Parallel processing for batch conversions using Grand Central Dispatch
- Efficient memory management with autoreleasepool usage
- Native Core Graphics rendering for best quality
- Minimal dependencies (only macOS system frameworks)


# main-overview

## Development Guidelines

- Only modify code directly relevant to the specific request. Avoid changing unrelated functionality.
- Never replace code with placeholders like `# ... rest of the processing ...`. Always include complete code.
- Break problems into smaller steps. Think through each step separately before implementing.
- Always provide a complete PLAN with REASONING based on evidence from code and logs before making changes.
- Explain your OBSERVATIONS clearly, then provide REASONING to identify the exact issue. Add console logs when needed to gather more information.


pdf22png implements specialized PDF to PNG conversion logic leveraging macOS native frameworks. The core business functionality is organized around:

## Core Conversion Engine
The primary conversion logic resides in `src/pdf22png.m`, handling:
- PDF page rendering with customizable scaling
- Transparent background preservation 
- Quality-controlled PNG output generation
- Batch processing with parallel execution

## Scale Specification System
Located in `src/utils.m`, implements specialized scaling algorithms:
- Percentage-based scaling (e.g. "150%")
- Fixed dimension specifications (e.g. "800x600")
- DPI-based resolution control
- Aspect ratio preservation logic

## Output Management
Implements flexible output handling:
- Custom naming pattern generation for batch conversions
- Directory organization for multi-page outputs
- Stream-based processing for pipeline integration
- Transparent vs opaque background handling

## Platform Integration
Native integration with macOS frameworks:
- Core Graphics PDF parsing and rendering
- Quartz image processing pipeline
- Universal binary support for Intel/ARM
- System-level optimization for performance

## Processing Modes
Supports multiple operational modes:
- Single page conversion
- Full document batch processing
- Stream-based pipeline processing
- Interactive command-line interface

The business logic focuses on providing professional-grade PDF to PNG conversion with emphasis on flexibility, quality control, and integration capabilities for automated workflows.

—— When you’re done with a round of updates, update CHANGELOG.md with the changes, remove done things from TODO.md, identify new things that need to be done and add them to TODO.md. Then build the app or run ./release.sh and then continue updates. 