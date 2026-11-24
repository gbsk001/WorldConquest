# WorldConquest: OpenFront source audit and porting plan

Current implementation: [Stage 7 report](STAGE7_IMPLEMENTATION.md). Stage 1–6 regressions and Stage 7 simulated stress/recovery checks pass. Live Studio/mobile acceptance, difficult searches and burst networking remain open. The original analysis below is a historical baseline.

Status: analysis baseline, not an implemented or tested OpenFront port.

Upstream: https://github.com/openfrontio/OpenFrontIO

Pinned commit: `8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94`. Findings apply to this revision, not every OpenFront release or the currently deployed website. Inspection date: 2026-11-17. The working checkout is in `build/OpenFrontIO`, outside the Rojo tree. No upstream application code or assets have been installed into the Roblox game. No upstream dependency scripts were executed.

The inspection traced territory, attack resolution, troop regeneration, economy, construction, transport/trade paths, AI entry points, rendering and turn transport, and examined relevant tests. This is a system-level audit, not a claim that every branch of all 124 engine TypeScript files and 748 test files has been verified. Nuclear/rail/AI edge cases require deeper fixture-driven inspection during their stages. See [source index](OPENFRONT_SOURCE_INDEX.md), [file hashes and runtime baseline](openfront-audit-manifest.json), and [local test output](openfront-baseline.txt).

## Decisions that follow from the source

1. The existing free, automatic FIFO expansion is **not OpenFront expansion**. Replace it with troop-funded attack executions and the upstream priority heap. Do not disguise the existing algorithm by adjusting its speed.
2. Troops are player reserves and committed attack stacks, not one soldier object per cell. Cities increase troop capacity; factories create rail/trade opportunities. There is no basis for inventing a flat factory-income mechanic.
3. Transport invasions launch from reachable owned shores; **ports are not a prerequisite**. Ports support trade, warship deployment and rail stations. An invasion must traverse a water route before landing.
4. The current source uses client simulation plus ordered server turns and consensus. Roblox must deliberately replace that trust model with authoritative server simulation, as requested.
5. Map scale affects almost every balance constant. The current 8192x4096 Natural Earth mask is not the same map as upstream World. Keep it as an explicitly different map, and validate formulas on identical small fixture maps before claiming parity.
6. Preserve the functioning Rojo project and camera/input code. Introduce the new simulation behind a configuration switch, validate each stage, and keep a reproducible fallback until the replacement passes its stage gate.

## 1. Territory, terrain, borders and phases

`packages/engine-lib/src/game/GameMapImpl.ts` uses zero-based `tile = y*width+x`, immutable Uint8 terrain and mutable Uint16 state. Terrain includes land bit 7, shoreline bit 6, ocean bit 5 and five magnitude bits. Land magnitude 0-9 is plains, 10-19 highland, 20-30 mountain, and 31 impassable. State includes a 12-bit owner ID, fallout bit 13 and defense bit 14. Ownership ID 0 is neutral; Roblox UserIds must map to compact match-local IDs.

Four-neighbour iteration is N, S, W, E, with **no wrap at map edges**. Existing WorldConquest wraps longitude and uses a different neighbour order. Those differences affect paths, heap ties and deterministic outcomes and must be removed in fidelity mode. Eight-neighbour traversal also exists for specific border/cluster calculations; do not replace every traversal with four-way adjacency indiscriminately.

The current bitmask has no elevation, ocean-component or impassable metadata. Add a terrain byte layer, shore flags, water components and validated magnitude generation. A temporary all-plains fixture is acceptable for tests, but not a claim of geographically accurate mountain combat. Keep elevation provenance and exact raster alignment with the existing land/lake mask.

Map-generator input PNG headers measured at this commit: World 2064x1032, World4000 4120x2060, World10000 10000x5000, GiantWorldMap 4110x1948. These are source image dimensions, not a promise of the selected runtime map size. The generator emits full, half-width/height and quarter-width/height terrain variants; `TerrainMapLoader` selects the runtime files. Exact upstream-map parity needs the selected generated terrain, not a visually similar Earth image. Porting higher-resolution ownership without rescaling distance/tile-count balance changes the experience.

