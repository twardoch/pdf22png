# CI/CD Setup for pdf22png

This document describes the complete CI/CD pipeline setup for the pdf22png project, including git-tag-based semantic versioning, comprehensive testing, and automated releases.

## Overview

The pdf22png project now includes a complete CI/CD pipeline that:

1. **Automatically builds** both Objective-C and Swift implementations
2. **Runs comprehensive tests** including unit tests, integration tests, and performance tests
3. **Creates releases** based on git tags with semantic versioning
4. **Generates artifacts** for easy distribution
5. **Supports multiplatform** builds for different architectures

## Git-Tag-Based Semver System

### Version Management

The project uses semantic versioning (semver) based on git tags:

- **Tags**: `v1.0.0`, `v1.2.3`, etc.
- **Development versions**: `1.0.0-dev.5+abc123` (X commits since last tag)
- **Release versions**: `1.0.0` (exact tag match)

### Version Scripts

#### `scripts/version.sh`
Main version management script with commands:

```bash
# Get current version
./scripts/version.sh get                    # Full version with dev info
./scripts/version.sh get --short            # Semantic version only
./scripts/version.sh get --format "{major}.{minor}.{patch}"

# Create new version
./scripts/version.sh set 1.0.0             # Create v1.0.0 tag
./scripts/version.sh bump patch             # Increment patch version
./scripts/version.sh bump minor             # Increment minor version
./scripts/version.sh bump major             # Increment major version

# Validation and utilities
./scripts/version.sh validate 1.0.0        # Validate semver format
./scripts/version.sh check                  # Check if current commit is tagged
./scripts/version.sh changelog             # Show changes since last tag
```

#### Version File Generation

Version information is embedded in the compiled binaries:

```bash
# Generate version files for both implementations
make generate-version

# Files created:
# - pdf22png/Sources/pdf22png/Version.swift
# - pdf21png/src/version.h
```

## Test Suite

### Comprehensive Testing

The project includes a comprehensive test suite covering:

1. **Unit Tests**: Framework-specific tests for both Swift and Objective-C
2. **Integration Tests**: End-to-end testing of CLI functionality
3. **Performance Tests**: Memory usage and execution time validation
4. **Cross-compatibility Tests**: Ensuring both implementations work consistently

### Test Script

```bash
# Run all tests
./scripts/test-all.sh

# Run specific test types
./scripts/test-all.sh --unit-only           # Unit tests only
./scripts/test-all.sh --integration-only    # Integration tests only
./scripts/test-all.sh --performance        # Include performance tests
./scripts/test-all.sh --memory            # Include memory leak detection

# Verbose output and cleanup
./scripts/test-all.sh --verbose --clean
```

### Test Coverage

- **Unit Tests**: Scale calculation, argument parsing, error handling
- **Integration Tests**: PDF conversion, file I/O, batch processing
- **Performance Tests**: Large file handling, memory usage, execution time
- **Compatibility Tests**: Cross-implementation result validation

## Build and Release System

### Local Build Script

The main build and release script handles the complete pipeline:

```bash
# Build, test, and create release artifacts
./scripts/build-and-release.sh

# Available commands
./scripts/build-and-release.sh build       # Build only
./scripts/build-and-release.sh test        # Test only
./scripts/build-and-release.sh release     # Create release artifacts
./scripts/build-and-release.sh all         # Build, test, and release (default)

# Options
./scripts/build-and-release.sh --version 1.0.0    # Specific version
./scripts/build-and-release.sh --clean            # Clean build
./scripts/build-and-release.sh --skip-tests       # Skip testing
./scripts/build-and-release.sh --tag --push       # Create and push git tag
./scripts/build-and-release.sh --upload           # Upload to GitHub releases
```

### Makefile Targets

```bash
# Basic targets
make all                    # Build both implementations
make test                   # Run comprehensive test suite
make clean                  # Clean build artifacts

# Release targets
make release                # Create release artifacts
make release-version VERSION=1.0.0  # Create release with specific version
make generate-version       # Generate version files

# Platform-specific
make universal              # Build universal binaries
make pdf21png              # Build Objective-C version only
make pdf22png              # Build Swift version only
```

## GitHub Actions Workflows

### CI Workflow (`.github/workflows/ci.yml`)

Triggered on:
- Push to `main` or `develop` branches
- Pull requests to `main` or `develop`
- Manual workflow dispatch

Steps:
1. **Setup Environment**: Checkout code, setup Xcode
2. **Cache Dependencies**: Cache build artifacts for faster builds
3. **Generate Version Files**: Create version files with current git info
4. **Build Projects**: Build both implementations
5. **Run Tests**: Execute comprehensive test suite
6. **Performance Tests**: Run benchmarks and memory leak detection
7. **Upload Artifacts**: Store build artifacts and test results

### Release Workflow (`.github/workflows/release.yml`)

Triggered on:
- Push of tags matching `v*` pattern
- Manual workflow dispatch with version input

