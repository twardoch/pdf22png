# PDF22PNG Project Plan

## COMPLETED: Implementation Renaming ✓

**Successfully Renamed** (2025-06-27):
- **Objective-C Implementation**: `pdf22png-objc` → `pdf21png` (mature, stable, performance-focused)
- **Swift Implementation**: `pdf22png-swift` → `pdf22png` (modern, evolving, feature-rich)

### What Was Accomplished
- ✓ Directory renaming: `pdf22png-objc` → `pdf21png`, `pdf22png-swift` → `pdf22png`
- ✓ Source code updates: All references updated in both implementations
- ✓ Build system updates: Makefiles and Package.swift updated
- ✓ Script updates: `build.sh`, `test_both.sh`, and `bench.sh` updated
- ✓ Binary naming: `pdf21png` for Objective-C, `pdf22png` for Swift
- ✓ Documentation: CHANGELOG.md updated, TODO.md tasks marked complete

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
- **Goal**: Gradually migrate the ObjC codebase to pure Swift while guaranteeing that the existing Objective-C implementation remains the canonical, production-ready path until feature- and performance-parity is proven.
- **High-level mapping between current ObjC modules and their future Swift equivalents:**
    - **CLI (Command Line Interface):**
        - Objective-C: `parseArguments`, `printUsage`
        - Swift Equivalent: Utilize `ArgumentParser` framework.
    - **PDFCore (PDF Document Handling):**
        - Objective-C: `readPDFData`, `parsePageRange`, `extractTextFromPDFPage`, `performOCROnImage`, direct `CoreGraphics` PDF functions.
        - Swift Equivalent: `PDFDocument` wrapper (PDFKit/CoreGraphics), `PageRangeParser`, `TextExtractor` (Vision for OCR).
    - **RenderCore (Image Rendering):**
        - Objective-C: `renderPDFPageToImage`, `renderPDFPageToImageOptimized`, `calculateScaleFactor`.
        - Swift Equivalent: `PDFRenderer` and `ScaleCalculator`.
    - **IO (Input/Output & File Management):**
        - Objective-C: `writeImageAsPNG`, `writeImageToFile`, `writeImageToFileWithLocking`, `fileExists`, `shouldOverwriteFile`, `promptUserForOverwrite`, `acquireFileLock`, `releaseFileLock`.
        - Swift Equivalent: `ImageWriter`, `FileManager` extensions, `FileLocker`.
    - **Utils (General Utilities):**
        - Objective-C: `logMessage`, `reportError`, `reportWarning`, `getTroubleshootingHint`, `slugifyText`, `formatFilenameWithPattern`, `getOutputPrefix`, `signalHandler`.
        - Swift Equivalent: `Logger`, `ErrorReporter`, `String` extensions, `FilenameFormatter`, `SignalHandler`.

### Next Steps
- Release version 2.1.0 for pdf21png
- Release version 2.2.0 for pdf22png
- Announce changes to users with migration guide

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
- Objective-C: `pdf22png` → `pdf21png`
- Swift: `pdf22png-swift` → `pdf22png`

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
- `src/pdf22png.m` → `src/pdf21png.m`
- `src/pdf22png.h` → `src/pdf21png.h`
- Update all `#include "pdf22png.h"` → `#include "pdf21png.h"`
- Update program name in help text and version strings
- Update `PDF22PNG` macros → `PDF21PNG`

### 2.2 Build System Updates
- `Makefile`: Change `TARGET = pdf22png` → `TARGET = pdf21png`
- Update all references to binary name
- Update installation paths

### 2.3 Directory Rename
```bash
mv pdf22png-objc pdf21png
```

## Phase 3: Swift Implementation Updates (Day 2-3)

### 3.1 Source Code Updates
Files to modify in `pdf22png-swift/` (becoming `pdf22png/`):
- `Package.swift`: Update executable name from `pdf22png-swift` to `pdf22png`
- `Sources/main.swift`: Update program identification
- Remove `-swift` suffix from all references

### 3.2 Build System Updates
- `Makefile`: Update target names
- `Package.swift`: Update product name

### 3.3 Directory Rename
```bash
mv pdf22png-swift pdf22png
```

## Phase 4: Documentation Updates (Day 3-4)

### 4.1 Main Documentation
- `README.md`: Update to explain new naming convention
  - pdf21png: The stable, performance-optimized implementation
  - pdf22png: The modern, feature-rich implementation
- Add migration guide for existing users

### 4.2 Implementation-Specific Docs
- `pdf21png/README.md`: Update all references
- `pdf22png/README.md`: Update all references
- Man pages: Create separate man pages for each

### 4.3 Guides and Examples
- Update all example commands
- Update installation instructions
- Create comparison table with new names

## Phase 5: Script and Automation Updates (Day 4)

### 5.1 Build Scripts
- `build.sh`: Update to build both with correct names
- `test_both.sh`: Update binary paths and names
- `bench.sh`: Update benchmark scripts

### 5.2 Installation Scripts
- `scripts/install.sh`: Support installing both binaries
- `scripts/uninstall.sh`: Remove both binaries
- Update default installation behavior

## Phase 6: CI/CD and Package Management (Day 5)

### 6.1 GitHub Actions
- Update all workflow files
- Ensure artifacts use correct names
- Update release automation

### 6.2 Homebrew Formula
- Create two formulas: `pdf21png.rb` and `pdf22png.rb`
- Update tap configuration
- Test installation of both tools

## Phase 7: Testing and Validation (Day 5-6)

### 7.1 Build Testing
- Verify both implementations build correctly
- Test installation process
- Verify binary names and paths

### 7.2 Functional Testing
- Run test suite for both implementations
- Verify command-line compatibility
- Test upgrade scenarios

### 7.3 Documentation Review
- Verify all references are updated
- Check for broken links
- Review help text and version info

## Phase 8: Release and Communication (Day 7)

### 8.1 Release Preparation
- Create release notes explaining the renaming
- Prepare migration guide
- Update changelog

### 8.2 Version Strategy
- pdf21png: v2.1.0 (indicating maturity)
- pdf22png: v2.2.0 (indicating next generation)

### 8.3 User Communication
- Clear explanation of why the change
- Benefits of the new naming
- Migration instructions

## Implementation Checklist

### Immediate Actions (Today)
- [ ] Create backup branch
- [ ] Start with Objective-C implementation rename
- [ ] Update core source files

### High Priority (This Week)
- [ ] Complete all source code updates
- [ ] Update build systems
- [ ] Test both implementations
- [ ] Update primary documentation

### Medium Priority (Next Week)
- [ ] Update all scripts
- [ ] Update CI/CD pipelines
- [ ] Create Homebrew formulas
- [ ] Complete documentation updates

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
- **Objective-C**: 17s real time (was 21.7s), 3.5m CPU time (was 5m)
- **Swift**: 21.7s real time (was 23.5s), 4.6m CPU time (was 5.5m)
- **CPU Efficiency**: 48% reduction in CPU time for both implementations