Spawn selection is an execution during the spawn phase. `getSpawnTiles` in `execution/Util.ts` uses a radius-4 Euclidean BFS area with the centre shifted by -0.5 on each axis, then filters invalid/occupied/water/impassable cells. That is different from our one-cell start and deserves an explicit migration. Preserve precise fractional marker positioning as a UI adaptation while the simulation uses an integer tile. Random placement has 1000 attempts, relaxing minimum spawn distance after 750; configured minimum Manhattan distance is 30.

Simulation ticks are 100 ms. Default normal multiplayer spawn phase is 200 turns, random-spawn 150, single-player 100; the timer checks `ticks > numSpawnPhaseTurns`, and single-player human placement can end selection. Default spawn immunity is 50 ticks. Most executions are inactive during selection. Reproduce execution initialization/tick order from `GameImpl.executeNextTick`, not independent unordered task loops.

`WinCheckExecution` checks every 10 ticks. Default victory is strictly more than 80% of non-fallout land, with configurable threshold, timer and team/ranked exceptions. Hard fallback is 170 minutes. Optional overtime defaults to starting at 30 minutes and reducing the target by two percentage points per minute; it is disabled by default. Optional Doomsday Clock is a separate anti-stall system. Those are later-stage features, not silent new rules for the existing prototype.

## 2. Soldiers and expansion: exact rules to translate

Primary sources: `EngineConfig`, shared `Config`, `PlayerExecution`, `PlayerImpl`, `AttackExecution`, `AttackImpl`, `FlatBinaryHeap`, `PseudoRandom`, `DetMath`.

For ordinary human play, reserve capacity is:

`M = 2 * (landTiles^0.6 * 1000 + 50000) + 250000 * completedCityLevels`.

Reserve growth each simulation tick is `(10 + troops^0.73 / 4) * (1 - troops/M)`, clamped so the resulting reserve does not exceed M. `PlayerImpl` applies integer conversion when adding/removing reserves; attack stack losses remain floating point. Do not round every intermediate or use Roblox Random in place of the source RNG. Human initial troops: 25,000. Bot initial troops: 10,000, capacity one-third, growth multiplier 0.5. Nation initial troops by Easy/Medium/Hard/Impossible: 12,500/18,750/25,000/31,250; capacity multipliers 0.5/0.75/1/1.25 and growth multipliers 0.9/0.95/1/1.05. Tutorial and host-cheat overrides are distinct branches.

Default human/nation attack allocation is one-fifth of reserves; bots one-twentieth. The client has a troop allocation slider, default 0.2, with user settings overriding it. Attack init deducts the amount actually removed, cancels opposing incoming stacks against it, and combines compatible outgoing attacks on the same target. Landing attacks have separate source-tile behaviour. Attack eligibility checks friendly relationships and immunity.

Land attacks initialize from the owner's eligible border against a particular owner (including neutral). A heap chooses tile order. For each candidate, priority is:

`(randomInt(0,7) + 10) * (1 - ownedCardinalNeighbors*0.5 + terrainPriority/2) + currentTick`,

where terrainPriority is 1/1.5/2 for plains/highland/mountain and randomInt has exclusive upper bound. The heap stores Float32 priorities with specific tie behaviour; duplicate/stale entries are checked at dequeue. Do not deduplicate or sort differently merely as an optimization without proving identical results.

Each attack tick fixes `borderSize = attack.borderSize + randomInt(0,5)` and starts a budget of 1. It consumes per-tile tick fractions until the budget is spent; troop exhaustion and stale candidates terminate/skip as implemented. Each claimed tile must still belong to the selected target, touch the attacker by an edge, and be passable land. Newly exposed candidates can be processed in the same tick: the existing FIFO's next-wave delay is another deliberate difference to remove. Border bookkeeping and neighbour insertion order are observable.

