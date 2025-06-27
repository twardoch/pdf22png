# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.1.0 / 2.2.0] - 2024-06-27

### Major Change: Implementation Renaming
- **BREAKING CHANGE**: The project now provides two distinct implementations with different names:
  - **pdf21png** (v2.1.0): The Objective-C implementation, formerly `pdf22png`
  - **pdf22png** (v2.2.0): The Swift implementation, formerly `pdf22png-swift`
- This change clarifies the purpose and evolution of each tool:
  - pdf21png = Mature, stable, performance-focused (version 2.1)
  - pdf22png = Modern, evolving, feature-rich (version 2.2)

### Migration Guide
- If you have scripts using `pdf22png`, they will now use the Swift implementation
- For performance-critical applications, switch to `pdf21png`
- Both tools maintain backward compatibility with existing command-line options

## [Unreleased]

### Changed
- **MAJOR CODEBASE REORGANIZATION**: Complete restructuring into dual self-contained implementations
  - **Removed**: Old `src/` directory structure with mixed implementation
  - **Removed**: Root-level `Makefile` and `Package.swift` files
  - **Created**: `pdf22png-objc/` directory with complete Objective-C implementation
    - Self-contained source files: `pdf22png.m`, `utils.m`, `*.h`
    - Complete Makefile with build, debug, universal, install, test targets
    - Implementation-specific README emphasizing performance
    - Binary output: `pdf22png-objc/build/pdf22png`
  - **Created**: `pdf22png-swift/` directory with complete Swift implementation
    - Simplified single-file implementation using ArgumentParser
    - Swift Package Manager configuration with minimal dependencies
    - Makefile wrapper for consistent build interface
    - Implementation-specific README emphasizing modern Swift features
    - Binary output: `pdf22png-swift/.build/release/pdf22png-swift`
  - **Enhanced**: Top-level `build.sh` script now orchestrates both implementations
    - Build both: `./build.sh`
    - Build specific: `./build.sh --objc-only` or `./build.sh --swift-only`
    - Debug builds: `./build.sh --debug`
    - Clean builds: `./build.sh --clean`
    - Verbose output: `./build.sh --verbose`
    - Color-coded output with build status indicators

### Added
- **Self-Contained Build Systems**: Each implementation has its own complete build system
  - **Objective-C**: Traditional Makefile with clang compilation
    - Targets: `all`, `debug`, `universal`, `install`, `uninstall`, `clean`, `test`, `help`
    - Universal binary support for Intel + Apple Silicon
    - Static analysis and profiling options
  - **Swift**: Swift Package Manager with ArgumentParser dependency
    - Targets: `build`, `debug`, `test`, `install`, `uninstall`, `clean`, `reset`, `help`
    - Modern Swift 5.7+ with structured error handling
    - Single-file implementation for easier maintenance
- **Implementation-Specific Documentation**: Focused README files for each implementation
  - **Objective-C README**: Emphasizes performance, native frameworks, file locking, OCR
  - **Swift README**: Emphasizes type safety, modern architecture, ArgumentParser integration
  - **Main README**: Updated with clear comparison table and decision guide
- **Unified Build Experience**: Top-level build script with comprehensive options
  - Parallel build support for both implementations
  - Individual implementation selection
  - Consistent interface across different build systems
  - Error handling and status reporting

### Fixed
- **Swift Implementation Stability**: Completely rebuilt for reliability
  - Removed complex module dependencies that caused circular import issues
  - Eliminated missing type errors and build failures
  - Fixed macOS version compatibility (now requires macOS 11+ for UTType support)
  - Simplified Package.swift structure for reliable dependency resolution
  - Consolidated into single main.swift file with ArgumentParser
- **Build System Reliability**: Eliminated build conflicts and dependency issues
  - Removed shared code that caused maintenance overhead
  - Fixed Swift Package Manager configuration issues
  - Resolved file path conflicts between implementations
  - Standardized build output locations

