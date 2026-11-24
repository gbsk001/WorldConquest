# Scalability acceptance — 24 November 2026

Status: partial optimisation, **not acceptance for hundreds of production participants**. Public `SafeParticipants` remains 20; the 250 target and 500 experimental ceiling are not production guarantees. The previous one-minute workloads understated later frontier/connectivity and naval costs. No gameplay formulas, ownership resolution, GUI design, AI bonuses or decision cadence were changed.

## Changes

- `WaterPath.luau`, `EarthTerrain.luau`: share immutable terrain pages across the route service; avoid repeated LRU/validation work for every A* edge; skip closed nodes before terrain reads; generate neighbors directly in the same N/S/W/E order. Exact existing float32 heap priorities, tie order, cost rules and search limits remain. Existing exact-route/negative-result cache remains. This reduces search cost but does **not** make it bounded to 100 ms. A hierarchical corridor can change this weighted search's selected route and travel time; it has not been substituted without parity proof.
- `MinHeap.luau`, `Grid.luau`, `Expansion.luau`, `Connectivity.luau`: keep validation on public helpers and use unchecked internal kernels for already validated simulation cells/priorities. Remove a closure allocation per eight-neighbor traversal. Traversal, RNG and ownership ordering remain unchanged.
- `OrderedSet.luau`, `Missiles.luau`: batch tombstone removal; cache affected owners within each impact; replace per-border-cell tables with a flat pair list. Damage formulas, casualty order, blast geometry, fallout and cleanup remain unchanged. These changes have not demonstrated a material reduction in the simultaneous-impact worst tick.
- `Grid.luau`, `Replica.luau`, `FoundationServer.luau`: lossless versioned signed-difference encoding for ordered ownership records, with absolute escapes and uniform-state encoding. Legacy/raw fallback remains. Atomic fragment assembly, round validation and snapshot recovery remain. This reduces application payload bytes; it does not pace all fragments across Heartbeats, remove metadata bursts or establish real Roblox bandwidth.
- `Replica.luau`: after validating a cell reference, validate its terrain with one immutable read rather than three nested `isLand`/`isImpassable` reads. Validation still precedes any ownership writes. `benchmark_replica_validation.py`: 100 batches of 8,192 changes, before → after average 6.494 → 4.053 ms, p95 7.187 → 4.578 ms, worst 7.362 → 4.762 ms, identical final counts/tick. This is interpreted client-handler CPU, not a claimed FPS increase. It does not affect the server simulation benchmark.
- `LobbyStore.luau`: atomically refuse a public Lobby→Game commit while an unexpired human reservation has not arrived. The existing countdown retries; reservations expire or release on failure. Bots only fill the committed roster after humans arrive. No new human claims are accepted once the record is in Game. Private admission rules are unchanged.
- Tests/tooling: `check_wire_codec.py`, `performance_storage_checks.luau`, `lobby_scenarios.luau`, `check_stage10_all.py`, `benchmark_scalability.py`, `benchmark_scalability_hotspots.py`, `stage8_benchmark.luau`, `studio_performance_observer.client.luau`. Observer logging is split to avoid Studio truncating measurement fields.

## Measurement scope

Fresh-process interpreted Luau, real 8192 × 4096 Earth, seed 12345, N−1 active AI plus one observer; 202 selection ticks followed by 1,800 gameplay ticks (180 simulated seconds). This is active expansion/combat/building/naval gameplay, not the synthetic icon renderer. Decision budget remains two decisions per tick, so larger rosters do not all act at the same cadence as a small roster. A single seed and three minutes cannot establish full-match or production capacity.

`build/scalability-before.json` and `build/scalability-after.json` record average/p95/worst ticks, sampled simulation heap, ordered raw delta volume, estimated metadata and component times. These are not GPU/FPS or actual wire-bandwidth measurements. Full-grid digest generation occurs after timed gameplay. A brief regression process overlapped the initial 500 baseline; do not infer a precise speedup from that row without a controlled repeat.

## Correctness and manual acceptance

`python scripts/check_stage10_all.py` passes Stage 1–11 functional regressions. New checks cover 500 exact wire round trips, malformed/truncated encodings, uniform/mixed/scattered updates, duplicate bulk deletions and human reservations at roster commit. Existing tests cover missile/SAM/MIRV, regeneration, ownership, deterministic replay, spawn reservations, recovery, results/restart and GUI adapters. Automated GUI/API stubs are not rendered or production-service tests.

