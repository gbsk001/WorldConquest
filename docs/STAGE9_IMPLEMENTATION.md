# Stage 9 — server AI and solo gameplay

Stage 9 is enabled in Rojo. The default is five Normal bots alongside human players. This is a working, deterministic **partial port of upstream nation AI**, with bounded Roblox decision adapters. It is not a claim that every OpenFront nation behaviour has been reproduced. No Studio/live multiplayer or physical-device testing was performed.

See [measured before/after performance](STAGE9_PERFORMANCE.md) and [changed files](STAGE9_CHANGED_FILES.md).

## Source and difficulty

Pinned source: OpenFrontIO `8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94`, inspected in `build/OpenFrontIO`. `tests/stage9/source-hashes.json` records the inspected sources. Copyright and AGPL notices remain.

| Source | Luau mapping |
|---|---|
| `NationExecution.ts` constructor/getAttackRate | `BotRules.personality`: same PRNG, ID/seed hash, trigger/reserve/expansion draws and reaction intervals |
| `utils/AiAttackBehavior.ts` reserveTroops/sendLandAttack | Reserve-based troop allocation through the existing Expand command |
| `nation/NationAttackBehavior.ts` | Neutral-first preference, stable weakest-neighbour ordering, human-attack reluctance, Hard threat cap and too-weak rejection; bounded frontier sampling replaces full neighbour discovery |
| `nation/NationStructureBehavior.ts` | City-first development, port/factory/SAM/silo ratios and density-based preference for upgrades; placement and purchase remain the existing authoritative implementation |
| `nation/NationNukePlanning.ts` | Direct weighted grid-sampled enemy blast coverage and friendly-land disk rejection |
| `SpawnExecution.ts` | Existing actual spawn algorithm supplies bot spawn positions; no bespoke random territory assignment |
| Existing expansion/economy/buildings/naval/missile/match modules | Execute bot intents with the same charges, cooldowns, construction, routing, damage, elimination and victory rules as humans |

Normal maps to upstream Medium. Reaction intervals use half-open integer ranges: Easy 65–99 ticks, Normal 55–69, Hard 45–59. Trigger ratio is 50–59%, attack reserve 30–39%, neutral-expansion reserve 10–19%, sampled once per bot from its seeded PRNG. Easy considers human attacks on one in four draws; Normal on three in four; Hard has no such reluctance. Hard retains `ceil(0.75 × strongest other sampled enemy troops)`, subject to incoming-army retaliation allowance, and rejects unprovoked sends below 20% of the target's troops. Team games bypass that threat cap.

All difficulties use **human initial soldiers, recruitment, cap, income, prices and combat rules**. `IsBot` identifies the controller; `Kind="Human"` intentionally avoids upstream Nation resource multipliers and Bot discounts. This is a requested fairness adaptation. Bots share human spawn immunity. There are no resource grants or instant construction in production defaults.

## Controls and lifecycle

Configure `src/shared/Config.luau` before starting the server:

```lua
PortStage = 9,
Bots = {
    Enabled = true,
    Count = 5,                  -- 0–100, fixed roster when not filling
    Difficulty = "Normal",     -- Easy / Normal / Hard
    FillEmptySlots = false,
    TargetPlayers = 10,         -- humans + bots when filling
    DecisionsPerTick = 2,       -- global deterministic decision budget
    SampleCells = 64,           -- bounded border slot probes per decision
    TerrainCachePages = 4096,   -- server only, up to 16 MiB decoded terrain
    -- DecisionTicks = 60,      -- optional common reaction interval, 10–600
    BuildEveryDecisions = 2,
    AdvancedEveryDecisions = 3,
    Buildings = true,
    Naval = true,
    Missiles = true,
},
Match = {Mode="FFA", WinThresholdTenths=800, SinglePlayer=true},
```

Use `SinglePlayer=true` in a private/reserved Roblox server or local solo test. The first active human is admitted; additional humans spectate until a fresh round. This setting does not create a private server or implement matchmaking. Leave it unset for ordinary multiplayer with bots. Server-side configuration is deliberate; clients cannot set bot identities, grant resources, or send orders on behalf of bots.

Bot roster size is fixed near the end of spawn selection using the human count then. Fill mode adds enough bots to reach TargetPlayers, capped at 100 bots. Late arrivals spectate normally; active bots are not silently removed/replaced. Bots use reserved negative internal IDs outside ordinary Studio test IDs. They appear as `[BOT] AI <difficulty> <number>` on the existing leaderboard. The GUI redesign and its controls remain intact.

Each round gets fresh bot identities/state, PRNGs, order sequences and economy through a fresh Simulation. Last-human departure ends the round rather than running an abandoned bot match forever. Eliminated bots stop deciding; victory/results freeze AI. Bots can win normal FFA and configured team matches through the existing Match module. The upstream reserved `"Bot"` team cannot win; choose a different team identifier when explicitly configuring teams.

## Decisions and bounded work

Bots sample their ordered frontier, expand into non-fallout neutral land, choose enemy targets, retain reserves and cancel outgoing armies when incoming troops exceed home reserves. Cities, defensive posts, factories, coastal ports, silos and SAMs use ordinary build orders. Upgrades use ordinary upgrade purchases. SAM and warship combat are handled by existing automatic unit executions.

Naval decisions buy a warship from a valid completed port and sample up to 16 nearby coast candidates for transport invasions. Nuclear decisions select an enemy/crown candidate, prefer known structures, require a ready silo and affordability, check sampled enemy coverage and reject friendly land in the target blast. All selected orders are revalidated when executed. Failed transport routing is a normal rejected order, not free movement or refunded fabricated success.

