# Stage 8 implementation and acceptance report

2026-11-20. **Functional implementation is enabled for manual Studio testing;
Stage 8 acceptance is NOT complete.** The 100-player simultaneous-impact test
still exceeds the 100 ms worst-tick target, large replication bursts remain,
and no real Studio, live-server, GPU or mobile test was performed.

The source is OpenFrontIO commit `8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94`,
read from `build/OpenFrontIO`. This is a port of the supported normal-game rules
onto this project's existing Earth map and Roblox adapters, not a claim of
complete upstream mode, map, visual or transport equivalence.

## What is implemented

- Missile Silo and SAM Launcher purchases, construction, upgrades, capture,
  launch-slot inventory and cooldowns. Atomic bombs, hydrogen bombs, MIRV
  carriers, child warheads, predictive SAM interception and cancellation.
- Fixed-point trajectories; deterministic blast footprints, ownership loss,
  reserve/attack/transport casualties, structure/ship/train-carriage damage,
  fallout accounting, reclaim costs and projectile cleanup.
- Normal FFA and server-configured team victory, exact threshold comparison,
  optional timer/overtime, elimination, rankings and match results.
- Waiting for map readiness, 20-second spawn selection/countdown, gameplay,
  victory, results, automatic fresh-match restart, spectators and disconnects.
  Results open three seconds after victory; restart is 18 seconds after victory.
- A shared order sequence across buildings, navy and missiles; authenticated
  intent validation; round IDs on orders, deltas, private statistics and reset.
  Old-round snapshots/deltas/orders cannot replace or mutate the next match.
- Missile controls, silo/SAM status, readable missile glyphs, fallout shading,
  leaderboard/results, responsive shop widths and non-overlapping menu toggles.
  Visible pooled projectile labels interpolate between server updates using
  map-relative coordinates, so zoom/pan remains aligned. No object per cell.

The default is now `Config.PortStage=8`. Run Rojo or open
`build/WorldConquest-stage8.rbxlx`. The root `WorldConquest.rbxlx` remains the older
place; editing Rojo source does not automatically rewrite that open file.

## Source mapping and formulas

| Production module | Pinned upstream source / responsibility |
|---|---|
| `MissileRules.luau`, `BuildingRules.luau` | `Config.ts`, `EngineConfig.ts`: costs, construction, blast radii, damage, SAM range |
| `MissilePath.luau` | `utilities/Line.ts`, `pathfinding/PathFinder.Parabola.ts`, MIRV deterministic-speed calculation |
| `Missiles.luau` | `NukeExecution.ts`, `MIRVExecution.ts`, `MissileSiloExecution.ts`, `SAMLauncherExecution.ts`, `SAMMissileExecution.ts` |
| `Match.luau` | Normal FFA/team `WinCheckExecution.ts`, integer threshold/overtime configuration |
| `Simulation.luau`, `Grid.luau`, `Expansion.luau` | Ownership/ordered frontier integration, fallout bit/count and reclaim modifier |
| `Buildings.luau`, `Naval.luau`, `Rail.luau` | Existing construction, global unit IDs, spatial queries, lifecycle and train-carriage integration |
| `FoundationServer.luau`, `Replica.luau`, wire modules | Roblox authority, incremental replication, snapshots and round isolation |
| Client modules | Original Roblox UI/animation adapters; no upstream artwork imported |

Source hashes are in `tests/stage8/source-hashes.json`; earlier building/rail/
naval dependencies retain their Stage 5/6 manifests. The source index links to
the exact revision.

- Silo: $1,000,000; construction counter 100 ticks. SAM: $1,500,000 initially,
  then $3,000,000, using the upstream owned/lifetime-built minimum; 300 ticks.
  Shared construction scheduling also has its creation/completion execution ticks.
- Atomic: $750,000. Hydrogen: $5,000,000. MIRV: $25,000,000 plus $15,000,000
  per **global** previous MIRV launch. Child warheads/interceptors are free.
- Each structure level provides one launch slot. Silo/SAM reload is 90 ticks.
  A silo reloads one expired slot per tick; SAM reloads all expired slots.
  Upgrading adds a reloading slot. SAM range is `150 - 480/(level+5)` and
  interpolates from its current range over 45 ticks after an upgrade.