### Removed
- **Legacy Mixed Implementation**: Cleaned up old architecture
  - Removed `src/` directory with mixed Objective-C/Swift code
  - Removed root-level `Makefile` that tried to handle both implementations
  - Removed root-level `Package.swift` with complex module structure
  - Eliminated shared dependencies that caused conflicts
- **Complex Module Structure**: Simplified Swift implementation
  - Removed separate CLI, Core, Models, Utilities modules
  - Eliminated circular dependencies and import issues
  - Removed unused test files and complex Package.swift targets

### Technical Details
- **Objective-C Implementation** (`pdf22png-objc/`):
  - Binary: `pdf22png-objc/build/pdf22png`
  - Build time: ~2 seconds
  - Memory usage: 9-12 MB
  - Features: Complete feature set with file locking, OCR, advanced error handling
  - Dependencies: System frameworks only
- **Swift Implementation** (`pdf22png-swift/`):
  - Binary: `pdf22png-swift/.build/release/pdf22png-swift`
  - Build time: ~60 seconds (includes dependency resolution)
  - Modern Swift with ArgumentParser for CLI
  - Simplified architecture for easier maintenance
  - Dependencies: ArgumentParser only

### Documentation Updates
- **CHANGELOG.md**: Updated with comprehensive reorganization details
- **README.md**: Complete rewrite for dual-implementation architecture
  - Clear comparison table between implementations
  - Updated usage examples with correct binary paths
  - Decision guide for choosing implementation
  - Installation instructions for both implementations
- **PLAN.md**: Updated to reflect new architecture and future roadmap
  - Focus on polishing and enhancing both implementations independently
  - Clear development workflow for dual implementations
- **TODO.md**: Restructured for dual-implementation development plan
  - Implementation-specific enhancement priorities
  - Cross-implementation validation strategies
  - Independent evolution roadmap

### Migration Guide
- **Old Usage**: `./build/pdf22png input.pdf output.png`
- **New Usage**:
  - Objective-C: `./pdf22png-objc/build/pdf22png input.pdf output.png`
  - Swift: `./pdf22png-swift/.build/release/pdf22png-swift input.pdf output.png`
- **Building**: Use `./build.sh` instead of `make` for unified builds
- **Installation**: Each implementation can be installed independently

### Changed
- **Major Codebase Reorganization**: Split into separate, self-contained implementations
  - Created `pdf22png-objc/` directory with complete Objective-C implementation
  - Created `pdf22png-swift/` directory with complete Swift implementation
  - Each implementation is now fully self-contained with its own:
    - Source code and headers
    - Makefile with build, debug, install, and test targets
    - README with implementation-specific documentation
    - Build artifacts in their own directories
  - Updated top-level `build.sh` script to build both implementations
    - Supports `--objc-only` and `--swift-only` options
    - Supports `--debug` for debug builds
    - Supports `--clean` for clean builds
    - Supports `--verbose` for detailed output
    - Color-coded output with build status
  - Removed old `src/` directory and consolidated files
  - Each implementation can be built, installed, and used independently

### Added
- **Self-Contained Build System**: Each implementation has its own complete build system
  - Objective-C: Traditional Makefile with clang compilation
  - Swift: Swift Package Manager with ArgumentParser dependency
- **Unified Build Script**: Top-level `build.sh` orchestrates both implementations
  - Build both: `./build.sh`
  - Build one: `./build.sh --objc-only` or `./build.sh --swift-only`
  - Debug builds: `./build.sh --debug`
  - Clean builds: `./build.sh --clean`
- **Implementation-Specific Documentation**: Each directory contains focused README
  - Objective-C README emphasizes performance and native frameworks
  - Swift README emphasizes type safety and modern architecture

### Fixed
- **Swift Implementation Stability**: Simplified Swift implementation for reliability
  - Removed complex module dependencies that caused build issues
  - Consolidated into single-file implementation using ArgumentParser
  - Fixed macOS version compatibility issues (now requires macOS 11+)
  - Eliminated circular dependencies and missing type errors
  - Simplified Package.swift structure for reliable builds

