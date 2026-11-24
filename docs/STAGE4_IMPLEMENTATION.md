# Stage 4 money and economy - 2026-11-18

Implemented in the existing Rojo project with `PortStage=4`. Automated Stage 1-4
regressions pass. Live Roblox multiplayer/UI acceptance and the previously reported
large-territory performance limits remain outstanding. No Stage 5 buildings exist.

## Original source and changed files

Reference: OpenFrontIO `8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94`, the existing audited
checkout, not a claim to track moving main: https://github.com/openfrontio/OpenFrontIO.

| Production file | Source mapping / change |
| --- | --- |
| `src/shared/OpenFront/Gold.luau` (new) | Roblox exact-integer adapter for upstream `Gold`/BigInt: canonical unsigned decimal strings, exact addition/subtraction/halving/comparison; no floating-point balance |
| `src/server/OpenFront/Economy.luau` (new) | `EngineConfig.ts` startingGold/startingGoldFor, goldMultiplierFor, goldAdditionRate, conquerGoldAmount, human infinite-gold cost behaviour; `PlayerImpl.ts` addGold/removeGold/canDonateGold/donateGold; server transaction adapter |
| `src/shared/OpenFront/MoneyFormat.luau` (new) | `packages/engine-lib/src/Format.ts` renderNumber default compact thresholds/precision |
| `src/server/OpenFront/Simulation.luau` | `PlayerExecution.ts`: income immediately after recruitment, clear money on death; constructor starting balance, scheduled transactions, snapshot/private HUD fields |
| `src/server/OpenFront/Expansion.luau` | `AttackExecution.ts` conquest hook; `StatsImpl.ts` attack sent and cancel accounting for loot eligibility |
| `src/server/OpenFront/Connectivity.luau` | Existing source conquest calls now invoke the same economy hook for complete encirclement conquest |
| `src/server/OpenFront/FoundationServer.luau` | Passes server economy config; existing 5 Hz private stats transport carries exact strings; EconomyMilliseconds profiling attribute |
| `src/client/Main.client.luau` | Money/income in existing resource row with compact formatting; map viewport and controls preserved |
| `src/shared/Config.luau` | Enables Stage 4; default StartingGold="0", GoldMultiplier=1, DonateGold=false |

New verification files: `scripts/prepare_economy_oracle.mjs`,
`generate_economy_oracle.mjs`, `stage4_checks.luau`, `stage4_server_checks.luau`,
`check_stage4.py`, and `tests/stage4/upstream-oracle.json`.
`check_stage1.py` loads the new production modules and checks. NOTICE, port-plan
status, source index and mapping are updated. No new map assets or import steps.

## Source formulas and lifecycle

* Starting gold: configured amount, otherwise **0**. Bots always start at 0.
  Host starting gold is added to the base for the configured host. Initial gold
  is assigned directly and does not count toward lifetime `GoldEarned`.
* Human/Nation passive income per tick: **floor(100 * multiplier)**. Bot: **floor(50 *
  multiplier)**. Default multiplier 1. Host multiplier overrides the base when
  configured for the host. There are 10 deterministic ticks/second: default human
  income is 100/tick, or 1,000/second of simulation time.
* There is **no territory, population, troop, difficulty, time or compounding factor
  in this passive formula**. Owning more land or recruiting more soldiers does not
  increase the rate. Balance grows linearly while alive. No substitute tax/growth
  mechanic was added. Trade/rail income awaits the actual routes and later stages.
* Source config limits: base starting gold 0..1,000,000,000; configured income
  multipliers 0.1..1000. These are input limits, not a cap on accumulated wealth.
  Balances and lifetime earnings have no artificial maximum.
* Income runs in the existing PlayerExecution ordering, after soldier recruitment
  and before connectivity analysis. No income during spawn selection; the source
  execution-init delay is preserved. Death clears remaining money and stops income.
* Conquest grants all remaining Bot/Nation money, or **floor(human balance / 2)**.
  On eligible capture, the loser loses its entire balance, including the uncaptured
  half. If the human's source net sent-attack statistic is zero, transfer is skipped;
  death cleanup later clears its remaining money. The source's sub-100-cell conquest
  calls can occur before literal zero ownership and isolated remnants can survive.
* The eligibility statistic is **not click count**: add committed troops at attack
  init (including neutral attacks), subtract with **floor(-survivors)** on explicit
  retreat. No-front automatic refunds do not undo that source statistic. Both signs
  are represented exactly. Repeated conquest cannot award already-removed money again.
* AddGold increases balance and lifetime earned. RemoveGold removes min(balance,
  requested amount). Public transaction boundaries reject malformed/negative money;
  trusted accounting uses canonical nonnegative decimal strings, including "0".
