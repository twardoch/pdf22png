# PDF22PNG Todo List - Implementation Renaming Priority

## CRITICAL: Renaming Implementation (IMMEDIATE PRIORITY)

### Objective
- **pdf22png-objc** → **pdf21png** (mature, stable, performance-focused)
- **pdf22png-swift** → **pdf22png** (modern, evolving, feature-rich)

## Day 1: Pre-Renaming and Objective-C Implementation

### Pre-Renaming Preparation
- [ ] Create backup branch: `git checkout -b pre-renaming-backup`
- [ ] Tag current state: `git tag v1.0-pre-rename`
- [ ] Document current state in CHANGELOG.md

### Objective-C Implementation Renaming (pdf22png-objc → pdf21png)
- [ ] Rename source files:
  - [ ] `mv pdf22png-objc/src/pdf22png.m pdf22png-objc/src/pdf21png.m`
  - [ ] `mv pdf22png-objc/src/pdf22png.h pdf22png-objc/src/pdf21png.h`
  
- [ ] Update source code content:
  - [ ] In `pdf21png.m`: Replace all "pdf22png" with "pdf21png"
  - [ ] In `pdf21png.h`: Update header guards and definitions
  - [ ] In `utils.h`: Update include statements
  - [ ] In `utils.m`: Update references
  - [ ] In `errors.h`: Update any references
  
- [ ] Update Makefile:
  - [ ] Change `TARGET = pdf22png` to `TARGET = pdf21png`
  - [ ] Update `SOURCES = src/pdf22png.m` to `SOURCES = src/pdf21png.m`
  - [ ] Update installation paths
  
- [ ] Rename directory:
  - [ ] `mv pdf22png-objc pdf21png`
  
- [ ] Update README.md in pdf21png/:
  - [ ] Replace all references to pdf22png with pdf21png
  - [ ] Update description to emphasize stability and performance

## Day 2: Swift Implementation Updates

### Swift Implementation Updates (pdf22png-swift → pdf22png)
- [ ] Update Package.swift:
  - [ ] Change executable name from "pdf22png-swift" to "pdf22png"
  - [ ] Update product name
  - [ ] Update target names if needed
  
- [ ] Update source code:
  - [ ] In `Sources/main.swift`: Update program identification
  - [ ] Update help text and version strings
  - [ ] Remove "-swift" suffix from all references
  
- [ ] Update Makefile:
  - [ ] Update binary name references
  - [ ] Change output paths
  
- [ ] Update Tests:
  - [ ] Update test file references
  - [ ] Update expected output in tests
  
- [ ] Rename directory:
  - [ ] `mv pdf22png-swift pdf22png`

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
- [ ] Update build.sh:
  - [ ] Update directory names (pdf21png, pdf22png)
  - [ ] Update binary output names
  - [ ] Update build messages
  
- [ ] Update test_both.sh:
  - [ ] Change binary paths: `./pdf21png/build/pdf21png`
  - [ ] Change binary paths: `./pdf22png/.build/release/pdf22png`
  - [ ] Update output directory names
  
- [ ] Update bench.sh:
  - [ ] Update binary references
  - [ ] Update benchmark output naming

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

---

## Previous Todo Items (NOW SECONDARY)

[All previous performance optimization and feature development tasks move to secondary priority until renaming is complete]