### Technical Details
- **Objective-C Implementation** (`pdf22png-objc/`):
  - Binary: `pdf22png-objc/build/pdf22png`
  - Build time: ~2 seconds
  - Memory usage: 9-12 MB
  - Optimized for maximum performance
- **Swift Implementation** (`pdf22png-swift/`):
  - Binary: `pdf22png-swift/.build/release/pdf22png-swift`
  - Build time: ~60 seconds (includes dependency resolution)
  - Modern Swift with ArgumentParser
  - Type-safe error handling
  - Requires macOS 11+ for UTType support

### Added
- **Enhanced Progress Reporting for Batch Operations**:
  - Real-time progress bar with visual indicators
  - Processing speed display (pages/second)
  - ETA (Estimated Time to Arrival) calculation
  - Success/failure counters during processing
  - Final summary with total time and average speed
  - Updates every 0.5 seconds for smooth feedback
  - Progress format: `[████████░░░░░░░░░░░░] 40% | 40/100 pages | 5.2 pages/s | ETA: 00:12 | ✓:38 ✗:2`
- **GitHub Actions Workflows for Continuous Integration**:
  - `benchmark.yml`: Automated performance benchmarking on PRs
    - Runs benchmarks on every PR to main branch
    - Compares performance against baseline
    - Blocks merge if regression exceeds 10%
    - Posts detailed results as PR comment
    - Supports quick, standard, and extended benchmark modes
  - `benchmark-history.yml`: Historical performance tracking
    - Stores benchmark results in dedicated branch
    - Archives CSV data for trend analysis
    - Generates performance badges for README
    - Maintains performance history by date

### Added
- **Comprehensive Documentation Update**:
  - Extensive architecture documentation for both implementations
  - Detailed technical stack descriptions
  - Code organization diagrams with tree structure
  - Implementation comparison table with 11 key metrics
  - Decision guide for choosing between implementations
  - Performance analysis with real benchmark data
  - File size optimization comparisons
  - Real-world performance tips and recommendations
- **Build and Benchmark Scripts**:
  - `build.sh`: Comprehensive build script for both implementations
    - Supports `--objc-only` and `--swift-only` options
    - Universal binary creation with `--universal` flag
    - Debug builds with `--debug`
    - Clean builds with `--clean`
    - Automatic detection of missing binaries
    - Colored output with build status indicators
    - Build time: ~2 seconds (ObjC), ~10 seconds (Swift)
  - `bench.sh`: Advanced performance benchmarking tool
    - Statistical analysis (average, min, max, standard deviation)
    - Multiple test scenarios with `-q` (quick) and `-e` (extended) modes
    - CSV export with `-o` option for data analysis
    - File size comparison between implementations
    - Colored output with performance summaries
    - Automatic test PDF generation if needed
    - Warm-up runs for accurate timing
    - Progress indicators during benchmark execution
- **Dual Implementation Support**: Both Objective-C and Swift versions now coexist
  - Complete Swift port maintaining feature parity with Objective-C version
  - Swift implementation uses modern Swift Package Manager
  - Both versions can be built and installed side by side
  - Objective-C binary: `pdf22png`, Swift binary: `pdf22png-swift`
- **Comprehensive Benchmark Suite**: Performance comparison framework
  - Automated benchmarking tool comparing ObjC vs Swift implementations
  - Measures conversion speed, memory usage, and scalability
  - Exports results to CSV for analysis
  - Includes multiple test scenarios (single page, multi-page, high DPI, transparency)
  - Sample PDF generator for consistent testing
  - Performance results show Swift is ~33% slower than Objective-C
- **Enhanced Build System**:
  - `make both` builds both implementations
  - `make benchmark` runs performance comparisons
  - `make install-both` installs both versions
  - `make clean-all` for complete cleanup including Swift artifacts
  - `benchmarks/compare_implementations.sh` for quick performance testing

