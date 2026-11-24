# Stage 5 buildings and purchases - 2026-11-18

Implemented in the existing Rojo project, enabled with `PortStage=5`. Automated
Stage 1-5 and retained renderer/input tests pass. This is **not live Studio acceptance
or a production capacity guarantee**. Stage 6 sea trade/naval invasions are not started.

Authoritative source: [OpenFrontIO at 8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94](https://github.com/openfrontio/OpenFrontIO/tree/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94).
The existing checkout is used, rather than silently changing balance to moving main.
New source hashes and executable parity fixtures are in `tests/stage5/`.

## Buildings and original rules

Let `n` be the sum, over the price's building types, of
`min(level-weighted currently owned units, lifetime constructed count)`.
Unfinished structures count as one. Building and upgrading both increment the
lifetime constructed count. Capture does not increment it. Losing a building can
therefore reduce future prices; captured levels alone do not inflate the price.

| Building | Exact price | Construction duration | Implemented effect |
| --- | --- | --- | --- |
| City | `min(1,000,000, 125,000 * 2^n)`, City only | 20 ticks | +250,000 troop capacity per completed level; rail trade destination |
| Defense Post | `min(250,000, (n+1)*50,000)` | 50 ticks | Defender-owned completed post within inclusive radius 30: combat magnitude x5, tile capture cost x3 |
| Factory | `min(1,000,000, 125,000 * 2^n)`, Factory **and Port** | 20 ticks | Creates rail station network; seeded trains produce arrival income |
| Port | Same shared Factory/Port price | 50 ticks | Owned shore placement; rail trade destination; sea trade/warships pending Stage 6 |

City/Factory/Port upgrades cost the current price of another structure, apply
immediately, and add one level. Defense posts are not upgradeable. The UI offers
one level per click; upstream bulk-upgrade UI is not reproduced. Missile silos
and SAM launchers remain locked until Stage 8, as specified in the port plan.
Upstream's defense-post ship-targeting block is commented out; no ship cannon
behavior was invented.

Source `ConstructionExecution` initializes without charging, purchases/places on
its first active tick, then decrements its remaining duration. Completion is on
the tick after the counter reaches zero: **21/51 ticks after placement**, not a
redesigned wall-clock timer. Optional `Buildings.InstantBuild=true` follows the
source instant-build branch; default is false. Money defaults remain unchanged.

Placement exactly follows `PlayerImpl.validStructureSpawnTiles`: clicked cell
must be owned; N/S/W/E-push LIFO flood remains on owned cells inside strict radius
15; structures of all owners, including unfinished ones, require separation
at least 15; stable distance sorting resolves ties. A port selects the first shore
candidate. This intentional upstream *building* adjustment does not change spawn
picking or map coordinates. Oceans/lakes are not claimable. Ports may be placed on
lake shores upstream; this does not grant a route to the ocean.

Structure reconciliation runs in the existing player tick before recruitment and
income. Enemy cities/factories/ports transfer owner and level, including unfinished
construction. Defense posts are destroyed on capture. Structures on unowned land
are destroyed. Capturing a structure clears its pending demolition mark. Demolition
requires ownership of the unit and its land; cooldown and mark delay are both 300
ticks. Deletion occurs strictly **after** the marked tick, with no refund. The
initial last-delete tick is -1, preserving the original initial cooldown. Player
elimination removes remaining trains and money; disconnect cleans up buildings.

## Rail economy

`Rail.luau` translates the station/rail/train chain required for factory income:

- City/Port station activation near a completed factory; factories promote eligible
  completed City/Port/Factory units within 110 cells. Upstream duplicate factory
  station behavior is retained, rather than silently deduplicated.
- Original four-hop connection avoidance, strict station separation >15, rail
  spatial buckets, insertion ordering, rail splitting and cluster reconstruction.
- Original A* integer bucket queue, LIFO priority ties, N/S/W/E neighbors, heuristic
  weight 2, water/shore penalty 5, turn penalty 3, and 500,000-iteration ceiling.
  Rail paths must contain fewer than `110*1.4142` cells. Shore bridges follow the
  source traversal predicate; trains do not claim any cells.
- Stations use tick-seeded RNG and the source 10-tick minimum spawn cooldown.
  Factory levels receive separate spawn chances. Destination selection uses source
  reservoir sampling in cluster trade-station insertion order.
- Train units count as seven: engine, tail and five cars. Motion advances two path
  cells per tick. Intermediate stops, stop indexing, split reconciliation, active
  endpoint checks, ownership changes and trade embargo checks are preserved.

The exact train spawn formulas are:

```
sigmoid(v,d,m) = 1 / (1 + exp(-d*(v-m)))
saturation(U) = max(1-sigmoid(U,LN2/100,560),
                    .25*(1-sigmoid(U,LN2/150,900)))
boost(L) = L<=0 ? 1 : 1 + .5*clamp((6-L)/5,0,1)/L
rate(L,U) = max(1, floor(((L+20)*165/21)/(saturation(U)*boost(L))))
```

Per visited City/Port: base 10,000 self, 35,000 ally, 25,000 team/other;
subtract `max(0, priorTradeStops-9)*5,000`, floor the result at 5,000, multiply
by the **train owner's** gold multiplier, then floor to integer. The train owner
receives it; a different station owner receives the same amount as well. Factory
stops do not pay. Diplomacy UI is not added; existing team/alliance fields and
server embargo flags are supported in the calculation. Default FFA uses self/other.
There is no passive factory-income substitute.

## Source mapping and changed files

Paths below are under `src/`; original engine paths are under
`packages/engine/src/`, except where stated.

| Luau / adapter | Original implementation |
| --- | --- |
| `shared/OpenFront/BuildingRules.luau` (new) | EngineConfig.unitCost/costWrapper; engine-lib Config.unitInfo, defensePostRange, structureMinDist, deletionMarkDuration/deleteUnitCooldown |
| `server/OpenFront/Buildings.luau` (new) | PlayerImpl placement, counts, upgrade/delete validation; ConstructionExecution; UpgradeStructureExecution; DeleteUnitExecution; UnitImpl ownership/levels; PlayerExecution structure reconciliation |
| `server/OpenFront/RailPath.luau` (new) | pathfinding/algorithms/AStar.ts, PriorityQueue.BucketQueue, AStar.Rail.ts, PathFinder.Station.ts |
| `shared/OpenFront/RailRules.luau` (new) | EngineConfig.trainSaturation/trainSpawnRate/smallEconomySpawnBoost/trainGold |
| `server/OpenFront/Rail.luau` (new) | RailNetworkImpl, Railroad, RailroadSpatialGrid, TrainStation/Cluster; CityExecution, FactoryExecution, PortExecution's station activation; TrainStationExecution, TrainExecution, RecomputeRailClusterExecution |
| `server/OpenFront/Expansion.luau` | AttackExecution defender post lookup now feeds existing original Combat.losses formulas |
| `server/OpenFront/Simulation.luau` | PlayerExecution ordering, city capacity/growth, building executions, elimination cleanup, profile/quote/rail stats and dirty replication |
| `server/OpenFront/Economy.luau` | Exposes existing human-free-cost and host multiplier rules to building/rail code; authoritative exact decimal accounting retained |
| `shared/OpenFront/BuildingWire.luau` (new), `Replica.luau`, `server/OpenFront/FoundationServer.luau` | Roblox-specific authenticated requests, packed incremental structure updates and chunked atomic snapshots |
| `client/BuildingShop.luau` (new), `Main.client.luau`, `MapView.luau` | Roblox shop, affordability, placement/upgrade/demolition controls, glyph icons anchored to actual cell centers; existing transform preserved |
| `shared/Config.luau` | Stage 5 enabled; normal construction durations |

Verification additions: `scripts/prepare_buildings_oracle.mjs`,
`generate_buildings_oracle.mjs`, `prepare_rail_oracle.mjs`, `generate_rail_oracle.mjs`,
`check_stage5.py`, `stage5_checks.luau`, `stage5_server_checks.luau`,
`rail_checks.luau`, `profile_rail_limit.py`, and `tests/stage5/`. The shared runner
`check_stage1.py` loads the production modules and Stage 5 fixtures.

## Authority, replication and rendering adaptations

Clients submit only operation, sequence, type/click or unit ID. The server uses the
authenticated Roblox Player, checks finite integral IDs, phase, ownership, funds,
spacing, construction state and cooldowns. It determines the actual placement and
price. Failed orders do not spend money. The Stage 4 receipt high-water mark makes
retries and stale/conflicting sequences unable to debit or apply effects twice.
Orders execute synchronously in deterministic tick/execution order; no callbacks yield.

Changed structures are coalesced to one **24-byte record** per unit per tick,
including capture, upgrade, completion, demolition mark and deletion. Zero changes
means zero building payload bytes. Combined ownership/building record fragments
are at most 24 KiB, excluding profile metadata/Roblox serialization. Snapshots
carry bounded structure chunks and install atomically with queued deltas. Quotes
and rail activity/earned money use the existing private 5 Hz HUD channel. Protocol
IDs, levels and completion/deletion ticks are unsigned 32-bit transport fields.

Sparse A* search state replaces four upstream world-sized typed arrays, avoiding
an unconditional 512 MiB allocation at this map size. Original algorithms and
tie ordering are retained. Buildings use spatial buckets, not world scans. The
map still uses the existing EditableImage territory renderer and exact ownership
grid. There is one reusable GUI glyph per building, not per land cell; offscreen
glyphs are hidden. Buildings do not change the viewport transform or spawn marker.

Rails and trains run as server simulation records. **Rail lines, animated engines,
tail/car sprites and browser build previews are not rendered yet.** The shop shows
station/train counts and earned rail gold. Their cosmetic omission does not change
route geometry, train-unit saturation, stop timing or payments. No proprietary
OpenFront icons were copied; C/D/F/P glyphs require no imported asset.

## Automated results and measured limits

Passed commands:

```
python scripts/check_stage5.py
python scripts/check_luau.py
python scripts/profile_rail_limit.py
rojo build default.project.json -o build/WorldConquest-stage5.rbxlx
```

- 336 original prices; 1,248 exact placement floods; eight construction timelines;
  64 upgrade validation cases; source demolition boundary checks.
- Transactions/retries/forgery, captured construction, city capacities, defense
  radius/strength, water-separated shores, capture/destruction and elimination.
- 64 original train spawn rates; 112 payouts; 200 exact A* paths; **7,000 original
  rail/cluster/train-motion/gold ticks**, including live rail splitting, destination
  capture/destruction, embargoes, duplicate factory stations and blocked ocean routes.
- Production RemoteEvent adapter with two Earth replicas, private quotes, building
  retries and resync during construction; 1,200-building fragment atomicity and removals.
- Stage 1-4 regressions, deterministic replay, combat/connectivity/economy parity,
  existing tile scheduler and **1,184 screen/map/marker coordinate round trips**.

These are local Luau CLI/service-stub results, **not Roblox networking, GPU or
mobile measurements**. Representative runs:

| Scenario | Mean | p95 | Maximum / limitation |
| --- | --- | --- | --- |
| 100 players, 400 City/Post buildings, 50 combat fronts, 240 ticks | 1.96 ms | 4.92 ms | 18.47 ms; different battle balance from posts, not directly comparable to Stage 4 capture throughput |
| 50 Factory + 50 City rail networks, 1,000 ticks | 0.21 ms | 0.36 ms | 11.76 ms; peak 50 trains / 350 virtual units, 4,050 stored rail cells |
| 100 simultaneous placement orders | -- | -- | about 56-58 ms for one tick |
| Unreachable 8192x4096 rail route | -- | -- | **783 ms** until the original 500,000-iteration limit; isolated heap ~77 to 60,508 KiB |

400 purchases produced 9,600 bytes of building records. Stationary rail test
buildings produced no additional building deltas. Combat building lifecycle averaged
about 0.080 ms/tick; rail execution averaged about 0.062 ms/tick in the rail test.
Total harness heap readings include fixtures/prior tests and garbage collection;
they are not claimed as isolated Roblox memory usage. Full logs are in
`build/stage5-results.txt` and `build/rail-limit-results.txt`.

**Outstanding performance risk:** blocked rail searches are synchronous and can
stall a server tick. Existing giant-territory connectivity spikes also remain.
These must be optimized with output-preserving methods and re-profiled before a
large public server rollout. No supported-player-count promise is made.

Oracles can be regenerated with Node supporting `node:module.stripTypeScriptTypes`
(e.g. Node 24): run each `prepare_*_oracle.mjs` followed by its matching
`generate_*_oracle.mjs`. They execute mechanically stripped original methods;
the fixtures do not use the Luau implementations to calculate expected results.
The original Stage 1 verified math module is also required in `build/`.

## Two-client Roblox Studio acceptance (still pending)

1. Stop Play. Run `rojo serve default.project.json` and connect the existing Rojo
   plugin to the running server. Keep the existing Mesh/Image API setting enabled.
   Let the new scripts sync. No geography/image import is needed. The built
   `build/WorldConquest-stage5.rbxlx` is an optional test artifact.
2. For a short **local test only**, set `Config.Economy.StartingGold="10000000"`
   before starting clients. Preserve `GoldMultiplier=1`, `Buildings.InstantBuild=false`.
   Restore StartingGold="0" afterward. With defaults, the first City takes roughly
   125 seconds of passive income after match start; a Post takes 50 seconds.
3. Studio Test -> Server & Clients -> **2 clients** -> Start. Pick nearby land
   spawns. Move each spawn during the countdown; verify both clients see exact
   positions. Expand enough to own sites at least 15 cells apart.
4. Open **Buildings**, buy City, then click owned land. Check one deduction,
   translucent `C...` on both clients, and completed `C1` after 21 ticks. Capacity
   increases by 250,000 only on completion. Next City quote is 250K. Upgrade via
   the shop and its icon: `C2`, another 250,000 capacity, next quote 500K.
5. Try water, enemy land, unaffordable purchases, an inland Port, and an Upgrade
   during construction. Money must not decrease. Near a blocked placement, verify
   the icon is at the server-selected nearby valid cell, not an arbitrary distant site.
6. Build a Post near a border. Before 51 ticks it must have no combat benefit;
   afterward attacks in its 30-cell range should incur greater attacker losses
   and slower captures. Have the second client capture its cell: the Post disappears
   on both clients. Capture a City: its owner color changes and capacity transfers.
7. Build a Factory and completed City **more than 15 and at most 110 cells apart**
   with a land route shorter than 156 path cells. Watch the shop's station/train
   counts and rail gold. Spawns are seeded random, so allow 1-2 minutes. Observe
   gold arrival jumps; no flat passive factory income should appear. A Port must
   be on owned coast and can serve as the same rail destination. No boats spawn.
8. After the initial 30-second delete cooldown, choose Demolish and click a
   building. Verify `!`, no refund, and deletion strictly after 300 ticks. Capture
   the marked building before expiry: the mark clears. A second demolition inside
   the 300-tick per-player cooldown must be rejected.
9. Repeat selection and icon operations at Fit, default focus and maximum zoom;
   pan, resize and test a narrow window. Scrolling the shop must not zoom the map.
   Ensure normal clicks still expand/attack after cancelling placement or Escape.
10. Restart with a new client joining an ongoing match: it spectates and receives
    matching buildings, levels, owners and pending construction. Test disconnect
    cleanup and an elimination with a moving train; no later income for the loser.
11. Inspect Output in server and both clients. Watch attributes on
    ReplicatedStorage.WorldConquestEvent: TickMilliseconds, TickBacklogSeconds,
    BuildingMilliseconds, BuildingDeltaBytes, BuildingCount, RailMilliseconds,
    TrainUnits, OwnershipBytes and LuaHeapKiB. Record actual device/network results.

AGPL-3.0 notices, attribution and the existing source-publication requirement are
preserved in LICENSE/NOTICE. Config.SourceURL is still unconfigured; this work
does not publish an experience or provide a hosted corresponding-source offer.
