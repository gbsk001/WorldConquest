# Build WorldConquest from the corresponding source

This is the modified Roblox/Luau game, including server code. It is not a copy of
the upstream browser game. No API key, account credential, player database, paid
product or uploaded image ID is required to build the place.

## Place build

1. Install [Rojo 7.7.1](https://github.com/rojo-rbx/rojo/releases/tag/v7.7.1),
   or install Aftman and run `aftman install` in this folder. See `aftman.toml`.
2. Open PowerShell in the source folder and run:

   ```powershell
   New-Item -ItemType Directory -Force build
   rojo build default.project.json --output build/WorldConquest-stage10.rbxlx
   ```

3. Open that file in Roblox Studio. Do not use the historical root prototype.
   Alternatively, run `rojo serve default.project.json` and connect Studio's Rojo
   plugin to that project. All services/scripts are declared in the project file.
4. For source-to-place integrity verification on Windows with Aftman installed,
   run `python scripts/package_stage10.py`. It rebuilds and compares every Luau
   source to the XML, then writes `build/stage10-build-manifest.json`.

Generated Earth, topology, icon and terrain modules are included in `src/shared`.
They are sufficient for a clean place build. No proprietary OpenFront artwork is
required. The simulation grid remains 8192 × 4096.

## Automated tests

Use Python 3.11+ and the official [Luau command-line tools](https://github.com/luau-lang/luau).
On Windows put `luau.exe` and `luau-compile.exe` under `build/luau/`.
Run `python scripts/check_stage10_all.py`. This is the Stage 1–13 functional gate,
including mobile input/fallback and spawn checks. Some scripts are Windows-oriented
and expect these executable names. Baseline oracle fixtures and expected hashes
are included under `tests`; regenerating them is separate from running the gate.
The Luau executable version used in the local development environment was not
recorded; do not claim a reproducible compiler binary from that environment.
The delivered source still builds with the pinned Rojo release, independently of
the optional CLI test tools. Test-service stubs are not live Roblox acceptance.

## Regenerating data and oracle fixtures

- `python scripts/generate_earth.py` uses the vendored Natural Earth 5.1.2 GeoJSON.
  Run `generate_topology.py`, then `generate_elevation.py` for terrain rebuilding.
- Elevation regeneration additionally needs the unmodified NOAA ETOPO GeoTIFF
  from the URL and SHA-256 in `data/elevation-manifest.json`, saved to
  `build/ETOPO_2022_v1_60s_N90W180_surface.tif`. Install
  `scripts/requirements-elevation.txt`; allow several GiB of disk/RAM. The large
  unmodified third-party TIFF is not in GitHub; generated class data and every
  modification/generation script are supplied. See `data/README.md`.
- Original GUI SVG sources and PNG exports are in `assets/gui-icons`;
  `scripts/generate_gui_icons.py` regenerates the runtime icon data. Inspect its
  documented build dependency before regenerating; runtime does not need it.
- For upstream TypeScript oracle regeneration, clone OpenFrontIO into
  `build/OpenFrontIO`, check out **8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94**,
  and install its lockfile dependencies. Use the Node/npm engines declared by that
  pinned checkout. Oracle scripts under `scripts/` document individual commands.
  The original browser game is not needed for the normal Roblox build.

## Deployment configuration

Keep `CommerceConfig.luau` `EnablePaidPurchasePrompts=false` and `PurchaseTestUserIDs={}` until controlled live acceptance. All six IDs are configured; see `docs/MONETISATION_ACCEPTANCE.md`. Studio
uses temporary progression deliberately. Review `docs/STAGE12_13_ACCEPTANCE.md`,
`docs/MOBILE_ACCEPTANCE.md` and `docs/SOURCE_RELEASE.md` before updating the existing
experience. Building or testing does not publish anything.
