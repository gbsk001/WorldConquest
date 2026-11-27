# Stage 15 implementation candidate — 27 November 2026

Follow-up: [manual atlas setup, exact economic values, actual delivery/conquest fixtures and Studio-only 300-grey candidate](STAGE15_MANUAL_SETUP.md). The spawn-planner sampling in that follow-up is not a large-population gameplay benchmark.

**Not publication-ready or visually accepted.** This update implements the rendering,
population, AI, infrastructure, economy, notification and status-HUD work together.
The owner's latest instruction explicitly defers heavy benchmarks, Studio, desktop
control and physical-device testing. Work and tests used CLI tools only, below-normal
priority on one logical CPU. No Roblox publication, graphical application launch or
live purchase was performed. `PortStage=11` remains the cumulative simulation switch;
it does not disable the newer interface, progression or Stage 15 adapters.

## Implementation and source mapping

| Requirement | Implemented behaviour / source |
|---|---|
| Terrain transitions | `MapTiles`: prepare a complete visible cohort before presentation; preserve the preceding cohort, fade new tiles together, reuse cached slots and prefetch four adjacent regions after visible work. Shared tiles do not fade. Device allocation-ceiling recovery retires a cohort together to the complete overview. |
| Terrain work and sharpness | `TilePainter`, `TerrainColors`, `DirtyTiles`: retain the Stage 14 native 10800×5400 geography, cached static terrain and changed ownership regions. 8192×4096 simulation unchanged. One upload/allocation per frame; existing time/row budgets; 32 desktop / 8 touch detail-image ceiling, divided between displayed and staging cohorts. Maximum zoom remains 64. |
| Compact notifications | `ToastStack`, `StrategyUI`: maximum three 2.8-second toasts, deduplication, dismissal, restrained motion, category colours/icons, All/Important/Minimal preferences. Routine neutral expansion is silent; construction completion and existing transaction/attack/reward messages are retained. Toasts sit beneath status and hide while conflicting panels/spawn controls are open. |
| Top-right status (§25) | `MatchStatus`: separate measured timer, rank and territory slots, horizontal layout, graphical icons/separators, opaque navy background, no gameplay WORLD CONQUEST title. Dynamic widths, smaller typography on narrow safe areas. |
| Layering / overlap audit | `Main.client`: map ScreenGui DisplayOrder 10, safe gameplay UI DisplayOrder 20, sibling ZIndex. Map crowns/names/flags/buildings cannot cover HUD. Rail lines sit inside the map canvas below markers. Leaderboard columns truncate names separately; building information responds to safe-area resizing; menus and toasts account for status height. |
| Initial balance | `Config.Balance`, `Simulation`: 5,000 soldiers for humans and competitive AI; 20% default allocation; zero starting gold. Recruitment multiplier 0.5 for both, proposed for acceptance. No resource advantage for competitive AI. |
| Lightweight nations | `BasicNations`: separate seeded controller, 500–1,500 starting soldiers, upstream Bot resistance/capacity rules, 0.2 recruitment multiplier, local neutral expansion, no economy/building/naval/missile planning. At most eight joins/spawns and four due decisions per tick; twelve sampled border cells per decision, normally 120–239 ticks apart. Shares geography and existing authoritative ownership/frontiers. |
| Population / spawning | Combined SpawnPlanner quotas for competitive and basic populations; existing geographic land-area balancing, Antarctica exclusion, spatial reservations, human displacement priority, fresh lobby seeds and live markers retained. Public competitive capacity stays 20. Basic requested count 350, **SafeCount=0** pending load acceptance. |
| Competitive AI | `Bots`: production option removes the large-capacity wait that left rich armies idle. Neutral probes can restart at 1,000 soldiers with no outgoing front; sends remain troop/reserve/threat limited. Bounded infrastructure probes near existing buildings encourage useful connections. Coastal enemy-border and global probes allow distant naval opportunities. Existing defence, upgrades and missiles remain. No free gold/territory or guaranteed victory shortcut. |
| Rail connectivity | Existing Stage 5 `Rail`/`RailPath` completed, not replaced. One queued connection search, deterministic 512-work allowance per tick; 256-entry directional positive/negative terrain-route cache. Completed Factory/City/Port station eligibility and distance/path rules remain pinned. Capture/destruction updates networks; cached geometry does not cache trade permissions. |
| Trains / trade | Existing train execution, carriage damage and source gold payouts retained. Read-only rolling income ledger records actual deliveries. `RailLayer` receives versioned geometry in four-route batches; atomic install, compressed turns, spatial buckets, 420 desktop / 160 touch pooled 2-D segments, ownership tint. `UnitMotion` interpolates recent authoritative waypoints, including corners; no train Parts or gameplay prediction. Ships now interpolate their replicated movement too. |
| Maritime pathfinding | Existing Stage 6 water A* retains costs, heuristics and tie ordering. At most two resumable workers, shared 1,024-node work allowance per simulation tick. Shoreline preparation also yields; only complete caches are published. Transport preparation occurs before the atomic purchase, then revalidates current resources/ownership. Pending duplicate commands cannot duplicate troop debits. Worker cancellation handles removed units/targets. |
| Maritime correctness | Existing ports/trade payouts/warships/transports preserved. Captured or destroyed sources and destinations invalidate deliveries. Failed paths clean up rather than permanently freezing ships. Search timing excludes time suspended between ticks. |
| Economy inspection | `EconomyPanel` opens by tapping the HUD gold balance and closes independently. Gold/base/rail/sea/total rates, completed City/Factory/Port counts and functioning trade-route counts. Trade is a trailing 30-second delivered-income average, not a promise of passive income. Building inspection includes its cumulative delivered contribution. No extra gold is granted by this ledger. |
| Basic presentation / progression | Grey territory with darker boundary, distant labels hidden, no crowns or equipped flags. Basic nations participate in combat/elimination but not competitive rankings, winners or remembered results. Existing IsBot guards exclude them from human-elimination records and permanent reward farming. |
| Existing features | Stage 1–14 mechanics, two match types, human-first admission, parties, invitations, Unicode filtering, communications, localisation framework, profiles, Stars/cosmetics, six products, touchscreen controls, icons, crowns and mobile renderer fallback retained. General paid prompts remain disabled; approved tester configuration unchanged. |

