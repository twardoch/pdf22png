# PDF22PNG Project Plan

## COMPLETED: Implementation Renaming ✓

**Successfully Renamed** (2025-06-27):

-   **Objective-C Implementation**: `pdf22png-objc` → `pdf21png` (mature, stable, performance-focused)
-   **Swift Implementation**: `pdf22png-swift` → `pdf22png` (modern, evolving, feature-rich)

### What Was Accomplished

-   ✓ Directory renaming: `pdf22png-objc` → `pdf21png`, `pdf22png-swift` → `pdf22png`
-   ✓ Source code updates: All references updated in both implementations
-   ✓ Build system updates: Makefiles and Package.swift updated
-   ✓ Script updates: `build.sh`, `test_both.sh`, and `bench.sh` updated
-   ✓ Binary naming: `pdf21png` for Objective-C, `pdf22png` for Swift
-   ✓ Documentation: CHANGELOG.md updated, TODO.md tasks marked complete

## Phase 15: Seamless Installation & Production Ready (2025-06-27)

### 15.1 Priority 1: Homebrew Installation (Immediate)

#### 15.1.1 Create Release Script
- **File**: `release.sh` - Automated release process for both implementations
  - Build universal binaries for both pdf21png and pdf22png
  - Generate SHA256 checksums automatically
  - Create GitHub releases with proper tags
  - Update Homebrew formulas with release URLs and checksums
  - Support version bumping (semantic versioning)
  - Include pre-release testing phase

#### 15.1.2 Finalize Homebrew Formulas
- **pdf21png.rb**: Production-ready formula for Objective-C implementation
  - Add proper download URL from GitHub releases
  - Include SHA256 verification
  - Add comprehensive test block
  - Support both Intel and Apple Silicon
  - Add caveats for migration from old names
  
- **pdf22png.rb**: Modern formula for Swift implementation
  - Configure Swift runtime dependencies
  - Add proper test coverage
  - Include migration notices
  - Support universal binary distribution

#### 15.1.3 Homebrew Tap Setup
- Create official tap repository: `homebrew-pdf22png`
- Configure tap automation with GitHub Actions
- Add tap documentation and usage instructions
- Set up bottle building for faster installation
- Configure tap CI/CD for automatic updates

### 15.2 Priority 2: Installation Documentation (Immediate)

#### 15.2.1 README.md Overhaul
- **Installation Section** (top priority):
  - Clear Homebrew installation as primary method
  - Simple one-liner: `brew install twardoch/pdf22png/pdf22png`
  - Alternative for pdf21png: `brew install twardoch/pdf22png/pdf21png`
  - Migration guide from old installation methods
  - Troubleshooting common installation issues

- **Quick Start Guide**:
  - 5-minute tutorial with real examples
  - Visual output examples (before/after)
  - Common use cases with copy-paste commands
  - Performance comparison table

#### 15.2.2 Installation Scripts Enhancement
- **scripts/install.sh**:
  - Auto-detect best installation method
  - Check for Homebrew and suggest it first
  - Fallback to source compilation
  - Interactive mode for choosing implementation
  - Post-install verification

- **scripts/uninstall.sh**:
  - Detect installation method (Homebrew vs manual)
  - Clean removal of all components
  - Backup configuration option
  - Migration data preservation

### 15.3 Priority 3: Build System Refinement (This Week)

#### 15.3.1 Universal Makefile
- Create top-level Makefile orchestrating both implementations:
  ```makefile
  all: pdf21png pdf22png
  pdf21png: check-deps-objc
  pdf22png: check-deps-swift
  install: install-pdf21png install-pdf22png
  test: test-pdf21png test-pdf22png
  release: release-pdf21png release-pdf22png
  ```

#### 15.3.2 Dependency Management
- **Objective-C**: Check for Xcode Command Line Tools
- **Swift**: Verify Swift toolchain version
- Add `make check-deps` target
- Create `scripts/install-deps.sh` for automated setup

### 15.4 Priority 4: Quality Assurance (This Week)

#### 15.4.1 Automated Testing Pipeline
- **Unit Tests**:
  - Port Objective-C tests to XCTest
  - Expand Swift test coverage to 80%+
  - Add edge case testing (corrupt PDFs, large files)
  
- **Integration Tests**:
  - Test both CLIs with same inputs
  - Verify output consistency
  - Performance regression tests
  - Memory leak detection

#### 15.4.2 CI/CD Enhancement
- **GitHub Actions Improvements**:
  - Matrix builds (macOS versions × architectures)
  - Automated release on tag push
  - Homebrew formula auto-update
  - Performance benchmarking on PRs
  - Security scanning (SAST)

### 15.5 Priority 5: Developer Experience (Next Week)

