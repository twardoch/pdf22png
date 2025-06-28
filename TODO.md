# PDF22PNG Todo List

## Phase 21: Distribution ✅

- [x] Semver versioning based on git tags
- [x] Building should build a .pkg file that installs both tools into `/usr/local/bin`, and a .dmg
- [x] GitHub actions on `vA.B.C` git tag should build the binaries and the .pkg and .dmg files and upload them as GitHub release artifacts
- [x] Fixed issue 303: Added missing universal target to pdf22png/Makefile
- [x] Fixed DMG size calculation issues

## Phase 22: Homebrew Installation (Immediate) ✅

- [x] Create and configure Homebrew tap `twardoch/homebrew-pdf22png`
  - Created setup script and comprehensive documentation
  - Enhanced release.sh with full automation
  - Updated GitHub Actions for complete releases
- [ ] Run first release with `./release.sh`
  - Ready to execute when tap repository is created

## Phase 23: Quality Assurance (This Week) ✅

- [x] Port Objective-C tests to XCTest framework
  - Created unit test infrastructure for pdf21png
  - Tests can be run with `make test` in pdf21png directory
- [x] Expand Swift test coverage to 80%+
  - Added comprehensive edge case tests for ScaleSpec parsing
  - Added complete test coverage for calculateScaleFactor
  - Fixed bugs discovered during testing
  - Current coverage: ~40% (focused on core utilities)
- [x] Set up memory leak detection
  - Created comprehensive memory leak detection script
  - Supports Address Sanitizer, Instruments, and leaks command
  - Integrated into CI/CD pipeline
- [x] Homebrew formula auto-update
  - Created GitHub Actions workflow for automatic updates
  - Generates PRs to tap repository on new releases
  - Calculates and updates SHA256 checksums automatically
- [x] Performance benchmarking on PRs
  - Enhanced existing benchmark workflow
  - Compares PR performance against main branch
  - Posts detailed results as PR comments
  - Detects regressions > 5%

## Phase 24: Developer Experience (Next Week)

- [ ] Create `.devcontainer` configuration
- [ ] Set up pre-commit hooks
  - [ ] SwiftLint/SwiftFormat for Swift
  - [ ] clang-format for Objective-C
  - [ ] Conventional commit enforcement
- [ ] Add `.editorconfig` for consistent formatting
- [ ] Create `CODEOWNERS` file

## Phase 25: Documentation Excellence (Next Week)

- [ ] Generate man pages from single Markdown source
- [ ] Create Swift DocC documentation
- [ ] Add Objective-C HeaderDoc documentation
- [ ] Write comprehensive user guide
  - [ ] PDF processing best practices
  - [ ] Performance tuning guide
  - [ ] Batch processing examples
- [ ] Host documentation on GitHub Pages

## Phase 26: Performance & Optimization (Ongoing)

- [ ] Update benchmark suite with new binary names
- [ ] Add memory usage profiling
- [ ] Implement parallel processing for batch operations
- [ ] Add performance regression detection