### Performance Notes

#### Speed Performance
- **Objective-C Implementation**: 
  - Single page (144 DPI): ~0.006s
  - Single page (300 DPI): ~0.008s
  - High resolution (600 DPI): ~0.032s
  - Batch processing (10 pages): ~0.061s
  - With transparency: ~0.007s
- **Swift Implementation**: 
  - Single page (144 DPI): ~0.008s (33% slower)
  - Single page (300 DPI): ~0.010s (25% slower)
  - High resolution (600 DPI): ~0.048s (50% slower)
  - Batch processing (10 pages): ~0.089s (46% slower)
  - With transparency: ~0.009s (29% slower)

#### File Size Performance
- Swift produces 65-66% smaller PNG files across all resolutions:
  - 144 DPI: 198KB → 69KB
  - 300 DPI: 856KB → 298KB
  - 600 DPI: 3.2MB → 1.1MB

#### Optimization Journey
- Initial Swift implementation was 10x slower than Objective-C
- Optimized to only ~33% slower through:
  - Replaced PDFKit with direct Core Graphics (`CGPDFDocument`)
  - Implemented resource caching (color spaces, contexts)
  - Pre-allocated memory buffers
  - Fixed deprecated API warnings
  - Optimized PNG compression settings
- Both implementations maintain low memory usage (9-12 MB)
- Binary sizes: ObjC (71KB) vs Swift (1.5MB)

### Changed
- **Reverted Swift Rewrite**: Restored the original Objective-C implementation after an incomplete Swift port.
  - Swift conversion was incomplete and caused loss of functionality
  - Restored all Objective-C source files from git history
  - Maintained all existing features and enhancements developed during the ObjC phase
  - Preserved enhanced error reporting, overwrite protection, and all other improvements
  - Codebase is back to the stable, fully-featured Objective-C implementation

### Added
- File overwrite protection with interactive prompts
  - New `-f/--force` flag to bypass overwrite prompts
  - Interactive confirmation when files would be overwritten
  - Dry-run mode now shows which files would be overwritten
  - Non-interactive mode defaults to not overwriting existing files
- Enhanced error reporting with troubleshooting hints
  - Context-aware error messages provide specific guidance
  - Automatic troubleshooting suggestions based on error type
  - Covers PDF-related, file I/O, memory, scaling, and page range errors
  - Improved user experience with actionable error resolution

### Improved
- Batch processing now provides detailed progress feedback
- Better user experience with visual progress indicators
- More informative output during long-running operations

### Fixed
- Fixed deprecated kUTTypePNG warnings in Objective-C implementation
  - Added UniformTypeIdentifiers framework support
  - Created compatibility layer for macOS 10.15+
  - Uses UTTypePNG on macOS 12+ with fallback to kUTTypePNG
- Optimized Swift implementation performance from 10x to ~33% slower
  - Replaced PDFKit with direct Core Graphics usage
  - Implemented resource caching for color spaces
  - Pre-allocated memory buffers for better performance
  - Created PDFError enum for proper error handling
- Fixed sign comparison warnings in utils.m (NSInteger vs NSUInteger)
- Replaced XCTest dependency with custom test runner for better compatibility
- Improved test coverage with overwrite protection functionality tests

## [1.1.0] - 2025-06-22

### Added
- Automated release script (`release.sh`) with semantic versioning support
  - Automatic version detection from git tags
  - Minor version auto-increment capability
  - Build verification before tagging
  - Colored output for better readability
- Complete GitHub Actions workflow for automated releases with:
  - Universal binary builds for Intel and Apple Silicon
  - PKG installer generation with proper macOS installer structure
  - DMG disk image creation with install script
  - Automated SHA-256 checksum generation
  - GitHub release creation with all artifacts
- New `-n/--name` flag for including extracted text in output filenames
  - Extracts text directly from PDF pages using Core Graphics
  - Falls back to OCR using Vision framework when no text is found
  - Generates slugified filenames like `prefix-001--extracted-text.png`
  - Maximum 30 characters for text suffix, properly truncated at word boundaries
  - Only available in batch mode for performance reasons