* Server donation API preserves live/friendly/self/config checks, min(balance,amount),
  recipient earned totals and the **100-tick per-recipient cooldown**. Same-team/allied
  flags use the existing model. There is no donation or diplomacy UI; default FFA
  configuration disables human donation. Trade embargo has no passive-income effect
  and no trade routes/embargo gameplay were invented in this stage.
* Upstream infinite gold means **zero human construction cost**, not an infinite
  balance. The future-product API supports this rule; it creates no building or unit.

The source oracle executes the original methods after hash checking and mechanical
TypeScript erasure, including actual GameImpl.conquerPlayer. Gold storage is rewritten
for Luau because it has no native BigInt. Only display formatting converts to a double,
as upstream does. At values beyond finite double display range, UI says "very large";
the exact ledger and transmitted decimal string remain intact.

## Server-only transaction API for Stage 5

No products are registered by the live game, no purchase button exists, and the
RemoteEvent whitelist accepts neither Purchase nor SetGold. Clients cannot supply
prices, grant themselves money or directly mutate balances.

Future trusted server code can use:

```
sim.Economy.register(productKey, costFunction, eligibilityFunction)
-- callbacks: (player, simulation, validatedContext); cost returns canonical decimal string
local receipt, fresh = sim.Economy.purchase(player, sequence, productKey, context)
-- Apply an effect only if BOTH fresh and receipt.OK are true.
```

Callbacks must be synchronous, read-only and server-owned. They must implement
source building price/placement/unit-count eligibility in Stage 5; no generic catalog
price is offered as a replacement. No unit creation or cross-system rollback is implemented.
A debit is all-or-nothing after eligibility and
funds checks. The receipt carries sequence, product, tick, cost and resulting balance. A replayed
receipt describes its original tick; it is not a replacement for the current HUD balance.

Sequence IDs are positive safe integers and strictly increase per player/session.
The latest identical retry returns its saved receipt with `fresh=false`; older IDs
are rejected permanently. Reusing a sequence for a different product is rejected.
Rejected fresh requests consume the sequence, so retrying later cannot unexpectedly
succeed. Only one receipt and high-water mark are retained per player; history does
not grow with playtime. A new purchase must use a new sequence. Context never causes
an effect on replay; callers must honour the `fresh && OK` contract.

Trusted `sim.enqueue({Kind="Purchase",UserId=...,Sequence=...,Product=...,Context=...})`
schedules a one-shot execution, initialized after existing executions and processed
on a subsequent active tick. This permits existing recruitment/income to precede
spending in execution order. Results include receipt/fresh in `sim.step()` results.
It is not a client action and does not implement ConstructionExecution. Stage 5 must
invoke the accounting API at the original construction execution's spending point,
with source building validation, and must authenticate any eventual new remote order.

Config uses decimal text for StartingGold. Optional server-only settings are
HostUserId (a Roblox UserId), HostStartingGold, HostGoldMultiplier, InfiniteGold and
HostInfiniteGold. A client does not select its host status. The source lobby-creator
role is adapted to this explicit server-configured ID. All defaults remain normal play.

## Passed automated verification

```
python scripts/check_stage4.py
python scripts/check_luau.py
rojo build default.project.json -o build/WorldConquest-stage4.rbxlx
```

Full transcript: `build/stage4-results.txt`. Build artifact:
`build/WorldConquest-stage4.rbxlx`.

* 90 original starting/income profiles across Human/Nation/Bot, multipliers, host
  overrides and different territory/population inputs; no fabricated growth factor.
* 45 actual GameImpl conquest cases, odd balances and values above 2^53, skipped
  transfer, and positive/zero/negative net attack statistics.
* 24 original donation eligibility/cooldown/accounting cases; exact ledger operations
  into multi-dozen-digit balances; 16 source compact-format boundaries.
* 12 source cost-wrapper cases for human/nation/bot and host/infinite-gold behaviour.
* Transaction affordability, atomic debit, duplicate/stale/conflicting sequences,
  unknown/malformed product, negative cost, NaN sequence, failed eligibility,
  spectator/forged player rejection and config limits.
* 300-tick two-simulation replay and replica consistency with purchases, retries,
  territory changes, constant income, countdown suppression and death cleanup.
* Actual attack/remnant and encirclement conquest hooks award and remove the expected
  money. A full economy-enabled combat benchmark runs recruitment/connectivity too.
* Production RemoteEvent adapter with two Earth clients: exact private money/rate
  fields, forged Purchase/SetGold rejection, combat/retreat, replicas and disconnect.
  Roblox services are stubbed; this is not a live Studio networking/UI test.
* Stage 1-3 regressions still pass, including 1,040 upstream battle ticks, 310 cluster
  fixtures, source recruitment/neutral expansion and 1,184 coordinate round trips.

Oracles can be regenerated with a Node runtime exposing node:module.stripTypeScriptTypes:
run `node scripts/prepare_economy_oracle.mjs`, then `node scripts/generate_economy_oracle.mjs`.
The normal Luau checks use the checked-in reference JSON and require no Node installation.

