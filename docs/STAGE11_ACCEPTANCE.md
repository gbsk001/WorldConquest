# Stage 11 and graphical icon acceptance - 23 November 2026

## Status
Implemented in the production Luau/Rojo sources and packaged as `build/WorldConquest-stage10.rbxlx` (requested filename; PortStage=11). Stages 1-10 remain enabled. **Not accepted for hundreds of production participants.** Public target is 250, maximum experimental configuration 500, shipped safe limit 20 total players. The 20-player early-game simulation meets the requested tick targets; that is not certification of a full live match.

## Implemented
- Public rosters fill remaining safe-cap slots with Normal AI; human admissions displace AI slots before starting. Private hosts retain count/difficulty controls, validated against capacity. Matchmaking namespaces isolate Stage 11 from old Stage 10 servers.
- Fresh server-generated session GUID seeds names, colours, spawn candidates and decision timing. Same seed and input order replay deterministically. Names stay shared across lobby/game/results; no individual AI or difficulty badges. Existing generated profiles and general AI disclosure remain.
- AI roster exists at selection start. Seeded decisions are staggered through the 20-second countdown, at most four spawn executions per tick. Every seventh AI can reconsider later. Spatial buckets enforce reservation spacing; human reselection frees its previous reservation and invalid moves retain it. Water/impassable/occupied cells are rejected. Automatic candidates mix global land sampling and local geographical clusters.
- Human reservations remain server-authoritative; selection changes are coalesced to 5 Hz and replicated as compact changed-player records, with full metadata at roster/phase boundaries. Final cutoff locks selections. Markers and selected/total count update across replicas. Low zoom hides crowded names; local marker is prioritised and highlighted.
- Reused sorted player lists and AI neighbor scratch tables reduce repeated allocation. Existing shared terrain cache, two AI decisions per tick and sampled target searches remain. Large populations consequently have slower per-player decision cadence; this is not equivalent to every AI deciding every tick.
- Seventeen original code-drawn graphical types cover cities, factories, defense posts, ports, SAM, silos, transports, warships, trade ships, trains, carriages and projectiles. No emoji, downloaded asset or letter abbreviations. Shared art is used in map, shop, purchase controls and building information. Numeric level sits beside the icon; transparent backgrounds and owner accent remain.
- Map icons pool/reuse objects, cull offscreen units, suppress 26-pixel bucket overlaps and bound visible objects to 256 per layer. Camera zoom scales symbols within 14-30 pixels. Building clicks open information with level, effect, upgrade quote and existing Upgrade/Demolish actions. Desktop placement ghost shows land/ownership feedback; full placement legality remains server-side. Train/carriage presentation snapshots update at 1 Hz, without changing rail simulation.

## Measurements
Fresh-process Luau CLI, actual 8192x4096 Earth grid, fixed seed 12345, one human observer plus N-1 simulated Normal opponents, 202 selection ticks then 600 gameplay ticks (60 simulated seconds). One timing sample per count. Timing is wall-clock on this development machine, not Roblox hosting. Heap is `gcinfo()` peak, not native memory/RSS. These are early-game expansion workloads, not mature missile/rail/naval wars. Lower 500-player results do not establish better scaling: decision budget and different territory contention change work.

| Total participants | Average ms | p95 ms | Worst ms | Peak Luau heap MiB | Encoded deltas MiB | Largest raw delta KiB | Metadata estimate MiB |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 20 | 4.81 | 14.95 | 63.13 | 181.4 | 1.23 | 7.3 | 0.63 |
| 100 | 25.04 | 65.03 | 122.07 | 594.6 | 6.60 | 32.6 | 3.12 |
| 200 | 60.38 | 209.56 | 1973.54 | 1027.0 | 13.13 | 92.5 | 6.37 |
| 250 | 50.10 | 177.06 | 336.68 | 951.4 | 12.78 | 89.9 | 7.77 |
| 300 | 73.45 | 215.50 | 378.88 | 1183.9 | 18.26 | 94.5 | 9.37 |
| 500 | 60.57 | 143.42 | 269.24 | 1050.6 | 14.68 | 62.1 | 16.86 |

Encoded territory/building/ship buffer totals are per stream before transport, compression and client fanout. Metadata estimate covers selection and gameplay table payloads; it is not Roblox wire traffic. Actual aggregate egress depends on human recipients, snapshots and Roblox serialization. Do not multiply these numbers into a production capacity promise. `build/stage11-earth-benchmarks.json` retains exact measurements/component means (historical key `bots` denotes total participants).