#### 15.5.1 Development Environment
- **Devcontainer Configuration**:
  - Pre-configured VS Code environment
  - All dependencies pre-installed
  - Debugging configurations for both implementations
  - Integrated testing shortcuts

#### 15.5.2 Code Quality Tools
- **Pre-commit Hooks**:
  - SwiftLint/SwiftFormat for Swift
  - clang-format for Objective-C
  - Spell checking for documentation
  - Conventional commit enforcement

### 15.6 Priority 6: Documentation Excellence (Next Week)

#### 15.6.1 User Documentation
- **Comprehensive Guide**:
  - PDF processing best practices
  - Performance tuning guide
  - Batch processing examples
  - Integration with other tools

#### 15.6.2 API Documentation
- **Swift**: Generate DocC documentation
- **Objective-C**: Use HeaderDoc format
- Host on GitHub Pages
- Include architecture diagrams

### 15.7 Priority 7: Performance & Optimization (Ongoing)

#### 15.7.1 Benchmarking Suite
- Standardized benchmark PDFs
- Automated performance tracking
- Memory usage profiling
- Regression detection

#### 15.7.2 Optimization Targets
- Parallel processing for batch operations
- Memory pool optimization
- Cache optimization for repeated operations

### 15.8 Priority 8: Long-term Maintenance (Future)

#### 15.8.1 Version Strategy
- Semantic versioning enforcement
- Changelog automation
- Breaking change documentation
- LTS version planning

#### 15.8.2 Community Building
- Contributing guidelines
- Code of conduct
- Issue templates
- Pull request templates

## Current Priorities (2025-06-27)

### Immediate Tasks (COMPLETED)

1. **Documentation Overhaul**

    - Rewrite README.md with user-friendly language
    - Create comprehensive CONTRIBUTING.md for developers
    - Update all examples and guides

2. **Remaining Renaming Tasks**

    - Update GitHub Actions workflows
    - Create separate Homebrew formulas
    - Update installation scripts

3. **Testing and Validation**
    - Run comprehensive test suite
    - Benchmark both implementations
    - Verify installation process

### Swift Porting Strategy (Phase 13.1: Architectural Blueprint)

-   **Goal**: Gradually migrate the ObjC codebase to pure Swift while guaranteeing that the existing Objective-C implementation remains the canonical, production-ready path until feature- and performance-parity is proven.
-   **High-level mapping between current ObjC modules and their future Swift equivalents:**
    -   **CLI (Command Line Interface):**
        -   Objective-C: `parseArguments`, `printUsage`
        -   Swift Equivalent: Utilize `ArgumentParser` framework.
    -   **PDFCore (PDF Document Handling):**
        -   Objective-C: `readPDFData`, `parsePageRange`, `extractTextFromPDFPage`, `performOCROnImage`, direct `CoreGraphics` PDF functions.
        -   Swift Equivalent: `PDFDocument` wrapper (PDFKit/CoreGraphics), `PageRangeParser`, `TextExtractor` (Vision for OCR).
    -   **RenderCore (Image Rendering):**
        -   Objective-C: `renderPDFPageToImage`, `renderPDFPageToImageOptimized`, `calculateScaleFactor`.
        -   Swift Equivalent: `PDFRenderer` and `ScaleCalculator`.
    -   **IO (Input/Output & File Management):**
        -   Objective-C: `writeImageAsPNG`, `writeImageToFile`, `writeImageToFileWithLocking`, `fileExists`, `shouldOverwriteFile`, `promptUserForOverwrite`, `acquireFileLock`, `releaseFileLock`.
        -   Swift Equivalent: `ImageWriter`, `FileManager` extensions, `FileLocker`.
    -   **Utils (General Utilities):**
        -   Objective-C: `logMessage`, `reportError`, `reportWarning`, `getTroubleshootingHint`, `slugifyText`, `formatFilenameWithPattern`, `getOutputPrefix`, `signalHandler`.
        -   Swift Equivalent: `Logger`, `ErrorReporter`, `String` extensions, `FilenameFormatter`, `SignalHandler`.

### Next Steps

-   Release version 2.1.0 for pdf21png
-   Release version 2.2.0 for pdf22png
-   Announce changes to users with migration guide

---

## Historical: Original Renaming Plan

## Phase 1: Core Renaming Strategy (Day 1)

### 1.1 Directory Structure Changes

```bash
# Current structure:
pdf22png/
├── pdf22png-objc/     → pdf21png/
├── pdf22png-swift/    → pdf22png/

# New structure:
pdf22png/              # Keep root as pdf22png for continuity
├── pdf21png/          # Objective-C implementation
├── pdf22png/          # Swift implementation
```

### 1.2 Binary Output Names

