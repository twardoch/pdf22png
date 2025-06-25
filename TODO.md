# pdf22png Improvement Plan

## Immediate Priority - Swift Performance Optimization

### Phase 0: Critical Performance Improvements ✅
-   [x] Profile Swift implementation to identify bottlenecks
    -   [x] Use Instruments to analyze time spent in Core Graphics calls
    -   [x] Identify memory allocation patterns causing slowdowns
    -   [x] Compare CGContext setup between ObjC and Swift
-   [x] Optimize Swift rendering pipeline
    -   [x] Cache CGColorSpace objects
    -   [x] Reuse CGContext when possible (via static cache)
    -   [x] Optimize image data buffer allocation
    -   [x] Review PNG compression settings
-   [x] Fix deprecated kUTTypePNG warnings
    -   [x] Replace with UTTypePNG for macOS 12+
    -   [x] Add compatibility wrapper for older macOS versions
-   [x] Create comprehensive build script (`build.sh`)
    -   [x] Support for both implementations
    -   [x] Universal binary creation
    -   [x] Debug/release configurations
    -   [x] Clean build option
-   [x] Create advanced benchmark script (`bench.sh`)
    -   [x] Statistical analysis (avg, min, max, std dev)
    -   [x] Multiple test scenarios
    -   [x] CSV export for data analysis
    -   [x] File size comparison
    -   [x] Colored output with summaries
-   [x] Implement performance regression tests
    -   [x] Add benchmark CI job to prevent performance regressions
    -   [x] Set acceptable performance thresholds (10% regression limit)
    -   [x] Auto-generate performance reports on PRs
    -   [x] Add performance badge data generation

### Phase 0.5: Swift-Specific Enhancements
-   [ ] Further optimize Swift performance
    -   [ ] Profile with Instruments to find remaining bottlenecks
    -   [ ] Consider unsafe buffer operations for critical paths
    -   [ ] Implement SIMD optimizations where applicable
    -   [ ] Target performance within 20% of ObjC
-   [ ] Add async/await support for batch operations
-   [ ] Implement progress reporting with Combine
-   [ ] Add SwiftUI preview generator for PDFs
-   [ ] Create Swift-specific performance optimizations
    -   [ ] Use Swift Concurrency for parallel processing
    -   [ ] Implement lazy page loading
    -   [ ] Add memory-mapped file support

## High Priority

### Phase 0.6: Continuous Integration Enhancements
-   [x] Create GitHub Actions workflow for automated benchmarks
    -   [x] Run on every PR to main branch
    -   [x] Compare performance against baseline
    -   [x] Block merge if regression > 10%
    -   [x] Generate performance report comments
-   [x] Add benchmark result archiving
    -   [x] Store historical performance data
    -   [ ] Generate performance trend graphs
    -   [ ] Create performance dashboard

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
-   [ ] Split monolithic `pdf22png.m` into logical modules:
    -   `PDFProcessor` class for PDF operations
    -   `ImageRenderer` class for rendering operations
    -   `BatchProcessor` class for batch operations
    -   `CLIParser` class for command-line parsing
-   [ ] Remove tight coupling with Options struct
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
-   [ ] Add header dependency tracking in Makefile
-   [ ] Create debug/release build configurations
-   [ ] Implement proper version injection from git tags
-   [ ] Add static analysis targets (clang-tidy, scan-build)
-   [ ] Create CMake build option for cross-platform builds
-   [ ] Add code signing for macOS distribution
-   [ ] Automate .pkg and .dmg creation in Makefile

### Phase 10: Modernization
-   [ ] Add nullability annotations throughout codebase
-   [ ] Convert to modern property syntax
-   [ ] Replace C-style casts with Objective-C casts
-   [ ] Use blocks instead of function pointers
-   [ ] Add collection generics
-   [ ] Implement proper NSError handling
-   [ ] Add async/await support for batch operations

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
1. **Consistent style**: Apply clang-format throughout
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
- **Phase 13**: Complete Swift port maintaining feature parity
- **Phase 13.2**: Dual-build system for ObjC and Swift (`make both`)
- **Phase 13.6**: Comprehensive benchmark suite comparing implementations
- **Phase 13.4**: Both implementations can be installed side-by-side
- **Phase 13.7**: Created build.sh and bench.sh scripts for easy development
- **Phase 0**: Swift performance optimized from 10x to ~33% slower than ObjC
- **Phase 0.6**: Added GitHub Actions workflows for automated benchmarking
- **Phase 5**: Enhanced progress reporting for batch operations with visual progress bar