For Studio, open **`build/WorldConquest-stage10.rbxlx`**. The root `WorldConquest.rbxlx` is an older November 17 prototype. `scripts/package_stage10.py` verifies all current embedded sources and Stage 11 enablement; Stage 8 remains included. Use the disposable `WorldConquest-performance-play.rbxlx` observer fixture for frame/server logs; it is not the release artifact.

Acceptance checklist:

- Start Server and Clients with at least two clients, join the same public lobby, verify humans reduce AI fill, and test a reservation arriving during countdown.
- Verify both clients see spawn changes/overlap rejection and the same countdown start, names, colours, crowns and leaderboard.
- Play through expansion/combat/buildings/naval routes; pan and zoom over actively changing territory at maximum detail. Capture MicroProfiler and frame distributions after several minutes, not just startup.
- Fire simultaneous atom/hydrogen/MIRV salvos into occupied terrain with SAMs and buildings; verify casualty/fallout/cleanup parity and network catch-up without a visible partial tick.
- Disconnect/rejoin during an impact burst, complete victory/results and return/restart; verify stale round packets cannot modify the new match.
- Test mobile rendering/memory and actual published Roblox servers separately. Measure real transport under several human receivers; localhost/Play Solo traffic does not certify that load.

## Actual Studio observations

Ran Studio **Server and Clients** with one local server and two separate client windows, 18 AI and two humans (20 total). Observed the second human displacing an AI lobby slot, shared spawn markers, ocean rejection, automatic match start, active expansion/combat, elimination, generated names, transparent labels, crowns, graphical building icons, the live/closable leaderboard, allocation slider and Leave Match returning to the menu. Zoom transforms responded and high-detail coastlines appeared after the existing budgeted tile painting caught up. This is a local Studio test, not published Roblox matchmaking or a full-match/restart certification.

This two-client run preceded the final one-read terrain-validation reduction in `Replica.luau`. The final reduction is separately covered by the client CPU comparison and the rerun full regression suite; do not attribute the following FPS to that last change. The final rebuilt sources passed a separate rendered Play Solo smoke check: menu, 20-participant public lobby, transition to gameplay, leaderboard/crowns and authoritative expansion. The final fixture was verified against all 69 current source files; see `build/studio-performance-preview-2026-11-24.json` and `build/scalability-studio-final-smoke.txt`.

- Foreground late ten-second samples (observer elapsed 150–220 s): **53.02–59.89 FPS**, maximum window p95 **54.468 ms**, worst frame **73.495 ms**. Earlier quiet windows reached 60 FPS. The unfocused second client was visibly throttled to approximately 15 FPS; those samples are not gameplay-capacity evidence.
- Server replicated diagnostic maxima: rolling average **21.742 ms**, rolling p95 **49.290 ms**, worst **81.699 ms**; sampled server Luau heap **153.27 MiB**. This local 20-participant run does not certify longer matches or other seeds.
- Client startup **2.505 s / 2.305 s** for the two clients. First client's recorded total-memory high-water was **1,489.8 MiB**, including Studio/engine/native allocations, not just the simulation. Separate raw observations are in `build/scalability-studio-2D289.txt`, `scalability-studio-34763.txt`, and `scalability-studio-summary.json`.
- MicroProfiler timer view showed `Network/ProcessPacket` about **0.96 ms average / 15.16 ms maximum** in the inspected aggregation and foreground runtime threads up to **15.85 ms**. Observed tile paint worst **4.207 ms**, upload worst **0.374 ms**, roster render worst **2.659 ms**. These maxima come from different windows and must not be summed as one frame.
- The observer's Roblox `Stats` receive counter returned zero despite active replication; send values were small localhost values. This instrumentation does **not** provide credible production receive bandwidth. Use application-byte tables for this pass and capture live transport separately.

The discrepancy with the synthetic renderer is therefore real: active replication, simulation and changing territories add work absent from static/icon workloads. Separate clients improve isolation but do not eliminate hitches. Packet handling is a measured contributor; the exact contribution of scheduling, garbage collection and all GUI callbacks is not fully isolated. No measured final-build FPS uplift is claimed from the last client CPU optimisation.

