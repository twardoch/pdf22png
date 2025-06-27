# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased] - 2025-06-27

### Added
- Created comprehensive improvement plan in PLAN.md (Phase 15) focusing on seamless installation
- Added `release.sh` script for automated release process with SHA256 checksum generation
- Created unified top-level Makefile for building both implementations
- Enhanced README.md with improved Homebrew installation instructions
- Added Quick Start guide with common examples in README.md
- Added troubleshooting section for common issues
- Created simplified TODO.md with prioritized task list
- Updated installation scripts (install.sh, uninstall.sh) to be Homebrew-aware with colored output
- Created `scripts/install-deps.sh` for checking and installing build dependencies
- Added `.editorconfig` for consistent code formatting across the project
- Created comprehensive integration test suite in `tests/integration_test.sh`
- Added `CODEOWNERS` file for repository ownership
- Created new GitHub Actions workflow for automated releases

### Changed
- Reorganized README.md structure for better user experience
- Updated installation section to prioritize Homebrew as primary method
- Improved command options documentation with clear table format
- Enhanced usage examples with real-world scenarios
- Updated install.sh to intelligently detect and prefer Homebrew
- Updated uninstall.sh to detect installation method and handle appropriately
- Both scripts now have interactive confirmation and better error handling
- Updated build.sh to use unified Makefile as backend
- Enhanced Homebrew formulas with better structure, caveats, and comprehensive tests
- Updated GitHub Actions workflows:
  - `build.yml`: Added matrix builds for multiple macOS versions
  - `release.yml`: Integrated with release.sh and automated SHA256 generation

### Improved
- Installation scripts now feature colored output for better readability
- Scripts automatically detect whether tools were installed via Homebrew or manually
- Added non-interactive mode for automation
- Better PATH verification after installation
- Homebrew formulas now include version detection and migration guidance
- Build system now has centralized dependency checking
- GitHub Actions now cache Swift Package Manager dependencies
- Release workflow can be triggered manually with version input

### Planned
- Homebrew tap configuration for official distribution
- Enhanced test coverage for both implementations
- Developer environment improvements (.devcontainer, pre-commit hooks)
- Performance benchmarking automation

## [Unreleased] - 2025-06-27 (Phase 21: Distribution)

### Added
- Created `scripts/get-version.sh` for semantic versioning based on git tags
- Created `scripts/build-pkg.sh` to build macOS .pkg installer
- Created `scripts/build-dmg.sh` to build macOS .dmg disk image
- Added distribution targets to Makefile: `dist`, `pkg`, `dmg`, `version`
- Updated GitHub Actions release workflow to automatically build installers

### Changed
- Release workflow now creates .pkg and .dmg files with SHA256 checksums
- Version numbering now based on git tags (e.g., v2.3.0)
- Installers include both pdf21png and pdf22png binaries

### Distribution Features
- **PKG Installer**: Professional installer with pre/post scripts, installs to /usr/local/bin
- **DMG Disk Image**: User-friendly drag-and-drop installation with install/uninstall scripts
- **Version Management**: Automatic version detection from git tags with semantic versioning
- **Automated Releases**: GitHub Actions builds all artifacts on version tag push

## [2.1.0 / 2.2.0] - 2025-06-27

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

### Fixed
- Fixed "use of undeclared identifier 'programName'" error in `pdf21png.m` by replacing `programName` with `argv[0]`.
- Fixed "conflicting types for 'shouldOverwriteFile'" and "too few arguments to function call" errors by removing the `interactive` parameter from `shouldOverwriteFile` in `utils.m` and `utils.h`.
- Confirmed that both Objective-C and Swift implementations build and pass tests.
- Updated `bench.sh` script to use correct binary paths after renaming
- Cleaned up old binary artifacts from build directories
- Marked implementation renaming tasks as complete in TODO.md

### Updated (2025-06-27)
- Updated Swift implementation's `main.swift` to use "pdf22png" as commandName instead of "pdf22png-swift"
- Updated version number in Swift implementation to 2.2.0 for consistency
- Added comprehensive migration guide to root README.md explaining the differences between implementations
- Added comparison table to help users choose between pdf21png and pdf22png
- Verified all tests pass after renaming (both implementations generate 134 PNG files successfully)
- Verified Homebrew formulas exist for both pdf21png and pdf22png
- Confirmed GitHub Actions workflows are updated with correct paths
- Marked completed tasks in TODO.md

### Remaining Tasks
The following tasks remain for future completion:
- Update documentation files in docs/ directory for dual implementation structure
- Update installation scripts (install.sh, uninstall.sh, dev-setup.sh)
- Update benchmark files to use new binary names
- Create man pages for both pdf21png and pdf22png

## [Unreleased]

### Added
- **Documentation**: dual man pages (`docs/pdf22png.1`, `docs/pdf21png.1`) clarifying Swift vs Objective-C binaries.
- **Docs**: Usage, API, Examples all now reference both binaries.
- **Plan**: Introduced Phase 14 streamlining roadmap in `PLAN.md` with detailed tasks.
- **Tests**: New `ScaleSpecTests` unit-test target covering core scale parsing logic.

### Changed
- **Scripts**: `dev-setup.sh` root-dir check & build logic updated for dual-implementation layout.
- **Package.swift**: added explicit `ScaleUtilitiesTests` test target.
- **TODO.md**: cleaned completed items, added Phase 14 checklist.

### Removed
- Placeholder and obsolete Swift test suites (`ArgumentParserTests`, `InputValidatorTests`, `CoreTests`, legacy test runner) preventing clean build.

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