-   Objective-C: `pdf22png` → `pdf21png`
-   Swift: `pdf22png-swift` → `pdf22png`

### 1.3 Renaming Order (Critical Path)

1. **Source Code** - Update internal references first
2. **Build Systems** - Ensure builds work with new names
3. **Documentation** - Update all docs to reflect new names
4. **Scripts** - Update automation scripts
5. **CI/CD** - Update GitHub Actions
6. **Package Management** - Update Homebrew formula

## Phase 2: Objective-C Implementation Renaming (Day 1-2)

### 2.1 Source Code Updates

Files to modify in `pdf22png-objc/` (becoming `pdf21png/`):

-   `src/pdf22png.m` → `src/pdf21png.m`
-   `src/pdf22png.h` → `src/pdf21png.h`
-   Update all `#include "pdf22png.h"` → `#include "pdf21png.h"`
-   Update program name in help text and version strings
-   Update `PDF22PNG` macros → `PDF21PNG`

### 2.2 Build System Updates

-   `Makefile`: Change `TARGET = pdf22png` → `TARGET = pdf21png`
-   Update all references to binary name
-   Update installation paths

### 2.3 Directory Rename

```bash
mv pdf22png-objc pdf21png
```

## Phase 3: Swift Implementation Updates (Day 2-3)

### 3.1 Source Code Updates

Files to modify in `pdf22png-swift/` (becoming `pdf22png/`):

-   `Package.swift`: Update executable name from `pdf22png-swift` to `pdf22png`
-   `Sources/main.swift`: Update program identification
-   Remove `-swift` suffix from all references

### 3.2 Build System Updates

-   `Makefile`: Update target names
-   `Package.swift`: Update product name

### 3.3 Directory Rename

```bash
mv pdf22png-swift pdf22png
```

## Phase 4: Documentation Updates (Day 3-4)

### 4.1 Main Documentation

-   `README.md`: Update to explain new naming convention
    -   pdf21png: The stable, performance-optimized implementation
    -   pdf22png: The modern, feature-rich implementation
-   Add migration guide for existing users

### 4.2 Implementation-Specific Docs

-   `pdf21png/README.md`: Update all references
-   `pdf22png/README.md`: Update all references
-   Man pages: Create separate man pages for each

### 4.3 Guides and Examples

-   Update all example commands
-   Update installation instructions
-   Create comparison table with new names

## Phase 5: Script and Automation Updates (Day 4)

### 5.1 Build Scripts

-   `build.sh`: Update to build both with correct names
-   `test_both.sh`: Update binary paths and names
-   `bench.sh`: Update benchmark scripts

### 5.2 Installation Scripts

-   `scripts/install.sh`: Support installing both binaries
-   `scripts/uninstall.sh`: Remove both binaries
-   Update default installation behavior

## Phase 6: CI/CD and Package Management (Day 5)

### 6.1 GitHub Actions

-   Update all workflow files
-   Ensure artifacts use correct names
-   Update release automation

### 6.2 Homebrew Formula

-   Create two formulas: `pdf21png.rb` and `pdf22png.rb`
-   Update tap configuration
-   Test installation of both tools

## Phase 7: Testing and Validation (Day 5-6)

### 7.1 Build Testing

-   Verify both implementations build correctly
-   Test installation process
-   Verify binary names and paths

### 7.2 Functional Testing

-   Run test suite for both implementations
-   Verify command-line compatibility
-   Test upgrade scenarios

### 7.3 Documentation Review

-   Verify all references are updated
-   Check for broken links
-   Review help text and version info

## Phase 8: Release and Communication (Day 7)

### 8.1 Release Preparation

-   Create release notes explaining the renaming
-   Prepare migration guide
-   Update changelog

### 8.2 Version Strategy

-   pdf21png: v2.1.0 (indicating maturity)
-   pdf22png: v2.2.0 (indicating next generation)

### 8.3 User Communication

-   Clear explanation of why the change
-   Benefits of the new naming
-   Migration instructions

## Implementation Checklist

### Immediate Actions (Today)

-   [ ] Create backup branch
-   [ ] Start with Objective-C implementation rename
-   [ ] Update core source files

### High Priority (This Week)

-   [ ] Complete all source code updates
-   [ ] Update build systems
-   [ ] Test both implementations
-   [ ] Update primary documentation

### Medium Priority (Next Week)

-   [ ] Update all scripts
-   [ ] Update CI/CD pipelines
-   [ ] Create Homebrew formulas
-   [ ] Complete documentation updates

## Success Criteria

1. **Clean Separation**: Each tool has its own identity
2. **No Breaking Changes**: Existing workflows continue to work
3. **Clear Communication**: Users understand the change
4. **Smooth Migration**: Easy path for existing users
5. **Consistent Naming**: All references updated consistently

