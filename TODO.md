# PDF22PNG Todo List

## Current Priorities (2025-06-27)

### Documentation Overhaul (COMPLETED)
- [x] Rewrite README.md with user-friendly language explaining:
  - Why this project exists
  - What it does in simple terms
  - How to install and use it
  - Clear distinction between pdf21png and pdf22png
- [x] Create CONTRIBUTING.md with technical details:
  - Project architecture and structure
  - Code requirements and standards
  - Development workflow
  - Testing procedures

### Remaining Implementation Tasks
- [x] Update GitHub Actions workflows for new binary names
- [x] Create separate Homebrew formulas (pdf21png.rb and pdf22png.rb)
- [x] Update installation scripts to support both implementations
- [x] Add version command support to pdf21png (Objective-C)

## COMPLETED: Implementation Renaming ✓

### Objective (COMPLETED)
- **pdf22png-objc** → **pdf21png** (mature, stable, performance-focused) ✓
- **pdf22png-swift** → **pdf22png** (modern, evolving, feature-rich) ✓

## Day 1: Pre-Renaming and Objective-C Implementation

### Pre-Renaming Preparation
- [x] Create backup branch: `git checkout -b pre-renaming-backup`
- [x] Tag current state: `git tag v1.0-pre-rename`
- [x] Document current state in CHANGELOG.md

### Objective-C Implementation Renaming (pdf22png-objc → pdf21png)
- [x] Rename source files:
  - [x] `mv pdf22png-objc/src/pdf22png.m pdf22png-objc/src/pdf21png.m`
  - [x] `mv pdf22png-objc/src/pdf22png.h pdf22png-objc/src/pdf21png.h`
  
- [x] Update source code content:
  - [x] In `pdf21png.m`: Replace all "pdf22png" with "pdf21png"
  - [x] In `pdf21png.h`: Update header guards and definitions
  - [x] In `utils.h`: Update include statements
  - [x] In `utils.m`: Update references
  - [x] In `errors.h`: Update any references
  
- [x] Update Makefile:
  - [x] Change `TARGET = pdf22png` to `TARGET = pdf21png`
  - [x] Update `SOURCES = src/pdf22png.m` to `SOURCES = src/pdf21png.m`
  - [x] Update installation paths
  
- [x] Rename directory:
  - [x] `mv pdf22png-objc pdf21png`
  
- [x] Update README.md in pdf21png/:
  - [x] Replace all references to pdf22png with pdf21png
  - [x] Update description to emphasize stability and performance

## Day 2: Swift Implementation Updates

### Swift Implementation Updates (pdf22png-swift → pdf22png)
- [x] Update Package.swift:
  - [x] Change executable name from "pdf22png-swift" to "pdf22png"
  - [x] Update product name
  - [x] Update target names if needed
  
- [x] Update source code:
  - [x] In `Sources/main.swift`: Update program identification
  - [x] Update help text and version strings
  - [x] Remove "-swift" suffix from all references
  
- [x] Update Makefile:
  - [x] Update binary name references
  - [x] Change output paths
  
- [ ] Update Tests:
  - [ ] Update test file references
  - [ ] Update expected output in tests
  
- [x] Rename directory:
  - [x] `mv pdf22png-swift pdf22png`

## Day 3: Core Documentation Updates

### Main Documentation
- [ ] Update root README.md:
  - [ ] Add clear explanation of naming:
    - [ ] pdf21png = Objective-C (stable, performance)
    - [ ] pdf22png = Swift (modern, features)
  - [ ] Update all example commands
  - [ ] Add migration guide section
  - [ ] Update installation instructions

- [ ] Update CHANGELOG.md:
  - [ ] Document the renaming as major version change
  - [ ] Explain rationale for the change

