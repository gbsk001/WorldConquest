# Stage 2: recruitment and neutral expansion

**Fidelity update:** [OPENFRONT_PORT_MAPPING.md](OPENFRONT_PORT_MAPPING.md) records
the current implementation. It supersedes this report's centre reservations,
end-of-phase-only spawning, human-only rule functions, fallback search, five-point
allocation buttons and early termination of missing-attack retreats. Historical
benchmark results below remain measurements of the earlier revision.

Implemented against OpenFront revision `8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94`.
Stage 3 combat is not implemented. The existing 8192 x 4096 Natural Earth mask,
integer-cell ownership and 100 ms deterministic ticks remain unchanged.

## Files and behaviour

| File | Change |
| --- | --- |
| `src/shared/OpenFront/Troops.luau` | Human reserve cap, regeneration, integer reserve operations and neutral loss/speed formulas |
| `src/server/OpenFront/Expansion.luau` | Neutral AttackExecution, seeded priority heap, duplicate/stale handling, merging, refunds and delayed retreat |
| `src/server/OpenFront/OrderedSet.luau` | Insertion-ordered owner borders; deleted/re-added entries move to end as upstream TileSet requires |
| `src/server/OpenFront/Spawn.luau` | Source radius-4 BFS footprint, shifted centre and N/S/W/E ordering |
| `src/server/OpenFront/Simulation.luau` | Player recruitment executions, ordered authoritative expansion/cancel input, incremental border updates, resources |
| `src/server/OpenFront/FoundationServer.luau` | Authenticated/rate-limited ingress, 24 KiB delta fragments, private 5 Hz HUD updates and profiling attributes |
| `src/shared/OpenFront/Grid.luau` | One read/check per ownership mutation, deterministic coalesced dirty list, allocation counter, allocation-free border check |
| `src/shared/OpenFront/Replica.luau` | Atomic multipart tick assembly; existing snapshot recovery preserved |
| `src/client/Main.client.luau` | Soldier/cap/growth/committed HUD, 0–100% allocation in 5% steps, Stop/return, resource updates |
| `src/shared/Config.luau` | PortStage=2 default; Foundation and Legacy modes retained |
| `scripts/check_stage2.py`, `stage2_checks.luau`, `stage2_server_checks.luau` | Production-module oracle, replay, service-adapter, geography and performance tests |
| `scripts/prepare_stage2_oracle.py`, `generate_stage2_oracle.mjs`, `tests/stage2/upstream-oracle.json` | Hash-checked upstream method extraction and independently executed TypeScript reference results |

The existing MapView/MapTransform/MapTiles and EditableImage ownership renderer are
used, with no new per-cell GUI instances, curves, coarse territory grid or blob
geometry. A footprint can look roughly circular because upstream seeds a circle;
every boundary and capture still consists of the exact tiny square cells.

## Exact rules and source references

All links are to the pinned revision; the audit index has additional line links.

- [Config.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine-lib/src/configuration/Config.ts):
  human capacity `M = 2 * (pow(land, 0.6) * 1000 + 50000) + 250000 * completedCityLevels`.
  No cities exist in Stage 2, so that final contribution is zero. Per-tick growth
  is `min(T + (10 + pow(T,0.73)/4)*(1-T/M), M) - T`.
  `pow` is the translated deterministic implementation, not platform `math.pow`.
- [PlayerImpl.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/game/PlayerImpl.ts):
  reserve addition/removal uses integer floor; negative additions remove the
  floored magnitude. Refunds are not independently capped. Recruitment corrects
  over-cap reserves using the source negative-growth path. A fractional capacity
  can leave an integer reserve less than one troop above it, exactly as upstream.
- [EngineConfig.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/configuration/EngineConfig.ts):
  ordinary human initial reserve is 25,000; default allocation is one fifth.
  Actual stack funding is `min(reserve, floor(requestedTroops))`, not the original
  fractional request. Neutral terrain bases `(magnitude,tileCost)` are plains
  `(80,16.5)`, highland `(100,20)`, mountain `(120,25)`. Loss is `magnitude/5`, so
  16/20/24 troops respectively. Tick fraction is
  `clamp(2000*tileCost/stack,5,100)/(2*fixedBorderSize)`.
- [AttackExecution.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/execution/AttackExecution.ts):
  each attack starts `PseudoRandom(123)`. Heap priority is
  `(nextInt(0,7)+10)*(1-ownedCardinalNeighbours*0.5+terrainPriority/2)+tick`,
  where terrain priority is 1/1.5/2. The heap stores f32 priorities. Each tick fixes
  border size to unique attack-border size plus `nextInt(0,5)`, then spends a
  budget of 1. It may overspend that budget on its final cell. It may also capture
  the final cell with fewer troops than its loss; stored stack is clamped to zero.
  Candidate neighbours are inserted **before** conquest, duplicates remain, and
  ownership/edge adjacency/passability are rechecked when popped. Newly exposed
  cells can be processed in the same tick. Empty heap refreshes and retreats as
  written in source; it does not silently continue with a different algorithm.
