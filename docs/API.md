# pdf22png / pdf21png API Documentation

The project ships two sibling command-line tools that share a very similar architecture:

* **`pdf21png`** – Objective-C implementation (stable, performance-optimised)
* **`pdf22png`** – Swift implementation (modern, feature-rich)

The sections below expose the internal structures of *both* implementations so you can embed them in a larger macOS application if needed.

## Core Structures

### Objective-C Implementation

#### `Options`
Defined in `pdf21png/src/pdf21png.h`

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
Defined in `pdf21png/src/pdf21png.h`

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

The primary logic is found in `src/pdf21png.m` and utility functions in `src/utils.m`.

#### Main Entry Point
The `main` function in `src/pdf21png.m` orchestrates the process:
1.  Parses command-line arguments into an `Options` struct (`parseArguments`).
2.  Reads PDF data (`readPDFData` from `utils.m`).
3.  Creates a `CGPDFDocumentRef` from the data.
4.  Either processes a single page (`processSinglePage`) or all pages in batch mode (`processBatchMode`).

#### Core Conversion Functions

*   **`BOOL parseArguments(int argc, const char *argv[])`** (in `pdf21png.m`)
    *   Parses command-line arguments and populates the `Options` struct.
    *   Handles help messages and argument validation.

*   **`BOOL parseScaleSpec(const char *spec, ScaleSpec *scale)`** (in `utils.m`)
    *   Parses the string provided to the `-s` or `-r` option into a `ScaleSpec` struct.

*   **`NSData *readPDFData(NSString *inputPath, BOOL verbose)`** (in `pdf21png.m`)
    *   Reads PDF file data from the given path or from stdin if `inputPath` is `nil`.

*   **`CGFloat calculateScaleFactor(ScaleSpec *scale, CGRect pageRect)`** (in `utils.m`)
    *   Calculates the final scale factor to be applied based on the `ScaleSpec` and page size.

*   **`CGImageRef renderPDFPageToImage(CGPDFPageRef pdfPage, CGFloat scaleFactor, BOOL transparentBackground, BOOL verbose)`** (in `utils.m`)
    *   Renders the page into a bitmap image with optional transparency.

*   **`BOOL writeImageToFile(CGImageRef image, NSString *outputPath, int pngQuality, BOOL verbose)`** (in `utils.m`)
    *   Writes a rendered `CGImageRef` to disk as PNG.

*   **`BOOL writeImageAsPNG(CGImageRef image, NSFileHandle *output, int pngQuality, BOOL verbose)`** (in `utils.m`)
    *   Streams PNG data to the supplied file handle (e.g. stdout).

*   **`BOOL processSinglePage(CGPDFDocumentRef pdfDocument, Options *options)`** (in `pdf21png.m`)
    *   Coordinates conversion of a single page.

*   **`BOOL processBatchMode(CGPDFDocumentRef pdfDocument, Options *options)`** (in `pdf21png.m`)
    *   Converts all pages, leveraging Grand Central Dispatch for parallelism.

#### Helper Functions

*   **`void printUsage(const char *programName)`** (in `pdf21png.m`)
*   **`NSString *getOutputPrefix(Options *options)`** (in `utils.m`)
*   **`void logMessage(BOOL verbose, NSString *format, ...)`** (in `utils.m`)
*   **`NSString *extractTextFromPDFPage(CGPDFPageRef page)`** (in `utils.m`)
*   **`NSString *performOCROnImage(CGImageRef image)`** (in `utils.m`)
*   **`NSArray<NSNumber *> *parsePageRange(NSString *rangeSpec, NSUInteger totalPages)`** (in `utils.m`)

### Swift Implementation

The Swift implementation lives in `pdf22png/Sources/`.

#### Main Entry Point

The `PDF22PNG` struct in `main.swift` uses `ArgumentParser` to map CLI flags to properties, then calls `run()` which invokes either `processSinglePage` or `processBatchMode`.

#### Core Conversion Functions

*   **`func parseScaleSpecification(_ spec: String) -> ScaleSpecification?`** (in `Utilities.swift`)
*   **`func readPDFData(_ inputPath: String?, verbose: Bool) -> Data?`** (in `Utilities.swift`)
*   **`func calculateScaleFactor(scale: ScaleSpecification, pageRect: CGRect) -> CGFloat`** (in `Utilities.swift`)
*   **`func renderPDFPageToImage(page: PDFPage, scaleFactor: CGFloat, transparentBackground: Bool, verbose: Bool) -> CGImage?`** (in `Utilities.swift`)
*   **`func writeImageToFile(image: CGImage, path: String, quality: Int, verbose: Bool, dryRun: Bool, forceOverwrite: Bool) -> Bool`** (in `Utilities.swift`)
*   **`func processSinglePage(pdfDocument: PDFDocument, options: inout ProcessingOptions) throws`** (in `main.swift`)
*   **`func processBatchMode(pdfDocument: PDFDocument, options: inout ProcessingOptions) throws`** (in `main.swift`)

#### Helper Functions

*   **`func logMessage(_ verbose: Bool, _ message: String)`** (in `Utilities.swift`)
*   **`func extractTextFromPDFPage(page: PDFPage) -> String?`** (in `Utilities.swift`)
*   **`func performOCROnImage(image: CGImage) async -> String?`** (in `Utilities.swift`)
*   **`func parsePageRange(_ rangeSpec: String, totalPages: Int) -> [Int]?`** (in `Utilities.swift`)
*   **`func formatFilenameWithPattern(...) -> String`** (in `Utilities.swift`)

## Using the Code

### Objective-C Usage

1. Include `pdf21png.h` and `utils.h` in your own Xcode target.
2. Compile and link `pdf21png.m` and `utils.m`.
3. Link against `Foundation`, `Quartz`, `Vision`, and `ImageIO` frameworks.
4. Populate an `Options` struct and call the desired processing function.

### Swift Usage

1. Import the `pdf22png` module (SwiftPM) or include the source files.
2. Create a `ProcessingOptions` instance.
3. Use utility helpers directly or leverage the CLI's `PDF22PNG` struct.

### Framework Requirements

Both implementations rely on:

* Foundation
* CoreGraphics / Quartz & PDFKit
* Vision (for OCR)
* ImageIO

### Error Handling

* **Objective-C**: Returns `BOOL` and logs errors to stderr.
* **Swift**: Uses `throws` for typed errors.

For library embedding you may wish to adapt these to surface proper error objects instead of printing.
