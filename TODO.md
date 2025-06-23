# pdf22png Improvement Plan

## High Priority

### Phase 1: Memory Management & Stability
-   [ ] Implement memory pressure monitoring to prevent OOM in batch operations

### Phase 2: Error Handling & Recovery
-   [ ] Add file locking to prevent concurrent write conflicts
-   [ ] Implement stdin timeout and size limits

### Phase 5: Performance Optimizations
-   [ ] Make thread pool size configurable (`--threads N`)
-   [ ] Implement page metadata caching during batch operations
-   [ ] Add fast rendering paths for thumbnails/previews
-   [ ] Skip transparency processing for opaque PDFs

### Phase 6: Testing Infrastructure
-   [ ] Create comprehensive test suite:
    -   Integration tests for CLI operations
    -   Rendering tests with visual regression
    -   Performance benchmarks
    -   Error path coverage
-   [ ] Add test PDF collection (various sizes, features, edge cases)
-   [ ] Add GitHub Actions CI for automated testing
-   [ ] Implement code coverage reporting

## Medium Priority

### Phase 3: Code Architecture Refactoring
-   [x] Split monolithic `pdf22png.m` into logical modules: (COMPLETED - Swift rewrite resulted in `main.swift`, `Models.swift`, `Utilities.swift`)
    -   `PDFProcessor` class for PDF operations (Partially done via functions in Utilities/main)
    -   `ImageRenderer` class for rendering operations (Partially done via functions in Utilities/main)
    -   `BatchProcessor` class for batch operations (Partially done via functions in main)
    -   `CLIParser` class for command-line parsing (COMPLETED - `swift-argument-parser` in `main.swift`)
-   [ ] Remove tight coupling with Options struct (ProcessingOptions is better, but still passed around)
-   [ ] Implement proper dependency injection for testability

### Phase 7: Additional Features
-   [ ] Add metadata preservation (copy PDF metadata to PNG)
-   [ ] Implement color space control (`--colorspace sRGB|AdobeRGB|Gray`)
-   [ ] Add encrypted PDF support with password prompt
-   [ ] Support multi-page TIFF output format
-   [ ] Add size estimation before processing
-   [ ] Implement configuration file support (`~/.pdf22pngrc`)
-   [ ] Add JSON output mode for scripting

### Phase 8: Documentation
-   [ ] Create man page for pdf22png(1)
-   [ ] Add inline code documentation (HeaderDoc format)
-   [ ] Write architecture documentation
-   [ ] Create troubleshooting guide
-   [ ] Add performance tuning guide
-   [ ] Document all error codes and solutions

## Low Priority

### Phase 9: Build System Enhancements
-   [ ] Add header dependency tracking in Makefile (N/A for Swift SPM)
-   [x] Create debug/release build configurations (COMPLETED - SPM handles this, Makefile updated)
-   [ ] Implement proper version injection from git tags (Partially done via Makefile, review Swift embedding)
-   [ ] Add static analysis targets (clang-tidy, scan-build) (Consider SwiftLint)
-   [ ] Create CMake build option for cross-platform builds (N/A, macOS only tool)
-   [ ] Add code signing for macOS distribution
-   [ ] Automate .pkg and .dmg creation in Makefile

### Phase 10: Modernization
-   [x] Add nullability annotations throughout codebase (COMPLETED - Swift optionals)
-   [x] Convert to modern property syntax (COMPLETED - Swift syntax)
-   [x] Replace C-style casts with Objective-C casts (COMPLETED - Swift casts)
-   [x] Use blocks instead of function pointers (COMPLETED - Swift closures)
-   [x] Add collection generics (COMPLETED - Swift generics)
-   [x] Implement proper NSError handling (COMPLETED - Swift `Error` protocol)
-   [x] Add async/await support for batch operations (COMPLETED - Swift Concurrency)

### Phase 11: Security Hardening
-   [ ] Sanitize all file paths to prevent injection
-   [ ] Validate output directories against path traversal
-   [ ] Add resource limits for PDF complexity
-   [ ] Use secure temp file creation
-   [ ] Implement sandboxing where possible
-   [ ] Add code signing and notarization

### Phase 12: Static Analysis
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
1. **Consistent style**: Apply clang-format throughout (Consider `swift-format`)
2. **Remove magic numbers**: Define all constants
3. **Audit TODO/FIXME comments**: Address or remove

## Completed Features ✅
- **Phase 0**: Text extraction with OCR fallback (`-n/--name`)
- **Phase 0**: Page range selection (`-p 1-5,10,15-20`)
- **Phase 0**: Dry-run mode (`-D/--dry-run`)
- **Phase 0**: Custom naming patterns (`-P/--pattern`)
- **Phase 1**: Memory management improvements (@autoreleasepool blocks)
- **Phase 1**: Memory leak fixes in error paths
- **Phase 1**: Graceful shutdown with signal handlers
- **Phase 2**: Unified error handling system with error codes
- **Phase 2**: Partial batch recovery (skip failed pages)
- **Phase 2**: PDF validation (encrypted, empty documents)
- **Phase 4**: Overwrite protection with interactive prompts (`-f/--force`)
- **Phase 4**: Enhanced error messages with troubleshooting hints
- **Phase 6**: Custom test runner (replaced XCTest dependency)
- **Phase 6**: Basic unit tests for utility functions

## Development Guidelines
-   DO NOT maintain backward compatibility for existing CLI usage
-   Prioritize stability over new features
-   Keep macOS-ONLY approach, do not plan portability
-   Focus on user experience and reliability
-   Maintain comprehensive test coverage for new features