# Implemented source mapping and differences

Current implementation: [Stage 6 report](STAGE6_IMPLEMENTATION.md). Stages 1–6 automated tests pass; live Studio acceptance and the documented routing/performance limitations remain. The original analysis below is retained as a historical baseline.

Authoritative reference: OpenFrontIO commit
`8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94`, under `build/OpenFrontIO` for inspection.
The manifest hashes are checked before extracting executable TypeScript oracles.
This is an incremental port, not a complete port of all listed upstream systems.

## Stage 5 update (2026-11-18)

BuildingRules/Buildings translate original costs, bounded placement, construction,
upgrades, capture and demolition. RailPath/RailRules/Rail translate original rail
paths, station clusters, train execution and trade income. BuildingWire/Replica,
FoundationServer and BuildingShop adapt transport and UI to Roblox. See
[STAGE5_IMPLEMENTATION.md](STAGE5_IMPLEMENTATION.md) for the full source mapping,
7,000 upstream rail timeline ticks, building fixtures, measured limits and pending
live acceptance. No sea trade, naval invasion or missile mechanics are enabled.

## Stage 4 update (2026-11-18)

Economy.luau maps EngineConfig gold rules, PlayerImpl accounting/donation and
GameImpl conquest gold; MoneyFormat.luau maps Format.renderNumber; Gold.luau provides
exact Luau storage for BigInt balances. See [the Stage 4 report](STAGE4_IMPLEMENTATION.md)
for the complete file mapping, source comparisons, transaction API and deviations.

## Stage 3 completion update (2026-11-18)

`Connectivity.luau` now translates PlayerExecution's cluster/sovereign/secondary/
pinch/hole/connectivity passes and shared traversal scratch. Simulation wires the
source cadence and ownership-change gating. Real NOAA CC0 elevation is baked into
the existing terrain. See [the current report](STAGE3_CONNECTIVITY_ACCEPTANCE.md)
for exact mapping, 310 cluster fixtures, 1,040 battle ticks, data adaptations,
performance limits and the pending manual Studio acceptance gate.

The following sections record the earlier implementation history.

## Stage 3 update (2026-11-17)

[STAGE3_IMPLEMENTATION.md](STAGE3_IMPLEMENTATION.md) records the new Combat module,
actual source formulas, extended AttackExecution/AttackImpl mapping, 117 formula
cases, 520 exact battle ticks, authority tests, measurements and outstanding gates.
Human direct attacks, incoming-stack cancellation, multiple target stacks, enemy
retreat and adjacent remnant conquest are implemented. The older Stage 2 notes
below remain historical; cluster/pinch processing is still outstanding.

## Current translations

| Original file / implementation | Luau implementation | Coverage |
| --- | --- | --- |
| `packages/engine-lib/src/PseudoRandom.ts` | `src/shared/OpenFront/Random32.luau` | sfc32 initialization, warmup, stream, integer bounds, state |
| `packages/engine-lib/src/DetMath.ts` | `src/shared/OpenFront/DetMath.luau` | deterministic transcendental functions |
| `packages/engine/src/execution/utils/FlatBinaryHeap.ts` | `src/shared/OpenFront/MinHeap.luau` | f32 priorities, exact ties, growth and state |
| `packages/engine-lib/src/game/GameMapImpl.ts` | `src/shared/OpenFront/Grid.luau`, `EarthTerrain.luau` | terrain/state bits, cardinal neighbours and border semantics; packed sparse Roblox storage |
| `packages/engine-lib/src/game/TileSet.ts` | `src/server/OpenFront/OrderedSet.luau` | insertion/deletion/re-add order used by owner border iteration; Luau tables replace typed hash arrays |
| `packages/engine-lib/src/configuration/Config.ts` (`troopCap`, `troopIncreaseRate`) | `src/shared/OpenFront/Troops.luau` | human/bot/nation, all four difficulties, tutorial cap, infinite-human cap, completed-city-level contribution |
| `packages/engine/src/configuration/EngineConfig.ts` (`startManpower`, `attackAmount`, neutral `attackLogic`, `falloutDefenseModifier`) | `Troops.luau` | source initial reserves, default allocations, neutral terrain costs/speed, bot costs and fallout modifier |
| `packages/engine/src/game/PlayerImpl.ts` (`addTroops`, `removeTroops`) | `Troops.luau` | integer conversion at reserve boundaries; attack stacks remain floating point |
| `packages/engine/src/execution/AttackExecution.ts` | `src/server/OpenFront/Expansion.luau` | neutral and human land init/tick/refresh, counterattack cancellation, target-specific merge/refund, 25% enemy retreat, adjacent remnant conquest; source RNG and heap ordering |
| `packages/engine/src/game/AttackImpl.ts` | attack state inside `Expansion.luau` | incoming/outgoing target stacks, border membership, deletion and active/retreat flags |
| `packages/engine/src/execution/RetreatExecution.ts` | `src/server/OpenFront/RetreatExecution.luau` | original init/order/deadline lifecycle, including an attack that disappears during the delay |
| `packages/engine/src/execution/Util.ts` (`getSpawnTiles`), `GameMapImpl.euclDistFN` | `src/server/OpenFront/Spawn.luau` | shifted radius-4 BFS, filtering and require-all-valid mode |
| `packages/engine/src/execution/SpawnExecution.ts` | `src/server/OpenFront/SpawnExecution.luau` | normal non-team intent/init/tick, relinquish/restore, overlapping selections, random fallback, 1,000 tries, distance 30 relaxed after 750 |
| `packages/engine-lib/src/Util.ts` (`simpleHash`) | `SpawnExecution.simpleHash` | signed 32-bit hash over UTF-16 units, used with player ID and match ID |
| `packages/engine/src/execution/PlayerExecution.ts` recruitment step | `Simulation.startRecruitment` | recruitment and stop-on-death; cluster/pinch processing still outstanding |
| `packages/engine/src/game/GameImpl.ts` execution and border mutation order | `Executions.luau`, `Simulation.luau` | old executions tick before pending init; changed cell then N/S/W/E border updates |
| `src/client/hud/layers/ControlPanel.ts` allocation range | `src/client/Main.client.luau` | ScreenGui slider: 1–100, integer steps, default 20%, ratio=value/100 |

