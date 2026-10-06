#!/usr/bin/env bash
# build_linux.sh — Build self-contained LOOM binaries for Linux x64 and write
#                  loom-binaries-linux-x64.zip in the repo root.
#
# Run from the repo root:
#   bash build_scripts/build_linux.sh
#
# Requires: Ubuntu 22.04 (its glibc is the oldest the binaries will run on) —
#           a machine, VM or `docker run ubuntu:22.04` container (CI uses the
#           container). Root or sudo for apt; set SKIP_DEPS=1 if the build
#           tools are already installed.
#
# The binaries only need libraries every Linux desktop has (glibc, libgcc,
# libgomp, zlib, bzip2). libstdc++ and GLPK are linked statically. See
# common.sh for what is enabled/disabled and why.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=common.sh
source "$REPO_ROOT/build_scripts/common.sh"

ZIP_PATH="$REPO_ROOT/loom-binaries-linux-x64.zip"
WORK="$REPO_ROOT/_build/linux"
DEPS="$WORK/deps"

if [ "${SKIP_DEPS:-0}" != "1" ]; then
  log "Installing build tools (apt)"
  SUDO=""
  if [ "$(id -u)" != "0" ]; then SUDO="sudo"; fi
  export DEBIAN_FRONTEND=noninteractive
  $SUDO apt-get update
  # Deliberately NOT installing libzip-dev, libglpk-dev or coinor-libcbc-dev:
  # the binaries must not depend on them at runtime.
  $SUDO apt-get install -y --no-install-recommends \
    cmake g++ make binutils git curl ca-certificates zip zlib1g-dev libbz2-dev
fi

log "Building GLPK ${GLPK_VERSION} (static)"
build_glpk "$WORK" "$DEPS"

log "Fetching LOOM"
fetch_loom "$WORK/loom"

log "Building LOOM"
build_loom "$WORK/loom" "$WORK/build" "$DEPS" \
  -DCMAKE_EXE_LINKER_FLAGS="-static-libstdc++ -static-libgcc"

log "Verifying"
bash "$REPO_ROOT/build_scripts/verify_binaries.sh" "$WORK/build"

log "Packaging"
package "$WORK/build" "$ZIP_PATH"

echo ""
echo "Done: $ZIP_PATH"
echo "Next: bash build_scripts/update_checksums.sh, then commit the ZIP and SHA256SUMS."