## Remaining blockers

Long naval searches remain synchronous; frontier/connectivity cost grows with occupied land; simultaneous impacts remain above budget in stress cases. Route scratch and active territories still consume substantial memory. Compression adds CPU cost and does not bound total replicated bytes per Heartbeat. Full-match soak, multiple seeds, separate-process client profiling and real multi-client network acceptance are required before any capacity increase.

The previous synthetic 500-icon 60 FPS result excluded server simulation and representative territory traffic. It cannot contradict or supersede the observed lower FPS in real 20-participant gameplay. Separate-client testing below narrows the issue: shared-process contention is not the sole explanation, and packet processing plus active territory work remain relevant.

Original AGPL notices and LICENSE/NOTICE are preserved; no new third-party assets were introduced. `Config.SourceURL` remains blank: hosting the complete corresponding source and configuring its in-game link remains a publication blocker, along with live matchmaking/teleport/recovery and mobile acceptance.

## Active gameplay measurements

| Participants | Before avg / p95 / worst ms | After avg / p95 / worst ms | Peak heap MiB before → after |
|---:|---:|---:|---:|
| 50 | 29.06 / 70.88 / 1394.85 | 28.67 / 70.05 / 1059.68 | 471.1 → 397.6 |
| 100 | 56.93 / 133.18 / 1364.66 | 57.31 / 130.57 / 1268.17 | 698.4 → 630.9 |
| 200 | 90.17 / 205.09 / 1415.75 | 85.77 / 191.75 / 1010.55 | 994.8 → 924.2 |
| 250 | 94.66 / 199.01 / 2459.56 | 89.73 / 186.72 / 1946.53 | 1075.4 → 1025.7 |
| 500 | 121.11 / 267.21 / 396.33 | 102.43 / 207.87 / 269.86 | 1353.0 → 1304.9 |

All five before/after replay digests, raw delta bytes, decisions, orders and metadata estimates agree. These runs do not pass a strict 100 ms worst-tick gate. Heap is sampled Luau heap, not total server process memory.

| Participants | Raw delta MiB / 180 s | Peak raw delta KiB / tick | Estimated metadata MiB (including selection) |
|---:|---:|---:|---:|
| 50 | 20.75 | 36.00 | 7.04 |
| 100 | 40.11 | 59.81 | 17.37 |
| 200 | 56.85 | 118.22 | 48.66 |
| 250 | 62.39 | 96.39 | 63.35 |
| 500 | 75.45 | 156.98 | 153.38 |

Raw volume excludes RemoteEvent framing, compression, Roblox transport and receiver fan-out. Metadata is a structural estimate, not serialized packet capture. Native multi-client wire measurements are still required.

## Focused path and impact measurements

| Route start → destination | Before ms | After ms | Result |
|---|---:|---:|---|
| 30427171 → 31393958 | 1602.17 | 991.94 | 1998 cells; identical hash 1646193824 |
| 30533944 → 31393958 | 1335.88 | 835.55 | 1834 cells; identical hash 2195548584 |
| 30427171 → 31287487 | 1507.01 | 985.11 | 1950 cells; identical hash 3008209974 |
| 5488371 → 3849972 | 2815.57 | 1850.37 | -1 cells; identical hash 0 |

These are isolated raw queries (single start, cold then shared-cache searches). A -1 result reaches the unchanged search cap. They are not identical to every multi-start route in active gameplay. No sub-100-ms bound is claimed.

| Salvo / participants | Worst simulation ms before → after | Worst including encoding ms before → after | Peak encoded application bytes before → after |
|---|---:|---:|---:|
| salvo50 | 70.10 → 70.34 | 71.24 → 73.52 | 447936 → 288244 |
| salvo100 | 120.85 → 121.72 | 122.04 → 125.04 | 885144 → 571128 |
| flat50 | 59.81 → 56.28 | 63.95 → 69.55 | 662172 → 402772 |
| flat100 | 119.51 → 106.74 | 127.83 → 129.73 | 1420052 → 858430 |

`salvo` uses actual Earth and `flat` the original all-land stress geometry. Identical final state, ordered border/territory, troops, impact timing and raw bytes are verified. Encoding CPU is additional to simulation; smaller payloads do not prove lower Roblox wire traffic or a faster simulation.
