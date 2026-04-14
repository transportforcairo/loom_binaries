# loom-binaries

Pre-built binaries of the [LOOM](https://github.com/ad-freiburg/loom) transit map generation suite for Windows, macOS, and Linux. These are consumed automatically by the [QGIS LOOM plugin](https://github.com/transportforcairo/qgis-loom-plugin) — you do not need to download anything from here manually.

**LOOM** © University of Freiburg (Hannah Bast, Patrick Brosi, Sabine Storandt), GPL-3.0.  
**Windows port** by [Transport for Cairo](https://transportforcairo.com), 2026.

---

## Downloads

Binaries are distributed as GitHub Release assets. Go to the [Releases](../../releases) page and download the ZIP for your platform:

| Platform | Asset filename | Notes |
|---|---|---|
| Windows 10/11 x64 | `loom-binaries-windows-x64.zip` | `.exe` files + bundled MSYS2 DLLs |
| macOS Intel | `loom-binaries-macos-x64.zip` | |
| macOS Apple Silicon | `loom-binaries-macos-arm64.zip` | |
| Linux x64 | `loom-binaries-linux-x64.zip` | Built on Ubuntu 20.04, runs on 20.04+ |

---

## For QGIS plugin users

You don't need to visit this repo at all. When you first open the QGIS LOOM plugin, it will detect that no binaries are installed and offer to download the correct ZIP for your platform automatically. The download points here.

---

## For maintainers — publishing a new release

1. Build binaries for each platform using the build scripts in the [plugin repo](https://github.com/transportforcairo/qgis-loom-plugin/tree/main/build_scripts).

2. From inside each platform's `plugin/bin/<os>/` folder, create the ZIP:

   ```bash
   # Windows (MSYS2 shell), macOS, or Linux — same command
   cd plugin/bin/windows
   zip -r ../../../loom-binaries-windows-x64.zip .
   ```

3. Create a new GitHub Release on this repo (e.g. `v1.0.0`) and attach all four ZIPs as release assets.

4. Update `FALLBACK_RELEASE_TAG` in [`plugin/downloader.py`](https://github.com/transportforcairo/qgis-loom-plugin/blob/main/plugin/downloader.py) to match the new tag, and push.

---

## Licence

The LOOM binaries are licensed under GPL-3.0, matching the upstream project. The Windows port patches are by Transport for Cairo and contributed under the same licence. Source code and patch history: [github.com/transportforcairo/qgis-loom-plugin](https://github.com/transportforcairo/qgis-loom-plugin).