- Atomic/hydrogen speed is 10 trajectory samples per configured curve step;
  SAM air movement advances 12 path nodes per tick. MIRV flight is normalized
  with the upstream integer/square-root calculation around 14 ticks, and
  warheads use speeds 22–26. Curve subdivision and sampling use 1/256 units.
- Inner/outer blast radii: atomic 12/30, hydrogen 80/100, MIRV warhead 12/18.
  The BFS is N/S/W/E, seeded by the **actual impact tick**. Failed fringe
  candidates can be sampled again. Impassable terrain stops that flood.
- Atomic/hydrogen casualties per affected cell are `5 * stack / tilesLeft`.
  MIRV casualties are `500 * (1 - exp(-2 * max(0, stack - .03*cap)/cap))`.
  Reserve losses retain integer flooring per cell; outgoing and embarked stacks
  retain fractional arithmetic. All stacks clamp at zero. Independent-stack
  evaluation preserves those exact per-cell results and rounding.
- Land receives fallout bit `0x2000`; terrain remains unchanged in the default
  mode. Successful reclaim clears fallout. Non-missile units inside the strict
  outer-radius circle are destroyed even if their tile missed the random fringe.
- MIRV retains the selected target, samples up to 350 owned target cells within
  1,500 cells, uses minimum Manhattan spacing 55 and two slots per spatial cell,
  revalidates ownership before separation, and assigns source-order speed/delay.
- Normal victory is checked every 10 ticks: `owned * 1000 >
  (landCount - falloutCount) * thresholdTenths`. Default threshold is 800:
  **exactly 80% does not win**. Team mode aggregates team land; the Bot team
  cannot win. Timer expiry selects the territory leader; hard limit is 170 min.
  Optional overtime defaults to two percentage points per minute after 30 min.
  Alliances are not teams and do not grant a shared victory in this source.

## Profiling and actual optimisations

The original profile attributed most impact time to repeated BFS work, checked
cell reads/writes, border churn, delta hash tables and per-cell damage dispatch.
The old terrain LRU made real Earth hydrogen impacts much worse than flat tests.

1. Simultaneous impacts share deterministic geometric footprints by type, tick
   and clipping bounds. Every selected tile is checked for blockers; blocked
   footprints fall back to the exact terrain-sensitive upstream flood.
2. Earth terrain now derives its no-impassable property from the compressed
   data, and supplies bounded read-only windows for blasts. A 201×201 maximum
   window avoids repeatedly evicting/re-decoding 128 cached terrain pages.
3. Fallout uses one packed state mutation, with counts, flags and copy-on-write
   preserved. Owned membership deletion is batched. Only surviving boundary
   neighbours are processed, in the same final insertion order as before.
4. Dirty state is recorded directly into a growable packed buffer with paged
   offsets. Repeated writes update the original record. Drain no longer walks
   a large hash table to repack every cell; large temporary buffers are released.
5. Independent casualty stacks avoid repeated empty attack/transport loops.
   Empty SAM queries are skipped using existing exact unit counts.

No blast is postponed or spread across authoritative ticks. No ownership cell,
impact, casualty, unit, resolution or valid order is dropped to meet a budget.
Snapshot sharing, bounded catch-up queues and atomic delta fragments remain.
The raw six-byte logical delta remains unchanged. Optional uniform-state fragments
now use four-byte references and a common state; clients expand them before atomic
application. Mixed fragments retain the existing encoding. Actual Roblox transport
throughput remains unverified.

## Benchmarks (standalone Luau, simulated players only)

The latest three-repeat timings, memory, raw/encoded payloads, historical before
comparisons and limitations are in [final technical acceptance](FINAL_TECHNICAL_ACCEPTANCE.md).
That report supersedes earlier single-run measurements. The 100-player worst-tick
gate remains open; no live capacity is certified.

## Automated verification and reproduction

Run `python scripts/check_stage8_all.py`. It sequentially runs:

- Stage 1–5 rules, oracle traces, server authority, combat, connectivity, economy,
  building placement/construction/capture/demolition and 7,000 rail trace ticks.