Terrain base `(lossMagnitude, tileCost)` is plains `(80,16.5)`, highland `(100,20)`, mountain `(120,25)`. Neutral expansion loses magnitude/5 troops per cell for humans/nations, magnitude/10 for bots. Tick fraction is `clamp(2000*tileCost/attackTroops,5,100)/(2*borderSize)`. Thus a plain neutral tile costs 16 human troops before other modifiers; it is not free idle growth.

Retreat returns survivors; cancellation against a player has a 25% troop penalty, neutral retreat does not. Preserve the 20-tick delayed retreat execution and checks that prevent absorbed/cancelled attacks refunding twice. An attack with no valid frontier refunds during init, avoiding reserve-regeneration exploits.

## 3. Combat formulas and territory capture

`EngineConfig.attackLogic` is a pure function and should be translated/tested before combat is connected to live state. Let A/D be attacker/defender land areas, T the committed attack troops, R the defender's reserve, density `d = R/D`, and ratio `r = R/T`.

Define `L(n,k) = 1 - k*sigmoid(log(n),2.5,log(300000))`, using upstream deterministic math and sigmoid semantics. Attacker loss bonus uses k=0.7, attacker speed k=0.73, defender bonus k=0.3.

Per-cell defender loss is d, passed through reserve removal's integer handling. Attacker loss is:

`magnitude * traitorLossModifier * clamp(r,0.6,2) * (0.463*L(A,0.7)*L(D,0.3) + 0.0039*d)`.

Tick fraction is:

`[clamp(r,0.82,7.5)*clamp(r/20,1,50)/8.55] * tileCost * L(A,0.73)*L(D,0.3)*traitorCostModifier / borderSize`.

Defense posts within 30 cells multiply magnitude by 5 and tileCost by 3. Fallout multiplies both by `5 - 2*globalFalloutLandRatio` on affected tiles (follow the code, not its stale comment). Human/nation attacking a bot multiplies magnitude by 0.7. Traitor defender modifiers are 0.5 loss and 0.8 cost. Disconnected teammates have special loss handling. These factors are not interchangeable with a generic attack-vs-defense strength ratio.

`handleDeadDefender` invokes conquest below 100 remaining tiles, then resolves reachable remnants, bounded by 100 passes. `PlayerExecution` separately analyzes border clusters, diagonal pinches, enclosed pockets and primary territory; it is scheduled roughly every 20 ticks and on tiny territories, gated by changes. Capture can transfer structures; defense posts are destroyed instead. Port these rules with the cluster fixtures rather than treating every disconnected island as dead.

## 4. Money, construction and naval balance

Gold is integer/BigInt upstream. Default starting gold is config-provided, otherwise 0; bots start at 0. Base income per tick is 100 for humans/nations and 50 for bots, multiplied by the configured gold multiplier and floored. Capturing a bot/nation grants its remaining gold; capturing a human grants half, with integer division. Donation, embargo and relationship rules affect the wider economy.

Cost counts are not simply current building count: `costWrapper` sums `min(unitsOwned(type), unitsConstructed(type))` for relevant types plus extra requested units. Preserve upgrades and capture semantics.

| Unit | Base cost rule | Construction (normal mode) |
| --- | --- | --- |
| City | min(1,000,000, 125,000 * 2^n), city count | 20 ticks |
| Port / Factory | same exponential rule; shared port+factory count | 50 / 20 ticks |
| Defense post | min(250,000, 50,000*(n+1)) | 50 ticks |
| Missile silo | 1,000,000 | 100 ticks |
| SAM launcher | min(3,000,000, 1,500,000*(n+1)) | 300 ticks |
| Warship | min(1,000,000, 250,000*(n+1)) | no structure timer |
| Atom / Hydrogen bomb | 750,000 / 5,000,000 | execution-specific launch |
| MIRV | 25,000,000 + 15,000,000*globalLaunchCount | execution-specific launch |
| Transport / trade ship / train | no gold unit cost | troops/routes have separate rules |

