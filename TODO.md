# pdf22png Improvement Plan

## Phase 0: New feature ✅ COMPLETED

If I supply `-n` or `--name` then the PNG output files should have the prefix, then the page number as it is, but then on top of that a `--TEXT` suffix (two hyphens, yes) where `TEXT` is a slugified string (of up to 30 characters) based on the text or OCR (done using macOS means) for each page. This of course will be a bit slower, so we make this optional.

## Phase 1: Memory Management & Stability

-   [x] Add `@autoreleasepool` blocks in `renderPDFPageToImage()` and batch processing loops
-   [x] Fix memory leaks in error paths (unreleased CGPDFDocumentRef and CGImageRef)
-   [ ] Implement memory pressure monitoring to prevent OOM in batch operations
-   [x] Add resource cleanup in signal handlers for graceful shutdown

## Phase 2: Error Handling & Recovery

-   [x] Create unified error handling system with error codes and descriptive messages
-   [x] Implement partial batch recovery (skip failed pages, continue with others)
-   [x] Add PDF validation before processing
-   [ ] Add file locking to prevent concurrent write conflicts
-   [ ] Implement stdin timeout and size limits

## Phase 3: Code Architecture Refactoring

-   [ ] Split monolithic `pdf22png.m` into logical modules:
    -   `PDFProcessor` class for PDF operations
    -   `ImageRenderer` class for rendering operations
    -   `BatchProcessor` class for batch operations
    -   `CLIParser` class for command-line parsing
-   [ ] Remove tight coupling with Options struct
-   [ ] Implement proper dependency injection for testability

## Phase 4: User Experience

-   [ ] Add progress reporting with ETA for batch operations
-   [ ] Implement page range selection (e.g., `-p 5-10,15,20-25`)
-   [ ] Add custom naming patterns with placeholders (e.g., `{basename}_{page:03d}_{date}`)
-   [ ] Add dry-run mode to preview operations
-   [ ] Implement overwrite protection with interactive prompts
-   [ ] Add verbose error messages with troubleshooting hints

## Phase 5: Performance Optimizations

-   [ ] Make thread pool size configurable (`--threads N`)
-   [ ] Implement page metadata caching during batch operations
-   [ ] Add fast rendering paths for thumbnails/previews
-   [ ] Skip transparency processing for opaque PDFs
-   [ ] Implement parallel PDF loading pipeline

## Phase 6: Testing Infrastructure

-   [ ] Create comprehensive test suite:
    -   Unit tests for all public methods
    -   Integration tests for CLI operations
    -   Rendering tests with visual regression
    -   Performance benchmarks
    -   Error path coverage
-   [ ] Add test PDF collection (various sizes, features, edge cases)
-   [ ] Fix XCTest runner integration
-   [ ] Add GitHub Actions CI for automated testing
-   [ ] Implement code coverage reporting

## Phase 7: Additional Features

-   [ ] Add metadata preservation (copy PDF metadata to PNG)
-   [ ] Implement color space control (`--colorspace sRGB|AdobeRGB|Gray`)
-   [ ] Add encrypted PDF support with password prompt
-   [ ] Support multi-page TIFF output format
-   [ ] Add size estimation before processing
-   [ ] Implement configuration file support (`~/.pdf22pngrc`)
-   [ ] Add JSON output mode for scripting

## Phase 8: Documentation

-   [ ] Create man page for pdf22png(1)
-   [ ] Add inline code documentation (HeaderDoc format)
-   [ ] Write architecture documentation
-   [ ] Create troubleshooting guide
-   [ ] Add performance tuning guide
-   [ ] Document all error codes and solutions
-   [ ] Add more usage examples in README

## Phase 9: Build System Enhancements

-   [ ] Add header dependency tracking in Makefile
-   [ ] Create debug/release build configurations
-   [ ] Implement proper version injection from git tags
-   [ ] Add static analysis targets (clang-tidy, scan-build)
-   [ ] Create CMake build option for cross-platform builds
-   [ ] Add code signing for macOS distribution
-   [ ] Automate .pkg and .dmg creation in Makefile

## Phase 10: Modernization

-   [ ] Add nullability annotations throughout codebase
-   [ ] Convert to modern property syntax
-   [ ] Replace C-style casts with Objective-C casts
-   [ ] Use blocks instead of function pointers
-   [ ] Add collection generics
-   [ ] Implement proper NSError handling
-   [ ] Add async/await support for batch operations

## Phase 11: Security Hardening

-   [ ] Sanitize all file paths to prevent injection
-   [ ] Validate output directories against path traversal
-   [ ] Add resource limits for PDF complexity
-   [ ] Use secure temp file creation
-   [ ] Implement sandboxing where possible
-   [ ] Add code signing and notarization

## Phase 12: Static Analysis

-   [ ] Fix all clang-tidy warnings
-   [ ] Address static analyzer issues
-   [ ] Enable strict compiler warnings
-   [ ] Add AddressSanitizer builds
-   [ ] Implement fuzz testing


## Success Metrics

-   [ ] 90%+ test coverage
-   [ ] Zero memory leaks (verified with Instruments)
-   [ ] Batch processing 100+ page PDFs without OOM
-   [ ] Process 1000 pages/minute on M1 Mac
-   [ ] Comprehensive error messages for all failure modes
-   [ ] Full API documentation
-   [ ] Automated release pipeline

## Technical Debt

1. **Remove unused variables**: ~~Fix `scaleXSet` and `scaleYSet` warnings~~ ✅ COMPLETED
2. **Standardize error codes**: ~~Currently mix of -1, 1, EXIT_FAILURE~~ ✅ COMPLETED (added errors.h)
3. **Consistent style**: Apply clang-format throughout
4. **Remove magic numbers**: Define all constants
5. **Audit TODO/FIXME comments**: Address or remove

## Notes

-   DO NOT maintain backward compatibility for existing CLI usage
-   Prioritize stability over new features
-   Keep macOS-ONLY approach, do not plan portability

