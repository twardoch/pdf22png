# PDF to PNG Converter for macOS: `pdf21png` & `pdf22png`

[![Version pdf21png](https://img.shields.io/badge/pdf21png-v2.1.0-blue)](https://github.com/twardoch/pdf22png/releases)
[![Version pdf22png](https://img.shields.io/badge/pdf22png-v2.2.0-green)](https://github.com/twardoch/pdf22png/releases)
[![License](https://img.shields.io/badge/license-MIT-lightgrey.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-macOS-lightgrey.svg)](https://www.apple.com/macos/)

Convert PDF documents to high-quality PNG images with two powerful command-line tools, meticulously optimized for macOS. This project offers two distinct implementations, catering to different needs:

*   **`pdf21png` (Objective-C):** The original, battle-tested workhorse. Prioritizes maximum performance and stability, ideal for high-volume batch processing and server-side tasks.
*   **`pdf22png` (Swift):** The modern, feature-rich successor. Leverages the latest Swift capabilities for enhanced flexibility, type safety, and active development.

Both tools provide a consistent command-line interface, allowing users to switch between them with ease.

## What is `pdf21png` / `pdf22png`?

At their core, `pdf21png` and `pdf22png` are command-line utilities that transform your PDF files into PNG images. Whether you need to extract a single page, convert an entire document, or automate image generation from PDFs, these tools offer a robust and efficient solution. They harness macOS's native Core Graphics and Quartz frameworks, ensuring optimal rendering quality and performance.

## Who is it for?

These tools are designed for a wide range of users on macOS:

*   **Developers:** Integrate PDF-to-PNG conversion into your applications or automated workflows.
*   **Designers:** Quickly extract high-quality images from PDF mockups or assets.
*   **Archivists & Librarians:** Convert document scans or digital records into a widely accessible image format.
*   **Researchers & Students:** Extract figures, tables, or pages from academic papers.
*   **Anyone needing to script PDF conversions:** Automate repetitive tasks involving PDF to image translation.

## Why is it useful?

*   **High-Quality Output:** Utilizes macOS's native rendering engine for crisp, accurate PNGs.
*   **Performance Options:**
    *   `pdf21png`: Offers blazing-fast conversions for demanding tasks.
    *   `pdf22png`: Provides excellent performance with modern Swift optimizations.
*   **Flexible Control:** Extensive command-line options for page selection, resolution, scaling, transparency, and more.
*   **Batch Processing:** Efficiently convert multiple pages or entire documents with a single command.
*   **Scriptable:** Easily integrate into shell scripts or other automation tools.
*   **Native macOS:** Optimized specifically for the macOS environment, ensuring seamless integration and reliability.
*   **Universal Binaries:** Support for both Intel and Apple Silicon Macs.

## Installation

Choose the method that best suits your needs:

### 1. Homebrew (Recommended)

This is the easiest way to install and manage `pdf21png` and `pdf22png`.

*   **To install the performance-optimized Objective-C version (`pdf21png`):**
    ```bash
    brew install twardoch/pdf22png/pdf21png
    ```
    *(Requires macOS 10.15 Catalina or later)*

*   **To install the modern Swift version (`pdf22png`):**
    ```bash
    brew install twardoch/pdf22png/pdf22png
    ```
    *(Requires macOS 11.0 Big Sur or later)*

*   **To install both versions:**
    ```bash
    brew install twardoch/pdf22png/pdf21png twardoch/pdf22png/pdf22png
    ```

The Homebrew tap is located at [twardoch/homebrew-pdf22png](https://github.com/twardoch/homebrew-pdf22png).

### 2. Building from Source

If you prefer to build the tools yourself:

**Prerequisites:**
*   macOS (10.15+ for `pdf21png`, 11.0+ for `pdf22png`)
*   Xcode Command Line Tools (install with `xcode-select --install`)
*   Git

**Steps:**

1.  Clone the repository:
    ```bash
    git clone https://github.com/twardoch/pdf22png.git
    cd pdf22png
    ```

2.  Run the unified build script:
    ```bash
    ./build.sh
    ```
    This will build both `pdf21png` (Objective-C) and `pdf22png` (Swift) by default.
    You can also build them individually:
    ```bash
    ./build.sh --objc-only  # Builds only pdf21png
    ./build.sh --swift-only # Builds only pdf22png
    ```

3.  Install the binaries (optional):
    *   **`pdf21png`:**
        ```bash
        cd pdf21png
        sudo make install
        cd ..
        ```
    *   **`pdf22png`:**
        ```bash
        cd pdf22png
        sudo make install
        cd ..
        ```
    This will typically install them to `/usr/local/bin/`. The Swift version installs as `pdf22png-swift` via its Makefile, while the ObjC version installs as `pdf21png`.

### 3. Manual Download

Pre-built universal binaries for both `pdf21png` and `pdf22png` are available from the [GitHub Releases page](https://github.com/twardoch/pdf22png/releases). Download the desired archive, extract it, and place the binary in a directory included in your system's `PATH` (e.g., `/usr/local/bin`).

## Quick Start

Both `pdf21png` and `pdf22png` share a similar command-line interface. The examples below use `pdf22png`. Replace `pdf22png` with `pdf21png` if you prefer to use the Objective-C version.

**1. Convert the first page of a PDF:**
```bash
pdf22png input.pdf output.png
```

**2. Convert page 5 at 300 DPI:**
```bash
pdf22png -p 5 -r 300dpi document.pdf page5_300dpi.png
```

**3. Convert all pages, outputting to a new directory `output_images`:**
```bash
mkdir -p output_images
pdf22png -a -d ./output_images document.pdf
```
*(This will create `output_images/document-001.png`, `output_images/document-002.png`, etc.)*

**4. Scale output to 50% of its original size:**
```bash
pdf22png -s 50% large.pdf smaller.png
```

**5. Convert page 3 with a transparent background:**
```bash
pdf22png -p 3 -t document.pdf page3_transparent.png
```

## Command-Line Options

The following table lists the most common command-line options. Both `pdf21png` and `pdf22png` aim to provide a consistent interface for these options. For the most accurate and detailed list for each tool, please consult its help output (e.g., `pdf21png --help`).

| Option        | Long Form         | Argument        | Description                                                                                                                               | Default        |
|---------------|-------------------|-----------------|-------------------------------------------------------------------------------------------------------------------------------------------|----------------|
| `-p <spec>`   | `--page <spec>`   | `<spec>`        | Page(s) to convert. Single page (`5`), range (`1-10`), or comma-separated list (`1,3,5-7`).                                                 | `1`            |
| `-a`          | `--all`           |                 | Convert all pages. Output files typically named `<input_basename>-<page_num>.png`.                                                        | Disabled       |
| `-r <dpi>`    | `--resolution <dpi>`| `<value>`       | Output resolution in DPI (e.g., `150`, `300dpi`).                                                                                         | `144dpi`       |
| `-s <spec>`   | `--scale <spec>`  | `<spec>`        | Scale specification (e.g., `150%`, `0.5`, `800x` for width, `x600` for height, `800x600` to fit).                                          | `100%` or `1.0`|
| `-t`          | `--transparent`   |                 | Preserve transparency from PDF. If PDF has no transparency or this is off, background is white.                                           | Disabled       |
| `-q <n>`      | `--quality <n>`   | `<0-9>`         | PNG compression quality (0=none/fastest, 9=max/slowest). Note: PNG is lossless; this often affects compression effort vs. speed.          | `6`            |
| `-o <path>`   | `--output <path>` | `<path/prefix>` | Output file path for single page, or filename prefix for batch mode. Use `-` for stdout (single page mode only).                            | Varies         |
| `-d <dir>`    | `--directory <dir>`| `<dir>`         | Output directory for batch mode (when `-a` is used or page spec results in multiple pages). Implies batch conversion of specified pages. | Current dir    |
| `-v`          | `--verbose`       |                 | Enable verbose logging output to stderr.                                                                                                  | Disabled       |
| `-f`          | `--force`         |                 | Force overwrite of existing output files without prompting.                                                                               | Disabled       |
| `-h`          | `--help`          |                 | Display the help message and exit.                                                                                                        |                |
|               | `--version`       |                 | Display version information and exit.                                                                                                     |                |

**Note on Page Selection with `-d`:** If `-d` (directory) is used and no specific page range is given with `-p`, it typically implies all pages should be converted, similar to `-a`.

**Scale Specification (`-s <spec>`) Details:**
*   **Percentage:** `150%` (1.5x original size), `50%` (0.5x original size).
*   **Factor:** `2.0` (double size), `0.75` (75% of original size).
*   **Fixed Width:** `800x` (output width is 800px, height adjusts by aspect ratio).
*   **Fixed Height:** `x600` (output height is 600px, width adjusts by aspect ratio).
*   **Fit Within Box:** `800x600` (output fits within an 800px by 600px box, maintaining aspect ratio).

For more advanced options and detailed explanations, refer to the help output of each tool (`pdf21png --help` or `pdf22png --help`).

## Technical Deep Dive

This section provides a more detailed look into the architecture of `pdf21png` and `pdf22png`, along with guidelines for coding and contributing to the project.

### Architecture

The project features a dual-implementation architecture, allowing users to choose between a performance-optimized Objective-C version and a modern Swift version.

**Shared Principles:**
Both implementations leverage macOS's native frameworks for core functionality:
*   **Core Graphics (Quartz):** Used for PDF parsing, rendering, and manipulation, ensuring high fidelity and access to deep system-level PDF capabilities.
*   **ImageIO:** Employed for efficient PNG encoding and handling image metadata.

#### `pdf21png` (Objective-C Implementation)

Located in the `pdf21png/` directory.

*   **Language:** Objective-C with Automatic Reference Counting (ARC) for memory management.
*   **Focus:** Maximum performance, stability, and minimal overhead. This version is ideal for high-throughput batch processing and server-side environments.
*   **Core Components:**
    *   `pdf21png.m`: Contains the main program logic, command-line argument parsing (using `getopt_long`), and orchestrates the conversion process.
    *   `utils.m`: Houses utility functions for PDF page rendering, scale calculations, image I/O operations, text extraction (including OCR fallback via Vision framework), and file system interactions.
    *   `errors.h`: Defines error codes and provides a centralized way to report errors.
*   **Concurrency:** Utilizes Grand Central Dispatch (GCD) for parallel processing of pages in batch mode, optimizing CPU core usage.
*   **Memory Management:** Employs `@autoreleasepool` blocks strategically, especially during batch operations, to manage memory efficiently and prevent buildup during intensive tasks.
*   **Advanced Features:**
    *   **Text Extraction:** Includes capabilities to extract text directly from PDF content and uses the Vision framework as a fallback for OCR on image-based PDFs.
    *   **File Locking:** Implements POSIX file locking (`flock`) to manage concurrent access when writing output files, which is crucial in multi-process or server environments.
    *   **Custom Naming Patterns:** Supports complex, user-defined output filename patterns.

#### `pdf22png` (Swift Implementation)

Located in the `pdf22png/` directory.

*   **Language:** Swift (currently 5.7+), emphasizing type safety, modern language features, and maintainability.
*   **Focus:** Providing a robust, user-friendly tool using modern Swift practices. While performance is a key consideration, the design also prioritizes clarity and leveraging Swift's strong type system.
*   **Core Components:**
    *   `Sources/main.swift`: The main entry point for the Swift version. It uses the `ArgumentParser` library for parsing command-line arguments, providing a rich and user-friendly CLI experience. This file contains the primary logic for handling options, loading PDFs, and managing the conversion workflow.
    *   **PDFKit & Core Graphics:** Interacts with PDF documents primarily through PDFKit for document and page handling, while still relying on Core Graphics for the rendering process to ensure quality and control.
*   **Concurrency:** Leverages Swift's modern concurrency features (e.g., `async/await` if more complex batching is re-introduced, or GCD via `DispatchQueue` for current parallel operations) for efficient multi-page processing.
*   **Error Handling:** Utilizes Swift's typed error handling (`Error` protocol, custom enums like `PDF22PNGError`) for robust error reporting and management.
*   **Dependencies:**
    *   `swift-argument-parser`: For a declarative and user-friendly command-line interface.
*   **Key Characteristics:**
    *   **Type Safety:** Swift's strong type system helps prevent common errors.
    *   **Modern Syntax:** Easier to read and maintain for developers familiar with Swift.
    *   **Simplified Architecture:** The current Swift version has been streamlined for stability and ease of maintenance, focusing on a clear, single-target structure managed by the Swift Package Manager.

### Coding and Contribution Guidelines

We welcome contributions to both `pdf21png` and `pdf22png`! To ensure a smooth process, please adhere to the following guidelines.

*   **Development Workflow:** For detailed steps on forking, branching, committing, and creating pull requests, please refer to [CONTRIBUTING.md](CONTRIBUTING.md).
*   **Code Standards:**
    *   **Objective-C (`pdf21png`):**
        *   Follow the [Apple Coding Guidelines for Cocoa](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CodingGuidelines/CodingGuidelines.html).
        *   Use 4 spaces for indentation.
        *   Keep lines under 100 characters where practical.
    *   **Swift (`pdf22png`):**
        *   Follow the [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/).
        *   Use 4 spaces for indentation.
        *   Keep lines under 100-120 characters.
        *   SwiftLint is configured for this project; try to adhere to its suggestions.
*   **Project Structure:**
    *   Contributions should be targeted to the appropriate directory: `pdf21png/` for the Objective-C tool or `pdf22png/` for the Swift tool.
    *   Each implementation is self-contained. Changes in one should generally not require changes in the other, unless it's a shared concept like CLI option parity.
*   **Commit Messages:** Write clear, concise, and descriptive commit messages. Follow conventional commit formats if possible (e.g., `feat: Add new scaling option`).
*   **Testing:**
    *   Before submitting changes, ensure they build correctly using `./build.sh` (or the respective `Makefile` in the implementation's directory).
    *   Run any available tests. For `pdf21png`, this might involve `make test`. For `pdf22png`, use `swift test` or `make test` within its directory.
    *   Manually test your changes with sample PDF files, covering edge cases if applicable.
*   **AI Development Guidelines (from `CLAUDE.md`):**
    *   *This project may involve AI-assisted development. The following guidelines are primarily for AI contributors but are good practice for all:*
    *   Only modify code directly relevant to the specific request. Avoid changing unrelated functionality.
    *   Never replace code with placeholders like `# ... rest of the processing ...`. Always include complete code.
    *   Break problems into smaller steps. Think through each step separately before implementing.
*   **Updating Documentation:** If your changes affect command-line options, behavior, or installation, please update relevant sections of the README files and other documentation (e.g., man pages, example files).
*   **Issue Tracker:** Check the [GitHub Issues](https://github.com/twardoch/pdf22png/issues) for bugs to fix or features to implement.

### License

By contributing to this project, you agree that your contributions will be licensed under the MIT License. See the [LICENSE](LICENSE) file for full details.