## Fidelity corrections made in this pass

The previous custom centre-reservation rule and stride-based automatic spawn search
are removed from Stage 2. They remain only in the isolated Stage 1 fallback where
applicable. Stage 2 now claims the source-filtered footprint during selection,
relinquishes previous spawn land before reselection and restores it on failure.
The source allows partially overlapping footprints; it does not impose our former
extra spacing rule. Intent eligibility is captured during execution init, so an
intent initialized on the last selection tick can execute after the phase ends.
Malformed refs fail before relinquishing land. Recruitment is registered once.

Random fallback now draws x and y with a per-player source RNG, rejects water,
occupied/border centres, enforces Manhattan distance 30 for the first 750 tries,
requires the whole footprint to be valid, and stops after 1,000 tries. Roblox
UserId and the match seed string supply source playerID/gameID inputs; identical
IDs, seed, map and state produce the same oracle results.

The previous 0–100% five-point buttons are replaced by the source's 1–100% integer
range control. Retirement of a missing/absorbed attack now remains scheduled to
the source retreat deadline rather than terminating early. Ordinary human balance
is unchanged; previously omitted player-type/config branches are now translated
and tested without inventing AI or buildings to exercise them in the live game.

## Parity evidence

Run `python scripts/check_stage2.py`, or `python scripts/check_stage1.py` for the
combined suite. New tests compare against actual extracted upstream methods:

- 96 combinations of human/bot/nation, difficulty, tutorial, infinite-troop override
  and completed-city levels, checking cap, growth, initial reserves, default attack
  amount and bot/fallout neutral cost/speed.
- 10 SpawnExecution snapshots checking exact centre, ordered footprint, ownership
  and recruitment-registration count. Includes overlap, invalid integer/fractional
  refs, failed spawn restoration, reselection, last-tick intent and seeded random
  placement.
- Existing 1,000 reserve steps, 45 neutral formula cases and 180 exact upstream
  AttackExecution ticks still pass, as do multiplayer/service-adapter tests.

Regenerate references with `node scripts/verify_stage1_oracle.mjs`,
`python scripts/prepare_stage2_oracle.py`, `node scripts/generate_stage2_oracle.mjs`
and `node scripts/generate_fidelity_oracle.mjs`. The latter executes upstream
SpawnExecution, not a rewritten expected-spawn algorithm. Map/player adapters
supply fixture state. The committed JSON permits normal tests without Node.

## Differences and not-yet-ported systems

Roblox rendering, input, reliable RemoteEvent transport and server authority are
platform adaptations. Fractional marker positions remain UI-only; integer cells
drive gameplay. The existing lobby's shared countdown and late-join spectators
remain adapters, not a claim of full upstream lobby parity. Team spawn areas,
random-spawn-only mode and single-player early ending are not yet wired.

Neutral and direct human combat paths are translated. Transport source-tile
attacks, structures, gold, ships, AI,
victory and the remaining PlayerExecution territory-cluster behaviours are **not
implemented yet**. Their eventual implementation must follow the pinned source
and fixtures. They have not been replaced by alternative gameplay. Merely exposing
city or bot rule inputs does not mean those systems exist in the game.

The Natural Earth 10m land/lake dataset remains public domain, with original
provenance. It is not OpenFront's World raster. Elevation is unavailable, so the
current live map's zero land magnitude uses plains balance; fixture parity does
not establish real-world terrain-class parity. Map scale also changes pacing even
with unchanged formulas. No proprietary or uncleared upstream assets were copied.

AGPL-3.0 and upstream additional attribution/origin terms remain in root LICENSE
and third_party/OpenFrontIO. Keep the visible “© OpenFront and Contributors” notice
and unofficial WorldConquest title. For public network deployment, offer the
complete corresponding source of the deployed adaptation, including modified
server code, build/configuration and data-generation scripts, prominently to
players. An upstream-only link is insufficient. Public source hosting is still
unconfigured; this development work neither publishes the game nor supplies that
hosted offer. See NOTICE and the preserved licence text.
