#!/usr/bin/env bash
# verify_binaries.sh — Check that built LOOM binaries are self-contained and
#                      actually run the full pipeline.
#
# Usage: bash build_scripts/verify_binaries.sh <folder-with-binaries>
#
# 1. Linkage: every binary may only depend on OS-provided libraries.
#    macOS: /usr/lib/* and /System/* only (no Homebrew); deployment target
#           no newer than MACOSX_DEPLOYMENT_TARGET.
#    Linux: an allow-list of libraries every desktop distro ships.
# 2. Smoke test: run the plugin's pipeline on a small GTFS feed (passed as a
#    folder, like the plugin does), including an ILP run that needs GLPK.

set -euo pipefail

DIR="$(cd "$1" && pwd)"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GTFS="$HERE/test_data/gtfs"
BINARIES=(loom topo octi gtfs2graph transitmap topoeval)
fail=0

ver_le() { [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | head -1)" = "$1" ]; }

echo "--- Linkage ---"
case "$(uname -s)" in
  Darwin)
    target="${MACOSX_DEPLOYMENT_TARGET:-}"
    for b in "${BINARIES[@]}"; do
      bad=0
      while read -r lib; do
        case "$lib" in
          /usr/lib/*|/System/*) ;;
          *) echo "FAIL  $b links $lib"; bad=1 ;;
        esac
      done < <(otool -L "$DIR/$b" | tail -n +2 | awk '{print $1}')
      minos="$(otool -l "$DIR/$b" | awk '/LC_BUILD_VERSION/{f=1} f && $1=="minos"{print $2; exit}')"
      if [ -n "$target" ] && [ -n "$minos" ] && ! ver_le "$minos" "$target"; then
        echo "FAIL  $b requires macOS $minos (target is $target)"; bad=1
      fi
      if [ "$bad" = 0 ]; then echo "ok    $b (minimum macOS ${minos:-?})"; else fail=1; fi
    done
    ;;
  Linux)
    allowed='^(libc\.so\.6|libm\.so\.6|libpthread\.so\.0|libdl\.so\.2|librt\.so\.1|libgcc_s\.so\.1|libstdc\+\+\.so\.6|libgomp\.so\.1|libz\.so\.1|libbz2\.so\.1\.0|ld-linux-x86-64\.so\.2)$'
    for b in "${BINARIES[@]}"; do
      bad=0
      while read -r lib; do
        if ! [[ "$lib" =~ $allowed ]]; then
          echo "FAIL  $b needs $lib"; bad=1
        fi
      done < <(readelf -d "$DIR/$b" | awk '/NEEDED/ {gsub(/[][]/, "", $5); print $5}')
      glibc="$(objdump -T "$DIR/$b" | grep -o 'GLIBC_[0-9.]*' | sort -uV | tail -1)"
      if [ "$bad" = 0 ]; then echo "ok    $b (needs ${glibc:-?})"; else fail=1; fi
    done
    ;;
  *)
    echo "Unsupported OS for linkage check: $(uname -s)"; fail=1 ;;
esac

[ "$fail" = 0 ] || { echo "Linkage check FAILED"; exit 1; }

echo "--- Smoke test ---"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

run() {  # run <name> <output> <cmd...> (stdin from caller)
  local name="$1" out="$2"; shift 2
  if ! "$@" > "$out" 2> "$tmp/$name.err"; then
    echo "FAIL  $name"; cat "$tmp/$name.err"; exit 1
  fi
  if [ ! -s "$out" ]; then
    echo "FAIL  $name produced no output"; cat "$tmp/$name.err"; exit 1
  fi
  echo "ok    $name"
}

run gtfs2graph      "$tmp/graph.json" "$DIR/gtfs2graph" -m all "$GTFS"
run topo            "$tmp/topo.json"  "$DIR/topo"                             < "$tmp/graph.json"
run loom            "$tmp/loom.json"  "$DIR/loom"                             < "$tmp/topo.json"
run "loom (glpk)"   "$tmp/ilp.json"   "$DIR/loom" -m ilp --ilp-solver glpk    < "$tmp/topo.json"
run octi            "$tmp/octi.json"  "$DIR/octi"                             < "$tmp/loom.json"
run transitmap      "$tmp/map.svg"    "$DIR/transitmap" -l                    < "$tmp/octi.json"

grep -q "<svg" "$tmp/map.svg" || { echo "FAIL  transitmap output is not SVG"; exit 1; }
echo "All checks passed."