### Upstream rules and deliberate adaptations

Pinned OpenFront revision: `8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94`.
Relevant reference files: `packages/engine/src/configuration/EngineConfig.ts`,
`game/RailNetworkImpl.ts`, `execution/TrainExecution.ts`, `execution/PortExecution.ts`,
`execution/nation/NationAttackBehavior.ts`, `execution/utils/AiAttackBehavior.ts`.
Local implementation retains AGPL notices and the existing upstream numerical oracles.

- Rail payout: `max(5000, base - max(0, stops - 9) × 5000) × goldMultiplier`.
  Base is 10,000 self, 35,000 ally, 25,000 other/team; existing endpoint payouts retained.
- Sea payout: existing `NavalRules.tradeGold` logistic distance formula, including
  `floor(75000 / (1 + exp(-0.03 × (distance - debuff))) + 50 × distance)` and multiplier.
- Rail stations use pinned 15-cell minimum, 110-cell search range and route length
  below `110 × 1.4142`. Military buildings do not become stations.
- **Near-shore water:** pinned rail routing allows narrow coastal bridging. Open-ocean
  crossings remain rejected. This is a known difference from interpreting “no oceans”
  as forbidding every water cell; no new blanket rule was silently added.
- Troop, combat, building-cost and trade formulas are unchanged in their core modules.
  Starting soldiers, recruitment multipliers and proactive AI priorities are explicit
  WorldConquest balance adaptations. They are configurable and not yet long-match balanced.
- Async searches preserve exact routes on static fixtures, but introduce deterministic
  waiting before a route/order can execute. A live-changing world can therefore diverge
  in timing from synchronous upstream execution. Current ownership/resources are checked
  again before committing. Node budgets are **not** proven wall-clock guarantees.
- The new basic controller is an original inexpensive adapter to the upstream spawn,
  expansion, resistance and recruitment systems, not a claim of verbatim upstream AI.

## Automated verification

Run `python scripts/run_idle.py scripts/check_stage15_all.py`. Sequential, one CPU,
below-normal priority. The gate explicitly omits heavy sections using `--quick`.
Existing small CPU probes in UI/codec/progression fixtures are not production benchmarks.

