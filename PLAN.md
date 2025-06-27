# PDF22PNG Project Renaming Plan

## CRITICAL PRIORITY: Implementation Renaming

**Objective**: Rename the two implementations to clearly differentiate their purpose and evolution:
- **Objective-C Implementation**: `pdf22png` → `pdf21png` (mature, stable, performance-focused)
- **Swift Implementation**: remains `pdf22png` (modern, evolving, feature-rich)

## Phase 0: Pre-Renaming Preparation (IMMEDIATE)

### 0.1 Backup and Version Control
- Create a backup branch: `pre-renaming-backup`
- Tag current state: `v1.0-pre-rename`
- Document current binary names and paths

### 0.2 Impact Analysis
Total files affected: ~56 files plus directory names
Major areas of impact:
1. Source code files (headers, implementation)
2. Build systems (Makefiles, Package.swift)
3. Documentation (READMEs, man pages)
4. Scripts (build, test, install)
5. CI/CD configurations
6. Package management (Homebrew)

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

[Rest of original plan content follows...]