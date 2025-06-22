# pdf22png API Documentation

While `pdf22png` is primarily a command-line tool, its core logic is written in Objective-C and could potentially be adapted for direct use within other macOS applications or scripts. This document provides a high-level overview of the key structures and functions.

## Core Structures

### `Options`
Defined in `src/pdf22png.h`

This structure holds all the configurable parameters for the PDF conversion process.

```objectivec
typedef struct {
    ScaleSpec scale;            // See ScaleSpec below
    NSInteger pageNumber;       // Specific page to convert (1-based)
    NSString *inputPath;        // Path to the input PDF file (nil for stdin)
    NSString *outputPath;       // Path for the output PNG file or prefix for batch
    NSString *outputDirectory;  // Directory for batch output
    BOOL batchMode;             // YES if converting all pages
    BOOL transparentBackground; // YES to render with transparency
    int pngQuality;             // PNG quality/compression hint (0-9)
    BOOL verbose;               // YES for verbose logging
} Options;
```

### `ScaleSpec`
Defined in `src/pdf22png.h`

This structure defines how the PDF page should be scaled.

```objectivec
typedef struct {
    CGFloat scaleFactor;  // e.g., 1.0, 1.5, 0.75
    CGFloat maxWidth;     // Max width in pixels for 'WxH' or 'Wx' scaling
    CGFloat maxHeight;    // Max height in pixels for 'WxH' or 'xH' scaling
    CGFloat dpi;          // Dots Per Inch for scaling
    BOOL isPercentage;    // YES if scaleFactor is from a 'NNN%' input
    BOOL isDPI;           // YES if scaling is based on DPI
    BOOL hasWidth;        // YES if maxWidth is set
    BOOL hasHeight;       // YES if maxHeight is set
} ScaleSpec;
```

## Key Functions

The primary logic is found in `src/pdf22png.m` and utility functions in `src/utils.m`.

### Main Entry Point (Conceptual)
The `main` function in `src/pdf22png.m` orchestrates the process:
1.  Parses command-line arguments into an `Options` struct (`parseArguments`).
2.  Reads PDF data (`readPDFData` from `utils.m`).
3.  Creates a `CGPDFDocumentRef` from the data.
4.  Either processes a single page (`processSinglePage`) or all pages in batch mode (`processBatchMode`).

### Core Conversion Functions

*   **`BOOL parseArguments(int argc, const char *argv[])`** (in `pdf22png.m`)
    *   Parses command-line arguments and populates the `Options` struct.
    *   Handles help messages and argument validation.

*   **`BOOL parseScaleSpec(const char *spec, ScaleSpec *scale)`** (in `utils.m`)
    *   Parses the string provided to the `-s` or `-r` option into a `ScaleSpec` struct.

*   **`NSData *readPDFData(NSString *inputPath, BOOL verbose)`** (in `utils.m`)
    *   Reads PDF file data from the given path or from stdin if `inputPath` is `nil`.

*   **`CGFloat calculateScaleFactor(ScaleSpec *scale, CGRect pageRect)`** (in `utils.m`)
    *   Calculates the final `CGFloat` scale factor to be applied, based on the `ScaleSpec` and the PDF page's dimensions.

*   **`CGImageRef renderPDFPageToImage(CGPDFPageRef pdfPage, CGFloat scaleFactor, BOOL transparentBackground, BOOL verbose)`** (in `utils.m`)
    *   Takes a `CGPDFPageRef` and a scale factor.
    *   Renders the page into a `CGImageRef` (a bitmap image).
    *   Handles background transparency.

*   **`BOOL writeImageToFile(CGImageRef image, NSString *outputPath, int pngQuality, BOOL verbose)`** (in `utils.m`)
    *   Writes the given `CGImageRef` to the specified `outputPath` as a PNG file.

*   **`BOOL writeImageAsPNG(CGImageRef image, NSFileHandle *output, int pngQuality, BOOL verbose)`** (in `utils.m`)
    *   Writes the `CGImageRef` as PNG data to the given `NSFileHandle` (e.g., stdout).

*   **`BOOL processSinglePage(CGPDFDocumentRef pdfDocument, Options *options)`** (in `pdf22png.m`)
    *   Orchestrates the conversion of a single PDF page based on `options`.

*   **`BOOL processBatchMode(CGPDFDocumentRef pdfDocument, Options *options)`** (in `pdf22png.m`)
    *   Orchestrates the conversion of all pages in a PDF document, typically using Grand Central Dispatch (`dispatch_apply`) for parallel processing.

### Helper Functions

*   **`void printUsage(const char *programName)`** (in `pdf22png.m`)
*   **`NSString *getOutputPrefix(Options *options)`** (in `utils.m`)
*   **`void logMessage(BOOL verbose, NSString *format, ...)`** (in `utils.m`)

## Using the Code

To use this code directly:
1.  Include `pdf22png.h` and `utils.h`.
2.  Compile and link `pdf22png.m` and `utils.m` with your project.
3.  Ensure your project links against the necessary frameworks: `Foundation`, `Quartz` (which includes CoreGraphics/PDFKit functionalities), and `ImageIO`.
4.  Manually populate an `Options` struct with your desired settings.
5.  Obtain a `CGPDFDocumentRef` for your PDF.
6.  Call `processSinglePage` or `processBatchMode`, or adapt their internal logic (like `renderPDFPageToImage` and `writeImageToFile`) for your specific needs.

This provides a starting point. The code is designed for CLI execution, so error handling often involves `fprintf` to `stderr` and `exit(1)`. For library use, you might want to adapt this to return `NSError` objects or use other error reporting mechanisms.