Frontier processing dominates: mean 22.35 ms at 100, 49.11 at 200, 44.58 at 250, 66.53 at 300, 54.16 at 500. The 200-player run includes a 1,973.54 ms tick and 5.91 ms average naval work; the long unreachable naval search is still a publication blocker for larger loads. Heap peaks exceed 1 GiB at 300/500. No gameplay work was discarded or territory resolution reduced to hide these failures.

The initial in-task baseline (`build/stage11-earth-before.json`) measured 100 participants at 31.31/79.67/155.75 ms average/p95/worst, versus 25.04/65.03/122.07 ms after. However the final spawn distribution added clustering, so this is a development comparison, not an isolated optimization speedup. At 250 the corresponding values were 58.51/205.56/375.43 versus 50.10/177.06/336.68. Both still fail.

Client icon CPU fixture: 5,000 unit inputs, 200 camera updates, latest full-gate average 0.707 ms, p95 0.774 ms, worst 1.078 ms; at most 256 visible icons per tested layer, no extra allocation on stationary updates. This uses GUI stubs and does **not** measure Roblox drawing/GPU/frame time. Native desktop/mobile dense-scene rendering remains unmeasured.

## Tests
`python scripts/check_stage10_all.py` passed Stage 1-11 automated functional regressions: Stage 1-8 parity/security/recovery suites, Stage 9 bots/replays/actions, Stage 10 matchmaking/UI adapters, transparent map labels, graphical geometry/pooling and Stage 11 selections. Follow-up `check_stage10.py` passes fresh seeds, safe capacity, human-priority AI fill, names and seed projection; `check_strategy_ui.py` passes final purchase-control padding edits and building inspection intent.

Stage 11 tests cover 100 staggered selections, land validity, reservation spacing, conflicting human inputs, moving/releasing old reservations, rejected invalid moves, AI reconsideration, cutoff rejection, different-seed variation and identical-seed replay. Two independent client replicas receive the production deltas. These are simulated clients, not two Studio windows. Stage 8 100-player missile stress still reports worst ticks of 114.68-127.17 ms in the final rerun; functional pass is not a performance pass.

## Rendered Studio scope
Actual Windows Roblox Studio Play was inspected, not just layout stubs. Connected production Rojo showed the 20-player lobby, generated names/profiles, disclosure, 4/20 -> 10/20 -> 16/20 spawn selections, circular markers, transparent outlined labels, human selection/reselection and transition to gameplay. A separate `WorldConquest-icon-preview.rbxlx` fixture rendered all 17 production icon geometries. It changes only starting gold/instant construction and adds a G-toggle gallery, and must never be published. Additional map/shop observations are recorded below after testing.

No published server, live multi-human session, production matchmaking/social/teleport call, mobile hardware or 250/500-player Studio rendering was verified.

## Changed source groups
- `src/shared/Config.luau`; `src/server/Main.server.luau`, `LobbyServer.luau`, `LobbyStore.luau`, `LobbyState.luau`: population cap, new seed and session bridge.
- `src/server/OpenFront/SpawnIndex.luau` (new), `SpawnExecution.luau`, `Bots.luau`, `Simulation.luau`, `FoundationServer.luau`: spatial reservations, staggered/reconsidered choices, cached lists/scratch, deterministic metadata/delta integration and seeded colour.
- `src/server/OpenFront/Rail.luau`; `src/shared/OpenFront/Replica.luau`: presentation snapshots and spawn-delta application/reassembly.
- `src/client/InterfaceArt.luau`, `IconLayer.luau`, `MapView.luau`, `Main.client.luau`, `BuildingShop.luau`, `NavalControls.luau`, `MissileControls.luau`, `MainMenu.luau`: shared graphical types, map markers, placement/inspection, responsive population configuration.
- `scripts/check_stage1.py`, `check_stage10_all.py`, `lobby_scenarios.luau`, `check_stage11.py`, `stage11_checks.luau`, `benchmark_stage11.py`, `stage11_benchmark.luau`, `check_unit_icons.py`, `unit_icon_checks.luau`, GUI/map-label fixtures and `package_stage10.py`; README and this report.

