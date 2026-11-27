# WorldConquest

Stage 15 follow-up: [four-atlas upload instructions, exact balance, income/conquest evidence and isolated 300-grey local build](docs/STAGE15_MANUAL_SETUP.md). Prepare assets with `python scripts/prepare_icon_upload.py`; build the separate local profile with `python scripts/package_stage15_local.py`. Neither command starts a match or publishes.

Stage 15 implementation candidate: [features, source mapping, tests, deferred benchmarks and manual acceptance](docs/STAGE15_ACCEPTANCE.md). Public capacity remains 20 competitive participants; new basic nations have SafeCount=0 pending approved load testing. No Stage 15 Studio or physical-device verification and no Roblox publication.

Latest Stage 14 corrections: [licensed icons, alignment, native terrain and upload/acceptance blockers](docs/STAGE14_CORRECTIONS.md). **Studio visual acceptance is still blocked.**

Earlier Stage 14 candidate: [full-screen presentation, terrain, rendering changes and acceptance limits](docs/STAGE14_ACCEPTANCE.md). Implemented in Rojo; **rendered visual acceptance and real-device performance remain blocked/pending**. No automatic Roblox publication.

Latest monetisation candidate: [six configured products, exact pass contents, receipt tests and safe activation](docs/MONETISATION_ACCEPTANCE.md). IDs are connected; **public purchase prompts remain disabled**; only verified `Owi00013` (UserId `11327713454`) is approved for controlled live prompts. See [the owner setup and test checklist](docs/CONTROLLED_LIVE_TESTING.md). No Roblox update has been published automatically.

Stage 12–13 acceptance candidate: [implemented names, native communications, localisation, progression/records, parties, configuration and remaining blockers](docs/STAGE12_13_ACCEPTANCE.md). Automated Stage 1–13 regressions pass; rendered Studio, real platform services, translation review and physical mobile acceptance remain pending.

