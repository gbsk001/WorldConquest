# Stage 3 connectivity and terrain completion report — 2026-11-18

The missing encirclement, connectivity and diagonal-pinch code is now implemented
and active in the Rojo project. Stage 1–3 automated regressions pass. The Stage 3
**live Roblox acceptance gate remains open**: this pass did not run live Studio
clients or measure Roblox network/GPU/device performance. Stage 4 is not started.
This report supersedes the missing-connectivity/elevation sections of the November
17 report; it does not claim complete OpenFront game or World-map parity.

## Implemented code and original source

Pinned upstream: `8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94`,
https://github.com/openfrontio/OpenFrontIO. Existing combat constants are unchanged.

| File | Implementation / source mapping |
| --- | --- |
| `src/server/OpenFront/Connectivity.luau` (new) | `packages/engine/src/execution/PlayerExecution.ts`: calculateClusters, floodFillWithGen, floodComponent/seedSpan, floodTerritoryAreas, sovereign ranking, surroundedBySamePlayer, classifyCluster, removeCluster, markRejectedComponent, isEnclosed, getCapturingPlayer, diagonal pinch detection/evaluation, isHoleCluster, checkAndAssignTerritory, ordered secondary and pinch passes |
| Same module, shared traversal scratch | `TileTraversalScratch.ts`: generation stamps, synchronous shared stack, rollover; sparse 4096-entry u32 pages replace two eagerly allocated full-map typed arrays |
| `Simulation.luau` | Source PlayerExecution scheduling: init tick + simpleHash(playerID)%20; analysis when tick-lastCalc>20 or land<100, gated by lastTileChange>=lastCalc. Tracks ownership-change ticks; analysis runs after recruitment in the existing execution order. Captures clear fallout as in GameImpl. |
| `FoundationServer.luau` | Adds ConnectivityMilliseconds and TraversalScratchBytes diagnostics; existing authoritative batched ownership replication retained |
| `EarthTopologyData.luau`, `EarthTerrain.luau` | NOAA elevation classes baked into the existing compressed terrain; exposes ElevationKnown and ElevationHash. Coastline/water topology unchanged; decoded cache remains bounded to 512 KiB. |
| `scripts/prepare_connectivity_oracle.mjs` | Hash-checks pinned source, uses Node's TypeScript erasure on actual PlayerExecution and TileTraversalScratch; no rewritten expected connectivity algorithm |
| `scripts/generate_connectivity_oracle.mjs`, `tests/stage3/connectivity-oracle.json`, `scripts/connectivity_checks.luau` | Actual-source connectivity fixtures and Luau comparison, scheduling, rollover and heavy-load tests |
| `scripts/generate_stage3_oracle.mjs`, `tests/stage3/upstream-oracle.json`, `scripts/stage3_checks.luau` | Extends battle traces to combine actual AttackExecution and PlayerExecution connectivity |
| `scripts/download_elevation.py`, `generate_elevation.py`, `requirements-elevation.txt` | Pinned NOAA download, checked georeferencing, reproducible classification and terrain bake; Python dependencies are build-only |
| `scripts/check_elevation.py`, `elevation_checks.luau`, `data/elevation-manifest.json`, `data/earth-elevation-rle.bin` | Independent verification/provenance of the elevation classes; runtime geographic samples |
| `scripts/check_stage1.py`, `stage2_checks.luau` | Loads new modules/tests in the regression harness; updates terrain status reporting |

Root NOTICE, data/README, source mapping/index, port-plan status and implementation
reports are updated. No GUI layout, click conversion, zoom/pan, spawn selection,
allocation, combat formula or retreat penalty was redesigned.

### Connectivity rules preserved

* Border clusters use the source's eight-neighbour order: NW,W,SW,N,S,NE,E,SE,
  with no longitude wrap. Flood result/capture order is retained.
* Four-way contiguous owned area ranks the sovereign territory; bounding-box area
  and then border count break ties. Inner hole rims do not displace the outer rim.
* A sovereign region must be fully enclosed by one nonfriendly owner to be annexed
  by the sovereign pass. Secondary clusters use their own source classification and
  bounded enclosure checks; open water, clean wilderness and map edges provide escape.