Construction validates funds, owned land and placement, pays once, waits for the timer, then activates its execution. Nearby valid structure placement searches within radius 15 on owned land, respecting 15-cell separation and stable distance ordering. Ports require shore placement; warships require a completed reachable port. City capacity only counts completed cities. Upgrades validate owner/type/funds and charge through PlayerImpl; do not implement a blanket free level increment.

Ports check trade spawning every 10 ticks with a stagger. Eligible partners are other tradable players' ports sharing reachable water components. Target weights include port level, proximity and friendliness; short-range threshold is 300. Spawn probability uses rejection pity, global ship saturation, player port levels and small-economy boost. `tradeShipGold(distance) = floor((75000/(1+exp(-0.03*(distance-300))) + 50*distance) * goldMultiplier)`. Normal arrival pays source and destination; piracy/recapture changes recipients. Transport, trade and warships are different executions.

Factories create rail stations, including eligible cities/ports/factories within 110 cells; stations have minimum range 15. Trains and rail connectivity are required for faithful factory income. Train arrival base rewards: ally 35,000; team/other 25,000; self 10,000, subtracting 5,000 per adjusted visited-city count (`max(0,citiesVisited-9)`), floor 5,000, then multiplier. Exact stop indexing matters. Train spawn rate uses level decay, global train-unit saturation and small-economy boosts. Both train and trade spawn formulas are indexed in the source reference; preserve them rather than substitute timers.

Transport cap is three concurrent ships. Default troops are floor(reserves/5). `TransportShipUtils` finds a reachable landing shore and closest owned deployment shore by water. Unit creation deducts committed troops. Ships follow a water path, normally one movement step per tick. On landing, the destination is conquered and an `AttackExecution` continues from that tile without charging troops again. Return-to-owned shore normally loses 25%; no-route branches refund as specified. Capture, alliance changes, destruction and destination terrain changes require explicit fixtures.

Water paths use shared component checks, hierarchical A*, minimap conversion, shore coercion and water-path smoothing; the latter is path processing, not ownership-border smoothing. The shared path memo has a 24,000,000-byte upstream budget and invalidates on water changes. Avoid a separate whole-world pathfinding array per ship.

Warships have 1000 base health, shells 250 base damage, patrol range 100, targeting 130, firing interval 20 ticks; healing, retreat, interception, piracy and veterancy have additional rules. Veterancy max is 3, with 20% health/damage increments; these values alone do not fully specify naval combat. Retain the corresponding execution tests before claiming the naval stage is complete.

## 5. AI, UI and multiplayer

Bots/tribes and nations are distinct. Tribes use seeded attack intervals in [40,80), trigger ratio [0.50,0.60), reserve [0.30,0.40), expansion [0.10,0.20), neutral growth, retaliation and target selection. Nation attack cadence varies with difficulty: [65,100), [55,70), [45,60), [30,50) ticks. Nations have separate attack, structure, alliance, emoji, warship, nuke and MIRV behaviours, not a random neighbouring-cell loop. AI must issue the same validated executions as humans; seeded decision order matters.

Upstream rendering is WebGL2: integer ownership textures, palette lookup, terrain passes, GPU scatter patches and border-compute shaders. Border detection compares cardinal owners; highlight expansion and relationship overlays are display effects. GLSL/WebGL/DOM/Lit code cannot be dropped into Roblox. Reuse the ideas and semantic state, rewrite in ScreenGui/EditableImage, pooling sprites and updating only dirty cell regions plus affected border neighbours. Keep simulation and display LOD separate.

