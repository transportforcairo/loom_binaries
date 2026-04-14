#!/usr/bin/env bash
# build_macos.sh — Build LOOM on macOS and output loom-binaries-macos-arm64.zip
#                  (or macos-x64.zip on Intel) in the repo root.
#
# Run from the repo root:
#   bash build_scripts/build_macos.sh
#
# Requires: Homebrew, Xcode Command Line Tools

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARCH=$(uname -m)   # arm64 or x86_64
ZIP_NAME="loom-binaries-macos-${ARCH}.zip"

echo "=== Installing Homebrew dependencies ==="
brew install cmake glpk cbc protobuf libzip

echo "=== Cloning LOOM ==="
cd "$REPO_ROOT"
if [ ! -d loom ]; then
  git clone --recurse-submodules https://github.com/ad-freiburg/loom.git
fi

echo "=== Building ==="
cd loom
mkdir -p build && cd build
cmake .. \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_CXX_STANDARD=17 \
  -DLOOM_USE_GUROBI=OFF \
  -DCOIN_INCLUDE_DIR="$(brew --prefix)/include/cbc"
make -j$(sysctl -n hw.logicalcpu)

echo "=== Packaging ==="
cd "$REPO_ROOT"
mkdir -p dist
for bin in loom topo octi gtfs2graph transitmap topoeval; do
  [ -f loom/build/$bin ] && cp loom/build/$bin dist/ && echo "  copied $bin"
done

cd dist && zip -r "../$ZIP_NAME" . && cd ..
echo ""
echo "=== Done: $ZIP_NAME ($(du -sh $ZIP_NAME | cut -f1)) ==="
echo "Commit and push $ZIP_NAME to publish."