* Captors are selected by largest committed incoming attack among neighbouring
  enemies, otherwise largest bordering count. Strict greater-than comparisons
  preserve first-encounter ties. Friendship excludes captors.
* Pinched clusters are processed by four-way component. The special pinch pass
  requires adjacent fallout, preserves components as large as the primary territory,
  and guards interior hole clusters by eight-way territory membership. Ordinary
  corner contact alone does **not** automatically cause nuclear-severance capture.
* The existing sub-100-cell adjacent-remnant conquest remains separate. No ocean
  jumping, coarse polygons, rounded regions or nonauthoritative ownership were added.
* All passes finish synchronously in deterministic execution order. No CPU cap drops
  claims or changes balance. Sparse scratch is shared once per simulation, not per player.

## Real elevation and explicit data adaptation

Source: NOAA NCEI **ETOPO 2022 v1, 60 arc-second ice-surface elevation**, WGS84,
21600×10800 GeoTIFF, DOI `10.25921/fd45-gt74`. NOAA's
[dataset metadata](https://www.ncei.noaa.gov/access/metadata/landing-page/bin/iso?id=gov.noaa.ngdc.mgg.dem%3Aetopo_2022)
identifies CC0-1.0. The source's SHA-256, URL, date, georeferencing and sampled
locations are in `data/elevation-manifest.json`. The download is pinned and checked.

The DEM is sampled at the centre of each 8192×4096 map cell using the nearest
source sample. The existing Natural Earth land/lake mask remains authoritative:
no water cell becomes land, and no low-lying land is submerged. Ice-surface heights
apply to Antarctica/Greenland. This is not slope classification or survey-grade data.

**Explicit difference from upstream map generation:** upstream consumes blue-channel
values in authored PNGs, not a universal metres-to-terrain formula. The real-DEM
adapter uses <1000 m plains, 1000..<2000 m highland, >=2000 m mountain, stored as
class magnitudes 0/10/20. These thresholds are a documented data choice, **not
claimed original OpenFront constants**. Combat uses the unchanged source class
modifiers: plains (80,16.5), highland (100,20), mountain (120,25). The same classification
feeds both neutral and enemy frontier priorities/costs. No impassable mountain
mechanic was invented. Matching the original World artwork's classifications is
not claimed; its projection, raster scale and artist-authored inputs differ.

Land classes: 6,629,176 plains; 1,677,294 highland; 2,708,270 mountain cells.
All 33,554,432 cells are independently decoded/hashed. The land mask hash is unchanged.
Final compressed terrain is 7,845,230 bytes; no second overlay decode occurs at runtime.
The 816,992-byte class RLE is a provenance/test artifact outside the Rojo source tree.
No uploaded asset, manual map import, runtime HTTP request, 3D terrain or extra GUI
per cell is required. Terrain class changes gameplay costs; the existing map colour
presentation remains unchanged.

Rebuild data (only when changing/reproducing assets): install the pinned build-only
packages with `python -m pip install --target build/pythonlibs -r scripts/requirements-elevation.txt`,
run `python scripts/download_elevation.py`, then `python scripts/generate_elevation.py`.
If regenerating all geography, run generate_earth, then generate_topology, **then**
generate_elevation: topology alone deliberately produces the base without elevation.

## Automated results — passed

```
python scripts/check_topology.py
python scripts/check_elevation.py
python scripts/check_stage3.py
python scripts/check_luau.py
rojo build default.project.json -o build/WorldConquest-stage3.rbxlx
```

Transcript: `build/stage3-results.txt`; Rojo artifact: `build/WorldConquest-stage3.rbxlx`.

* 310 actual upstream connectivity scenarios: 10 targeted geometries and 300 seeded
  small maps. Exact cluster membership/order, pinch flags, capturing owner, capture
  order, final ownership and sovereign bounds match. Targets include one-cell clean
  escapes, nuclear and clean diagonals, hole rims, friendly enclosure, competing
  captors, shoreline escape, nonwrapping edges and winding shapes. These execute
  the original source against data adapters; this is not a claim to run the entire
  upstream Vitest suite.
* 117 combat formula cases and **1,040 exact battle ticks** (16 traces). Eight traces
  retain direct combat coverage; eight additionally run actual source connectivity
  between attack execution and new orders. Cases include simultaneous attackers,
  counterattacks, army cancellation/merge, retreat, conquest and isolated islands.
* Actual scheduler integration: ownership-change gating, deterministic replay,
  enclosure elimination and u32 generation rollover. Core multiplayer tests cover
  invalid/self/friendly/nonadjacent/water/NaN/immunity orders and replica ownership.
* Production RemoteEvent adapter with two simulated Earth clients: authentication,
  private HUDs, enemy capture, cancellation, bounded fragments, identical ownership,
  disconnect cleanup. These use service stubs, not Roblox Studio networking.
* All Stage 1/2 source parity and spawn/recruitment/neutral-expansion regressions;
  1,184 coordinate round trips, exact-cell rendering and tile upload/recovery tests.
* Full terrain/elevation hashes, unchanged ocean/lake mask, class counts, and live
  EarthTerrain samples in Himalaya/Tibet/Andes/Rockies/Netherlands/Africa/Pacific.

To regenerate source oracles with a Node runtime exposing
`node:module.stripTypeScriptTypes`: prepare the existing Stage 1/2 oracle first,
then run prepare_connectivity_oracle.mjs, generate_connectivity_oracle.mjs, and
finally generate_stage3_oracle.mjs. Normal Luau tests use the checked-in JSON and
need no Node installation or NOAA download.

## Performance and remaining limits

Local official Luau CLI timings; excludes Roblox GPU, transport, device variation,
serialization overhead and client paint latency. These are measured workloads,
not guarantees for a supported player count.

| Workload | Mean / p95 / max |
| --- | --- |
| 100 humans, 50 attacking fronts, 180,000 initial cells, 240 ticks; recruitment AND scheduled connectivity | **3.543 / 10.564 / 17.372 ms per tick** |
| 32 players on real Earth with baked elevation, 120 ticks | **13.574 / 31.897 / 44.019 ms per tick** |
| 100-player neutral regression, 300 ticks | **11.910 / 61.493 / 87.738 ms per tick** |
| Adversarial 262,000-cell owned region with an interior hole | **150.739 ms for one connectivity pass** |

Heavy combat: 43,150 captures; connectivity CPU 181.1 ms summed over 240 ticks;
2,457,600 bytes packed ownership; 4,915,200 bytes shared scratch; raw deltas
1,079 bytes/tick average and 5,400 maximum. At 10 Hz this is approximately 10.8 KB/s
per recipient before HUD/transport overhead, or 1.08 MB/s aggregate for 100 recipients.
Cumulative test-process Lua heap was 88,408 KiB at the end; this includes earlier
fixtures and GC effects and is not isolated Roblox memory. The adversarial pass used
8,388,608 scratch bytes.

**Large enclosed/holey territories can stall a 100 ms simulation tick.** This is
an outstanding performance limit, not a hidden cap or a passing performance gate.
Further optimisation must preserve traversal, mutation and tick ordering; blindly
splitting a pass across independently advancing ticks changes gameplay. No whole
33.6-million-cell scan runs each tick, but source area floods can traverse an entire
changed player's territory. Table-backed owner sets and frontier heaps remain memory
risks at millions of occupied cells. At the extreme, both shared sparse scratch arrays
can reach about 256 MiB together if every world page is touched, plus other state.

The source-related implementation gap from November 17 is closed. Acceptance is
still conditional on the manual checks below and an explicitly chosen supported
load/device budget. The higher Earth/neutral p95 values and adversarial stall mean
we cannot claim the plan's proposed universal <20 ms p95 target is met.

## Manual Roblox Studio multiplayer acceptance — NOT YET RUN

Use a private local test, not a production publication. Record pass/fail, Output
errors, approximate server ticks/backlog and client memory/network for each row.
Do not mark Stage 3 live-accepted until these observations exist.

1. Stop all test windows. Sync the existing Rojo connection, or open the built
   `build/WorldConquest-stage3.rbxlx`. In Shared/Config confirm Foundation mode and
   PortStage=3. Confirm OpenFront/Connectivity exists and EarthTopologyData has
   ElevationKnown=true. Leave the existing EditableImage permissions enabled.
2. In Studio's Test dropdown select **Server & Clients**, set **2 clients**, start.
   [Official test-mode instructions](https://create.roblox.com/docs/studio/testing-modes).
   Open Output on server and clients. Confirm both see the same Earth and countdown.
3. Within 20 seconds choose nearby inland central-African spawns, roughly 15–25 tiny
   cells apart. Zoom in fully to distinguish cells. Move each spawn before the
   deadline; the marker must stay under the clicked point, including after panning.
   Both players start on the same server tick. The first five seconds of enemy
   immunity must reject attacks without removing soldiers.
4. Allocate 20–50%, click neutral land in each window and wait for colours to touch.
   Click enemy colour after immunity. Pass: committed soldiers leave reserve;
   defender loses soldiers and cells; both clients show the same exact square border;
   no capture crosses a lake/ocean or occurs ahead of the shared frontier.
5. In the second client attack back while the first attack is active. Pass: opposing
   committed armies net out; no free refund appears. Repeat an attack against the
   same target to check merging. With a fresh **3-client** run, attack the same
   defender from both sides: both fronts must agree across all clients without
   overlapping ownership or resurrecting a depleted attack.
6. Select an active enemy attack and press Stop / return. Pass: that frontier stops;
   after its init+20-tick retreat deadline and following attack execution, surviving
   troops return with the 25% penalty/flooring. Neutral retreat has no 25% penalty.
   Other-target attacks continue. Repeat stop/merge near the deadline; no double refund.
7. In a **3-client** run form a large closed pocket around a defender with >100 cells
   remaining (below 100 tests the separate remnant rule). Keep a one-cell clean
   escape until the final closure. Pass: open pocket survives; after closure and
   the next eligible change-gated cluster check (~2 seconds, not necessarily
   immediately), an eligible captor gets it consistently on all clients. A coastal
   escape must survive. A sovereign enclosure touching multiple enemy owners does
   not use the single-enemy sovereign shortcut. The reproducible exact narrow-corridor,
   tie, hole-rim and diagonal geometries are covered by the automated fixture suite;
   manually arranging them through the all-frontier attack UI is not a substitute
   for those tests. Fallout pinches are fixture-only because nuclear creation is
   deliberately absent from Stage 3; do not add a nuke mechanic just to test them.
8. Conquer a weak defender to zero. Pass: eliminated/spectating label, growth stopped,
   new orders rejected, no resurrection. Test a separate-island remnant: normal
   expansion/remnant cleanup must not cross open water to take it.
9. Stop and repeat with **4 clients**. Have one attacker disconnect mid-fight; existing
   Roblox disconnect behaviour releases their land. Join another client after match
   start: it spectates and receives an atomic snapshot. Pass: existing clients stay
   in agreement; no unknown-owner errors, stale coloured cells or huge frame spikes
   on snapshot completion. Exercise pan/zoom and resize while captures occur.
10. Server Explorer: select ReplicatedStorage/WorldConquestEvent. Record
    TickMilliseconds, ConnectivityMilliseconds, TickBacklogSeconds, ActiveAttacks,
    CombatCellsClaimed, FrontierPops, DeltaBytes, OwnershipBytes, TraversalScratchBytes,
    LuaHeapKiB. In MicroProfiler inspect WorldConquest.FoundationTick. Use client
    Developer Console for memory/network and observe paint backlog. Compare 2 and 4
    clients; deliberately dense/holey borders must be profiled before approving a
    larger match limit. Stop all sessions to reset between cases.

## Scope, licensing and honest limits

No economy, buildings, naval mechanics or Stage 4 work was introduced. Existing
combat/casualties/retreat/conquest/elimination and server authority remain intact.
Pinch algorithms support fallout state for parity, but this does not enable nuclear
weapons. Upstream economy/unit-transfer/diplomacy side effects remain their later
stages. The lobby is still human FFA; disconnect releases land as before. This is
not full browser-network/lobby parity.

Natural Earth remains public domain; NOAA ETOPO classes are CC0 with provenance.
No restricted OpenFront imagery was copied. AGPL-3.0 notices, the pinned source
attribution and visible OpenFront credit remain. Keep the actual corresponding
server/client/build/data source available under the preserved terms when serving
remote users; Config.SourceURL is still unconfigured and this work does not publish
an experience or host its source. The source code and regeneration scripts are part
of that offer; upstream-only links are insufficient. See LICENSE and NOTICE.
