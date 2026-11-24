# Stage 3 human combat implementation — 2026-11-17

**Superseded status, 2026-11-18:** connectivity and real elevation are now implemented.
See [STAGE3_CONNECTIVITY_ACCEPTANCE.md](STAGE3_CONNECTIVITY_ACCEPTANCE.md) for
current tests, performance limits and the still-pending live Studio gate. The rest
of this file is the November 17 historical report.

Implemented directly in the Rojo project; `Config.PortStage = 3`. This is the
**direct human land-combat portion** of Stage 3, not a claim that the entire Stage 3
acceptance gate or OpenFront port is complete. The separate upstream cluster /
encirclement / diagonal-pinch system and live Studio acceptance remain outstanding.
Stage 4 economy has not been started.

## Source and changed files

Reference: https://github.com/openfrontio/OpenFrontIO, pinned revision
`8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94` (the existing audited revision, not a
claim to follow the moving main branch). Oracle extraction checks the audit
manifest hashes before executing mechanically type-erased source methods.

| Changed production file | Original implementation and changes |
| --- | --- |
| `src/shared/OpenFront/Combat.luau` (new) | `EngineConfig.ts`: player `attackLogic`, `largeTerritoryBonus`, terrain and combat constants; `Util.sigmoid`, existing deterministic `DetMath` |
| `src/server/OpenFront/Expansion.luau` | `AttackExecution.ts`: enemy target validation, target-specific frontier, incoming-stack cancellation, same-target merging, combat casualties/speed, retreat penalty, sub-100-cell conquest; `AttackImpl.ts`: outgoing/incoming registration and deletion |
| `src/server/OpenFront/Simulation.luau` | `PlayerImpl.ts` friendly/attack eligibility and ownership; `GameImpl.ts` border mutation and spawn immunity; `PlayerExecution.ts` recruitment stops at death; ordered owned-cell sets, target-resolved authenticated orders, elimination metadata, private attack summaries |
| `src/server/OpenFront/RetreatExecution.luau` | Source retreat deadline, now finds the requested outgoing attack rather than only the latest attack |
| `src/server/OpenFront/FoundationServer.luau` | Existing 10 Hz authority and 24 KiB atomic delta fragments retained; adds `CombatCellsClaimed` and `ActiveAttacks` profiling attributes |
| `src/client/Main.client.luau` | Enables Stage 3 resource HUD, enemy click orders, attack target selector and per-attack Stop/return; displays eliminated state and total committed troops |
| `src/shared/Config.luau` | Enables Stage 3 |

The 8192×4096 Natural Earth grid, precise click conversion, selection markers,
zoom/pan, exact square-cell renderer, dirty raster updates and Rojo hierarchy
remain in place. Enemy captures change the same authoritative cell ownership used
by the renderer. There are no rounded conquest regions or per-cell GUI objects.

New verification files: `scripts/generate_stage3_oracle.mjs`,
`tests/stage3/upstream-oracle.json`, `scripts/stage3_checks.luau`,
`scripts/stage3_server_checks.luau`, `scripts/check_stage3.py`.
Updated verification: `scripts/prepare_stage2_oracle.py` extracts combat constants,
helpers and methods as well as existing Stage 2 code; `scripts/check_stage1.py`
loads Combat and runs the added checks. Documentation changes: this report,
`OPENFRONT_PORT_PLAN.md`, `OPENFRONT_PORT_MAPPING.md`, and root `NOTICE`.

## Exact combat behaviour

Let A/D be attacking/defending owned cells, T the committed stack, R the defending
reserve, d=R/D, r=R/T, and B the unique eligible frontier size plus the per-tick
source RNG jitter `[0,5)`. Define:

```
bonus(n, depth) = 1 - depth / (1 + exp(-2.5 * (log(n) - log(300000))))
LA = bonus(A, .7)
LD = bonus(D, .3)
attackerLoss = mag * traitorLossMod * clamp(r, .6, 2)
               * (.463 * LA * LD + .0039 * d)
defenderLoss = R / D
speedCost = clamp(r, .82, 7.5) * clamp(r / 20, 1, 50) / 8.55
fraction = speedCost * tileCost * bonus(A, .73) * LD * traitorCostMod / B
```