- Stage 6 formulas, 4,810 naval trace ticks, actual landing/combat integration,
  malformed wire records, fleets, recovery and authenticated remote orders.
- All Luau compilation, map coordinate/render scheduling checks.
- Stage 7 2/10/20/50/100-player stress, saved determinism digests, recovery,
  rail rejection, icon pooling and 1M/4M/8M-cell memory workloads.
- Stage 8: 140 exact curves/MIRV speeds, 54 ordered blast footprints (clear,
  blocked, clipped and cached), 48 casualty formulas, 100 SAM ranges,
  100 original predictive interception schedules and 16 victory thresholds.
- Five **original upstream MIRV execution** traces: ordinary targets, ownership
  loss/revalidation, early cancellation, 350-warhead cap and cancellation after
  child creation. Exact ordered destinations, motion, speed and wait ticks match.
- Actual MIRV purchase/flight/127 child impacts/cleanup, real SAM interception,
  normal silo/SAM construction, upgrades, duplicate orders, nonnegative stacks,
  fallout reclaim, independent carriage loss, copy-on-write and ordered borders.
- Victory threshold/team/timer/fallout rules, frozen results, real server adapter
  restart, two replicas, late spectator, malformed/forged requests, stale round
  rejection, stale snapshot rejection and last-player disconnect cleanup.

For upstream regeneration, prepare the existing Stage 1 DetMath oracle, then in
a fresh Node process run `node scripts/verify_stage8_oracle.mjs`. It checks pinned
source hashes, extracts original TypeScript methods/classes and requires
byte-identical fixture regeneration. `tests/stage8/regeneration.json` records
SHA-256 `577accc60454f2c8e8972a8b4f41a3218f463d5628ef4f794c8ca1873f26458e`.
It does not claim complete end-to-end equivalence of every upstream execution.

Run `python scripts/benchmark_stage8.py` and add `--earth` for real terrain.
`--baseline` requires the saved pre-change harness under `build/`.
Final suite logs are `build/check_*-stage8-final.txt`.

## Earlier-stage gaps and remaining limitations

Actual Stage 6 code is present and regressed; it is not the complete upstream
hierarchical naval routing pipeline. Existing full-resolution A*/shore routes
can differ in timing and trade payout, and difficult searches can still stall.
Stage 7 reduced connectivity/rail stalls but was never fully accepted in Studio.
Its adversarial water-search, large-disconnect and network/device risks remain.

The Natural Earth/ETOPO grid is not upstream's authored World raster. Existing
bot/nation formulas are tested, but no full upstream autonomous-bot lobby,
diplomacy/alliance-request interface or disconnected-team inheritance is added.
Team victory uses server-provided teams; there is no new team-selection lobby.
Ranked/tutorial victory and terrain-changing water nukes are explicitly rejected
as unsupported configuration. No ranked persistence or cross-server recovery.

Normal victories freeze gameplay and auto-restart, replacing upstream aftergame
play. All-disconnected/no-survivor matches reset through an explicit Roblox
adapter. MIRV separation is clipped vertically on tiny fixtures; normal Earth
coordinates fit the original formula. Train carriages remain virtual server
units, with blast damage/spacing tracked, not newly rendered individual icons.

Desktop/mobile animation, small-screen controls, EditableImage memory, actual
latency, high-density labels and long-session memory stability require Studio
and physical-device acceptance. A hundred simultaneous full MIRVs is far beyond
the one-projectile-per-player salvo workload and is not certified.

## Publication status and licences

Do not publish as a completed Stage 8 release yet: the 100-player worst-tick gate,
large broadcast bursts, earlier naval-search issues and real-device acceptance
remain open. `Config.SourceURL` is still blank; publish the complete corresponding
source for the deployed adaptation and provide the required prominent offer.

AGPL licence, additional terms, copyright headers and `NOTICE` are preserved.
The existing Natural Earth public-domain and NOAA ETOPO CC0 provenance was checked
in `data/README.md` and its manifests. No new image/audio/model asset or upstream
proprietary artwork was imported. New controls/icons use original UI primitives,
text and existing platform fonts. No game was published by this work.

See [manual acceptance checklist](STAGE8_STUDIO_CHECKLIST.md) and
[changed files](STAGE8_CHANGED_FILES.md).
