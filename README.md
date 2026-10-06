# loom-binaries

Pre-built binaries of the [LOOM](https://github.com/ad-freiburg/loom) transit map generation suite for Windows, macOS, and Linux. Consumed automatically by the [QGIS LOOM plugin](https://github.com/transportforcairo/loom_qgis) — end users do not need to interact with this repo directly.

**LOOM** © University of Freiburg (Hannah Bast, Patrick Brosi, Sabine Storandt), GPL-3.0.  
**Windows port** by [Transport for Cairo](https://transportforcairo.com), 2026.

---

## Contents

| File | Platform | Built with |
|---|---|---|
| `loom-binaries-windows-x64.zip` | Windows 10/11 x64 | MSYS2 UCRT64 + TfC Windows patches |
| `loom-binaries-macos-arm64.zip` | macOS 12+ on Apple Silicon | Apple clang, static GLPK |
| `loom-binaries-linux-x64.zip` | Linux x64, glibc 2.34+ (Ubuntu 22.04+, Debian 12+, Fedora 35+) | Ubuntu 22.04 gcc, static GLPK + libstdc++ |
| `SHA256SUMS` | — | Checksums the plugin verifies before installing a ZIP |

All three ZIPs are self-contained:

- **Windows** bundles the MSYS2 DLLs — no MSYS2 installation needed.
- **macOS / Linux** link only OS libraries. libzip is not used (the plugin unzips GTFS feeds itself), GLPK is linked statically, and CBC is left out. `build_scripts/verify_binaries.sh` checks every build: it fails if a binary links Homebrew or other non-system libraries, then runs the whole pipeline on a small GTFS feed (`build_scripts/test_data/gtfs`).

ILP solvers available: GLPK on all platforms, CBC on Windows only.

---

## For QGIS plugin users

You don't need to visit this repo. When you first open the QGIS LOOM plugin, it detects that no binaries are installed and downloads the correct ZIP for your platform automatically. Each plugin version downloads from a fixed **tag** of this repo (not from `main`) and checks the ZIP against `SHA256SUMS` at that tag.

---

## Updating binaries

### macOS and Linux — GitHub Actions (recommended)

A workflow is included that builds both platforms automatically on GitHub's runners and commits the resulting ZIPs back to this repo.

1. Go to **Actions → Build and Commit Binaries → Run workflow**
2. Choose `all`, `macos`, or `linux`
3. Wait ~10–15 minutes — the ZIPs and an updated `SHA256SUMS` are committed to the repo root automatically. A build that fails the linkage check or the smoke test is not committed.

No local Mac or Linux machine needed. Pull requests that change `build_scripts/` run the same build and checks without committing anything.

The upstream LOOM commit is pinned in `build_scripts/common.sh` (`LOOM_REF`) so rebuilds are reproducible; bump it deliberately.

### Windows — manual (MSYS2 required)

The Windows build cannot run on GitHub Actions because applying the POSIX-to-Windows patches requires a local MSYS2 environment. Build locally and commit the ZIP **and `SHA256SUMS`** (the script regenerates it):

```bash
# In the MSYS2 UCRT64 shell, from this repo root:
bash build_scripts/build_windows.sh
git add loom-binaries-windows-x64.zip SHA256SUMS
git commit -m "chore: update Windows binaries"
git push
```

The **Verify checksums** workflow fails if a ZIP is committed without a matching `SHA256SUMS` entry.

### Publishing a set of binaries to the plugin

The plugin only ever downloads from a tag, so binaries on `main` reach users only once tagged:

1. Make sure **Verify checksums** is green on `main`.
2. Tag it: `git tag v1.1.0 && git push origin v1.1.0` (the plugin 1.1.0 expects `v1.1.0`).
3. In `loom_qgis`, set `BINARIES_REF` in `downloader.py` to the new tag and release the plugin.

Never move or delete a tag that a released plugin version points to.

The `patches/` directory must be present. Copy the R1–R10 patch folders from the [LOOM Windows port repo](https://github.com/transportforcairo/loom-windows-port) into `patches/` before running the script.

### Building locally (macOS or Linux)

If you prefer to build macOS or Linux binaries on your own machine instead of using the workflow:

```bash
bash build_scripts/build_macos.sh   # on an Apple Silicon Mac
bash build_scripts/build_linux.sh   # on Ubuntu 22.04
bash build_scripts/update_checksums.sh
git add loom-binaries-*.zip SHA256SUMS
git commit -m "chore: update binaries"
git push
```

To check binaries you already have: `bash build_scripts/verify_binaries.sh <folder-with-binaries>`.

---

## Repository structure

```
loom-binaries/
├── .github/
│   └── workflows/
│       ├── build.yml                  Build + verify (+ commit on manual runs)
│       └── checksums.yml              Checks SHA256SUMS matches the ZIPs
├── build_scripts/
│   ├── common.sh                      Shared: pinned LOOM commit, static GLPK, packaging
│   ├── build_windows.sh               MSYS2 UCRT64 build + DLL bundling
│   ├── build_macos.sh                 Self-contained Apple Silicon build
│   ├── build_linux.sh                 Self-contained Linux x64 build
│   ├── verify_binaries.sh             Linkage check + pipeline smoke test
│   ├── update_checksums.sh            Regenerates SHA256SUMS
│   └── test_data/gtfs/                Tiny synthetic GTFS feed for the smoke test
├── patches/                           R1–R10 Windows compatibility patches
│   ├── loom-patches/                  (copy from loom-windows-port repo)
│   ├── loom-patches-r2/
│   └── ...
├── loom-binaries-windows-x64.zip      ← ready
├── loom-binaries-macos-arm64.zip      ← built by workflow
├── loom-binaries-linux-x64.zip        ← built by workflow
├── SHA256SUMS                         ← updated by workflow / update_checksums.sh
├── README.md
└── LICENSE
```

---

## Licence

The LOOM binaries are licensed under GPL-3.0, matching the upstream project. The Windows port patches are by Transport for Cairo and contributed under the same licence.