- [AttackImpl.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/game/AttackImpl.ts)
  and [RetreatExecution.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/execution/RetreatExecution.ts):
  a new neutral order absorbs the old outgoing stack and rebuilds the frontier;
  absorbed executions cannot refund. Retreat first marks the attack retreating,
  marks it retreated at startTick+20, then the attack execution refunds on its
  next turn. Because existing attacks tick before the new retreat execution,
  stopping can allow one additional attack tick. Neutral retreat has no 25%
  player-combat penalty. An empty initial frontier refunds in init, before another
  recruitment step, preventing the no-front regeneration exploit.
- [Util.ts](https://github.com/openfrontio/OpenFrontIO/blob/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94/packages/engine/src/execution/Util.ts):
  spawn BFS uses a radius of four with centre shifted -0.5 on each axis, then
  filters occupied, water and impassable cells. Fully inland footprint is 52 cells.

## Authority, performance and transport

Clients send only coordinates/allocation or an attack ID. The server identifies
the actual Roblox Player, checks phase, spectator state, finite bounds, neutral
land and allocation, and orders executions on the simulation tick. A click on
neutral land selects the neutral *owner*, not a remote destination: expansion
starts on all eligible existing borders and cannot jump to the clicked island.
Competing players are processed in stable execution order; the second attacker
skips cells already captured by the first. Player-owned targets are rejected.

Only player borders and active attack heaps are traversed during expansion.
Recruitment is O(players). Ownership writes update the changed cell and its four
neighbours. No 33.6-million-cell tick scan occurs. Disconnect cleanup still scans
allocated ownership pages once; that is a possible late-game spike, not hidden
in the regular tick benchmark. Reinitializing very large borders on many repeated
orders also costs time; the remote cooldown bounds ingress but is not a workload
guarantee. No arbitrary capture cap was added that would change source speed.

Changes are coalesced by cell in deterministic first-mutation order. This differs
from Stage 1's sorted wire order but not from final ownership. Buffers contain six
bytes per change, split at 24 KiB boundaries, then assembled and applied atomically
by the client. Snapshots retain their existing 8 KiB page transport. Public profile
metadata changes on joins/spawns/phases; each player's own resources update at
5 Hz. Names/colours are not rebroadcast at 5 Hz to every client. In-flight snapshot
deltas retain the Stage 1 queue limit; huge late-game recovery still needs testing.

Measured official Luau CLI results on this machine, with Studio running:

| Workload | Result |
| --- | --- |
| 1,048,576 packed writes | About 0.27–0.29 s, previously about 0.60 s |
| Packing that dirty set | About 0.028–0.030 s, previously about 0.10 s |
| 100 players, 300 ticks, flat 8192x4096 fixture | 350,300 captures / 650,200 pops; mean 11–13 ms, p95 59–68 ms, max 88–105 ms |
| 32 players, 120 ticks, actual Earth | 42,832 captures; mean 13–15 ms, p95 31–41 ms, max 38–52 ms |
| Raw ownership traffic, flat fixture | Mean 7,006 B/tick/client; largest tick 52,200 B before splitting/compression |
| Raw ownership traffic, Earth fixture | Mean 2,142 B/tick/client before compression |
| Allocated ownership buffers | 10,665,984 B flat / 11,059,200 B Earth; sparse rows can occupy many pages |
| Terrain decoded cache | 524,288 B; compressed source/buffers/indexes are additional |

These are CPU/storage and raw-payload measurements, not Roblox wire throughput or
GPU FPS. Metadata, private resource packets, Roblox serialization and server
fan-out add traffic. The combined harness Lua heap peaked around 116.5 MiB including
earlier tests/data and temporary allocations; Stage 2-only was about 69.4 MiB.
Neither is isolated Roblox production memory.
The 100-player peak can exceed one 100 ms tick. Clock catchup retains backlog;
it does not drop simulation work. Long-running/high-frontier servers, mobile GPUs,
and sustained compressed network throughput are not capacity-certified.

Server diagnostics are attributes on ReplicatedStorage.WorldConquestEvent:
SimulationTick, TickMilliseconds, TickBacklogSeconds, CellsClaimed, FrontierPops,
OwnershipBytes, DeltaBytes and LuaHeapKiB. MicroProfiler uses
WorldConquest.FoundationTick. These support actual deployment profiling without
claiming that CLI timings are Studio measurements.

## Tests and how to run

`python scripts/check_stage2.py` compiles all production files and runs:

- 1,000 reserve results and 45 neutral formula cases from the actual pinned TS;
- 180 actual upstream AttackExecution ticks with exact cells, ordering, reserves
  and committed stacks on mixed terrain with water/impassable barriers;
- cap saturation, fractional costs/allocations, merged retreat protection and
  immediate no-front refunds;
- radius-4 footprints, two competing authorities/replay/replica agreement, ocean
  barriers, forged/NaN/invalid orders and spectator restrictions;
- multipart atomic installation, missing-fragment rejection and recovery coverage;
- the **production** FoundationServer adapter against two client replicas, including
  authenticated ingress, private stats routing, cancellation and disconnect release;
- full-sized-grid active-frontier and real-Earth benchmarks with a 100 ms p95
  regression threshold for these fixtures only.

`python scripts/check_stage1.py` also reruns foundation parity and replay tests.
`python scripts/check_luau.py` reruns legacy and renderer regressions, including
1,184 coordinate round trips. `python scripts/check_topology.py` checks all shipped
terrain cells and the unchanged land-mask hash.

Oracle regeneration uses the audited checkout: run
`node scripts/verify_stage1_oracle.mjs`, `python scripts/prepare_stage2_oracle.py`,
then `node scripts/generate_stage2_oracle.mjs`. The preparer verifies source hashes
and erases TypeScript syntax from source methods; the JS adapter supplies map/player
state, while the upstream AttackExecution decides captures. Existing committed
fixtures let normal Luau tests run without Node or the upstream checkout.

Studio testing:

1. Stop the old playtest and let Rojo sync. Keep Foundation/PortStage=2, then Play.
2. Select land during the countdown. Check exact marker alignment at Fit, zoomed
   and panned positions; the simulation footprint may be clipped by water.
3. At start inspect 25,000 soldiers, recruitment and territory count. Change
   allocation with -/+, click neutral land, and watch committed soldiers pay for
   individual cells. Click again to reinforce. Stop/return refunds survivors after
   the source delay. Zoom in to inspect square boundaries.
4. Start Server and Clients with two players **before** the countdown ends. Verify
   competing neutral expansion and matching regions; a later client spectates.
   Leave one client and confirm its land is released.
5. Inspect Output, profiling attributes, MicroProfiler and Developer Console
   memory/network statistics; check resizing, touch and slower devices separately.

Observed live: new HUD, recruitment, paid expansion, allocation adjustment, square
ownership at higher zoom, and a local server with late-joining spectators receiving
the active player's territory. The live test did not exercise two simultaneously
expanding humans or precisely time the Stop refund; those pass automated tests but
remain manual acceptance checks. One local client emitted Roblox CoreGui
PlayerPermissionsModule/CreatorType errors, rather than WorldConquest stack traces.

## Explicit deviations and remaining work

- Human/neutral mechanics only: no bot/nation multipliers, AI, cities, fallout,
  hostile stacks, combat, diplomacy, immunity or capture-conquest logic. These
  branches were deliberately not enabled ahead of their planned stages.
- Existing accurate Natural Earth coastline data has **unknown elevation**. Land
  magnitude zero currently selects plains costs; highland/mountain parity is proven
  on fixtures, not claimed for real Earth. No unlicensed elevation asset was added.
- World scale is not the upstream World map. Formulas are unchanged, so distances,
  territory counts and pacing differ from a smaller upstream map.
- Fractional marker coordinates, the shared 20-second selection phase, seeded
  fallback placement and simultaneous end-of-phase spawning remain Roblox UI/lobby
  adaptations. Footprints use source BFS/filtering, but the full upstream spawn
  placement/immunity lifecycle is not ported. Overlapping chosen footprint areas
  resolve in stable player order at match start. Selection rejects centres inside
  another reserved footprint, and footprints covering another reserved centre,
  so every selected marker retains its own starting cell. This reservation rule
  adapts the source's immediate spawn ownership to our simultaneous-start lobby.
- Roblox server authority and private HUD updates intentionally replace browser
  deterministic client consensus. Allocation controls use 5% buttons, not the
  browser slider. The OrderedSet uses Luau tables, not upstream typed hash arrays.
- No asset import is required. Existing EditableImage access is required. Source
  notices are retained; public corresponding-source hosting is still unconfigured.

Rollback archive: `build/WorldConquest-before-stage2.zip`. PortStage=1 retains
foundation-only simulation; SimulationMode=Legacy restores the old free-growth
prototype. No Stage 3 code was introduced.