## Risk Mitigation

1. **Backup Everything**: Keep pre-rename state accessible
2. **Gradual Rollout**: Test thoroughly before release
3. **Compatibility Period**: Support old names temporarily
4. **Clear Documentation**: Extensive migration guides
5. **User Feedback**: Monitor and respond to issues

## Long-term Benefits

1. **Clear Product Differentiation**

    - pdf21png: The reliable workhorse
    - pdf22png: The innovative future

2. **Version Clarity**

    - Version numbers align with product names
    - Clear evolution path

3. **User Choice**

    - Obvious which tool to choose
    - No confusion about capabilities

4. **Development Focus**
    - pdf21png: Stability and performance
    - pdf22png: New features and capabilities

---

# Original Performance Optimization Plan (Now Secondary Priority)

## Executive Summary

**PERFORMANCE OPTIMIZATION COMPLETE**: Both implementations have been successfully optimized, achieving near-parity performance with dramatic improvements:

-   **Objective-C**: 17s real time (was 21.7s), 3.5m CPU time (was 5m)
-   **Swift**: 21.7s real time (was 23.5s), 4.6m CPU time (was 5.5m)
-   **CPU Efficiency**: 48% reduction in CPU time for both implementations

## Phase 14: Codebase Streamlining Roadmap (2025-06-27)

Below is a granular, opinionated roadmap for bringing the dual-implementation project to a truly polished state. Actions are grouped by theme and ordered for maximum leverage.

### 14.1 Repository Hygiene

1. Audit **build artifacts**: ensure `MAKE clean`, `swift package clean`, and top-level `build.sh --clean` leave repository pristine.
2. Introduce **`.gitattributes`** to enforce LF endings, ensure linguist language classification, and generate clean GitHub diffs for Swift/Objective-C.
3. Create a top-level **`.editorconfig`** covering indentation, charset, trim-trailing-whitespace.
4. Add a root-level **`CODEOWNERS`** designating Swift vs ObjC maintainers.

### 14.2 Build System Consolidation

1. Move ObjC + Swift build invocations into a single top-level **`Makefile`** that shells out to the sub-Makefiles / SwiftPM. Targets:
    - `make objc`, `make swift`, `make all`, `make test`, `make install`, `make uninstall`, `make clean`.
2. Deprecate duplicate logic in **`build.sh`**; keep it as thin wrapper calling `make`.
3. Ensure **CI workflows** use the unified make targets.

### 14.3 Swift Package Refactor

1. Promote `ScaleUtilities` into its own SwiftPM package path `Sources/ScaleUtilities/` (move out of `Utils` dir) and mark as **public library**.
2. Split `main.swift` into modules: `CLI.swift`, `Renderer.swift`, `IO.swift`, `Helpers.swift` — retaining single-executable target.
3. Adopt **Result Builders** for option validation to cut boilerplate.

### 14.4 Objective-C Modernisation

1. Replace manual memory pools with **`@autoreleasepool`** blocks in loops.
2. Migrate C macros to `static inline` functions where appropriate.
3. Introduce **Clang Static Analyzer** target in Makefile.

### 14.5 Shared Test Strategy

1. Keep logic-heavy code (e.g. parsing, scaling) in shared Swift/ObjC independent libraries where feasible.
2. Add Swift **integration tests** that spawn the binaries with `Process` and inspect stdout/stderr.
3. Port the Objective-C unit tests to **XCTest** via an ObjC test bundle.

### 14.6 Documentation Automation

1. Generate man pages from a **single Markdown source** via `ronn` to avoid duplication.
2. Have CI verify that generated `.1` files are up-to-date.
3. Create API docs with **DocC** for Swift and **appledoc** for ObjC.

### 14.7 Benchmark & CI Enhancements

1. Slim down benchmark PDF set; add synthetic stress PDFs for pathological cases.
2. Cache SwiftPM build in CI to cut runtime.
3. Post benchmark deltas as PR comments using GitHub Actions.

### 14.8 Release Engineering

1. Bump **semantic versions** automatically based on Conventional Commits using `semantic-release`.
2. Publish universal binaries as **GitHub Releases** assets and Homebrew bottle.
3. Push Docker image with both binaries pre-installed for CI consumers.

### 14.9 Developer-Experience Polish

1. Provide VS Code **`.devcontainer`** with Xcode CLT, swiftlint, swift-format.
2. Offer GitHub Codespaces ready-to-hack environment.
3. Enable pre-commit hooks with `swiftformat`, `swiftlint`, and `clang-format`.

> **Milestone**: tagged `v2.3.0` once sections 14.1-14.5 are complete; `v2.4.0` after 14.6-14.9.