## Performance and remaining risks

Latest local Luau CLI measurements, not Roblox transport/GPU/device guarantees:

| Workload | Mean / p95 / max |
| --- | --- |
| Income only, 100 players x 1,000 ticks | **0.169 / 0.241 / 0.391 ms per tick** |
| Stage 4: 100 humans / 50 fronts / 180,000 initial cells / 240 ticks, including income, recruitment and connectivity | **4.026 / 11.805 / 18.423 ms per tick** |
| Existing adversarial 262,000-cell territory with a hole | **158.886 ms for one connectivity pass** |

Income performs no grid reads or world scans. It is O(players * decimal digits).
Heavy combat still made 43,150 captures; raw ownership delta average 1,079 B/tick,
maximum 5,400 B; 2,457,600 B ownership buffers and 4,915,200 B traversal scratch.
The cumulative harness heap at the end was 103,771 KiB, not isolated Roblox memory.
Income-only before/after heap varied with GC; do not infer allocation cost by
subtracting those process-wide values.

Money/rate strings piggyback on each player's existing private 5 Hz stats packet;
there is no per-income-tick RemoteEvent or world rebroadcast. Snapshots include balance
for initial/resync state. For a six-digit balance plus three-digit rate, the two value
strings add roughly 45 bytes/second per recipient before key/serialization overhead.
Actual transport must be measured in Studio. EconomyMilliseconds measures passive
grants; TickMilliseconds includes the whole simulation/transport work.

Existing Earth/neutral p95 and large-region cluster stalls remain performance risks.
We did not change conquest budgets or hide those limits. Live multiplayer acceptance,
HUD readability on small windows and device/network profiling remain pending as the
user specified. No full OpenFront match, building, trade or diplomacy parity is claimed.

## Manual Studio acceptance (not run in this pass)

1. Stop tests, sync Rojo or open the Stage 4 build. Confirm Config has Foundation,
   PortStage=4 and the default Economy settings. Start Server & Clients with 2 clients.
2. Select nearby inland spawns in the 20-second phase. Both money balances should
   remain 0 during selection. Confirm markers, zoom and pan still work.
3. After start, the HUD should show money and +1.00K/s. For exact values, attach this
   in a client Command Bar while testing (each client receives its own stats):

   ```lua
   game.ReplicatedStorage.WorldConquestEvent.OnClientEvent:Connect(function(action, p)
       if action == "FoundationStats" then print(p.Tick, p.Gold, p.GoldIncome) end
   end)
   ```

   With no conquest/transfers, balance difference must equal **100 times the tick
   difference**, after income activation. Wall-clock delays may reflect backlog.
4. Expand much more land in one client than the other. Income must remain 100/tick
   in both; soldiers and territory still change normally. Resizing/panning/zooming
   must not alter the clicked ownership cell or disconnect money updates.
5. Have both clients expand/attack, then eliminate one. Pass: eligible human loot
   is floor(loser balance/2) at the source conquest call, loser balance is removed,
   loser income stops. Tick-time income and sub-100-cell remnant processing affect
   the exact observed before/after samples, so use server ticks and captured logs.
   In a separate run, never send an attack from the victim: there should be no loot.
6. Repeat counterattacks and Stop/return, including a merge near retreat completion.
   Soldiers must still follow Stage 3 rules; cancelling an army does not refund
   gold, since army orders have no gold cost. Net attack statistics affect eligibility.
7. While no economic event is happening, try these from a client Command Bar:
   `game.ReplicatedStorage.WorldConquestEvent:FireServer("SetGold", "999999999")`
   and `:FireServer("Purchase", 1, "fake")` on that same RemoteEvent. Both are ignored;
   money should only increase with normal ticks. There is deliberately nothing to buy.
8. Stop and test StartingGold="12345", GoldMultiplier=1.239 in shared Config. During
   selection exact balance should be 12345 with no growth; in-match rate is **123/tick**,
   not 123.9. The compact HUD shows +1.23K/s. Restore defaults and resync afterward.
9. Run 3-4 clients: simultaneous attacks, elimination, a disconnect and a late spectator
   join. Confirm snapshots and private money messages agree with server state, spectators
   cannot earn/spend, no double loot and no Output errors. Donation and future purchases
   are automated/server-API tests only; no UI is present to exercise them manually.
10. Inspect WorldConquestEvent attributes EconomyMilliseconds, TickMilliseconds and
    TickBacklogSeconds; use MicroProfiler/Developer Console for server CPU, client memory,
    networking and paint queues. Carry forward the Stage 3 acceptance checklist for
    encirclement, islands, narrow borders and the previously measured stall risk.

AGPL-3.0, upstream additional terms and visible OpenFront attribution remain intact.
The corresponding-source publication setup is still the existing release task;
Config.SourceURL remains unconfigured. This change does not publish an experience.
