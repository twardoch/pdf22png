# Project Progress: pdf22png

This document tracks the progress of major features and milestones, especially in relation to the `TODO.md`.

## Current Phase: Initial Reorganization and v1.0 Release Candidate

**Objective**: Establish a robust project structure, implement core features, set up CI/CD, and prepare for an initial public release.

### Completed Milestones:
*   **Project Scaffolding**:
    *   [x] Directory structure established (src, tests, docs, .github, etc.).
    *   [x] Initial `.gitignore` created.
    *   [x] `Makefile` for build, install, clean, test, format, lint.
*   **Core Functionality**:
    *   [x] Renamed `pdfupng.m` to `src/pdf22png.m`.
    *   [x] Refactored code into modular components: `pdf22png.m`, `pdf22png.h`, `utils.m`, `utils.h`.
    *   [x] Implemented PDF to PNG conversion using Core Graphics.
    *   [x] Argument parsing for:
        *   [x] Input/Output files (including stdin/stdout).
        *   [x] Page selection (`-p`).
        *   [x] Batch mode (`-a`, `-d`).
        *   [x] Scaling (`-s`): percentage, factor, WxH, Wx, xH.
        *   [x] Resolution (`-r` DPI).
        *   [x] Transparency (`-t`).
        *   [x] PNG Quality hint (`-q`).
        *   [x] Verbose mode (`-v`).
        *   [x] Help (`-h`).
*   **Testing**:
    *   [x] Basic unit test structure using XCTest (`tests/test_pdf22png.m`).
    *   [x] Unit tests for `parseScaleSpec` and other utility functions.
    *   [x] Sample PDF fixture (`tests/fixtures/sample.pdf`).
    *   [x] Makefile `test` target configured to compile and run tests.
*   **CI/CD**:
    *   [x] GitHub Actions: `build.yml` for building and testing on macOS.
    *   [x] GitHub Actions: `release.yml` for creating releases and updating Homebrew formula (template).
*   **Distribution**:
    *   [x] Homebrew formula template (`homebrew/pdf22png.rb`).
*   **Documentation**:
    *   [x] `README.md` (comprehensive overview).
    *   [x] `docs/USAGE.md` (detailed command-line usage).
    *   [x] `docs/EXAMPLES.md` (practical examples).
    *   [x] `docs/API.md` (overview for code re-use).
    *   [x] `CHANGELOG.md` (tracking changes).
    *   [x] `TODO.md` (future plans).
    *   [x] `PROGRESS.md` (this file).

### In Progress / Next Steps (for v1.0):
*   [ ] **License File**: Choose and add `LICENSE` file (MIT or Apache 2.0).
*   [ ] **`.editorconfig`**: Add.
*   [ ] **`scripts/build-universal.sh`**: Implement.
*   [ ] **`scripts/uninstall.sh`**: Create.
*   [ ] **GitHub Issue Templates**: Create.
*   [ ] **GitHub Funding File**: Create.
*   [ ] **Thorough Testing**: Run `make test` and ensure all tests pass. Manually test CLI with various PDFs and options.
*   [ ] **Review & Refine**: Code review, documentation review.
*   [ ] **Tag v1.0.0**: Create the first official release tag.

### Future Goals (Post v1.0):
*   Refer to `TODO.md` for planned features like man page generation, advanced testing, color profile handling, etc.

This document will be updated as the project evolves.