Corresponding source: [https://github.com/gbsk001/WorldConquest](https://github.com/gbsk001/WorldConquest). The source upload was authorized and completed on 24 November 2026; the full source archive was downloaded without authentication and compared with the audited package. See [publication evidence](docs/SOURCE_PUBLICATION.md), [source update steps](docs/SOURCE_RELEASE.md), [build instructions](BUILDING.md) and [dependencies/licences](DEPENDENCIES.md). The Roblox game has not been republished by this task.

Mobile startup/input patch: [implementation, remaining device tests and instructions to update the existing public experience](docs/MOBILE_ACCEPTANCE.md). Automated regressions passed; fresh Studio device emulation and physical mobile acceptance are still pending. Do not interpret earlier desktop GUI previews as mobile certification.

Latest: [Balanced geographic spawns: 100 seeds at 20–500 participants and native Studio inspection](docs/SPAWN_DISTRIBUTION.md). See [24 November scalability acceptance and remaining blockers](docs/SCALABILITY_ACCEPTANCE_2026-11-24.md), [Dedicated performance optimisation and measurements](docs/PERFORMANCE_OPTIMISATION.md), [GUI and rendering acceptance](docs/GUI_PERFORMANCE_UPDATE.md) and [Stage 11 population, spawn selection and graphical icons](docs/STAGE11_ACCEPTANCE.md).

The Rojo project enables **Stage 11**, preserving Stages 1-10. Exactly two match types remain: Public and Private. Public lobbies fill to the configured safe limit of **20 total participants**, prioritising humans. The target of 250 and ceiling of 500 are experimental configuration values: large-load benchmarks failed the performance targets, so neither is enabled by default.

Open `build/WorldConquest-stage10.rbxlx` (the requested filename, now containing Stage 11), or sync `default.project.json` with Rojo. The root `WorldConquest.rbxlx` is an old prototype. `build/WorldConquest-icon-preview.rbxlx` is a separate visual-test fixture with extra gold and instant construction; **do not publish it**.

Run `python scripts/check_stage10_all.py` for Stage 1-11 regressions and `python scripts/benchmark_stage11.py` for actual-Earth simulated loads. Automated tests, local Studio rendering, and published multiplayer acceptance are separate. See the current report for the exact observed scope and outstanding checks.

Preserve [NOTICE](NOTICE) and [LICENSE]. Public corresponding-source hosting is not configured (`Config.SourceURL` is blank). Production teleports, live multi-client recovery, mobile performance and hundreds of concurrent participants are not certified.

## Retained legacy prototype documentation

The following gameplay instructions apply to `SimulationMode="Legacy"`.
Descriptions of automatic growth below do not describe the Foundation mode.

A simple 2D multiplayer Earth-conquest game using Luau, ScreenGui and the existing Rojo project. The interface and 20-second spawn-selection flow are retained. The map now uses detailed real geography, exact click positioning, and connected territory expansion.

## Play and test in Roblox Studio

1. Stop any running playtest and allow Rojo to sync. If needed, run `rojo serve default.project.json` and connect the Studio Rojo plugin to `localhost:34872`.
2. Press **Play**. Wait for the initial visible map to finish drawing; the first ready client starts the shared **20-second** countdown.
3. Click land to select a spawn. Click another valid location before zero to move it. The circular marker centre should be under the click; the username is intentionally displayed above the marker.
4. Use the mouse wheel or **+ / -** to zoom, left-drag to pan, and **Fit** to return to the whole Earth. Touch uses tap, one-finger drag and the zoom buttons.
5. At zero, everyone starts together. Players without a selection receive automatic free spawns. Each player starts with exactly one owned cell. The camera centres on your spawn at approximately one screen pixel per cell.
6. Watch automatic growth along the entire eligible frontier. Zoom further to inspect individual square cells. Optionally click an empty cell directly touching your territory to claim exactly that one cell. Distant land, occupied land, lakes, oceans and diagonal-only connections are rejected. Other players' territory cannot be captured.
7. Stop and restart Play for a new selection phase. Late joiners spectate; leaving frees your land. No economy, buildings or military systems are added.

### Map renderer setting

No map images need uploading or importing. The renderer creates its images locally from bundled geographical data.

Published experiences require **Experience Settings > Security > Allow Mesh / Image APIs** (or the equivalent Creator Dashboard setting). The renderer worked in the existing Studio session without changing any settings. If another environment shows the renderer setup message, check that setting and restart Play. See [EditableImage requirements](https://create.roblox.com/docs/reference/engine/classes/EditableImage).

### Coordinate and coastline checks

- At Fit, click clearly inland. The marker centre must match the click.
- Repeat at roughly 2x, 8x and 32x zoom, after panning, and in both a smaller Studio window and a maximised window. Resize while a territory is visible; marker and territory must remain aligned.
- Click the map's letterbox padding: it must do nothing. Dragging must pan without selecting a spawn.
- Zoom into Britain/France, the Great Lakes, Japan/Taiwan, Indonesia or Hawaii. The coastlines and inland water should become more detailed as higher-detail tiles load.
- Click a lake or ocean. It must be rejected without moving your spawn or increasing your land count.
- On an island, grow to the coast. Expansion must stop at water; there is no ownership smoothing.

### Multiplayer checks

Use Studio's **Server & Clients** test mode with two clients. Confirm shared countdowns, different colours/usernames, visible spawn changes, overlapping-spawn rejection, simultaneous starting territory and expansion updates in both windows. Competing claims must have one winner. A late joiner should receive current ownership as a spectator. Closing a client must release its territory in the remaining client.

This frontier change has automated production-module and simulated server/replica checks. Live Studio verification of the new renderer/frontier, multi-client load testing and physical touch-device testing remain to be done. [Roblox testing modes](https://create.roblox.com/docs/studio/testing-modes)

## What changed

### Detailed geography

The mask is newly rasterized from Natural Earth **1:10 million land and lakes, version 5.1.2**, into **8192 x 4096** cells. This is about 129 times as many cells as the previous mask; it is not an enlargement of the previous 1:110m source.

Lake polygons are subtracted and island holes are preserved. The projection keeps longitude/latitude positions and a 2:1 world rectangle. Equirectangular polar distortion remains; coastlines are finite-resolution, not exact at arbitrary magnification. See [geography sources, licence and limitations](data/README.md).

### Exact pointer mapping

The root ScreenGui explicitly uses `ScreenInsets.None`, with safe-area padding applied to its content. Roblox still reports GUI positions relative to an inset-dependent origin: in the live Studio test the root's `AbsolutePosition` was `(0, -58)`.

Physical mouse/touch input is normalized **once** with that actual root origin, then mapped through the **actual rendered canvas AbsolutePosition and AbsoluteSize**. Padding, zoom, pan and window resizing are therefore included in the same transform. Mouse positions are read fresh from UserInputService instead of stale mouse-button InputObjects.

The server validates the containing land cell but preserves the exact fractional map coordinates. Markers use the inverse normalized transform. No nearest-land search or distant cell-centre snapping occurs.

### Square-cell expansion

The actual simulation remains **8192 x 4096** (33,554,432 possible cells; 11,014,740 land cells). Every land cell is independently ownable. The previous radius-8/160-cell brush and radius-6 spawn disk are removed, not merely drawn at finer resolution. Each spawn owns one cell.

`Frontier.luau` maintains a deduplicated FIFO of every eligible edge cell for each player. Every 0.1 seconds it claims small batches using only four-direction land adjacency. Newly exposed cells wait for a later tick. All frontier sides receive turns; there is no click-centred brush, radius constraint, diagonal link or ocean traversal. Longitude adjacency wraps at the date line. Sorted initialization and rotating player order make automatic growth deterministic given the same input order. Optional manual clicks claim exactly one adjacent cell and join the next network batch.

Owned pixels use exact owner colours and nearest-neighbour filtering, with no outlines, fades, colour averaging or polygon smoothing. At match start the camera targets **1 pixel per simulation cell**; zooming further enlarges those same square cells. **Fit** intentionally returns to the whole-world overview. At Fit, or under image-memory pressure, multiple cells necessarily fall below one screen pixel: overview ownership uses nearest-cell sampling and can omit tiny regions. Zoom in to inspect exact boundaries. The simulation never switches to a coarser grid.

### Performance and networking limits

- Land mask: **4 MiB**. Sparse server/client ownership tables grow with conquered cells.
- Growth: **10 ticks/sec**, up to **16 cells/player/tick**, **256 globally/tick**, with at most **4096 frontier checks/tick** and **128/player/tick**. Busy matches share the global allowance using rotating order. Frontier length determines how long a complete perimeter sweep takes.
- Manual claims: up to **4/sec/player**, additional to automatic growth. They are validated server-side, individually adjacent, and coalesced into the same batch.
- One batched `Delta` per changed tick contains per-owner packed cell IDs/counts and a revision. Automatic cell-ID payload is at most **1024 bytes/tick** (10 KiB/sec before metadata, transport and recipient fan-out); manual claims add at most 16 bytes/sec/player of IDs. Full sync/release payloads can be much larger.
- Explicit prototype ceiling: **1,048,576 simultaneously owned cells**, shared across players. Growth pauses visibly at the ceiling and resumes after territory is released. This bounds sparse-table growth but is not a measured mobile memory guarantee. Increase only after measuring snapshots, heap and networking on target devices; complete global conquest is not supported by the default ceiling.
- Up to **32 reusable detail ImageLabels plus one overview**, not a GUI object per cell. RGBA detail textures total about **8.1 MiB**, with about **10.2 MiB** of CPU pixel/coverage buffers, excluding Roblox overhead, ownership tables and source data. Allocation failure reduces tile capacity and display detail.
- Changes mark dirty rectangles in existing tiles; only those pixels are painted and uploaded through [EditableImage.WritePixelsBuffer](https://create.roblox.com/docs/reference/engine/classes/EditableImage/WritePixelsBuffer). Camera/LOD changes and full snapshots require complete tile paints. Widely separated changes within one tile can enlarge its dirty rectangle.
- Eight-row work slices target **3 ms/frame** plus the final slice and upload cost. At most **one changed image uploads per frame**. Many dirty tiles therefore introduce visual latency; authoritative ownership continues at the server tick rate. CPU work and upload costs require device profiling.

Before replacement, the local baseline used 799 radius-brush requests / 91,293 added cells, averaging 0.189 ms/request; complete dirty-tile repaints cost about 13-14 ms. After replacement, a synthetic **100-player, 1,000-tick** run claimed **256,000 individual cells**, averaging **1.28 ms/tick**, p95 **1.98 ms**, worst **12.28 ms**. Sparse insertion of 256,100 ownership records took **0.057 s**; a 16x16 dirty-region paint took **0.05-0.08 ms**. Full fresh tiles still cost about **18-51 ms total**, split across frames. These different workloads are not a direct speedup ratio. Timings are local Luau CPU measurements, excluding Roblox networking/GPU; they do not establish 100-player live capacity.

## Project files

| File | Purpose |
| --- | --- |
| `src/shared/EarthData.luau` | Generated full-resolution land runs and display coverage levels |
| `src/shared/Map.luau` | Bit mask, geography queries, four-edge adjacency |
| `src/server/Rules.luau` | Spawn conflicts and single-cell starts |
| `src/server/Frontier.luau` | Persistent frontier queues, single-cell claims and budgets |
| `src/server/Main.server.luau` | Countdown, authoritative ownership, rate limits and delta sync |
| `src/client/MapTransform.luau` | Screen-origin normalization and map/marker conversion |
| `src/client/MapView.luau` | Camera, input, markers and ownership application |
| `src/client/MapTiles.luau` | Bounded tile cache, detail selection and frame scheduling |
| `src/client/TilePainter.luau` | Pure CPU colour/coverage tile compositing |
| `src/client/OwnershipRaster.luau` | Exact sparse cell ownership and nearest-cell display sampling |
| `src/client/Main.client.luau` | Existing simple interface and network subscription |
| `data/` | Vendored licensed source geography and generation hashes |
| `scripts/` | Reproducible generation, correctness tests and performance checks |

The Rojo mappings and tool pin in `aftman.toml` are unchanged. Source geography and tests under `scripts/` are not placed into Roblox.

## Rebuild and validation

Python standard library only:

```powershell
python scripts/generate_earth.py
python scripts/check_luau.py
rojo build default.project.json -o WorldConquest.rbxlx
```

The Luau checks use official CLI binaries in `build/luau`; an alternative tool directory can be passed to `check_luau.py`. If Rojo is not on PATH, use `& "$env:USERPROFILE\.aftman\bin\rojo.exe"`.

Generation validates continental/island/lake samples and lossless mask encoding. It writes `build/earth-detail.png`, `build/earth-preview.png`, and `data/earth-manifest.json`.

Automated checks cover compilation, malformed requests, spawn conflicts, exact fractional positions, deadline enforcement, connected growth, deterministic replay, island isolation, delta/full-sync agreement, late joins, departures, 1,184 coordinate round trips, exact non-blended ownership, incremental/full tile equality, one-pixel image uploads, mid-job changes and cancelled repaint recovery, frontier budgets and memory ceiling and synthetic 100-player load.

A manual isolated rule check is also available in Studio's **server** Command Bar:

```lua
require(game.ServerScriptService.Server.RulesTests)()
```

Earlier live Studio verification covered the unchanged click transform, pan/zoom and resize. It predates this frontier change and is not evidence for the new runtime rendering. For this change, run the two-client test above, leave both players idle after spawning, inspect growth on all sides, zoom beyond 1:1 for square borders, then grow an island to its shoreline. Use Studio MicroProfiler and client/server memory and network statistics for target-device capacity measurements.

## OpenFront source audit and planned port

The pinned-source analysis and staged implementation gates are in [the porting plan](docs/OPENFRONT_PORT_PLAN.md), with [source references](docs/OPENFRONT_SOURCE_INDEX.md). The original analysis is historical; current implementation status and limitations are in the Stage 6 report above.