Passed functional coverage:

- Stage 1–5 source oracles, deterministic ownership/recruitment/combat/connectivity,
  transactions, placement, building lifecycle, capture and replication. Rail: 200 exact
  paths and 7,000 pinned station/train/trade trace ticks.
- Stage 6: 450 exact raw/shore/bounded routes, 4,810 upstream execution trace ticks,
  actual landing/combat integration, trade, warships, refunds, duplicate orders and replicas.
- Stage 7–9: recovery/gaps/fragmentation, rate limiting, missile/SAM/MIRV/fallout,
  victory/results/restart, bot decisions, elimination, names and source formulas.
- Stage 10–14: menu and private/public/party admission, teleport failure recovery,
  live spawn replicas, icons/name labels, wire codec, names/filtering/communication,
  cross-server storage stubs, all six products/receipts, touch gestures/fallback renderer,
  seven terrain LODs and cached ownership recolouring.
- Stage 15: six basic + two smart + one human small-grid fixture, distinct seeds and
  identical-seed replay, disjoint starting ownership, both controllers expanding,
  no basic infrastructure/gold, basic exclusion from rankings/private HUD.
- New production async transport test: shared pop limit, completed preparation,
  revalidated purchase, duplicate pending command produces one debit/effect. Pending
  preparations plus active transports are capped at the existing transport limit;
  malformed sequences and 100 queued request attempts do not create unbounded work.
- New queued infrastructure test: automatic connection, moving authoritative waypoints,
  actual trade gold, compressed geometry, destroyed destination invalidation.
- New UI fixtures: six safe sizes (320×568, 390×844, 844×390, 768×1024, 1024×768,
  1920×1080), long timer/rank/100% text, opaque layer, three-toast cap/dedupe/dismissal,
  preferences, atomic rail geometry, pooling/culling and corner-following train interpolation.
- New tile-scheduler test: preceding cohort stays visible; no individual replacement tile
  is exposed before the whole cohort is ready. Existing image allocation/upload-failure
  fallback and native-density ownership tests pass.

These are production-module CLI/service-stub tests, **not rendered Studio screenshots,
real networking, Roblox services or physical-device tests**. Logs are kept locally in
`build/*-stage15-acceptance.txt`; build outputs are intentionally excluded from source.

## Performance evidence and unverified limits

| Measure | Before | Current Stage 15 evidence |
|---|---|---|
| Visible LOD presentation | Individual tiles exposed as uploaded | Automated cohort atomicity passes; visual blur/seams/flicker acceptance deferred |
| Naval/rail work | Synchronous searches; historical reports included long stalls | Deterministic search yielding and exact-route fixtures pass; no new live worst-ms result |
| Desktop/mobile FPS, zoom/pan frame times | Existing reports are historical | **Not measured** in this revision; 60 / 30–60 FPS targets unverified |
| 100/200/300/400/500 basics + 20 competitive | No Stage 15 accepted capacity | **Not run**, owner deferred intensive benchmarks |
| Server/client memory and bandwidth | Historical figures do not certify this build | No new Roblox measurements; heap/payload proxies would not certify them either |
| Startup time, missile/connectivity worst tick | Previous optimisations retained | Functional tests only; no updated full-world timing claim |
| AI-only Earth conquest / economy pacing | Not established for new balance | Extended run deferred; small AI progression and profitable infrastructure proven only |

**Maximum new basic population functionally exercised in gameplay: six in a small
fixture. Maximum reliable Earth/live basic population: not established.** Production
configuration consequently enables zero basics and retains the previously conservative
20 competitive cap; that cap is not re-certified on live hardware by this task.

Prepared, but not run: `python scripts/run_idle.py scripts/benchmark_stage15.py --allow-heavy`.
After owner authorisation this runs separate Earth processes for 100/200/300/400/500
basics plus 20 competitive AI, 18,000 active ticks (30 simulated minutes), measuring
tick average/p95/worst, harness heap, payload proxy, subsystem times, occupation and
winner. Use `--ticks 102000 --seed <seed>` for extended conquest; repeat seeds.
Actual Studio MicroProfiler, Stats and physical-device frame/memory/network measurements
remain necessary. Raise SafeCount only after both server and client acceptance pass.

