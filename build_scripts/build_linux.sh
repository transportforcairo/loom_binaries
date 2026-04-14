#!/usr/bin/env bash
# build_linux.sh — Build LOOM on Ubuntu 20.04+ and output loom-binaries-linux-x64.zip
#                  in the repo root.
#
# Run from the repo root:
#   bash build_scripts/build_linux.sh
#
# Requires: Ubuntu 20.04+, sudo access

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ZIP_NAME="loom-binaries-linux-x64.zip"

echo "=== Installing apt dependencies ==="
sudo apt-get update
sudo apt-get install -y \
  cmake g++ make \
  libglpk-dev coinor-libcbc-dev \
  libprotobuf-dev protobuf-compiler \
  libzip-dev git

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
  -DLOOM_USE_GUROBI=OFF
make -j$(nproc)

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
