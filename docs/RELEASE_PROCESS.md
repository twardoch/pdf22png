# PDF22PNG Release Process Guide

This guide describes the complete release process for pdf22png.

## Prerequisites

1. **Clean working directory**: No uncommitted changes
2. **Main branch**: Releases should be made from the main branch
3. **Updated CHANGELOG.md**: Document all changes for the release
4. **Homebrew tap repository**: Set up at `twardoch/homebrew-pdf22png`

## Step 1: Prepare for Release

### 1.1 Update Version References

Ensure version numbers are consistent across:
- `CHANGELOG.md` - Add new version section
- Binary version outputs (check with `--version`)

### 1.2 Run Tests

```bash
# Run all tests
make test

# Run integration tests
./tests/integration_test.sh

# Build distribution packages
make dist
```

### 1.3 Update Documentation

- Review and update README.md if needed
- Update any changed command options or features
- Ensure installation instructions are current

## Step 2: Create Release

### 2.1 Commit Changes

```bash
git add -A
git commit -m "Prepare for release v2.3.1"
git push origin main
```

### 2.2 Run Release Script

The release script automates most of the process:

```bash
# Dry run first to verify
./scripts/release.sh --dry-run v2.3.1

# If everything looks good, run the actual release
./scripts/release.sh v2.3.1
```

This script will:
- Build universal binaries
- Create .pkg and .dmg installers
- Generate release tarballs
- Calculate SHA256 checksums
- Update Homebrew formulas
- Create release notes
- Tag the release

### 2.3 Push the Tag

```bash
git push origin v2.3.1
```

This triggers the GitHub Actions workflow that:
- Builds all artifacts
- Creates the GitHub release
- Uploads all release assets

## Step 3: Update Homebrew Tap

### 3.1 Clone/Update Tap Repository

```bash
cd ~/Developer  # or your preferred directory
git clone https://github.com/twardoch/homebrew-pdf22png.git
# or if already cloned
cd homebrew-pdf22png
git pull
```

### 3.2 Copy Updated Formulas

```bash
# Copy the updated formulas from the main repo
cp ~/Developer/pdf22png/homebrew/*.rb Formula/

# Review the changes
git diff
```

### 3.3 Commit and Push

```bash
git add Formula/*.rb
git commit -m "Update to version 2.3.1"
git push
```

### 3.4 Test the Tap

```bash
# Update local tap
brew update

# Test installation
brew upgrade pdf22png
brew test pdf22png

# Verify version
pdf22png --version
```

## Step 4: Post-Release

### 4.1 Verify GitHub Release

1. Go to https://github.com/twardoch/pdf22png/releases
2. Verify all assets are uploaded:
   - `pdf21png-v2.3.1-macos-universal.tar.gz`
   - `pdf22png-v2.3.1-macos-universal.tar.gz`
   - `pdf22png-2.3.1.pkg`
   - `pdf22png-2.3.1.dmg`
   - SHA256 checksum files

### 4.2 Test Installation Methods

Test each installation method:

```bash
# Homebrew
brew install twardoch/pdf22png/pdf22png

# Direct download and install
curl -LO https://github.com/twardoch/pdf22png/releases/download/v2.3.1/pdf22png-2.3.1.pkg
sudo installer -pkg pdf22png-2.3.1.pkg -target /
```

### 4.3 Update Documentation

If this is a significant release:
- Update the website/documentation
- Post release announcement
- Update any example repositories

## Release Checklist

- [ ] CHANGELOG.md updated
- [ ] All tests passing
- [ ] Documentation updated
- [ ] Release script run successfully
- [ ] Tag pushed to GitHub
- [ ] GitHub Actions workflow completed
- [ ] Release assets verified on GitHub
- [ ] Homebrew tap updated
- [ ] Homebrew installation tested
- [ ] Package installer tested
- [ ] DMG installer tested

## Troubleshooting

### Build Failures

If the build fails:
1. Check build logs: `make clean && make dist`
2. Verify all dependencies: `make check-deps`
3. Test locally: `make test`

### GitHub Actions Issues

If the workflow fails:
1. Check Actions tab on GitHub
2. Review workflow logs
3. Ensure secrets are configured (if using signing)

### Homebrew Formula Issues

If formula updates fail:
1. Run `brew audit --strict Formula/pdf22png.rb`
2. Test locally: `brew install --build-from-source Formula/pdf22png.rb`
3. Check SHA256 matches: `shasum -a 256 <file>`

### Release Asset Issues

If assets are missing:
1. Check the release workflow completed
2. Manually upload missing assets if needed
3. Regenerate checksums if files changed

## Version Numbering

We follow semantic versioning (MAJOR.MINOR.PATCH):
- MAJOR: Breaking changes
- MINOR: New features, backward compatible
- PATCH: Bug fixes, backward compatible

Examples:
- `2.3.0` → `2.3.1`: Bug fix
- `2.3.1` → `2.4.0`: New feature
- `2.4.0` → `3.0.0`: Breaking change

## Emergency Rollback

If a release has critical issues:

1. **Delete the release** (but keep the tag):
   ```bash
   gh release delete v2.3.1 --yes
   ```

2. **Fix the issue** and create a new patch version:
   ```bash
   ./scripts/release.sh v2.3.2
   ```

3. **Update Homebrew tap** to point to the new version

Never delete tags from the repository history.