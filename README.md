# PDF to PNG Converter for macOS

Two powerful command-line tools for converting PDF files to high-quality PNG images on macOS.

- **`pdf21png`**: A mature, performance-focused tool written in Objective-C.
- **`pdf22png`**: A modern, feature-rich tool written in Swift.

## What's New?

The project has been recently reorganized to provide two distinct tools:

- `pdf21png` is the original, battle-tested Objective-C implementation, optimized for speed and stability.
- `pdf22png` is the new Swift implementation, offering a modern codebase and new features.

This change allows users to choose the tool that best fits their needs, whether it's the raw performance of `pdf21png` or the modern features of `pdf22png`.

## Features

- Convert single pages or entire PDFs.
- Control image resolution (DPI).
- Scale images to specific sizes.
- Preserve transparency.
- Batch process multiple files.
- Fine-tune PNG compression.

## Installation

### Homebrew

```bash
# Install the Objective-C version
brew tap twardoch/pdf22png
brew install pdf21png

# Install the Swift version
brew tap twardoch/pdf22png
brew install pdf22png
```

### From Source

```bash
git clone https://github.com/twardoch/pdf22png.git
cd pdf22png
./build.sh
```

## Usage

```bash
# Convert the first page of a PDF
pdf21png document.pdf page1.png

# Convert a specific page
pdf21png -p 5 document.pdf page5.png

# Convert all pages
pdf21png -a document.pdf

# Set resolution to 300 DPI
pdf21png -r 300 document.pdf output.png

# Scale to 50%
pdf21png -s 50% document.pdf output.png
```

## Migration Guide

### For Existing Users

If you've been using the original `pdf22png` command, here's what you need to know:

- The original Objective-C implementation is now called `pdf21png`
- The new Swift implementation is now called `pdf22png`
- All command-line options remain the same
- Your existing scripts will continue to work, but will now use the Swift version

To continue using the original Objective-C version:
```bash
# Replace pdf22png with pdf21png in your scripts
pdf21png [same options as before]
```

To use the new Swift version:
```bash
# Continue using pdf22png as before
pdf22png [same options as before]
```

### Choosing Between Implementations

| Feature | pdf21png (Objective-C) | pdf22png (Swift) |
|---------|----------------------|------------------|
| Performance | ⭐⭐⭐⭐⭐ Fastest | ⭐⭐⭐⭐ Fast |
| Memory Usage | ⭐⭐⭐⭐⭐ Minimal | ⭐⭐⭐⭐ Efficient |
| Stability | ⭐⭐⭐⭐⭐ Battle-tested | ⭐⭐⭐⭐ Modern |
| Features | Core functionality | Extended features |
| macOS Support | 10.15+ | 11.0+ |
| Architecture | Universal Binary | Universal Binary |

Use `pdf21png` when:
- Performance is critical
- Processing large batches
- Running on older macOS versions
- Stability is paramount

Use `pdf22png` when:
- You want the latest features
- Modern Swift integration is important
- You're building new workflows

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## License

MIT License. See [LICENSE](LICENSE) for details.