## Remaining risks and publication blockers

1. Stage 15 visual and performance acceptance is deliberately **unfinished**. No claim
   that rectangular transitions, lag or HUD appearance are fixed in the rendered game.
2. Worldwide conquest, smaller-island occupation, long-term balance, 100–500 basic nation
   loads and worst-case combined missiles/connectivity/trade remain unmeasured.
3. Water searches share two workers; long searches can delay queued orders substantially.
   Reduced stall risk is an architectural change, not a measured latency guarantee.
4. Rail route changes use bounded batches, but receiving a large replacement cohort still
   rebuilds its client spatial index. Large-network frame/memory acceptance is outstanding.
5. Ownership, terrain and rail presentation pools have finite budgets. Zoomed-out rails
   and distant basic names are intentionally culled; verify visual readability on hardware.
6. `IconAssets.AssetIDs` still need the four licensed atlas uploads for a complete icon
   fallback on devices denied EditableImage. IDs remain zero rather than fabricated.
   Follow `docs/STAGE14_CORRECTIONS.md`; test permission-denied rendering explicitly.
7. Live DataStore, party teleports, text filtering/chat/voice permissions, translation
   review, actual purchase receipts and rejoin restoration retain the existing manual
   blockers. General public purchase prompts stay false.
8. Corresponding source must match the released build. This task prepares/uploads the
   complete source, licences, asset inputs and build instructions to the existing public
   repository; `build/source-upload-status.json` records the final anonymous verification.
   Source availability alone does not certify all Roblox platform/licensing obligations.

## Manual acceptance when the owner is ready

1. Open the rebuilt `build/WorldConquest-stage10.rbxlx` locally. Do not overwrite/publish
   the live experience until acceptance. Check the embedded Config values and current
   source URL; leave paid public prompts false.
2. Run two or more Studio clients. Exercise Public/Private, friends/party invitations,
   host migration, errors, join/rejoin and Leave. Real teleport/voice/commerce tests
   require a controlled published environment later; Studio stubs do not verify those.
3. Test spawn selection at desktop, phone landscape/portrait and iPad/tablet sizes.
   After load approval, set a temporary **local** BasicNations.SafeCount progressively.
   Check land validity, continental coverage, staggering, human replacement priority,
   live selection changes and simultaneous start; confirm grey nations do not consume
   the 20 competitive slots.
4. Pan and pinch/wheel continuously between world overview and maximum zoom, returning
   to cached areas. Check coastlines, old-to-new cohort transitions, allocation failure,
   startup responsiveness and accurate taps. Record MicroProfiler/Stats, not impressions alone.
5. Place busy territory labels, crowns, flags and buildings behind the top-right HUD.
   Check long ranks, 100%, hour-long timer, orientation changes and safe areas. Verify
   three distinct readable slots; trigger three toasts and open/close other panels.
6. Build/upgrade City, Factory and Port at eligible distances. Inspect costs and delivery
   contribution; open gold/economy panel. Observe rail connections, curves/train movement,
   ship routes and actual gold deliveries. Capture/demolish each endpoint and test embargoes.
   Disconnected factories must not manufacture trade income.
7. Test humans and smart AI attacking grey nations, grey elimination, defensive posts,
   naval landings, SAM interception, missiles/fallout, crowns and leaderboard updates.
   Check no grey nation appears as a competitive winner or grants human-kill rewards.
8. Complete a match and restart. Verify routes, trains, ships, basic nations, toasts and
   round-ID validation reset. Repeat late join/disconnect recovery during active trade.
9. Run extended AI-only Earth matches and approved population loads with early/mid/late
   economy sampling, network burst counters, server p95/worst, client frame times and heap.
   Require sustained <100 ms server ticks and acceptable desktop/mobile rendering before
   increasing SafeCount. Record failures and retain the lower safe configuration.
10. Repeat touch gameplay and purchase-safe UI checks on physical iPhone, Android phone,
    iPad and Android tablet. No compatibility completion claim before those tests pass.

See [complete changed-file inventory](STAGE15_CHANGED_FILES.md) and
[earlier Stage 14 asset/rendering corrections](STAGE14_CORRECTIONS.md). Those unshipped
Stage 14 corrections are included in this source update, not silently omitted.