## Manual multiplayer acceptance checklist
1. Open `build/WorldConquest-stage10.rbxlx`, not the root historical place or extra-gold fixture. Confirm PortStage 11, StartingGold 0, InstantBuild false, safe cap 20, exact production source manifest.
2. Start a Studio server with at least two clients. Join Public; verify humans replace AI slots, total stays 20, same names/profiles/colours on both clients. Repeat Private with zero/maximum bots and each difficulty; only host can configure/start.
3. During countdown select identical points simultaneously; only one reservation must succeed. Move one selection; both clients must immediately converge and freed land becomes available. Try water, lakes, invalid land, occupied territory and final-boundary requests. Observe staggered AI markers/reconsideration, 20/20 at start, same shared launch tick.
4. Repeat several fresh matches; names/locations/colours must differ. Replay saved same seed+intents and compare deterministic state hashes. Disconnect/reconnect during selection and gameplay; stale round deltas/orders must be rejected.
5. In a disposable local fixture, buy each building, inspect level/effect/price, upgrade and demolish. Check port coast constraints and SAM/silo rules. Verify numeric levels, owner accents, transparent backgrounds, placement cancellation, zoom/pan, dense overlaps and hidden-icon hit rejection. Check navy, train/carriage and each missile in motion.
6. Desktop resolutions and mobile portrait/landscape: inspect safe areas, shop/info panel sizing, touch hit targets, preview behavior, local marker visibility, zoom/pan and no map-click interception by labels. Record MicroProfiler, frame p95, memory and actual Stats network traffic with dense unit fixtures.
7. Published private staging: real teleport failure/recovery, reserved-code privacy, friends/invites, human capacity, late joins, host transfer, full victory/results/menu/restart. Test sustained late-game battles and unreachable paths, not just 60 seconds of expansion.
8. Raise safe cap only after repeated complete-match server and client measurements meet tick/memory/network budgets. 250/500 remain disabled until then.

## Remaining limitations and publication blockers
- Large population performance is **not solved**; frontier memory/work and pathological naval routes remain major issues. Mature combat, combined missile impacts, rail, recovery storms and human network fanout need sustained benchmarks.
- AI algorithms retain documented Stage 9 upstream deviations; this is not a new full upstream AI parity claim. Global decision budgeting changes per-player reaction cadence at high counts. Same seed alone requires same human inputs/order to replay.
- Marker changes are batched at 5 Hz, not zero-latency delivery. Compact metadata reduces selection bursts, but full roster/profile snapshots still grow with population. Lobby participant cards are not virtualized for 500; shipped safe limit avoids that unverified UI load.
- Icon culling scans the unit list when dirty/camera changes; capped GUI count bounds objects but does not provide a spatial unit query. Train rendering currently receives 1 Hz positions. Touch placement and actual GPU performance remain acceptance items.
- Original code-drawn icons introduce no third-party image licence. Existing AGPL notices remain. Configure a publicly accessible Corresponding Source release and `Config.SourceURL`, ship licence/notices and verify all inherited assets before publishing. Existing `NOTICE` and upstream audit documents remain authoritative; no new upstream formulas were introduced here.

### Studio findings and follow-up
The first fixture also rendered map building levels/owner accents, the graphical shop, animated missiles and a click-open SAM information panel. It exposed a preview ghost offset: it subtracted the ScreenGui inset while the established map input transform adds the reported root origin. Production MapView now calls the same `MapTransform.screenToGui` as map input. Regression checks cover that shared path; final native recheck is recorded below. The v2 fixture disables AI execution to isolate human placement, in addition to extra gold/instant build. Neither fixture is the release artifact.

A second integration bug surfaced in the rendered shop: public metadata refresh replaced the local profile, dropping private building/naval/missile/rail quotes until the next private stats packet. The client now retains those four private fields across public refreshes, while preserving newer public state and clearing them on MatchReset. `check_private_profile.py` tests retention, fresh-data precedence, player isolation and reset; it is included in the full gate.

Final v2 native observations: corrected ghost centred on the cursor; human City purchase returned `Build:City accepted`; its transparent skyline/level 1 rendered on the map; click opened City information with a $250K upgrade quote; Upgrade returned `Upgrade accepted`, gold decreased and the map displayed level 2. The public-profile quote-retention fix was made after this fixture was built, so that final change is automated-tested, not separately native-rendered. Studio Play was stopped after inspection. Full native multiplayer/mobile acceptance remains pending.

For repeatable isolated visual checks, run `python scripts/package_stage10.py` then `python scripts/package_icon_preview.py`; open the resulting **icon-preview** file only for testing. G toggles the gallery. This fixture intentionally suppresses AI execution even though its lobby cards still reflect the production lobby roster; do not use it to judge population/spawn behavior. Use the release artifact for that acceptance. The final quote-retention change is included in regenerated fixtures.