Plains `(mag,tileCost)=(80,16.5)`, highland `(100,20)`, mountain `(120,25)`.
Traitor modifiers are `.5` loss and `.8` cost. Human/Nation attacking a Bot uses
`.7` magnitude. Defense posts multiply magnitude by 5 and cost by 3. Fallout
multiplies both by `5-2*falloutRatio`. Disconnected teammates have magnitude 0.
These optional formula branches are implemented as inputs and fixture-tested;
there are no live defense posts, fallout, traitor diplomacy or bots in this stage.

Reserve changes use upstream integer flooring, while committed stacks and attacker
casualties retain fractional precision. Each tick starts with budget 1 and
captures eligible adjacent cells until subtracting their fractions exhausts it.
The budget is not replaced with a fixed Roblox claims-per-tick cap.

Heap priorities remain `(rng.nextInt(0,7)+10) *
(1-ownedNeighbours*.5+terrainMagnitude/2) + tick`, magnitude 1/1.5/2.
Each execution uses source seed 123; f32 heap priorities, duplicate entries,
N/S/W/E iteration, insertion before conquest and stale-owner rechecks are retained.

Enemy orders require a living non-spectator attacker, valid land, available troops,
a nonfriendly target and a shared cardinal border. Human targets receive the
source 50-tick post-spawn immunity. Execution init rechecks target eligibility.
Allocation commits the actual integer reserve removed at init. Opposing incoming
stacks cancel first; remaining same-target outgoing stacks merge. Different target
attacks can coexist. Stable execution order and ownership rechecks resolve competing
claims without claiming a cell twice for different players in one mutation.

Cancellation pauses the selected attack via the source RetreatExecution lifecycle.
Its deadline is init tick +20; the attack subsequently refunds survivors. Enemy
retreat loses 25%; neutral retreat has no penalty. Natural frontier exhaustion
refunds without that penalty. Deleted/absorbed attacks cannot refund again.

After a capture leaves a defender below 100 cells, the source's bounded 100-pass
remnant traversal transfers only cells adjacent to the attacker or another eligible
enemy. Isolated island remnants stay owned. Elimination is recorded at zero cells;
recruitment stops and new attack orders are rejected. Remaining reserves are not
invented as a loot reward or forcibly set to zero. No economy transfer is implemented.

## Validation and measurements

Run from the project directory:

```
python scripts/check_stage3.py
python scripts/check_luau.py
rojo build default.project.json -o build/WorldConquest-stage3.rbxlx
```

All three passed on 2026-11-17. Full simulation output:
`build/stage3-results.txt`. Rojo build artifact:
`build/WorldConquest-stage3.rbxlx`.

* 117 exact source combat formula comparisons, including traitor, defense-post,
  fallout and bot modifiers across terrain classes and ratios.
* 520 ticks executing the original upstream AttackExecution against fixture adapters:
  ordinary battle, sub-100 conquest, counterattack, equal opposing armies, two
  attackers, merge, retreat, and isolated island. Every capture/order, reserve,
  owned count and outgoing stack agrees exactly with Luau.
* 160-tick deterministic contested-combat replay and atomic replica comparison;
  self/friendly/nonadjacent/water/NaN/immunity rejection, elimination and halted growth.
* Production RemoteEvent adapter with two client replicas on actual Earth: authenticated
  orders, private attack HUD updates, enemy captures, cancellation, identical final
  ownership, disconnect and fragment bounds. Roblox services are stubbed: this is
  **not a live two-window Studio playtest**.
* Prior Stage 1/2 source parity, spawn lifecycle, recruitment, neutral expansion,
  snapshot recovery and multiplayer tests still pass. Renderer suite passes 1,184
  coordinate round trips plus dirty-tile/upload recovery tests.

Measured local Luau CLI simulation workload (not Roblox network/GPU performance):

| Workload | Mean / p95 / max tick | Ownership buffers | Raw ownership deltas |
| --- | --- | --- | --- |
| 100 humans, 50 enemy fronts, 8192×4096, 200 ticks | 1.717 / 4.262 / 18.044 ms | 2,457,600 B | 608 B/tick mean; 2,100 B max |
| Stage 2 regression: 100 humans, 300 ticks | 11.973 / 61.480 / 88.624 ms | 10,665,984 B | 7,006 B/tick mean; 52,200 B max |
| Real Earth regression: 32 players, 120 ticks | 13.401 / 32.993 / 37.244 ms | 11,059,200 B | 2,142 B/tick mean |

