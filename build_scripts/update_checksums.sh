#!/usr/bin/env bash
# update_checksums.sh — Regenerate SHA256SUMS for all binary ZIPs in the repo
#                       root. The QGIS plugin refuses to install a ZIP whose
#                       hash does not match this file, so run it after every
#                       rebuild (CI does this automatically for macOS/Linux).
#
# Usage (from anywhere):  bash build_scripts/update_checksums.sh

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

if command -v sha256sum >/dev/null 2>&1; then
  sha256sum loom-binaries-*.zip > SHA256SUMS
else
  shasum -a 256 loom-binaries-*.zip > SHA256SUMS
fi

cat SHA256SUMS
