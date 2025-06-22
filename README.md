# pdf22png

<div align="center">

![macOS](https://img.shields.io/badge/macOS-10.15+-blue.svg)
![Build Status](https://github.com/twardoch/pdf22png/workflows/Build%20and%20Test/badge.svg)
![License](https://img.shields.io/github/license/twardoch/pdf22png)
![Version](https://img.shields.io/github/v/release/twardoch/pdf22png)

High-performance native macOS CLI tool for converting PDF documents to PNG images.

</div>

## 3. Features

- 🚀 **Fast**: Native Core Graphics rendering
- 📄 **Flexible**: Convert single pages or entire documents
- 🎨 **Quality**: Customizable DPI settings (72-600)
- 🖼️ **Smart**: Automatic transparency handling
- 📦 **Simple**: Zero dependencies beyond macOS frameworks

## 4. Installation

### 4.1. Homebrew (Recommended)

```bash
brew tap twardoch/tap
brew install pdf22png
```

### 4.2. From Source

```bash
git clone https://github.com/twardoch/pdf22png.git
cd pdf22png
make
sudo make install
```

### 4.3. Pre-built Binary

Download the latest release from the [Releases](https://github.com/twardoch/pdf22png/releases) page.

## 5. Usage

### 5.1. Basic Usage

```bash
# Convert first page
pdf22png input.pdf output.png

# Convert all pages
pdf22png -a input.pdf output_%03d.png

# Custom resolution
pdf22png -r 300 input.pdf output.png
```

### 5.2. Advanced Options

```bash
pdf22png [OPTIONS] <input.pdf> <output.png>

Options:
  -p, --page <n>       Convert specific page (default: 1)
  -a, --all            Convert all pages
  -r, --resolution <n> Set output DPI (default: 144)
  -s, --scale <n>      Scale factor (default: 1.0)
  -t, --transparent    Preserve transparency
  -q, --quality <n>    PNG compression (0-9, default: 6)
  -v, --verbose        Verbose output
  -h, --help           Show help
```

### 5.3. Examples

```bash
# High-resolution conversion
pdf22png -r 300 presentation.pdf slide.png

# Batch convert with custom naming
pdf22png -a -r 200 book.pdf page_%04d.png

# Extract page 5 at 2x scale
pdf22png -p 5 -s 2.0 document.pdf page5.png
```

## 6. Development

### 6.1. Building

```bash
# Standard build
make

# Universal binary (Intel + Apple Silicon)
make universal

# Run tests
make test
```

### 6.2. Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 7. License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 8. Acknowledgments

Built with macOS Core Graphics framework for optimal performance and quality.
```