Combat workload: 20,250 captures, 38,650 heap pops. Cumulative harness heap at this
benchmark peaked at 85,696 KiB; GC timing and preceding tests affect that number,
so it is not an isolated per-match Roblox memory measurement. Ownership numbers
exclude ordered sets, dirty tables, terrain and Lua overhead. Wire figures exclude
HUD tables, RemoteEvent overhead and fan-out: the mean combat delta alone is about
6.08 KB/s **per recipient** at 10 Hz. At 100 recipients it is about 608 KB/s aggregate.

Work visits active frontiers and ordered border sets, not all 33.6 million cells
per tick. Stage 3 disconnect cleanup visits that player's owned cells. Remnant
conquest only scans a defender below 100 cells. There is no tested full-world
memory/player guarantee: table-backed owned sets and huge frontier heaps remain
scaling risks. The Stage 2 p95 already exceeds the plan's proposed 20 ms target;
maintain honest backlog/device profiling before raising supported match size.
No balancing constants were changed to disguise load.

## Two-client Studio test

1. Stop any running test. Let the existing Rojo connection sync these files, or
   open the built `build/WorldConquest-stage3.rbxlx`. Confirm Shared/Config has
   `SimulationMode="Foundation"`, `PortStage=3`.
2. Use Studio's **Server & Clients** mode with **2 clients**, then start. See
   https://create.roblox.com/docs/studio/testing-modes for the current test UI.
3. During the 20-second selection phase, choose nearby inland locations on the
   same continent (central Africa works well). Zoom in; place spawns roughly
   15–25 tiny cells apart, avoiding a lake/coast. Move a marker and verify its
   exact position before the deadline.
4. In each client, allocate 20–50% and click unclaimed land to expand. Grow until
   the two colours share a cell edge. Enemy attacks during the first five seconds
   after match start must be rejected without committing soldiers.
5. Click the other player's colour after immunity ends. Check soldiers committed,
   target username, defender reserve loss, changing cell-exact borders and matching
   ownership in both windows. Click back from the defender to test opposing-stack
   cancellation. Repeated orders to the same target should merge.
6. Click the attack target button to cycle active attacks, then Stop / return.
   That attack pauses and returns after the source delay; enemy survivors lose
   25% before integer refund. Other target attacks continue.
7. Conquer a weak opponent. Below 100 cells, reachable remnants may transfer in a
   single conquest pass. At zero cells the player displays eliminated/spectating
   and cannot recruit or launch a new attack. An isolated island must not be
   automatically transferred across water by this remnant rule.
8. Pan/zoom in both clients, check Output for errors, and inspect server
   ReplicatedStorage/WorldConquestEvent attributes: TickMilliseconds,
   TickBacklogSeconds, ActiveAttacks, CombatCellsClaimed, FrontierPops, DeltaBytes,
   OwnershipBytes and LuaHeapKiB. Use MicroProfiler/Developer Console for actual
   transport, paint queues and device memory. Stop the test to reset the match.

## Outstanding differences and acceptance limits

* **PlayerExecution cluster/encirclement/diagonal-pinch analysis is not ported.**
  The plan's complete Stage 3 gate therefore remains open. No alternative pocket
  capture algorithm has been substituted. Direct attack/remnant parity tests do
  not claim parity for complete matches involving automatic encirclement.
* Live two-client Studio acceptance and live Roblox load/device profiling were not
  performed in this pass. The Rojo artifact builds and automated checks pass.
* Natural Earth is unchanged, public-domain and accurately aligned to the existing
  mask, but has no elevation metadata. Live land still uses plains combat; synthetic
  highland/mountain parity does not establish real-world terrain-class parity.
  It is not OpenFront's differently sized World raster; unchanged formulas on a
  different raster can produce different geographic pacing. No manual asset import
  is needed for this change.
* Economy/unit capture, diplomacy/embargo effects, victory/scoreboard, teams UI,
  naval attacks and sourceTile transport execution remain later work. Friendly
  checks support same-team/allied flags, but the live lobby remains human FFA.
  Disconnect still releases land under the existing Roblox lifecycle instead of
  retaining upstream AFK players. Numeric attack IDs and authoritative batched
  replication replace browser IDs/lockstep without changing tested combat arithmetic.
* AGPL-3.0 and attribution remain intact. No upstream visual assets were imported.
  Preserve LICENSE, NOTICE and visible OpenFront credit. Before serving a public
  version, prominently offer the actual corresponding source of the deployed Luau
  adaptation, including server/client modifications and build/data scripts, under
  the preserved licence terms. `Config.SourceURL` is still empty; an upstream-only
  link is not that source offer. This change neither publishes the game nor hosts
  its source. See existing licensing analysis and the verbatim licence for details.

