# pdf22png API Documentation

While `pdf22png` is primarily a command-line tool, its core logic is available in both Swift and Objective-C implementations. This document provides an overview of the key structures and functions for both versions, which could be adapted for direct use within other macOS applications.

## Core Structures

### Objective-C Implementation

#### `Options`
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
    BOOL includeText;           // Include extracted text in filename
    NSString *pageRange;        // Page range specification
    BOOL dryRun;                // Preview operations without writing
    NSString *namingPattern;    // Custom naming pattern
    BOOL forceOverwrite;        // Force overwrite without prompting
} Options;
```

#### `ScaleSpec`
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

### Swift Implementation

#### `ProcessingOptions`
Defined in `Sources/pdf22png/Models.swift`

```swift
struct ProcessingOptions {
    var scale = ScaleSpecification()
    var pageNumber: Int = 1
    var inputPath: String?
    var outputPath: String?
    var outputDirectory: String?
    var batchMode = false
    var transparentBackground = false
    var pngQuality = 6
    var verbose = false
    var includeText = false
    var pageRange: String?
    var dryRun = false
    var namingPattern: String?
    var forceOverwrite = false
}
```

#### `ScaleSpecification`
Defined in `Sources/pdf22png/Models.swift`

```swift
struct ScaleSpecification {
    var scaleFactor: CGFloat = 1.0
    var maxWidth: CGFloat = 0
    var maxHeight: CGFloat = 0
    var dpi: CGFloat = 144  // Default DPI
    var isPercentage: Bool = true
    var isDPI: Bool = false
    var hasWidth: Bool = false
    var hasHeight: Bool = false
}
```

## Key Functions

### Objective-C Implementation

The primary logic is found in `src/pdf22png.m` and utility functions in `src/utils.m`.

#### Main Entry Point
The `main` function in `src/pdf22png.m` orchestrates the process:
1.  Parses command-line arguments into an `Options` struct (`parseArguments`).
2.  Reads PDF data (`readPDFData` from `utils.m`).
3.  Creates a `CGPDFDocumentRef` from the data.
4.  Either processes a single page (`processSinglePage`) or all pages in batch mode (`processBatchMode`).

#### Core Conversion Functions

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

#### Helper Functions

*   **`void printUsage(const char *programName)`** (in `pdf22png.m`)
*   **`NSString *getOutputPrefix(Options *options)`** (in `utils.m`)
*   **`void logMessage(BOOL verbose, NSString *format, ...)`** (in `utils.m`)
*   **`NSString *extractTextFromPDFPage(CGPDFPageRef page)`** (in `utils.m`)
*   **`NSString *performOCROnImage(CGImageRef image)`** (in `utils.m`)
*   **`NSArray<NSNumber *> *parsePageRange(NSString *rangeSpec, NSUInteger totalPages)`** (in `utils.m`)

### Swift Implementation

The Swift implementation is found in `Sources/pdf22png/`.

#### Main Entry Point
The `PDF22PNG` struct in `main.swift` uses ArgumentParser:
1. Parses command-line arguments automatically via `@Option` and `@Flag` properties
2. Configures options in the `run()` method
3. Calls either `processSinglePage` or `processBatchMode`

#### Core Conversion Functions

*   **`func parseScaleSpecification(_ spec: String) -> ScaleSpecification?`** (in `Utilities.swift`)
    *   Parses scale specifications into a `ScaleSpecification` struct

*   **`func readPDFData(_ inputPath: String?, verbose: Bool) -> Data?`** (in `Utilities.swift`)
    *   Reads PDF data from file or stdin

*   **`func calculateScaleFactor(scale: ScaleSpecification, pageRect: CGRect) -> CGFloat`** (in `Utilities.swift`)
    *   Calculates the scale factor based on specifications

*   **`func renderPDFPageToImage(page: PDFPage, scaleFactor: CGFloat, transparentBackground: Bool, verbose: Bool) -> CGImage?`** (in `Utilities.swift`)
    *   Renders a PDF page to a CGImage

*   **`func writeImageToFile(image: CGImage, path: String, quality: Int, verbose: Bool, dryRun: Bool, forceOverwrite: Bool) -> Bool`** (in `Utilities.swift`)
    *   Writes image to file with overwrite protection

*   **`func processSinglePage(pdfDocument: PDFDocument, options: inout ProcessingOptions) throws -> Bool`** (in `main.swift`)
    *   Processes a single PDF page

*   **`func processBatchMode(pdfDocument: PDFDocument, options: inout ProcessingOptions) throws -> Bool`** (in `main.swift`)
    *   Processes multiple pages using Swift Concurrency

#### Helper Functions

*   **`func logMessage(_ verbose: Bool, _ message: String)`** (in `Utilities.swift`)
*   **`func extractTextFromPDFPage(page: PDFPage) -> String?`** (in `Utilities.swift`)
*   **`func performOCROnImage(image: CGImage) async -> String?`** (in `Utilities.swift`)
*   **`func parsePageRange(_ rangeSpec: String, totalPages: Int) -> [Int]?`** (in `Utilities.swift`)
*   **`func formatFilenameWithPattern(...) -> String`** (in `Utilities.swift`)

## Using the Code

### Objective-C Usage

To use the Objective-C implementation directly:
1. Include `pdf22png.h` and `utils.h`
2. Compile and link `pdf22png.m` and `utils.m` with your project
3. Link against frameworks: `Foundation`, `Quartz`, `Vision`, and `ImageIO`
4. Populate an `Options` struct with your settings
5. Call the appropriate processing functions

### Swift Usage

To use the Swift implementation:
1. Import the module or include the Swift files
2. Create a `ProcessingOptions` instance
3. Use the utility functions directly
4. For CLI parsing, extend the `PDF22PNG` struct

### Framework Requirements

Both implementations require:
- Foundation
- CoreGraphics / Quartz
- PDFKit (part of Quartz)
- Vision (for OCR)
- ImageIO

### Error Handling

- **Objective-C**: Uses BOOL returns and logs errors to stderr
- **Swift**: Uses Swift's error handling with `throws` and typed errors

For library use, you may want to adapt the error handling to return proper error objects instead of printing to stderr.
