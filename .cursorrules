# pdf22png — agent & contributor guide

Two macOS command-line tools that rasterize PDF pages to PNG using Core Graphics
and Quartz. They ship as a pair:

- **`pdf21png`** — Objective-C. Battle-tested, tuned for throughput. Lives in `pdf21png/`.
- **`pdf22png`** — Swift + `swift-argument-parser`. Modern, feature-rich. Lives in `pdf22png/`.

Both produce native renders (no external tools) and build as universal binaries
(Intel + Apple Silicon).

## Layout

| Path | What |
|------|------|
| `pdf21png/` | Objective-C tool: `src/*.m,*.h`, `Makefile`, `Tests/` |
| `pdf22png/` | Swift package: `Sources/`, `Tests/`, `Package.swift` |
| `Makefile` | Top-level build orchestrating both |
| `docs/` | Man pages, usage, API, CI/CD, Homebrew notes |
| `homebrew/` | Formula |
| `scripts/` | Build, version, release, packaging helpers |

## Build

```bash
make all                              # both tools
make -C pdf21png                      # ObjC only  -> pdf21png/build/pdf21png
swift build --package-path pdf22png   # Swift only
```

Release (universal): `make -C pdf21png universal` and
`swift build --package-path pdf22png -c release --arch arm64 --arch x86_64`.

## Test

```bash
bash pdf21png/Tests/run-unit-tests.sh    # ObjC unit tests
swift test --package-path pdf22png       # Swift tests
```

CI (`.github/workflows/ci.yml`) runs both on every push and PR. Tagging `v*`
triggers `.github/workflows/release.yml`, which builds universal binaries for
both tools and publishes a GitHub Release tarball.

## Conventions

- The scale-spec parser rejects malformed input rather than silently dropping
  parts (fail loud). Note the tools differ on dimension order: `pdf22png` is
  width-first (`WxH`), `pdf21png` is height-first (`HxW`) — preserved for
  backward compatibility and documented in the tests.
- PDF pages use a bottom-left origin; PNG output is top-left. The Core Graphics
  render path accounts for this — see the rendering functions in each tool.
- Keep changes surgical; match existing style. Update `CHANGELOG.md` for
  user-visible changes.