- Page range selection with `-p/--page` option supporting complex ranges
  - Single pages: `-p 5`
  - Ranges: `-p 5-10`
  - Comma-separated lists: `-p 1,3,5-10,15`
  - Works in both single page and batch modes
  - Validates ranges against total page count
- Dry-run mode with `-D/--dry-run` flag
  - Preview all operations without writing any files
  - Shows what files would be created with their dimensions
  - Estimates file sizes based on image dimensions
  - Works with all output modes (file, stdout, batch)
  - Useful for testing command options before actual conversion
- Custom naming patterns with `-P/--pattern` option for batch mode
  - `{basename}` or `{name}` - Input filename without extension
  - `{page}` - Page number with automatic padding
  - `{page:03d}` - Page number with custom padding (e.g., 001, 002)
  - `{text}` - Extracted text from page (requires -n flag)
  - `{date}` - Current date in YYYYMMDD format
  - `{time}` - Current time in HHMMSS format
  - `{total}` - Total page count
  - Example: `'{basename}_p{page:04d}_of_{total}'` → `document_p0001_of_10.png`

### Fixed
- Updated GitHub Actions workflow to use modern actions (replaced deprecated create-release@v1 with softprops/action-gh-release@v1)
- Fixed binary path references throughout release workflow
- Corrected build paths in distribution packaging
- Added @autoreleasepool blocks in renderPDFPageToImage() and batch processing loops to prevent memory buildup
- Fixed memory leaks in error paths by ensuring proper cleanup of Core Graphics resources
- Fixed unused variables warnings (scaleXSet, scaleYSet) in calculateScaleFactor()
- Added PDF validation to check for encrypted PDFs and empty documents before processing
- Created unified error handling system with dedicated errors.h header and standardized error codes
- Implemented partial batch recovery - failed pages are now skipped instead of stopping entire batch
- Added graceful shutdown with signal handlers (SIGINT, SIGTERM) for batch operations
- Added progress reporting for batch operations (shows every 10 pages processed)

### Changed
- Reorganized project structure for better maintainability:
  - Build output now goes to `build/` directory instead of project root
  - Updated Makefile to use dedicated build directory with proper dependencies
  - Modified universal build script to output to `build/` directory
  - Updated all scripts and workflows to reference new build location
- Improved build system with explicit directory creation
- Enhanced clean target to properly remove all build artifacts

### Removed
- Removed old monolithic `pdf22png.m` from root directory (superseded by modular version in `src/`)

### Documentation
- Created comprehensive improvement plan in TODO.md with:
  - Critical stability and memory management fixes
  - High-priority user experience enhancements
  - Performance optimization opportunities
  - Testing infrastructure requirements
  - Code modernization roadmap
  - Security hardening recommendations
  - Phased implementation strategy

## [1.0.0] - 2024-06-23

### Added
- Initial project structure for `pdf22png`.
- Core functionality to convert PDF pages to PNG images.
- Support for:
    - Specific page selection (`-p`).
    - Batch conversion of all pages (`-a`, `-d`).
    - Various scaling methods (`-s`): percentage, factor, width/height fitting.
    - Resolution setting in DPI (`-r`).
    - Transparent backgrounds (`-t`).
    - PNG quality hint (`-q`).
    - Input from file or stdin.
    - Output to file or stdout (single page mode).
    - Customizable output directory and filename prefix for batch mode.
    - Verbose logging (`-v`).
    - Help message (`-h`).
- Makefile for building, testing, installing, and cleaning.
- Basic unit tests for utility functions using XCTest.
- GitHub Actions workflows for CI (build & test) and Releases.
- Homebrew formula template.
- Documentation: README, USAGE, EXAMPLES, API, CHANGELOG, TODO.
- `.gitignore`, `.editorconfig` (to be created).