The browser worker executes deterministic turns, produces view updates and supports snapshots/replays. Server `GameServer.endTurn` broadcasts ordered intents over WebSocket; `Consensus.ts` documents client-simulation outcomes and weighted votes. Do not reuse consensus for authority in Roblox. `RemoteEvent` ingress must authenticate the actual Player, validate finite bounded arguments, eligibility and funds, and order actions on a server tick. Clients receive ownership/resource/unit deltas and motion plans. They never approve captures, prices or winners.

Keep the current simple controls, then add reserves/cap, committed troops, gold, attack allocation, selected target/attack cancellation, build/upgrade actions and fleet status as their systems arrive. Preserve spawn picking, drag threshold, root GUI inset normalization and pointer-centred zoom. Names and any future chat require Roblox filtering/services. Do not bring browser auth, payments, ads, premium cosmetics, external moderation APIs, or OpenFront branding into the Roblox adaptation.

## Reuse versus rewrite

| Existing or upstream piece | Treatment |
| --- | --- |
| WorldConquest Rojo mappings, camera and MapTransform | Keep; rerun inset/zoom/pan tests at every UI stage |
| Existing Natural Earth land/lakes and provenance | Keep as its own map; add aligned terrain metadata; not upstream-map parity |
| Existing MapTiles / TilePainter | Keep as baseline; add border-neighbour invalidation and measure atlases |
| Existing Frontier and free single-cell click | Retain only as fallback; replace for faithful troop-funded play |
| Existing sparse Owners/Owned/raster tables | Replace with chunked packed state and compact player indices as scaling requires |
| Upstream RNG, deterministic math, heap, pure formulas | Translate to Luau with exact integer/f32 boundaries and golden tests |
| Attack/Player/construction/trade/naval/AI executions | Translate incrementally, preserve execution order and edge cases |
| Upstream Go map tools and data | Offline conversion where licensed; runtime consumes generated Luau/buffers |
| Browser renderer, worker transport, WebSocket server | Rewrite for Roblox; retain state semantics, not incompatible platform files |
| Proprietary/CDN assets and unrelated service integrations | Exclude; original or individually cleared open replacements only |

Proposed modules: `src/shared/OpenFront/{Ruleset,DetMath,Random32,GridCodec,Protocol}`, `src/server/OpenFront/{Simulation,PlayerState,AttackExecution,Economy,Construction,WaterRoutes,Fleet,AI,Snapshot}`, and client HUD/render adapters. Keep authoritative mutations in ServerScriptService. Rojo can map these folders through existing mappings without remapping the place. Pin ruleset and map hashes in snapshots and traces.

Numerical parity needs deliberate work: Luau has no native JavaScript BigInt or Math.imul. Port 32-bit multiply using exact limb arithmetic and `bit32`, including signed/unsigned coercions, the splitmix seed expansion and sfc32 warmup. Preserve f32 heap writes through buffers and upstream deterministic exp/log/pow rather than assuming platform math matches. Use a tested integer representation for large gold/reserve values, or prove a bounded exact-double range below 2^53 and reject unsupported configurations explicitly. Never silently overflow or round money. JavaScript Set insertion order, heap ties and execution order must be represented explicitly; unordered Luau `pairs` is not equivalent.

## Incremental implementation and acceptance gates

Each stage: checkpoint working files, add pure module tests, compare against the pinned TypeScript oracle, integrate behind the mode flag, run Luau compile/Rojo build and two-client Studio checks, then make it the default. Do not move ahead with known regressions.

