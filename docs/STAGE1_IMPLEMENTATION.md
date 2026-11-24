# Stage 1 implementation and test record

Implemented 2026-11-17 against OpenFront revision
`8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94`. This supersedes the analysis-only
status at the end of OPENFRONT_PORT_PLAN.md. Stage 2 has not started.

## Runtime changes

- `Config.SimulationMode="Foundation"` selects the new server. `"Legacy"`
  restores the previous free-growth prototype, preserved in LegacyServer.
- Random32 reproduces upstream splitmix32-seeded sfc32, including warmup,
  signed state and exclusive integer bounds. MinHeap preserves f32 storage,
  double-before-store comparisons, tie order and snapshot layout. DetMath
  preserves upstream operation order and bit conversions.
- Grid uses upstream zero-based cell IDs, N/S/W/E adjacency without world wrap,
  u8 terrain and u16 state masks (12-bit owner IDs and separate flags). Ownership
  allocates 4096-cell buffer pages on demand. UI's existing one-based map IDs are
  converted only at the simulation/render boundary. Border tests use those same
  cardinal cells; no smoothed polygon or separate coarse ownership exists.
- Fixed 100 ms simulation ticks consume ordered input queues. The execution
  scheduler ticks existing executions before initializing pending ones. Catchup
  runs at most four ticks per Heartbeat and retains backlog instead of dropping
  simulation time. Replay determinism assumes the same ordered tick inputs;
  network arrival timing itself is not deterministic.
- Server validates selection, reserves cells and commits ownership. Clients
  receive ordered packed six-byte changes and metadata only when changed.
  Initial/recovery snapshots send 8 KiB pages, up to four per client per frame.
  A client stages snapshots, buffers concurrent deltas and installs atomically;
  missing revisions, invalid cells or incomplete snapshots trigger resync.
- Existing EditableImage tile renderer, fractional spawn coordinates, pan,
  zoom, Fit and usernames/colours are retained. Dirty changes also invalidate
  cardinal neighbours so borders are redrawn correctly.

## Geography and fidelity boundaries

The existing detailed Natural Earth 10m 5.1.2 mask is retained at **8192 x 4096**
(33,554,432 cells, 11,014,740 land cells), not enlarged from coarse data. New
topology adds shoreline flags, water depth magnitude and 8,306 cardinal water
components; only the largest component is ocean. Lakes remain water. Generated
data includes hashes and an explicit `ElevationKnown=false`: this source has
no elevation, so magnitude zero on land is an unknown-data placeholder, not
verified plains. Terrain class thresholds are implemented/tested on fixtures;
actual mountain/elevation data must be resolved before terrain-dependent combat.
This is not byte-identical to OpenFront's supplied World map. No new map asset
upload or manual image import is needed. Existing EditableImage access applies.

The 20-second UI phase and one-cell starting footprint are retained transitional
WorldConquest behaviour. Automatic fallback spawn selection is seeded but is not
OpenFront SpawnExecution. No troop generation, attack formulas, combat or free
expansion runs in Foundation. The source-faithful primitives are ready for those
ports; the heap is not artificially used for one-cell selection.

## Validation

Run `python scripts/check_stage1.py`, `python scripts/check_luau.py`, then
`rojo build default.project.json -o build/WorldConquest-stage1.rbxlx`.
Run `python scripts/check_topology.py` to independently decode all 33,554,432
shipped terrain cells and compare terrain and land-mask SHA-256 values.
All production Luau files compile. Stage 1 checks exercise actual modules:
1,280 exact upstream RNG outputs, 4,522 heap operations, 83 exact DetMath cases,
state restoration, bit masks, cardinal edges, impassable terrain, lake/ocean
distinction, 10,000 Earth mask samples, deterministic 240-tick replay under
different frame cadence, duplicate spawn reservation, fractional picks,
automatic selection, disconnect release, atomic snapshots and missing-tick
recovery. Scheduler ordering is checked separately. Previous renderer and
coordinate regression tests also pass. The committed oracle contains upstream
results, not Luau-generated expectations. With the audited checkout available,
`node scripts/verify_stage1_oracle.mjs` independently rechecks the upstream source
hashes and executes its TypeScript bodies after removing type annotations.

Live Studio single-player smoke test: Rojo-synced startup, full Earth rendering,
inland click with aligned marker, countdown-to-one-cell ownership, increasing
server tick display, panning and zoom succeeded. Playtest was stopped afterward.
This is not a two-client/load test. Those remain an acceptance gate before
Stage 2; do not treat this document as evidence that they passed.

## Performance limits

Official Luau CLI benchmark on this machine: 1,048,576 writes took about 0.58 s;
sorting/packing their delta took about 0.10 s. Packed state was exactly 2 MiB,
excluding tables and dirty records. Such a burst is **not** within a 100 ms tick
budget. A million-cell delta is 6 MiB and must not be used as a regular frame.
Stage 1 changes only one spawn cell per player, with at most 4095 compact IDs;
production attack workloads require measured mutation/transport budgets in later
stages. The current drain API does not split arbitrary huge deltas automatically.

Fully allocated Earth ownership is 64 MiB per grid, with another grid temporarily
during client recovery. Terrain RLE is 7,100,036 bytes plus 579,240 bytes of water
runs; source strings, buffers, indexes and Roblox script replication add memory.
Decoded terrain cache is bounded at 512 KiB, not total terrain memory. Renderer
cache and dirty-cell tables are additional. Snapshot queues cap at 256 ticks;
slow transfers can fail and request recovery. Four pages/frame is an application
budget, not a measured Roblox network throughput guarantee. No many-player FPS,
mobile memory ceiling or Studio server/client bandwidth capacity is certified.

## Studio acceptance checklist

1. Stop Play, let Rojo sync, then Play. Confirm Foundation in the phase label.
2. Select land, move selection before zero, and click ocean/lakes/padding.
   Invalid clicks must preserve the previous spawn. Repeat after zoom and pan.
3. At countdown end verify count becomes 1 and remains 1. Stage 1 has no growth.
4. Use Test > Server & Clients with two clients. Check shared countdown, distinct
   colours/usernames, rejected overlapping selection, and simultaneous starts.
5. Verify both clients see the same owned cells; close one client and verify its
   cell is released. Join after start and verify a spectator snapshot.
6. Inspect Output for errors. On the server inspect WorldConquestEvent attributes
   SimulationTick, OwnershipBytes and TickBacklogSeconds. Use MicroProfiler's
   WorldConquest.FoundationTick label and Developer Console memory/network panels
   for actual deployment measurements. Test resized windows and zoom extremes.

Rollback: set SimulationMode to Legacy and restart, or use the complete pre-change
archive `build/WorldConquest-before-stage1.zip`. Licensing/source deployment
requirements are in NOTICE and third_party/OpenFrontIO. A public source URL has
not been fabricated or hosted.
