#!/usr/bin/env bash
# build_windows.sh — Build LOOM on Windows (MSYS2 UCRT64) and output
#                    loom-binaries-windows-x64.zip in the repo root.
#
# Run from the repo root inside the MSYS2 UCRT64 shell:
#   bash build_scripts/build_windows.sh
#
# Requires: MSYS2 (msys2.org), run from the UCRT64 shell
# Note: patches/ directory must be present (copy from the LOOM Windows port repo)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ZIP_NAME="loom-binaries-windows-x64.zip"

echo "=== Installing MSYS2 dependencies ==="
pacman -S --needed --noconfirm \
  mingw-w64-ucrt-x86_64-cmake \
  mingw-w64-ucrt-x86_64-gcc \
  mingw-w64-ucrt-x86_64-make \
  mingw-w64-ucrt-x86_64-glpk \
  mingw-w64-ucrt-x86_64-coin-or-cbc \
  mingw-w64-ucrt-x86_64-protobuf \
  mingw-w64-ucrt-x86_64-libzip \
  git

echo "=== Cloning LOOM ==="
cd "$REPO_ROOT"
if [ ! -d loom ]; then
  git clone --recurse-submodules https://github.com/ad-freiburg/loom.git
fi
cd loom

echo "=== Applying patches (R1–R10) ==="
for dir in "$REPO_ROOT"/patches/loom-patches*/; do
  script=$(find "$dir" -name "apply_patches*.ps1" | head -1)
  if [ -n "$script" ]; then
    echo "  Applying $(basename $dir)..."
    powershell.exe -ExecutionPolicy Bypass -File "$(cygpath -w "$script")"
  fi
done

echo "=== Building ==="
mkdir -p build && cd build
cmake .. -G "MinGW Makefiles" \
  -DCMAKE_BUILD_TYPE=Release \
  -DLOOM_USE_GUROBI=OFF
mingw32-make -j$(nproc)

echo "=== Packaging ==="
cd "$REPO_ROOT"
mkdir -p dist
for exe in loom.exe topo.exe octi.exe gtfs2graph.exe transitmap.exe topoeval.exe; do
  [ -f loom/build/$exe ] && cp loom/build/$exe dist/ && echo "  copied $exe"
done

# Bundle DLLs
for exe in dist/*.exe; do
  ldd "$exe" 2>/dev/null \
    | grep -v -i 'system32\|windows' \
    | awk '{print $3}' \
    | while read dll; do
        [ -f "$dll" ] && cp -n "$dll" dist/ && echo "  dll: $(basename $dll)"
      done
done

cd dist && zip -r "../$ZIP_NAME" . && cd ..
echo ""
echo "=== Done: $ZIP_NAME ($(du -sh $ZIP_NAME | cut -f1)) ==="
echo "Commit and push $ZIP_NAME to publish."