- [ ] Update docs/:
  - [ ] `docs/USAGE.md`: Update all command examples
  - [ ] `docs/API.md`: Update API references
  - [ ] `docs/EXAMPLES.md`: Update all examples
  - [ ] `docs/pdf22png.1`: Create two man pages (pdf21png.1 and pdf22png.1)

## Day 4: Scripts and Build System Updates

### Build Scripts
- [x] Update build.sh:
  - [x] Update directory names (pdf21png, pdf22png)
  - [x] Update binary output names
  - [x] Update build messages
  
- [x] Update test_both.sh:
  - [x] Change binary paths: `./pdf21png/build/pdf21png`
  - [x] Change binary paths: `./pdf22png/.build/release/pdf22png`
  - [x] Update output directory names
  
- [x] Update bench.sh:
  - [x] Update binary references
  - [x] Update benchmark output naming

### Installation Scripts
- [ ] Update scripts/install.sh:
  - [ ] Support installing both pdf21png and pdf22png
  - [ ] Update binary names in installation
  
- [ ] Update scripts/uninstall.sh:
  - [ ] Remove both pdf21png and pdf22png
  
- [ ] Update scripts/dev-setup.sh:
  - [ ] Update development environment setup

## Day 5: Benchmarks and Tests

### Benchmark Updates
- [ ] Update benchmarks/:
  - [ ] `benchmark.sh`: Update binary paths
  - [ ] `benchmark_objc.m`: Update references
  - [ ] `BenchmarkSwift.swift`: Update references
  - [ ] `compare_implementations.sh`: Update for new names
  - [ ] `run_benchmarks.sh`: Update all paths
  - [ ] Update README.md in benchmarks/

### Test Updates
- [ ] Update all test files to use new binary names
- [ ] Verify tests pass with renamed implementations

## Day 6: CI/CD and Package Management

### GitHub Actions
- [ ] Update .github/workflows/build.yml:
  - [ ] Update artifact names
  - [ ] Update binary paths
  
- [ ] Update .github/workflows/release.yml:
  - [ ] Update release artifact names
  - [ ] Update version tagging
  
- [ ] Update .github/workflows/benchmark.yml:
  - [ ] Update benchmark paths

### Homebrew Formula
- [ ] Create homebrew/pdf21png.rb:
  - [ ] New formula for Objective-C implementation
  - [ ] Update URLs and descriptions
  
- [ ] Update homebrew/pdf22png.rb:
  - [ ] Update to install Swift implementation
  - [ ] Remove -swift suffix references

## Day 7: Final Validation and Release

### Testing Checklist
- [ ] Build both implementations successfully
- [ ] Run test suite for both
- [ ] Verify binary names are correct
- [ ] Test installation process
- [ ] Verify help text shows correct names
- [ ] Run benchmarks with new names

### Documentation Review
- [ ] All READMEs updated
- [ ] Man pages created for both
- [ ] Examples all use new names
- [ ] No references to old names remain

### Release Preparation
- [ ] Create release notes
- [ ] Update version numbers:
  - [ ] pdf21png: v2.1.0
  - [ ] pdf22png: v2.2.0
- [ ] Create GitHub release
- [ ] Update Homebrew tap

## Verification Checklist

### Source Code
- [ ] No "pdf22png" strings in pdf21png source
- [ ] No "pdf22png-swift" strings in pdf22png source
- [ ] All includes/imports updated
- [ ] All macro definitions updated

### Build System
- [ ] Both implementations build successfully
- [ ] Correct binary names produced
- [ ] Installation places correct binaries

### Documentation
- [ ] Clear distinction between implementations
- [ ] Migration guide complete
- [ ] All examples updated

### User Experience
- [ ] Clear which tool to use when
- [ ] Easy installation of either/both
- [ ] Help text is clear and correct

## Notes

- This renaming is the TOP PRIORITY before any other work
- Ensures clear product differentiation
- Aligns version numbers with product names (2.1 for pdf21png, 2.2 for pdf22png)
- Sets foundation for independent evolution of each tool