| Stage | Deliverable | Required evidence before acceptance |
| --- | --- | --- |
| 1 Map and territory engine | Packed grid, tile ID adapter, no-wrap N/S/W/E, terrain classes, compact owners, deterministic scheduler/RNG/heap, source/credit display scaffolding | Bit-exact terrain round trip; first/last-row boundaries; shore/island/lake fixtures; identical heap/RNG traces; preserved camera tests; allocation profile. Existing gameplay still works in fallback mode. |
| 2 Soldiers and expansion | Reserve regeneration/cap, radius-4 spawn footprint, allocated neutral attacks, priority frontier, attack merging/cancellation, troop HUD | Golden neutral loss/speed and reserve curves; integer rounding; multi-front attacks; no-water crossing; no-front refund exploit; two clients agree. Remove free expansion from faithful mode. |
| 3 Combat | Player-v-player formulas, capture, loss/remnant/cluster rules, defense eligibility, attack/retreat UI, minimum team/friendly relationship model | AttackLogicGolden and AttackScenarios equivalents; contested borders; all terrain classes; reserve/stack conservation; diagonal pinches and isolated islands; death and building hooks. Defense/fallout formula branches can be fixture-tested before those units are live. |
| 4 Economy | Integer gold, passive income, capture loot, donation/embargo ledger, transaction events | ConstructionGold/ConquerGold/donation fixtures; rounding and overflow; replayable balances; invalid/spammed purchases rejected. Trade income remains explicitly unavailable until routes exist. |
| 5 Buildings | City/defense/port/factory construction and upgrades; ownership/capture; rail/station/train chain for factories | ConstructionCost/upgrade/capture tests; timed activation and city capacity; defense range formula; rail connectivity and TradeTrainGolden/Scenarios parity. Port trade starts in stage 6; missile systems remain locked until stage 8. |
| 6 Ports and naval invasions | Shared water graph, transports without mandatory ports, trade ships, warships/interception/piracy/repair and landing attacks | TransportShipUtils and TransportShipExecution fixtures; disconnected lakes; failed routes; simultaneous landings; no double troop charge/refund; port capture; trade payouts; warship/veterancy tests; many-ship CPU/memory profile. |
| 7 Multiplayer optimization and UI | Snapshot chunking, ordered/versioned deltas, rejoin/spectator recovery, motion plans, responsive build/attack HUD and visible source/credits | Baseline+delta atomicity; gap/rejoin recovery; malicious requests; 2/8/16/32-player load matrix; slow client/backpressure; mobile pan/touch and UI checks. Basic authority/deltas exist from stage 1, not postponed until here. |
| 8 Additional mechanics | Tribe/nation AI, full diplomacy/teams, rockets/nukes/SAM/fallout/water changes, victory/aftergame, optional clocks, replay/save | One substage per subsystem; seeded AI behaviour traces, alliance/traitor tests, nuclear/terrain mutations, full-game replay and source-attribution audit. Define a feature matrix; never label missing features complete. |

## Roblox performance plan and limits

The existing simulation-only benchmark was rerun: 100 synthetic players, 1000 ticks, 256,000 added cells; mean 1.064 ms/tick, p95 1.638 ms, maximum 6.118 ms. 256,100 sparse raster inserts took 0.047 s. Full fresh tile work was about 17-49 ms total, sliced across frames; 16x16 dirty painting about 0.05-0.07 ms. These measure the **old simple frontier**, not OpenFront combat, pathfinding, networking or Roblox FPS.

At 8192x4096, dense one-byte terrain is 32 MiB and two-byte state 64 MiB. One full Uint32 traversal scratch array adds 128 MiB. A full RGBA map would add 128 MiB before copies/textures. Existing 4 MiB land bits are cheap; duplicating dense tables/sets and scratch buffers is not. Lua per-cell tables are unsuitable at this scale. Prototype chunked buffers, shared scratch with stamps or chunk-local work, compact frontier sets and limited caches; measure overhead and copy peaks, not just raw storage.

At present the prototype has a 1,048,576-owned-cell ceiling and arbitrary 16/player/256-global claim budgets. These are **not upstream balance** and prevent full-world conquest. They must be removed/replaced after profiling, not silently retained in a supposedly faithful ruleset. A work scheduler can spread CPU work over frames while preserving logical tick order; dropping claims or modifying attack budgets changes the game. If 10 Hz cannot be sustained, report slow simulation or restrict admitted match complexity/map choice explicitly.

