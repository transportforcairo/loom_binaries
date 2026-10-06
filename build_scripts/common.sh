#!/usr/bin/env bash
# common.sh — Shared helpers for build_macos.sh and build_linux.sh.
# Sourced by those scripts, not run on its own.
#
# Goal: binaries that run on a clean machine. Nothing may link against
# Homebrew (/opt/homebrew, /usr/local) or distro packages the user is
# unlikely to have. verify_binaries.sh enforces this after every build.
#
#   * libzip  — disabled. The QGIS plugin (>= 1.1.0) unzips GTFS feeds itself
#               and passes gtfs2graph a folder.
#   * GLPK    — compiled from source here and linked statically.
#   * COIN-OR — disabled (CBC is only shipped in the Windows build).
#   * Gurobi  — disabled (commercial licence).

# Upstream LOOM commit the binaries are built from. Pinned so that a rebuild is
# reproducible; bump deliberately (and check the plugin still works) to pick up
# upstream changes.
LOOM_REPO="${LOOM_REPO:-https://github.com/ad-freiburg/loom.git}"
LOOM_REF="${LOOM_REF:-1e4757838104d1e4d22186c9b77d5fc4b98681a0}"

GLPK_VERSION="${GLPK_VERSION:-5.0}"
GLPK_SHA256="${GLPK_SHA256:-4a1013eebb50f728fc601bdd833b0b2870333c3b3e5a816eeba921d95bec6f15}"
GLPK_URLS=(
  "https://ftpmirror.gnu.org/glpk/glpk-${GLPK_VERSION}.tar.gz"
  "https://ftp.gnu.org/gnu/glpk/glpk-${GLPK_VERSION}.tar.gz"
)
# Set GLPK_SRC_DIR to an unpacked GLPK source tree to skip the download.
GLPK_SRC_DIR="${GLPK_SRC_DIR:-}"

BINARIES=(loom topo octi gtfs2graph transitmap topoeval)

log() { echo ""; echo "=== $* ==="; }

ncpu() { getconf _NPROCESSORS_ONLN 2>/dev/null || sysctl -n hw.logicalcpu 2>/dev/null || echo 2; }

sha256_of() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

# fetch_loom <dest>: check out LOOM at LOOM_REF (with submodules) into <dest>.
fetch_loom() {
  local dest="$1"
  if [ ! -d "$dest/.git" ]; then
    git init -q "$dest"
    git -C "$dest" remote add origin "$LOOM_REPO"
  fi
  git -C "$dest" fetch -q --depth 1 origin "$LOOM_REF"
  git -C "$dest" checkout -q --force FETCH_HEAD
  git -C "$dest" submodule update -q --init --recursive --depth 1
  echo "LOOM at $(git -C "$dest" rev-parse HEAD)"
}

# build_glpk <work_dir> <install_prefix>: static GLPK, no shared library.
# Honours CFLAGS / MACOSX_DEPLOYMENT_TARGET from the environment.
build_glpk() {
  local work="$1" prefix="$2" src
  if [ -f "$prefix/lib/libglpk.a" ]; then
    echo "GLPK already built in $prefix"
    return
  fi
  mkdir -p "$work"
  if [ -n "$GLPK_SRC_DIR" ]; then
    src="$GLPK_SRC_DIR"
  else
    local tarball="$work/glpk-${GLPK_VERSION}.tar.gz" url ok=0
    for url in "${GLPK_URLS[@]}"; do
      if curl -fsSL --retry 3 -o "$tarball" "$url"; then ok=1; break; fi
    done
    [ "$ok" = 1 ] || { echo "ERROR: could not download GLPK ${GLPK_VERSION}"; exit 1; }
    local got; got="$(sha256_of "$tarball")"
    if [ "$got" != "$GLPK_SHA256" ]; then
      echo "ERROR: GLPK tarball checksum mismatch (got $got, expected $GLPK_SHA256)"
      exit 1
    fi
    tar -xzf "$tarball" -C "$work"
    src="$work/glpk-${GLPK_VERSION}"
  fi
  (
    cd "$src" || exit 1
    ./configure --prefix="$prefix" --disable-shared --enable-static --with-pic \
                --disable-dependency-tracking
    make -j"$(ncpu)"
    make install
  )
}

# build_loom <src> <build_dir> <glpk_prefix> [extra cmake args...]
build_loom() {
  local src="$1" build="$2" glpk="$3"; shift 3
  cmake -S "$src" -B "$build" \
    -DCMAKE_BUILD_TYPE=Release \
    -DGLPK_ROOT_DIR="$glpk" \
    -DCMAKE_DISABLE_FIND_PACKAGE_LibZip=ON \
    -DCMAKE_DISABLE_FIND_PACKAGE_COIN=ON \
    -DCMAKE_DISABLE_FIND_PACKAGE_Gurobi=ON \
    "$@"

  # Fail early if CMake picked up anything other than our static GLPK.
  local glpk_lib
  glpk_lib="$(grep '^GLPK_LIBRARY:' "$build/CMakeCache.txt" | cut -d= -f2-)"
  if [ "$glpk_lib" != "$glpk/lib/libglpk.a" ]; then
    echo "ERROR: expected static GLPK at $glpk/lib/libglpk.a, CMake found: '$glpk_lib'"
    exit 1
  fi

  cmake --build "$build" -j "$(ncpu)"
}

# package <build_dir> <zip_path>: zip the binaries flat (no sub-folder).
package() {
  local build="$1" zip_path="$2" stage
  stage="$(mktemp -d)"
  for bin in "${BINARIES[@]}"; do
    if [ ! -f "$build/$bin" ]; then
      echo "ERROR: $bin was not built"
      exit 1
    fi
    cp "$build/$bin" "$stage/"
  done
  rm -f "$zip_path"
  (cd "$stage" && zip -q -X "$zip_path" "${BINARIES[@]}")
  rm -rf "$stage"
  echo "Packaged $(basename "$zip_path") ($(du -h "$zip_path" | cut -f1))"
}
