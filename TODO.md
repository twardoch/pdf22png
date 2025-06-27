# PDF22PNG Todo List

## Phase 15: Seamless Installation & Production Ready (2025-06-27)

### Priority 1: Homebrew Installation (Immediate)
- [x] Create `release.sh` script for automated releases
  - [x] Build universal binaries for both implementations
  - [x] Generate SHA256 checksums automatically
  - [x] Create GitHub releases with proper tags
  - [x] Update Homebrew formulas with release data
- [ ] Finalize `homebrew/pdf21png.rb` with release URL and SHA256
- [ ] Finalize `homebrew/pdf22png.rb` with release URL and SHA256
- [ ] Create and configure Homebrew tap `twardoch/homebrew-pdf22png`
- [ ] Test Homebrew installation for both tools

### Priority 2: Installation Documentation (Immediate)
- [x] Update README.md with Homebrew as primary installation method
  - [x] Add one-liner: `brew install twardoch/pdf22png/pdf22png`
  - [x] Add alternative: `brew install twardoch/pdf22png/pdf21png`
  - [x] Include migration guide from old methods
  - [x] Add troubleshooting section
- [x] Add Quick Start Guide with real examples
- [x] Enhance `scripts/install.sh` to detect and prefer Homebrew
- [x] Update `scripts/uninstall.sh` for Homebrew-aware removal

### Priority 3: Build System Refinement (This Week)
- [x] Create unified top-level Makefile
  - [x] `make all` - build both implementations
  - [x] `make test` - run all tests
  - [x] `make install` - install both tools
  - [x] `make release` - prepare releases
  - [x] `make check-deps` - verify dependencies
- [ ] Create `scripts/install-deps.sh` for dependency setup
- [ ] Update `build.sh` to use Makefile targets

### Priority 4: Quality Assurance (This Week)
- [ ] Port Objective-C tests to XCTest framework
- [ ] Expand Swift test coverage to 80%+
- [ ] Add integration tests for both CLIs
- [ ] Set up memory leak detection
- [ ] Update GitHub Actions workflows
  - [ ] Matrix builds (macOS versions × architectures)
  - [ ] Automated release on tag push
  - [ ] Homebrew formula auto-update
  - [ ] Performance benchmarking on PRs

### Priority 5: Developer Experience (Next Week)
- [ ] Create `.devcontainer` configuration
- [ ] Set up pre-commit hooks
  - [ ] SwiftLint/SwiftFormat for Swift
  - [ ] clang-format for Objective-C
  - [ ] Conventional commit enforcement
- [ ] Add `.editorconfig` for consistent formatting
- [ ] Create `CODEOWNERS` file

### Priority 6: Documentation Excellence (Next Week)
- [ ] Generate man pages from single Markdown source
- [ ] Create Swift DocC documentation
- [ ] Add Objective-C HeaderDoc documentation
- [ ] Write comprehensive user guide
  - [ ] PDF processing best practices
  - [ ] Performance tuning guide
  - [ ] Batch processing examples
- [ ] Host documentation on GitHub Pages

### Priority 7: Performance & Optimization (Ongoing)
- [ ] Update benchmark suite with new binary names
- [ ] Add memory usage profiling
- [ ] Implement parallel processing for batch operations
- [ ] Add performance regression detection

### Priority 8: Long-term Maintenance (Future)
- [ ] Set up semantic versioning automation
- [ ] Create issue and PR templates
- [ ] Add security scanning (SAST)
- [ ] Plan LTS version strategy

## Completed Tasks ✓

### Implementation Renaming (2025-06-27)
- [x] Renamed `pdf22png-objc` → `pdf21png`
- [x] Renamed `pdf22png-swift` → `pdf22png`
- [x] Updated all source code references
- [x] Updated build systems and scripts
- [x] Created placeholder Homebrew formulas
- [x] Updated primary documentation

### Documentation Overhaul
- [x] Rewrote README.md with user-friendly language
- [x] Created comprehensive CONTRIBUTING.md
- [x] Updated CHANGELOG.md with renaming details

## Notes

- Focus on seamless Homebrew installation above all
- Maintain backward compatibility during transition
- Prioritize user experience and clear documentation
- Keep both implementations building and tested