Roblox [EditableImage](https://create.roblox.com/docs/reference/engine/classes/EditableImage) has a 1024x1024 maximum, device-specific allocation limits, and one display-side image update per frame. The current 32 detail tiles can exhibit delayed presentation under widespread changes. Compare 256/512/1024 atlases, pooled visible tiles, dirty spans versus rectangles, and upload latency. At fit-to-world scale, cells are subpixel; no renderer can show every full-resolution cell separately on a small screen. Do not coarsen simulation to conceal that.

Roblox [buffers](https://create.roblox.com/docs/reference/engine/libraries/buffer) have a 1 GiB per-buffer limit and are copied through APIs. That is a ceiling, not an available memory budget. Split large snapshots into bounded chunks with manifest/tick/hash, atomically install on the client, then replay later deltas. Compress repeated tile IDs with chunk-local runs; retain reliable ownership messages. Use interpolation only for visual unit movement. An uncompressed 100,000 changed cells/s at four-byte ID plus two-byte owner is about 0.6 MB/s per recipient before metadata; fan-out matters. Do not assume browser lockstep bandwidth figures apply to authoritative replication.

Profile each subsystem using Studio MicroProfiler labels, Script Performance, Developer Console memory/network, server tick histograms, render queue age and snapshot peaks. Test 2/8/16/32 clients, 1/4/8 million occupied cells, crowded fronts, AI, 0/50/200 ships, mass captures, nukes and reconnects; increase only after lower loads pass. Proposed targets, not promises: 10 Hz logical ticks with p95 server simulation under 20 ms and no sustained >100 ms backlog; 60 FPS desktop/30 FPS target mobile; client paint CPU around 3 ms/frame; no steadily growing upload/snapshot queue. Measure actual device memory before choosing a supported player/map limit. Live Roblox profiling of the future systems is pending.

## Licensing and asset obligations

This is an engineering compliance plan, not a definitive legal opinion about publishing AGPL software on Roblox. The user's request to investigate licensing is why these issues are documented. They do not prevent local source study or development.

The pinned code is AGPL v3 with additional section 7 attribution/origin terms. Translating TypeScript to Luau is not a way to avoid those terms. Preserve source copyright/licence notices, mark modifications and dates, include the licence, and retain the visible notice **"© OpenFront and Contributors"**. Keep **WorldConquest** as the primary title and identify it as an unofficial modified adaptation; do not imply endorsement. Exact upstream notices are preserved in `third_party/OpenFrontIO`.

[AGPL section 13](https://www.gnu.org/licenses/agpl-3.0.html#section13) requires a modified network-interactive version to prominently offer its Corresponding Source to all remote users at no charge through a standard/customary way of copying software. The conservative plan is a public versioned source repository/archive for the actual running Luau game, including covered server code, client code, modifications, required build/configuration scripts and covered dependencies. Offering only original upstream TypeScript or exposing LocalScripts is insufficient. A private Studio project does not satisfy the offer for remote players. Local private work alone is different from serving remote users.

Plan a visible Credits/Source panel with a release identifier and an accessible source offer, plus experience-level source information using a Roblox-permitted mechanism. Verify the actual allowed link/access route for the target audience before release; a GitHub URL hidden in a developer-only file is not a prominent offer. Do not promise arbitrary clickable external links inside a ScreenGui. Exclude secrets and player data from source bundles. AGPL does not automatically require releasing Roblox's proprietary engine; the scope of the combined adaptation, System Library treatment and platform compatibility needs specific review.

Roblox's [current Creator Terms](https://en.help.roblox.com/hc/en-us/articles/115004647846-Roblox-Terms-of-Use) require adequate rights for uploaded content and platform licences. Do not assume that publishing a GitHub repository alone resolves all compatibility issues with AGPL/CC additional-restriction rules and Roblox distribution. Before public deployment, verify that the proposed upload/source-offer arrangement can satisfy both; obtain appropriate legal review or separate rights-holder permission if needed. This is a publication issue, not a request to stop the authorized implementation work.

Asset licences are separate:

| Material | Observed licence / action |
| --- | --- |
| `resources/` | CC BY-SA 4.0 under its directory licence; preserve creator/source/licence and modification credit, share adaptations under compatible share-alike terms |
| `map-generator/assets/` | Has its own CC BY-SA 4.0 licence, including map inputs; do not assume public domain merely because the subject is Earth |
| `proprietary/` | Restricted licence expressly prohibits reuse in other projects; exclude from WorldConquest |
| CDN/API/database-only skins/audio/assets | Not granted by the code licence; exclude unless independently licensed |
| Existing WorldConquest Natural Earth sources | Public domain with existing provenance; useful to avoid importing unrelated asset obligations |
| OpenStreetMap-derived maps | ODbL; assess database/derived-database and produced-work obligations and attribution for the particular source, not just an image credit |
| Other credited data/assets | GSHHG LGPL-3.0, Bedmap3 CC-BY-4.0, Copernicus-specific terms, Terrain Tiles constituent attributions, Wikimedia image/flag licences, and individual icon sources require per-file tracing |

[CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/) requires attribution, licence identification, change indication, share-alike for adaptations and no additional restrictions. It does not automatically license unrelated code under CC. Directory-level language does not override third-party provenance. `CREDITS.md` lists NOAA/NASA/Natural Earth public-domain material alongside multiple non-public-domain sources, some with custom terms. Do not import every credited asset as if it had one uniform licence. Use original simple UI symbols initially, retain source records/hashes, and admit an asset only after its individual origin is checked. npm dependencies are not part of the Roblox deliverable merely because the audit checkout has a package-lock; any actual translated/bundled dependency needs its own notice review.

## What is complete in this analysis, and what is next

**Stage 4 implementation, 2026-11-18:** money/income, exact integer accounting,
conquest loot, server transaction APIs and automated Stage 1-4 tests are implemented.
See [STAGE4_IMPLEMENTATION.md](STAGE4_IMPLEMENTATION.md) for actual source formulas,
measurements, limitations and the pending live acceptance steps. Stage 5 buildings and the rail/station/train economy are now implemented; see
[STAGE5_IMPLEMENTATION.md](STAGE5_IMPLEMENTATION.md). Automated Stage 1-5 checks pass.
Live Studio acceptance and performance approval remain pending; Stage 6 is not started.


**Implementation update, 2026-11-18:** Stage 1 and Stage 2 code and tests are
implemented. Read [STAGE2_IMPLEMENTATION.md](STAGE2_IMPLEMENTATION.md) for
actual source parity, changes, measurements, smoke tests and remaining acceptance
limits. Stage 3 direct human combat is now implemented and source-parity tested;
see [STAGE3_IMPLEMENTATION.md](STAGE3_IMPLEMENTATION.md). The full Stage 3 gate
now has upstream cluster/pinch implementation and passing automated parity tests;
see [STAGE3_CONNECTIVITY_ACCEPTANCE.md](STAGE3_CONNECTIVITY_ACCEPTANCE.md).
Live Studio acceptance and supported-load performance approval remain open. The
paragraphs below record the earlier analysis baseline, not current runtime status.

Completed: pinned checkout, source-system audit, formula and constant identification, licensing split, reusable/rewrite inventory, eight-stage gates, rollback archive, runtime hashes and passing current Luau checks. Runtime source and Rojo configuration remain unchanged.

Not completed: upstream test execution, a full line-by-line audit of every optional system, TS-versus-Luau oracle comparisons, any new OpenFront gameplay stage, live Roblox load/memory measurements, publication/source hosting or asset clearance for future imports.

Next implementation slice is stage 1: deterministic primitives and packed grid behind a ruleset switch, with fixed oracle fixtures and no dependency on UI assets. The existing Natural Earth map remains available while terrain classification and upstream-map parity are evaluated separately. The full experience remains an incremental port, not a finished feature promised by this plan.
