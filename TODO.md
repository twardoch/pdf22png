# TODO List for pdf22png

This list tracks planned features, improvements, and bug fixes.

## Near Term / v1.1 Features

*   [ ] **Man Page**: Create a comprehensive man page for `pdf22png`.
*   [ ] **Enhanced Testing**:
    *   [ ] More unit tests for `utils.m` functions (e.g., `renderPDFPageToImage` with mock objects or actual small PDFs).
    *   [ ] Integration tests: CLI invocation tests covering various argument combinations.
    *   [ ] Test with various complex PDF files (e.g., with layers, annotations, different color spaces).
    *   [ ] Performance benchmarks.
*   [ ] **Color Profile Handling**: Investigate and ensure correct color profile handling during conversion.
*   [ ] **Error Handling**: More robust error reporting, potentially with specific error codes.
*   [ ] **`scripts/build-universal.sh`**: Implement the actual script for creating a universal binary.
*   [ ] **Homebrew Tap**: Finalize and test the Homebrew formula and set up a tap.
*   [ ] **License**: Finalize choice (MIT / Apache 2.0) and add `LICENSE` file.
*   [ ] **Code Signing & Notarization**: For official releases, investigate signing and notarizing the binary.
*   [ ] **`.editorconfig`**: Add a suitable `.editorconfig` file.
*   [ ] **`CMakeLists.txt`**: Decide if CMake build system is needed and implement if so.
*   [ ] **Xcode Project**: Decide if an accompanying Xcode project is beneficial.

## Medium Term / Future Features

*   [ ] **Output Format Selection**: Allow output to other formats like JPEG, TIFF, WebP (would require more image processing libraries or different ImageIO usage).
*   [ ] **PDF Crop Box Selection**: Allow user to specify which PDF box to use for rendering (MediaBox, CropBox, ArtBox, TrimBox, BleedBox).
*   [ ] **Password Protected PDFs**: Add support for decrypting password-protected PDFs (if a password is provided).
*   [ ] **Annotation Handling**: Option to include/exclude PDF annotations in the output.
*   [ ] **Grayscale Output**: Option to convert to grayscale PNG.
*   [ ] **Configuration File**: Support for a configuration file for default options.
*   [ ] **Plugin System**: (Ambitious) Allow plugins for pre/post-processing.

## Completed for v1.0 (Initial Reorganization)

*   [x] Basic directory structure.
*   [x] Core PDF to PNG conversion logic.
*   [x] Argument parsing for main features (page, scale, resolution, batch, etc.).
*   [x] Makefile for build, clean, install.
*   [x] Initial unit tests for `parseScaleSpec`.
*   [x] GitHub Actions for build/test and release.
*   [x] Homebrew formula template.
*   [x] Basic README, USAGE, EXAMPLES, API, CHANGELOG.
*   [x] Refactor code into `pdf22png.m`, `utils.m`, and header files.
*   [x] Implement verbose mode.
*   [x] Add `-t` for transparency.
*   [x] Add `-q` for PNG quality.
*   [x] Add `-a` for all pages without requiring `-d`.
*   [x] Improve argument parsing and help messages.
