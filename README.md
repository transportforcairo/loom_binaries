LOOM Windows Port — Transport for Cairo
Windows (MSYS2/UCRT64) compatibility patches for the LOOM transit map generation suite, produced by Transport for Cairo.
LOOM is an open-source tool for the automated generation of geographically correct and schematic transit maps, developed by Hannah Bast, Patrick Brosi, and Sabine Storandt at the University of Freiburg. It was originally written for Linux/macOS. This repository contains everything needed to build and run it natively on Windows — without Docker or WSL.
Original LOOM © University of Freiburg, GPL-3.0 — github.com/ad-freiburg/loom  
These patches © Transport for Cairo, 2026 — contributed under the same GPL-3.0 licence.
---
Platform support
Platform	Status	Method
Windows 10/11 x64	✔ Working	MSYS2 UCRT64 + these patches
macOS (Intel + Apple Silicon)	✔ Working	Native — Homebrew + C++17 flag only
Linux (Ubuntu 20.04+)	✔ Working	Native — apt packages, as per upstream Dockerfile
---
Quick start — Windows build
1. Install MSYS2
Download and install from msys2.org, then open the MSYS2 UCRT64 shell.
2. Install dependencies
```bash
pacman -S --needed \
  mingw-w64-ucrt-x86_64-cmake \
  mingw-w64-ucrt-x86_64-gcc \
  mingw-w64-ucrt-x86_64-make \
  mingw-w64-ucrt-x86_64-glpk \
  mingw-w64-ucrt-x86_64-coin-or-cbc \
  mingw-w64-ucrt-x86_64-protobuf \
  mingw-w64-ucrt-x86_64-libzip \
  git
```
3. Clone LOOM and apply patches
```bash
git clone --recurse-submodules https://github.com/ad-freiburg/loom.git
cd loom
```
Apply each patch round in order from PowerShell (run from the repo root):
```powershell
.\loom-patches\apply_patches.ps1       # Round 1
.\loom-patches-r2\apply_patches_r2.ps1 # Round 2
# ... through to round 10
```
4. Build
```bash
mkdir build && cd build
cmake .. -G "MinGW Makefiles" -DCMAKE_BUILD_TYPE=Release -DLOOM_USE_GUROBI=OFF
mingw32-make -j$(nproc)
```
5. Run
> **Always use `cmd.exe` or the MSYS2 shell — not PowerShell.** PowerShell does not support `<` stdin redirection for native executables.
```cmd
:: cmd.exe
loom.exe < input.json > loom_out.json
transitmap.exe -l < loom_out.json > map.svg
```
```bash
# MSYS2 shell — full pipeline
cat examples/stuttgart.json | ./loom | ./transitmap -l > stuttgart.svg
```
6. Create a portable distribution (no MSYS2 required on target machine)
```bash
mkdir -p loom-windows-dist
cp loom.exe topo.exe octi.exe gtfs2graph.exe transitmap.exe topoeval.exe loom-windows-dist/
cp -r ../examples loom-windows-dist/

# Bundle required DLLs
for exe in loom-windows-dist/*.exe; do
  ldd "$exe" | grep -v -i 'system32\|windows' | awk '{print $3}' | while read dll; do
    [ -f "$dll" ] && cp -n "$dll" loom-windows-dist/
  done
done
```
You can then zip `loom-windows-dist/` and run it on any Windows 10/11 x64 machine.
---
Patch overview
All patches are applied to a clean clone of the upstream LOOM repository. No changes were made to LOOM's core algorithms or data structures — every change is a Windows compatibility shim.
Round	Files changed	What was fixed
R1	`win_compat.h` (new), all `*Main.cpp`, `CMakeLists.txt`	Core POSIX shim (`unistd.h`, `dirent.h`, `isatty`, `getpid`, `ssize_t`); binary stdio; WIN32 CMake block
R2	`win_compat.h`, `Log.h`, `Server.cpp`, `Misc.cpp`	`netdb.h` and `pwd.h` stubs; Windows macro clashes (`ERROR`, `DEBUG`, `INFO`, `WARNING`)
R3	`win_compat.h`, `Server.cpp`	MSYS2 UCRT64 awareness; `uid_t`, `getpwuid_r`, `pread`/`pwrite` via Windows OVERLAPPED API; remove conflicting socket headers
R4	`win_compat.h`, `Server.cpp`, `Agency.h`	Fix `usleep` as inline function; `setsockopt` cast; `SO_REUSEPORT`; `SIGPIPE` guard; `timezone` macro clash in MinGW `time.h`
R5	`Geo.h`, `Agency.h`	`#undef Polygon` after `wingdi.h` include; rename `_timezone` → `_tz` throughout
R6	`Misc.h`, all `cppgtfs/` files	`#define NOGDI` before `windows.h`; rename `stop_timezone` → `stop_tz` throughout
R7	`CMakeLists.txt`, `Parser.tpp`	Add `NOGDI NOUSER NOSOUND` to global compile definitions; fix remaining `stop_timezone` references
R8–R9	`CMakeLists.txt`	Remove broken generator expression fragments introduced by R8 automation
R10	Three test `CMakeLists.txt`, `Protobuf.h`, `MvtRenderer.cpp`	Remove `-lutil` (POSIX-only); guard `arpa/inet.h`; fix `mkdir()` call (Windows takes 1 arg, not 2)
For the full file-by-file patch registry see `TfC_LOOM_Windows_Port_Handoff.pdf`.
---
Repository contents
```
loom-windows-port/
├── loom-patches/              Round 1 — core POSIX shim + CMake WIN32 block
│   ├── win_compat.h
│   ├── *.patch
│   └── apply_patches.ps1
├── loom-patches-r2/           Round 2
│   ├── *.patch
│   └── apply_patches_r2.ps1
├── ...                        Rounds 3–10, same structure
├── TfC_LOOM_Windows_Port_Handoff.pdf   Full technical handoff document
└── README.md
```
Each patch round directory contains `.patch` files and a PowerShell apply script. Apply them in order (R1 → R10) to a clean LOOM clone.
---
What's next
A QGIS plugin that wraps the full LOOM pipeline in a cross-platform GUI is in development, using these binaries as its backend. See the handoff document (section 4) for the plugin architecture brief.
---
Attribution
LOOM is developed by Hannah Bast, Patrick Brosi, and Sabine Storandt at the University of Freiburg (Chair of Algorithms and Data Structures). Published under GPL-3.0.
Key publications:
Bast, Brosi, Storandt. Efficient Generation of Geographically Accurate Transit Maps. SIGSPATIAL 2018.
Bast, Brosi, Storandt. Metro Maps on Octilinear Grid Graphs. EuroVis 2020.
Bast, Brosi, Storandt. Metro Maps on Flexible Base Grids. SSTD 2021.
The Windows compatibility patches in this repository were produced by Transport for Cairo and are contributed under the same GPL-3.0 licence as the upstream project.
> This tool uses LOOM (github.com/ad-freiburg/loom), developed by Hannah Bast, Patrick Brosi, and Sabine Storandt at the University of Freiburg, licensed under GPL-3.0. Windows port by Transport for Cairo (transportforcairo.com), 2026.