### Phase 13: Swift Porting Strategy

**Goal**: Gradually migrate the ObjC codebase to pure Swift while guaranteeing that the existing Objective-C implementation remains the canonical, production-ready path until feature- and performance-parity is proven.

#### 13.1 Architectural Blueprint

- [ ] Produce a high-level mapping between current ObjC modules and their future Swift equivalents (CLI, PDFCore, RenderCore, IO, Utils).
- [ ] Decide on packaging model: Swift Package Manager monorepo with multiple products (`pdf22pngCLI`, `CorePDF22PNG`).
- [ ] Create an `ObjCCompatibility` target that exposes current public APIs via `@objc` to keep integration surface stable.

#### 13.2 Build & CI Dual-Lane

- [ ] Update Makefile to build two artefacts: `pdf22png_objc` (default) and `pdf22png_swift` (experimental).
- [ ] Extend GitHub Actions matrix to run `make swift` on macOS-latest (Intel+ARM runners).
- [ ] Add Swift-Lint and Swift-Format steps to match existing style gates.

#### 13.3 Incremental Module-by-Module Port

Port order is chosen to minimise risk. Each sub-task must pass unit tests and performance gate before merging.

1. Utils (string parsing, scale calculation).
2. CLI argument parsing (replace custom parser with `swift-argument-parser`).
3. Image output handling (PNG encoding via ImageIO).
4. Rendering pipeline (CoreGraphics layer).
5. Batch processing & GCD queues (migrate to Swift Concurrency).

#### 13.4 Bridging Layer

- [ ] Introduce Bridging Header `pdf22png-Bridging-Header.h`.
- [ ] Keep ObjC classes accessible from Swift while the port is incomplete (`NS_SWIFT_NAME`).
- [ ] Add thin Swift wrappers that forward to ObjC implementation when native Swift is not yet ready.

#### 13.5 Verification Matrix

Every migration PR must:

- [ ] Add/extend XCTest cases for new Swift code.
- [ ] Prove feature parity via golden-image visual regression tests.
- [ ] Pass speed benchmarks (see 13.6).

#### 13.6 Performance Benchmarking Plan

Establish repeatable micro- & macro-benchmarks to compare ObjC vs Swift.

Benchmark harness:

```bash
# once
brew install hyperfine graphicsmagick

# run
hyperfine --warmup 3 '\
  ./pdf22png_objc -a -r 144 samples/10p.pdf -d /tmp/out_objc' '\
  ./pdf22png_swift -a -r 144 samples/10p.pdf -d /tmp/out_swift'
```

Datasets (checked into `benchmarks/`):

| Alias | Pages | Size | Features | Type |
|-------|------:|------|----------|------|
| small | 10    | 1 MB | vector   | brochure |
| medium| 120   | 12 MB| mixed    | novel |
| large | 800   | 95 MB| images   | catalogue |

Metrics recorded:

- Wall-clock time (mean ± stddev, 10 runs)
- Pages per second & MB/s throughput
- Peak RSS memory (via `/usr/bin/time -l`)
- Energy impact (Xcode Instruments)

Success criteria:

- Swift build must be within **±5 %** execution time and **±10 %** memory of ObjC before sign-off.
- After full port, Swift must outperform ObjC by **≥15 %** or justify regressions in changelog.

#### 13.7 Roll-out & Deprecation

- [ ] Tag first Swift-parity release `v2.0.0-beta1`.
- [ ] Ship dual binaries for two minor versions.
- [ ] Announce ObjC deprecation; remove ObjC build code by `v3.0`.

---

## Development Guidelines

- DO NOT maintain backward compatibility for existing CLI usage
- Prioritize stability over new features
- Keep macOS-ONLY approach, do not plan portability
- Focus on user experience and reliability
- Maintain comprehensive test coverage for new features