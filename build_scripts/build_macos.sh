#!/usr/bin/env bash
# build_macos.sh — Build self-contained LOOM binaries for macOS on Apple Silicon
#                  and write loom-binaries-macos-arm64.zip in the repo root.
#
# Run from the repo root on an Apple Silicon Mac:
#   bash build_scripts/build_macos.sh
#
# Requires: Xcode Command Line Tools, cmake (installed via Homebrew if missing).
#
# The binaries only link macOS system libraries (/usr/lib, /System) and run on
# macOS 12 or newer (MACOSX_DEPLOYMENT_TARGET) — even on a Mac without Homebrew.
# No Homebrew libraries are installed or linked. See common.sh for details.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=common.sh
source "$REPO_ROOT/build_scripts/common.sh"

if [ "$(uname -m)" != "arm64" ]; then
  echo "ERROR: build on an Apple Silicon Mac (the plugin ships arm64 binaries only)."
  exit 1
fi

# Oldest macOS the binaries must run on. Applied to GLPK (via the environment)
# and to LOOM (via CMake). verify_binaries.sh checks it.
export MACOSX_DEPLOYMENT_TARGET="${MACOSX_DEPLOYMENT_TARGET:-12.0}"

ZIP_PATH="$REPO_ROOT/loom-binaries-macos-arm64.zip"
WORK="$REPO_ROOT/_build/macos"
DEPS="$WORK/deps"

if ! command -v cmake >/dev/null 2>&1; then
  log "Installing cmake (Homebrew)"
  brew install cmake
fi

log "Building GLPK ${GLPK_VERSION} (static, macOS ${MACOSX_DEPLOYMENT_TARGET}+)"
build_glpk "$WORK" "$DEPS"

log "Fetching LOOM"
fetch_loom "$WORK/loom"

log "Building LOOM"
# OpenMP is disabled because Apple clang has none built in and Homebrew's
# libomp would become a runtime dependency (same as the previous macOS builds).
build_loom "$WORK/loom" "$WORK/build" "$DEPS" \
  -DCMAKE_CXX_STANDARD=17 \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DCMAKE_OSX_DEPLOYMENT_TARGET="$MACOSX_DEPLOYMENT_TARGET" \
  -DCMAKE_DISABLE_FIND_PACKAGE_OpenMP=ON

log "Verifying"
bash "$REPO_ROOT/build_scripts/verify_binaries.sh" "$WORK/build"

log "Packaging"
package "$WORK/build" "$ZIP_PATH"

echo ""
echo "Done: $ZIP_PATH"
echo "Next: bash build_scripts/update_checksums.sh, then commit the ZIP and SHA256SUMS."
