# Stage 7: multiplayer performance and reliability — 2026-11-20

**Implemented in Rojo; automated checks pass; the full Stage 7 acceptance gate is NOT complete.**
The default is `PortStage=7`. Gameplay remains the implemented Stages 1–6. Stage 6
was verified in source and tested, including ships, ports, naval combat and trade.
The grid remains **8192 × 4096**. No claim budgets, troop formulas, execution order,
ownership resolution or movement speeds were changed. Stage 8 was not started.

The source reference remains [OpenFrontIO at the existing pinned revision](https://github.com/openfrontio/OpenFrontIO/tree/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94).
The local pinned checkout and existing upstream oracle fixtures were used; this
work does not silently upgrade to current upstream gameplay. AGPL copyright,
LICENSE and visible attribution remain. NOTICE records these modifications.

## Implemented changes and changed runtime files

| Files | Change and correctness constraint |
|---|---|
| `src/shared/OpenFront/Grid.luau` | Packed owner reads, horizontal owned-run scanning and read-only page access for traversal. Copy-on-write snapshot pages; client grids omit dirty tracking; validated empty snapshot chunks install in one pass. Large drained dirty tables are released instead of retaining peak capacity. |
| `src/server/OpenFront/Connectivity.luau` | Scanline marking and seed scans operate directly on packed pages. Retains scan order, fallout checks, generation rollover, pinch/hole rules, captor selection and original transfer order. |
| `src/server/OpenFront/RailPath.luau`, `Rail.luau` | After 1,024 A* pops, difficult station connections receive a bounded necessary-condition reachability check using the **existing** `<110*1.4142` node acceptance gate. If no short-enough path exists, reject. Otherwise resume original A*, with identical costs, ties and iteration limit. Easy routes avoid precheck overhead. General `Path.land` calls without the gate remain unchanged. |
| `src/server/OpenFront/Expansion.luau` | Read each neighbour's terrain byte once during frontier insertion; preserve duplicate heap entries, random draws and ordering. Add frontier/combat execution CPU measurement. |
| `src/server/OpenFront/OrderedSet.luau`, `Simulation.luau` | Short-circuit shared-border lookup; clear departing sets; release a disconnected owner's cells in the original order without redundant border reconstruction. Other owners' bordering cells remain borders when an enemy-owned neighbour becomes neutral. No tick splitting or dropped ownership mutations. |
| `src/server/OpenFront/FoundationServer.luau` | Share snapshot buffers among same-tick joins, copy only subsequently mutated pages, admit at most four active transfers, send at most 32 KiB/client/heartbeat, suppress redundant Sync restarts. Reuse complete delta buffers and an empty buffer instead of copying every small packet. Route results directly by authenticated user ID. Add rolling mean/p95 and lifetime-worst tick telemetry. |
| `src/shared/OpenFront/Replica.luau` | Validate fragment shape before buffering; cap snapshot catch-up at **16 MiB of binary payload or 2,048 ticks**. Preserve atomic snapshot/tick installation and rollback on gaps; resync on overflow. The longer tick window accommodates large low-churn snapshots that outlast the previous 25.6-second window. |
| `src/client/IconLayer.luau` (new), `MapView.luau` | Instantiate labels only for visible units, reuse at most 128 pooled labels per layer, cache unchanged properties, skip stationary frames and release deleted units. Keep every unit in replica data and preserve hit-test list ordering. No object per cell. |
| `src/client/MapTiles.luau`, `MapView.luau` | One tile-pool invalidation walk per changed cell covers the cell and border-shading neighbours, replacing five walks. Paint slices and the one-upload-per-frame limit remain. Expose paint/upload/queue/icon measurements on the Earth canvas. |
| `src/client/Main.client.luau` | Fix building-only deltas failing to refresh icons without metadata; avoid rewriting the Foundation phase label on every rendered frame. Legacy countdown updates are retained. |
| `src/shared/Config.luau` | Enable the Stage 7 adapters. Existing legacy prototype budgets apply only to Legacy mode, not Foundation gameplay. |

New tests/runners: `scripts/check_stage7.py`, `check_stage7_all.py`,
`stage7_checks.luau`, `stage7_memory_checks.luau`, `stage7_recovery_checks.luau`,
`stage7_server_checks.luau`, and `tests/stage7/baseline-digests.json`.
Updated tests: `scripts/tile_checks.luau`, `profile_rail_limit.py`.
Documentation changes: this report, README, OPENFRONT_PORT_PLAN and NOTICE.

## Measurements and methodology

All numbers below are **local standalone Luau CPU measurements on this Windows
machine**, not real Studio servers, real network clients or mobile/GPU results.
Suites run sequentially. p95 is the sorted 95th-percentile sample, not an average
of per-player values. Runtime timing never changes simulation outcomes.

The pre-change source is retained locally in `build/stage7-baseline/src`.
`python scripts/check_stage7.py --baseline` runs the same match fixtures against
it. Stage 1–6 baseline logs are alongside that source. The baseline source is a
local comparison artifact, not a dependency of normal regression checks.

Each mixed fixture uses the full grid dimensions, synthetic flat land with an
ocean band, **N simulated humans, N/2 combat fronts, 1,800 initial combat cells
per player, two purchased rail buildings and one seeded warship per player**.
Recruitment, economy, connectivity, rail, naval execution and packet packing run
for 300 ticks. A player disconnects and rejoins as spectator. One verification
replica and one delayed late-join replica apply the actual packets; they are not
N real network connections. Setup orders are measured separately. Ship seeding
is test setup, not an alternate production purchase API.

| Simulated players | Before mean / p95 / worst (ms) | After mean / p95 / worst (ms) |
|---:|---:|---:|
| 2 | 0.138 / 0.314 / 2.487 | 0.094 / 0.295 / 1.750 |
| 10 | 0.608 / 2.180 / 4.763 | 0.443 / 1.179 / 4.909 |
| 20 | 1.220 / 4.015 / 10.226 | 0.857 / 2.191 / 9.968 |
| 50 | 3.270 / 8.521 / 24.594 | 2.259 / 5.542 / 30.111 |
| 100 | 6.551 / 16.810 / 50.560 | 4.588 / 11.445 / 47.405 |

The five before/after rolling digests match for ownership, building and ship
packets plus all present players' gold and troop values. Separate upstream
oracle suites compare exact traces and capture order, rather than relying only
on these compact digests. At 100 simulated players the fixture produces 29,450
captures and 56,750 frontier pops; these totals also match the baseline.

| Bottleneck/workload | Before | After / interpretation |
|---|---:|---:|
| Original 262,000-cell interior-hole connectivity fixture | 153.3 ms | About 32–34 ms |
| Additional interior-hole fixture spanning a 4,096-cell page boundary | 139.9 ms | About 34 ms |
| Unreachable production rail connection, full-size ocean-strip geometry | 729.7 ms in matched run; 760.5 ms in isolated baseline (previous report: 783 ms) | About 6.4 ms; rejected by the existing length gate |
| Atomic departure releasing 262,000 cells | 548.3 ms | About 91 ms; exact 1,572,000-byte ownership delta order verified |
| Synchronized Stage 2 expansion, 100 players/300 ticks: mean / p95 / worst | 11.85 / 61.38 / 85.53 ms | 9.54 / 48.76 / 69.32 ms; limited p95 headroom |
| 32-player real Earth terrain, Stage 2: mean / p95 / worst | 13.62 / 33.12 / 36.00 ms | 12.60 / 29.07 / 32.18 ms |
| 50 factories + 50 cities / 1,000 ticks, rail fixture | 0.220 ms mean; 16.46 ms worst | About 0.24 ms mean; 11–13 ms worst; no claimed mean speedup |
| 10,000 ownership changes, visible-tile invalidation | About 8.7 ms, five walks | About 2.3 ms, combined walk; extra corner pixels may repaint |
| 10,000-unit icon visibility scan | No visibility-based object allocation | About 0.9 ms pure CPU; stationary updates skipped; GUI/GPU cost unmeasured |

Naval routing was profiled, not replaced: four real Earth routes take roughly
1.5–23 ms on first search and 0.02–0.25 ms cached. The dense 100-warship combat
fixture is about 3.2–3.3 ms mean, 5.4–5.9 ms p95 and 11–12 ms worst, with up to
294 ships/shells. A raw disconnected-water A* test deliberately bypassing the
normal component rejection still takes **about 293–309 ms**. Connected difficult
routes can also be expensive. Preserving route outcomes means not inventing a
smaller search cap or cancelling routes based on wall-clock time.

## Memory, replication and practical capacity

The isolated grid-memory suite writes and drains 1,048,576, 4,194,304 and
8,388,608 cells. It exercises production Grid storage, not complete matches with
that many entries in player tile sets.

| Owned cells | Packed ownership | One full changed-cell delta | Write / pack CPU | Shared snapshot capture |
|---:|---:|---:|---:|---:|
| 1,048,576 | 2 MiB | 6 MiB | 274 / 26 ms | 0.04 ms |
| 4,194,304 | 8 MiB | 24 MiB | 1,097 / 101 ms | 0.13 ms |
| 8,388,608 | 16 MiB | 48 MiB | 2,215 / 199 ms | 0.28 ms |

The snapshot test shares one immutable page list among 100 references and proves
that later writes do not mutate it; it does **not** simulate sending 100 snapshots
over Roblox. Runtime admits four active transfers, and network serialization may
still copy buffers. `gcinfo()` reaches about **347,000 KiB** in the sequential
grid-memory process. That includes loaded fixtures, dirty tables, delta buffers
and uncollected earlier cases; it is neither isolated live memory nor a mobile
memory guarantee. Full simulation also stores ordered per-player tile/border
sets. The 100-player mixed fixture uses about 2.54 MB packed grid and 5.08 MB
traversal pages; its process heap includes verification replicas and fixtures.

At 100 simulated players, binary deltas average **3,986 B/tick** and peak at
14,300 B/tick: approximately **39.9 KB/s per recipient**, or **4.0 MB/s for 100
recipients**, before metadata, private HUDs, transport overhead and compression.
The synchronized expansion fixture averages 7,006 B/tick and peaks at 52,200 B.
Fragments stay within 24,192 binary payload bytes for Stage 6/7, and each tick
remains atomic at the receiver. Fragmentation does not reduce total fan-out.
The 262,000-cell departure still means 1.57 MB per recipient, about 157 MB for
100 recipients; pacing those large delta bursts is an unresolved issue.

The CPU results make **20, 50 and 100 simulated players plausible for these
specific small-territory workloads**. They do not establish a supported live
player limit. Start real validation with 2, then 10 and 20 clients; approve 50 or
100 only after actual bandwidth, device memory, frame time and long-match tests.
No admission cap or gameplay slowdown has been hidden in the rules.

## RemoteEvent/security and recovery audit

- The Roblox-supplied Player object must be connected. Payload user IDs, prices,
  ownership, reserves, paths and combat results do not establish authority.
- Explicit action/type allowlists, finite in-bounds coordinates, integer order
  sequences/unit IDs, allocation bounds and stage/phase checks precede enqueue.
  Unknown actions and malformed values are rejected. The existing shared action
  cooldown is 0.12 seconds and Sync cooldown is 2 seconds.
- Server economy/building/naval handlers revalidate alive/spectator state,
  ownership, funds, caps, port/coast/route requirements and idempotent sequences
  when executing. Server-only grant/purchase hooks are not exposed as remotes.
- A 10-client service-stub test sends 1,000 Sync attempts and observes exactly
  10 snapshots, at most four active transfers and at most 32 KiB/client/frame.
  Forged Player objects, unknown grants, tables/strings/NaN/infinities and invalid
  order IDs are covered. Existing Stage 3–6 tests cover cross-owner orders,
  duplicate payments, private HUD routing and actual combat/building/naval orders.
- Snapshot pages are immutable across server writes. Duplicate pages, missing
  ticks, malformed fragments, interrupted snapshot rollback, tick/byte catch-up
  overflow and successful later resync are tested. Binary queue memory is bounded;
  metadata/table overhead is additional. Rejoins preserve the existing spectator
  policy; persistent restoration of a departed empire is not implemented.

This is a source/standalone adapter audit, not a penetration test of Roblox's
transport. Client-side limits are defensive reliability measures, not server
authorization. Large accepted legitimate workloads can still exhaust time or
network budget.

## Validation and reproducibility

```powershell
python scripts/check_stage7_all.py
python scripts/profile_rail_limit.py
rojo build default.project.json -o build/WorldConquest-stage7.rbxlx
```

All passed. The aggregate runner includes Stage 1–5 through `check_stage5.py`,
Stage 6, all-source compilation, renderer/coordinate checks, the five Stage 7
loads, deterministic baseline digests, recovery/security tests and memory stress.
The connectivity suite covers 310 upstream cases and generation rollover;
rail covers 200 exact upstream paths, 7,000 execution ticks plus 160 additional
guarded-path comparisons; naval covers 4,810 execution ticks and 450 water paths.
The renderer checks cover 1,184 coordinate round trips, in-flight dirty updates,
cancelled tile jobs, combined invalidation and icon culling/pool cleanup.

Logs: `build/stage7-before-results.txt`, `stage7-after-results.txt`,
`stage7-memory-results.txt`, `stage5-results.txt`, `stage6-results.txt`, and
`check_*-stage7-final.txt`. The catch-up window was subsequently extended to
2,048 ticks; the affected Stage 6 and Stage 7 suites were rerun successfully.
`profile_rail_limit.py --raw` intentionally measures the original ungated A*.

## Remaining major issues / acceptance not complete

1. Difficult connected naval searches, large simultaneous connectivity passes,
   mass departures and whole-world mutations are synchronous. The tested stalls
   improved; **worst-case <100 ms is not guaranteed**. Eight-million-cell bulk
   writes/packing explicitly exceed it. A resumable deterministic logical tick
   scheduler would be substantial further work; arbitrary work-dropping is not a fix.
2. Large delta bursts are still broadcast in a tick. They need real transport
   measurements and potentially paced ordered transmission/compact encoding.
   Snapshot catch-up can still overflow under sustained churn or very slow
   connections; retry is safe but eventual catch-up is not guaranteed.
3. Full-world player-set and traversal memory, long-session GC, 50/100-client
   serialization, and disconnected/rejoining churn are not live-qualified.
4. Visible-only icons reduce hidden GUI objects, but a Fit view can show every
   unit. Large visible fleets can still be expensive. Desktop 60 FPS and mobile
   30 FPS are targets, **not measured outcomes**. No physical mobile device,
   real Studio multiplayer session or published server was tested here.
5. Existing Stage 6 terrain/routing differences remain documented in its report.
   Source hosting is still unconfigured; this work does not publish the game.

## Studio acceptance steps

1. Stop Play; sync `rojo serve default.project.json`, or open
   `build/WorldConquest-stage7.rbxlx`. The root `WorldConquest.rbxlx` is the older
   place and was not overwritten. Confirm `PortStage=7` and map/image APIs work.
2. Start **Server & Clients with 2 clients**. Check Outputs, spawn selection,
   troop allocation, opposing land attacks, retreat, buildings and rail income.
   Repeat the Stage 6 transport/warship/repair tests; use **3 clients for piracy**.
   A temporary local starting-gold override can speed testing; restore it afterwards.
3. Join while ownership and ships change, disconnect an active large owner,
   rejoin as spectator, and trigger repeated Sync requests in a local test.
   Check matching owners/counts, no duplicate ships/buildings, no second charges,
   correct refunds, and eventual snapshot completion. Deliberately test slow delivery.
4. Inspect server `ReplicatedStorage.WorldConquestEvent` attributes:
   `TickAverageMilliseconds`, `TickP95Milliseconds` (last 300 ticks),
   `TickWorstMilliseconds` (lifetime), `TickBacklogSeconds`, subsystem milliseconds,
   `OwnershipBytes`, `TraversalScratchBytes`, `LuaHeapKiB`,
   `UnitAndOwnershipDeltaBytes`, `DeltaFragments` and `SnapshotTransfers`.
   Use MicroProfiler's `WorldConquest.FoundationTick` plus Developer Console
   network/memory statistics; stored buffer bytes are not actual network traffic.
5. On each client inspect the **Earth canvas attributes**: paint/upload times and
   maxima, upload bytes, dirty visible tile count, paint-job age, tile object count,
   icon time and visible/pooled icon counts. Pan, Fit, zoom to exact cells, resize,
   hide/show shops, create/delete/capture buildings and follow fast ship movement.
   Verify building-only updates render immediately and map clicks remain aligned.
6. Measure desktop and a physical low-end mobile device. Test continuous dirty
   fronts and dense fleets while panning; verify tile queues settle, memory does
   not climb indefinitely, and controls remain usable. CPU upload timing is not GPU time.
7. Repeat long runs at **10, 20, 50 and 100 actual clients** where tooling permits,
   recording configuration and territory/unit counts. Increase complexity only
   after lower loads pass. Require mean <20 ms, p95 <50 ms, worst <100 ms without
   sustained backlog, plus measured desktop/mobile frame targets, before signing
   off a capacity tier. Keep this gate open when any major issue remains.
