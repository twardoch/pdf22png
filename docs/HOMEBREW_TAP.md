# Homebrew Tap Setup Guide

This guide explains how to set up and maintain the Homebrew tap for pdf22png.

## Overview

The Homebrew tap `twardoch/pdf22png` provides easy installation of both pdf21png and pdf22png tools. The tap repository is separate from the main project repository.

## Initial Setup

### 1. Create the Tap Repository

Create a new GitHub repository named `homebrew-pdf22png`:
- Go to https://github.com/new
- Name: `homebrew-pdf22png`
- Description: "Homebrew tap for pdf22png - PDF to PNG converter for macOS"
- Public repository
- Initialize with README

### 2. Run Setup Script

Use the provided setup script to generate the tap structure:

```bash
./scripts/setup-homebrew-tap.sh
```

This script will:
- Guide you through the setup process
- Generate the Formula directory structure
- Create README and .gitignore files
- Provide commands to test the tap

### 3. Formula Structure

The tap contains two formulas:
- `Formula/pdf21png.rb` - Objective-C implementation
- `Formula/pdf22png.rb` - Swift implementation

## Release Process

When creating a new release:

1. **Tag the release** in the main repository:
   ```bash
   git tag -a v2.3.1 -m "Release version 2.3.1"
   git push origin v2.3.1
   ```

2. **Run the release script**:
   ```bash
   ./release.sh v2.3.1
   ```
   
   This will:
   - Build universal binaries
   - Create .pkg and .dmg installers
   - Generate SHA256 checksums
   - Update formula files with new URLs and checksums
   - Create release tarballs

3. **Update the tap repository**:
   ```bash
   cd ~/Developer/homebrew-pdf22png
   git pull
   git add Formula/*.rb
   git commit -m "Update to version 2.3.1"
   git push
   ```

## Formula Updates

The formulas are automatically updated by `release.sh`. Manual updates can be done:

```ruby
class Pdf22png < Formula
  desc "Modern PDF to PNG converter for macOS"
  homepage "https://github.com/twardoch/pdf22png"
  version "2.3.1"
  
  url "https://github.com/twardoch/pdf22png/releases/download/v2.3.1/pdf22png-v2.3.1-macos-universal.tar.gz"
  sha256 "actual_sha256_from_release"
  
  # ... rest of formula
end
```

## Testing Formulas

### Local Testing

Before pushing updates:

```bash
# Test installation from local formula
brew install --build-from-source ./Formula/pdf22png.rb

# Run tests
brew test pdf22png

# Audit formula
brew audit --strict pdf22png
```

### User Testing

Users can test the tap:

```bash
# Add tap
brew tap twardoch/pdf22png

# Install
brew install twardoch/pdf22png/pdf22png

# Verify
pdf22png --version
```

## Troubleshooting

### Common Issues

1. **Formula syntax errors**:
   ```bash
   brew audit --strict Formula/pdf22png.rb
   ```

2. **SHA256 mismatch**:
   - Ensure the release tarball hasn't changed
   - Verify with: `shasum -a 256 pdf22png-v2.3.1-macos-universal.tar.gz`

3. **Installation failures**:
   - Check that release assets are properly uploaded
   - Verify URLs are accessible

### Updating After Repository Changes

If the tap repository structure changes:

```bash
# Update local tap
brew tap --repair

# Force update
brew update --force
```

## Best Practices

1. **Version Management**:
   - Use semantic versioning (e.g., 2.3.1)
   - Keep version numbers synchronized between:
     - Git tags
     - Formula versions
     - Binary versions

2. **Testing**:
   - Always test formulas locally before pushing
   - Run `brew audit` to catch common issues
   - Test both new installations and upgrades

3. **Documentation**:
   - Update tap README when adding features
   - Include migration guides for breaking changes
   - Document any special installation requirements

## Maintenance

### Regular Tasks

- **Monitor issues**: Check tap repository for user-reported issues
- **Update dependencies**: Keep formula dependencies current
- **Security updates**: Apply security patches promptly

### Formula Deprecation

If deprecating a formula:

```ruby
def deprecate_date
  "2024-01-01"
end

def deprecate_reason
  "pdf21png has been merged into pdf22png"
end
```

## Integration with CI/CD

The GitHub Actions workflow automatically:
- Builds release artifacts
- Generates SHA256 checksums
- Creates draft releases

The `release.sh` script handles:
- Formula updates
- Checksum verification
- Tarball creation

## Support

For issues with:
- **The tools**: Report at https://github.com/twardoch/pdf22png/issues
- **The formulas**: Report at https://github.com/twardoch/homebrew-pdf22png/issues
- **Homebrew itself**: See https://docs.brew.sh