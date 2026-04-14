# loom-binaries

Pre-built binaries of the [LOOM](https://github.com/ad-freiburg/loom) transit map generation suite for Windows, macOS, and Linux. Consumed automatically by the [QGIS LOOM plugin](https://github.com/transportforcairo/qgis-loom-plugin) — end users do not need to interact with this repo directly.

**LOOM** © University of Freiburg (Hannah Bast, Patrick Brosi, Sabine Storandt), GPL-3.0.  
**Windows port** by [Transport for Cairo](https://transportforcairo.com), 2026.

---

## Contents

| File | Platform | Built with |
|---|---|---|
| `loom-binaries-windows-x64.zip` | Windows 10/11 x64 | MSYS2 UCRT64 + TfC Windows patches |
| `loom-binaries-macos-arm64.zip` | macOS Apple Silicon | Homebrew + C++17 |
| `loom-binaries-linux-x64.zip` | Ubuntu 20.04+ x64 | apt + upstream Dockerfile |

The Windows ZIP includes all required MSYS2 DLLs — no MSYS2 installation needed on the target machine.

---

## For QGIS plugin users

You don't need to visit this repo. When you first open the QGIS LOOM plugin, it detects that no binaries are installed and downloads the correct ZIP for your platform automatically. The download URL points to the raw files in this repo.

---

## Updating binaries

### macOS and Linux — GitHub Actions (recommended)

A workflow is included that builds both platforms automatically on GitHub's runners and commits the resulting ZIPs back to this repo.

1. Go to **Actions → Build and Commit Binaries → Run workflow**
2. Choose `all`, `macos`, or `linux`
3. Wait ~10 minutes — the ZIPs will be committed to the repo root automatically

No local Mac or Linux machine needed.

### Windows — manual (MSYS2 required)

The Windows build cannot run on GitHub Actions because applying the POSIX-to-Windows patches requires a local MSYS2 environment. Build locally and commit the ZIP manually:

```bash
# In the MSYS2 UCRT64 shell, from this repo root:
bash build_scripts/build_windows.sh
git add loom-binaries-windows-x64.zip
git commit -m "chore: update Windows binaries"
git push
```

The `patches/` directory must be present. Copy the R1–R10 patch folders from the [LOOM Windows port repo](https://github.com/transportforcairo/loom-windows-port) into `patches/` before running the script.

### Building locally (macOS or Linux)

If you prefer to build macOS or Linux binaries on your own machine instead of using the workflow:

```bash
bash build_scripts/build_macos.sh   # on a Mac
bash build_scripts/build_linux.sh   # on Ubuntu 20.04+
git add loom-binaries-*.zip
git commit -m "chore: update binaries"
git push
```

---

## Repository structure

```
loom-binaries/
├── .github/
│   └── workflows/
│       └── build.yml                  GitHub Actions build + commit workflow
├── build_scripts/
│   ├── build_windows.sh               MSYS2 UCRT64 build + DLL bundling
│   ├── build_macos.sh                 Homebrew build
│   └── build_linux.sh                 apt build
├── patches/                           R1–R10 Windows compatibility patches
│   ├── loom-patches/                  (copy from loom-windows-port repo)
│   ├── loom-patches-r2/
│   └── ...
├── loom-binaries-windows-x64.zip      ← ready
├── loom-binaries-macos-arm64.zip      ← built by workflow
├── loom-binaries-linux-x64.zip        ← built by workflow
├── README.md
└── LICENSE
```

---

## Licence

The LOOM binaries are licensed under GPL-3.0, matching the upstream project. The Windows port patches are by Transport for Cairo and contributed under the same licence.