Steps:
1. **Setup Environment**: Checkout code, setup Xcode
2. **Version Validation**: Validate version format and extract from tag
3. **Build and Test**: Generate version files, build, and run tests
4. **Create Artifacts**: Generate release artifacts with checksums
5. **Create GitHub Release**: Upload artifacts to GitHub releases
6. **Update Documentation**: Show Homebrew formula updates needed

## Multiplatform Support

### Platform-Specific Builds

The multiplatform release script creates artifacts for multiple architectures:

```bash
# Create multiplatform release
./scripts/multiplatform-release.sh --version 1.0.0

# Available platforms
./scripts/multiplatform-release.sh --platforms macos-x86_64,macos-arm64,macos-universal

# Build options
./scripts/multiplatform-release.sh --version 1.0.0 --clean --verbose
```

### Supported Platforms

- **macOS Universal**: Combined x86_64 and ARM64 binaries
- **macOS x86_64**: Intel-specific binaries
- **macOS ARM64**: Apple Silicon-specific binaries

### Artifact Structure

```
artifacts/
├── pdf21png-v1.0.0-macos-universal.tar.gz
├── pdf21png-v1.0.0-macos-universal.tar.gz.sha256
├── pdf22png-v1.0.0-macos-universal.tar.gz
├── pdf22png-v1.0.0-macos-universal.tar.gz.sha256
├── pdf22png-tools-v1.0.0-macos-universal.tar.gz
├── pdf22png-tools-v1.0.0-macos-universal.tar.gz.sha256
├── RELEASE_NOTES.md
└── release-metadata.json
```

## Release Process

### Creating a New Release

1. **Prepare Release**:
   ```bash
   # Ensure all changes are committed
   git add -A && git commit -m "Prepare release v1.0.0"
   
   # Update changelog if needed
   vim CHANGELOG.md
   ```

2. **Create Release Locally**:
   ```bash
   # Option 1: Use release script
   ./scripts/build-and-release.sh --version 1.0.0 --tag --push
   
   # Option 2: Use Makefile
   make release-version VERSION=1.0.0
   
   # Option 3: Use version script
   ./scripts/version.sh set 1.0.0
   git push origin v1.0.0
   ```

3. **Automated Release**:
   - GitHub Actions will automatically create release artifacts
   - Release will be published to GitHub releases
   - Artifacts will be available for download

4. **Manual Release**:
   ```bash
   # Create release with GitHub CLI
   gh release create v1.0.0 \
     --title "Release v1.0.0" \
     --notes-file CHANGELOG.md \
     artifacts/*.tar.gz \
     artifacts/*.sha256
   ```

### Post-Release Tasks

1. **Update Homebrew Formula**:
   - Use SHA256 checksums from release artifacts
   - Update URLs in `homebrew/pdf22png.rb`
   - Submit PR to Homebrew tap

2. **Update Documentation**:
   - Update version numbers in README
   - Add release notes to changelog
   - Update installation instructions

## Installation and Usage

### For Users

```bash
# Install via Homebrew
brew tap twardoch/homebrew-pdf22png
brew install pdf22png

# Manual installation
curl -L https://github.com/twardoch/pdf22png/releases/latest/download/pdf22png-v1.0.0-macos-universal.tar.gz | tar -xz
sudo cp pdf22png /usr/local/bin/
```

### For Developers

```bash
# Clone repository
git clone https://github.com/twardoch/pdf22png.git
cd pdf22png

# Build and test
make all
make test

# Create release
make release-version VERSION=1.0.0
```

## Configuration

### Environment Variables

- `VERSION`: Override version for builds
- `GITHUB_TOKEN`: GitHub token for releases
- `VERBOSE`: Enable verbose output
- `DRY_RUN`: Enable dry run mode

### Makefile Configuration

```makefile
# Default installation prefix
INSTALL_PREFIX := /usr/local/bin

# Project directories
PDF21PNG_DIR := pdf21png
PDF22PNG_DIR := pdf22png
```

## Troubleshooting

### Common Issues

1. **Version Mismatch**:
   ```bash
   # Regenerate version files
   make generate-version
   ```

2. **Test Failures**:
   ```bash
   # Run tests with verbose output
   ./scripts/test-all.sh --verbose
   ```

3. **Build Failures**:
   ```bash
   # Clean and rebuild
   make clean && make all
   ```

4. **Release Issues**:
   ```bash
   # Check version format
   ./scripts/version.sh validate 1.0.0
   
   # Check git status
   git status
   git tag -l
   ```

### Dependencies

- **macOS**: Xcode Command Line Tools
- **Swift**: Swift compiler and Package Manager
- **Objective-C**: Clang compiler
- **Git**: Version control
- **Make**: Build system
- **GitHub CLI**: Optional, for automated releases

## Best Practices

1. **Version Tags**: Always use annotated tags (`git tag -a v1.0.0`)
2. **Testing**: Run full test suite before releases
3. **Documentation**: Update changelog and version references
4. **Artifacts**: Verify checksums match
5. **Rollback**: Keep previous versions available for rollback

This CI/CD system provides a robust foundation for maintaining and releasing the pdf22png project with automated quality assurance and streamlined deployment processes.