A deterministic rotating scheduler services at most DecisionsPerTick due bots. Delayed decisions move to a later tick rather than using wall-clock cutoffs. Border and owned-cell cursors examine bounded slots, including tombstones. There is no full-grid decision scan. Public player summaries and owned unit lists may be inspected; missile safety scans are bounded to the blast disk. Existing gameplay executions, pathfinding and connectivity can still be expensive independently of the decision budget.

Private HUD quotes/stats are no longer generated for bots because they have no client recipient. The existing 128-page immutable terrain LRU had severe contention with scattered Earth bots. Its eviction now uses an O(1) linked order. Stage 9 servers opt into 4,096 pages; clients retain the 128-page / 512 KiB default. Terrain bytes, ownership, formulas and resolution are unchanged. See `build/stage9-earth-benchmarks-before.json` and the latest benchmark report for measured effects.

## Explicit deviations and limitations

- This does not port the complete diplomacy/emoji/alliance/embargo system, bot annexation planning, runaway-leader coalitions, beachhead follow-ups, warship retaliation/infestation planning, or upstream naval route-risk scoring.
- Advanced priorities are a bounded adapter, not the complete upstream perceived-cost/savings model. Structure and advanced decisions share a budget instead of running all upstream behaviours in one reaction tick.
- Local frontier sampling can miss a threat temporarily. Stable ordering is preserved among sampled neighbours, not all upstream neighbours. The scheduler can delay reactions under load.
- Nuclear coverage/friendly-land helpers are ported, but complete SAM-overwhelm salvo planning, interception-cost forecasting, recently-launched strike deduplication and upstream MIRV savings/target optimization are not. MIRV uses an adapter minimum target size of 3,500 cells and the existing real MIRV execution. Friendly safety at the chosen carrier target does not guarantee every eventual warhead is far from a moving friendly frontier.
- Spawn-phase re-hopping is omitted; bots are admitted near the countdown end and use normal automatic spawns. No autonomous replacement mid-round, save/resume, bot lobby editor or private-server purchase/teleport UI was added.
- Existing Stage 6 route differences and Stage 7/8 large combat/missile/network stalls remain relevant. A short early-game bot benchmark cannot certify a long, wealthy full match or 100 simultaneous MIRVs.

## Tests and reproduction

`python scripts/check_stage9.py` runs the real production simulation, explicit advanced fixtures, repeated compact 20/50/100 bot workloads and a real FoundationServer/Replica harness with stubbed Roblox services. `--quick` omits only the repeated compact load runs. Tests cover spawn/disable/fill, resource parity, enemy combat, building purchase/upgrade, defence cancellation, warship/transport purchase, missile purchase/launch, elimination, bot victory, freeze, solo spectators, restart, labels, stats routing and deterministic replay.

`scripts/generate_bot_oracle.mjs` extracts original pinned TypeScript methods and executes them using Node's TypeScript stripping. The fixture compares 300 original NationExecution personality/rate/offset cases and 30 original nuclear coverage/friendly-land cases. These are targeted exact parity checks; the complete AI adapter is not an upstream end-to-end parity implementation.

Regeneration was verified byte-identical: SHA-256 `52a8d2cab95675ea15b256bb561d0e3fc94c6c691ddcbf849886c2352739bd38`, recorded in `tests/stage9/regeneration.json`.

Run `python scripts/check_stage8_all.py` for the complete Stage 1–8 regression suite, `python scripts/check_strategy_ui.py` for GUI adapters, and `python scripts/benchmark_bots.py` for two fresh-process 600-tick Earth runs at each requested count. Results are standalone Luau simulation and buffer lengths, not live Roblox, transport or GPU measurements. `python scripts/package_stage9.py` builds and verifies embedded sources.

## Studio acceptance steps — pending

1. Stop Play; sync Rojo or open `build/WorldConquest-stage9.rbxlx`. Confirm Stage=9, Normal, Count=5. Keep all production economy/building defaults.
2. Run one client with SinglePlayer=true. Observe countdown, automatic bot spawns, `[BOT]` leaderboard entries and recruiting/expanding armies. Verify the human still uses the redesigned HUD, map pan/zoom and placement controls.
3. Repeat Easy/Normal/Hard with the same seed. Verify equal starting resources and differing decision timing; no hidden gold/troop bonuses.
4. Exercise bot combat, defensive reserve behaviour, retreat, city/factory/port purchases and upgrades. In an unpublished test copy only, grant all players equal test gold to exercise advanced systems sooner; restore defaults afterward.
5. Put opponents on reachable coasts; observe a purchased warship and real invasion/landing. Verify ships cannot cross invalid water components. Observe missile purchase, travel, SAM defence, impact and fallout; test close friendly territory.
6. Eliminate a bot and verify no further decisions; let a bot satisfy the normal victory threshold or a test-only timer. Check results and three fresh restarts, reset prices/inventory/AI sequences, and stale-round rejection.
7. Join a second client in SinglePlayer mode (spectator), then test ordinary multiplayer and fill mode. Disconnect the last human; rejoin and verify a clean round. Disabled bots and Count=0 must create none.
8. Start at 2–5 bots. Profile server tick/backlog, BotDecisionMilliseconds/BotDecisions/BotOrders/BotCount and actual network/memory. Scale only after acceptance at lower counts. Test dense land wars, routes and rich late-game salvos, not just the early benchmark.
9. Repeat GUI acceptance on desktop/mobile, test recovery/late joins and run a long memory soak. Record versions, settings and pass/fail evidence.

Publication still requires real Studio/device acceptance, performance/network risk resolution, restored test overrides, and a public corresponding-source offer (`Config.SourceURL` is blank). No new third-party visual/audio assets were introduced; existing AGPL/data notices remain. Nothing was published.
