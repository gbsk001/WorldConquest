# Stage 6 naval implementation — 2026-11-18

Stage 6 is enabled in the existing Rojo project (`Config.PortStage=6`). Automated
naval tests and Stage 1–5 regressions pass. **Live Roblox Studio acceptance is still
pending.** This is an implementation with the routing/platform differences below,
not a claim of complete OpenFront parity or production capacity. No Stage 7 features
or Stage 8 missile systems were started.

Source: [OpenFrontIO, pinned 8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94](https://github.com/openfrontio/OpenFrontIO/tree/8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94).
The existing checkout was used; balance was not silently updated to moving main.

## Implemented behaviour and source mapping

Upstream paths below are relative to `packages/engine/src/`, except where noted.

| Original implementation | Luau implementation / change |
|---|---|
| `execution/TransportShipExecution.ts`, `game/TransportShipUtils.ts`, `execution/BoatRetreatExecution.ts` | `src/server/OpenFront/Naval.luau`: owned-shore launch without a port, allocation, transport limit, travel, return, landing and already-paid attack stack |
| `pathfinding/spatial/SpatialQuery.ts` | `ShoreQuery.luau`: reachable shoreline selection, source border cache invalidation, multi-source route and bounded launch refinement |
| `pathfinding/algorithms/AStar.Water.ts`, `AStar.WaterBounded.ts`, `transformers/ShoreCoercingTransformer.ts`, `PathFinderStepper.ts`, `PathFinder.Air.ts` | `WaterPath.luau`: sparse A*, original float32 priority comparisons, cardinal tie order, shoreline coercion, packed stepping, cached routes and seeded shell paths |
| `execution/WarshipExecution.ts`, `execution/ShellExecution.ts`, `execution/MoveWarshipExecution.ts` | `Warship.luau`, `Naval.luau`: patrol, targeting, interception, shell combat, piracy, repair, docking capacity and manual movement |
| `execution/TradeShipExecution.ts`, `execution/PortExecution.ts` | `Naval.luau`: automatic destination selection, port levels, spawn throttle, trade, capture/rerouting, port ownership and destruction |
| `configuration/EngineConfig.ts`, `game/UnitImpl.ts`, `game/PlayerImpl.ts` | `src/shared/OpenFront/NavalRules.luau`, `Naval.luau`, `Warship.luau`: costs, troop accounting, health, veterancy, trade payments and validation |
| `execution/AttackExecution.ts` | `Expansion.luau`: optional naval source tile and no second troop debit; naval attacks stay separate, ordinary land attacks retain upstream merge behaviour |
| `execution/PlayerExecution.ts`, `game/PlayerImpl.ts` | `Simulation.luau`: fleet cleanup and per-conquest tile versions; temporary attack embargo shared by sea trade and `Rail.luau` |
| `packages/engine-lib/src/game/UnitGrid.ts` | 100-cell naval spatial buckets, row-major/type/insertion order; moving inside a bucket preserves insertion order |
| Browser input/rendering and original turn protocol | Roblox adapters: `ShipWire.luau`, `Replica.luau`, `FoundationServer.luau`, `NavalControls.luau`, `MapView.luau`, `Main.client.luau`, `BuildingShop.luau` |

Other changed files: `Buildings.luau` starts the port sea-trade execution on
construction completion; `BuildingRules.luau` updates the port description;
`Config.luau` selects Stage 6. Existing world map, ownership raster, click transform,
spawn selection, zoom, pan, soldiers, economy, buildings, rail and combat remain.
Ship icons are original text glyphs: **T** transport, **W** warship, **$** trade,
and small shell markers. They use the same map-cell centre and canvas transform
as buildings; there is no new asset upload.

## Rules and formulas retained

All times are deterministic 100 ms ticks. Wall-clock profiling never determines outcomes.

- Transports: maximum **3 per player**; no gold cost or port requirement. The
  default upstream boat allocation is `floor(reserve / 5)`; the UI sends its
  selected allocation ratio, evaluated against authoritative reserves. Ownership
  must provide a reachable coastline. The target is the nearest qualifying
  same-owner shore within Manhattan radius **50**, reachable from the attacker's
  shores. Source refinement uses radius **20**, waypoint distance **50–200**,
  padding **10**, and at most **10,000** cells in the bounded search.
- Fractional accounting is deliberately retained: the boat stores the fractional
  committed amount, while the player's integer reserve deducts its floor. Zero
  troop boats are also allowed upstream. Arrival claims the landing cell before
  queuing the existing source-tile attack with `removeTroops=false`. The remaining
  conquest uses Stage 2/3 terrain, casualty, connectivity and elimination rules.
  Simultaneous invasions execute in the same ordered deterministic scheduler.
- Transport/trade/patrol movement is **one route node per tick**. A successful
  transport return to owned land refunds `floor(0.75 * boatTroops)`. A route failure
  or missing return shore refunds `floor(boatTroops)`. Original initial target
  identity and ownership-change landing branches are preserved.
- Warship price: `min(1,000,000, (min(currentOwned, lifetimeConstructed)+1)*250,000)`.
  Thus $250K / $500K / $750K / $1M, capped at $1M; existing infinite-gold behaviour
  still applies. A completed owned port connected to the requested water is
  required. The nearest qualifying port is selected by Manhattan distance.
- Warship base health **1,000**, patrol range **100**, targeting range **130**.
  Target priority is transport, warship, then eligible trade ship; equal type uses
  squared distance and original spatial ordering. Docked warships are excluded.
- Shell firing uses strict `tick-lastShellAttack > 20`. Transport shots do not
  reset that reload timestamp. Shells advance **3 air-path nodes per tick** and
  expire **50 ticks after their firing unit dies**. The source's separate unused
  `warshipShellLifetime=20` was not substituted for `shellLifetime=50`.
- Damage roll `r = nextInt(1,6)` gives `200 + 25*(r-1)`; with veterancy `v`, use
  `floor(base * (100+20*v)/100)`. Maximum health is `floor(1000*(100+20*v)/100)`.
  Veterancy caps at **3**. A warship killing blow adds a level and resets progress;
  transport kills give **25** points, trade captures **10**, with **250** per level.
  Promotion does not instantly heal.
- Ports passively heal owned warships by **1/tick within radius 150**. Automatic
  repair starts below **75%** of veteran-adjusted max health, unless manually
  redirected in the previous **50 ticks**. Docking radius is **5**; capacity is
  port level. Active docked healing adds a pool of **5 × portLevel/tick**, divided
  among qualifying ships, retaining fractional remainders. Better-port switching
  uses squared distance ratio **0.75**.
- Piracy pursues at **2 nodes/tick**, uses greedy cardinal water steps within
  Manhattan **20**, and captures within **5**. Trade ships are protected for
  **20 ticks** after launch/shoreline contact. Own/friendly destinations and lack
  of a reachable completed unmarked home port block piracy. Captured trade ships
  reroute to the captor's nearest qualifying port.
- Sea trade income for distance `d` and recipient multiplier `m`:
  `floor((75000 / (1 + exp(-0.03*(d-300))) + 50*d) * m)`.
  Ordinary trips pay both current source and destination owners. Captured trips
  pay the captor; original-owner recovery does not count as piracy income.
- Let `sigmoid(x,k,c)=1/(1+exp(-k*(x-c)))`, and
  `S=max(1-sigmoid(N,ln(2)/50,330), 0.25*(1-sigmoid(N,ln(2)/100,800)))`.
  For owner port levels `L`, `B=1` when `L<=0`, otherwise
  `B=1+0.5*clamp((6-L)/5,0,1)/L`. Spawn odds denominator is
  `max(1,floor((100/(B*B))*(1/(rejections+1))/S))`.
  Port level supplies that many attempts on `(tick + initTick%10)%10==0`.
  Successful spawning resets rejections. Tick-seeded RNG and candidate order are retained.
- Destination weight starts at destination port level. At distance **>=300**, add
  one multiplier for the nearest `clamp(portCount/3,4,portCount)` candidates and
  one for friendly destinations. Under-construction destination ports remain
  eligible, matching the source. Trade embargoes created by attacks last until
  strictly more than **3,000 ticks** have elapsed.
- Water A*: base cost **100**, magnitude `<3` penalty **1,000**, magnitude `3..10`
  penalty **0**, deeper penalty **100**; heuristic weight **5**, original cross
  tie-breaker, **1,000,000** iteration limit. Bounded refinement uses weight **3**,
  nearshore penalty **300**, and **100,000** iterations. No ownership cells are
  smoothed or enlarged by the naval implementation.

## Authority, rendering and performance

Only authenticated, rate-limited intents reach the server. No client price,
reserve, owner, path, position update or combat result is accepted. Building and
naval transactions share one monotonic sequence and the existing idempotent ledger.
Naval inputs validate phase/alive state, ownership, funds, coordinates, allocation,
transport cap, coastline/component and port requirements as appropriate.

Ship mutations coalesce into **32-byte records**. Ownership, buildings and ships
install atomically per tick, including fragmented packets and snapshots with queued
subsequent deltas. Each fragment has at most **24,192 payload bytes** (8,064 per
stream). Private resource/shop information remains 5 Hz. Icons are one object per
unit, never per world cell; offscreen icons are hidden. No full-world scan runs
per tick. Source ownership borders and rendering remain at **8192×4096** resolution.

Routes and individual stepper paths are packed u32 buffers. Route caching is extended
to transports and warships as well as trade because the map is immutable; tests
show identical outcomes. The cache is limited to 24,000,000 accounted bytes and
4,096 entries; accounting includes a 64-byte allowance per key, not a measurement
of actual Roblox table overhead. Each ship also retains its own path buffer.
Shore caches invalidate with an ownership mutation counter, including multiple
mutations within one tick. Naval targeting visits nearby 100-cell buckets only.

Local standalone Luau measurements on this machine, including GC variability:

| Workload | Result |
|---|---|
| Four actual Earth routes | 190–1,024 path cells; first search **1.4–23 ms**; cache **0.02–0.3 ms**; 11,376 retained cache bytes total |
| 100 patrolling warships, 300 ticks | Around **1.4–1.8 ms mean**, **1.8–2.6 ms p95**; 3,157 ship bytes/tick average; 5 searches after caching versus 500 before |
| 100 opposing warships, 300 ticks | Around **3.2–3.7 ms mean**, **5.3–6.3 ms p95**; peak 294 ships/shells; 4,510 bytes/tick average, 9,408 maximum; 71 survivors |
| Deliberately unfiltered blocked raw A*, 512×512 | **309–341 ms**, 181,164 heap pops; one run increased harness heap by about 12 MiB (other runs collected garbage). Normal component validation rejects this divided-basin case before searching |
| Build | `build/WorldConquest-stage6.rbxlx`, 36,703,673 bytes |

At 10 Hz the measured combat stream is about **45 KB/s per receiving client**,
before ownership/buildings, metadata and Roblox transport overhead. This is not
Roblox's compressed-wire measurement. Harness heap figures include fixtures and
previous runs; they are not isolated per-ship memory measurements. Search scratch
uses sparse tables, so large difficult searches can still exceed a tick budget.
The one-million-iteration bound is not a 100 ms CPU guarantee.

## Tests and precise coverage

Run from the project root:

```powershell
python scripts/check_stage6.py
python scripts/check_stage5.py
python scripts/check_luau.py
rojo build default.project.json -o build/WorldConquest-stage6.rbxlx
```

All passed on 2026-11-18. `check_stage5.py` includes Stage 1–5 regressions, not just
building tests. `check_luau.py` also retains the old renderer tests and **1,184**
screen/map/marker coordinate round trips. Logs are in `build/stage6-results.txt`,
`build/stage5-results.txt`; this does not test the new GUI in a live client.

New tests and fixture tooling:

- `scripts/prepare_naval_oracle.mjs` mechanically extracts the pinned TypeScript
  implementations, records source hashes and strips TypeScript syntax.
- `scripts/generate_naval_oracle.mjs` executes those originals against explicit
  game/platform adapters. Both scripts require Node with `stripTypeScriptTypes`;
  normal Python/Luau tests use the committed JSON and need no Node install.
- `tests/stage6/upstream-oracle.json`, `source-hashes.json`: **168** spawn rates,
  **32** payments, **30** prices, **100** shell rolls, **450** raw/coerced/bounded
  water paths, **30** air routes and original UnitImpl veterancy sequences.
- **4,810** original execution ticks across 15 scenes: neutral landings, fractional/zero boats,
  ordinary landing, retreat, simultaneous invasions, sea trade, port scheduling,
  ship combat, interception, repair/manual override, piracy, captured trade,
  upgraded/captured ports and destroyed destination ports.
- `scripts/naval_checks.luau`: real order/economy/landing-combat integration,
  authentication-independent intent validation, allocation/cap, duplicate charges,
  foreign ship control, embargo expiry, two matching replicas, 300-tick replay,
  1,200-ship atomic fragmentation, invalid wire records, islands/water components,
  immutable cache results, Earth routes and fleet/search profiles.
- `scripts/naval_server_checks.luau`: **actual production FoundationServer** with
  service stubs and two replicas: forged caller/fields, invalid sequence, purchase
  replay, port completion, building/naval shared sequence, retreat/movement,
  moving-ship snapshot, private HUD, disconnect cleanup and payload bounds.

Naval trace tests isolate landing AttackExecution and compare its arguments, so
that naval failures are diagnosable. Separate integration tests run the real
Expansion/combat implementation. The 15-scene oracle uses the same full-resolution
water adapter as Luau, **not the upstream HPA/minimap routing pipeline**. Thus these
passing fixtures do not establish identical routes or outcomes on upstream World.

## Differences and outstanding limits

1. **Routing differs:** the pinned upstream normally combines a 2× minimap, water
   graph/HPA and smoothing. This port uses its original A* and shore algorithms
   directly on the existing full-resolution terrain. It avoids traversing land,
   but chosen paths, journey length, arrival times and distance-based trade payouts
   can differ. The upstream hierarchical graph pipeline has not been ported.
2. The existing Natural Earth/ETOPO map and elevation classification remain, not
   the upstream World raster. Cell-count balance is unchanged, so travel across
   this larger map can take much longer. No unlicensed upstream map/artwork was imported.
3. Original browser motion-plan playback is replaced with authoritative batched
   position deltas and simple glyph icons. There is no client prediction or native
   ship artwork/rotation. High fleet counts, viewport hit-testing and device GPU/UI
   costs still need live profiling; retained hidden icons consume GUI memory.
4. Existing project adapters for lobby, eliminated/disconnected players and teams
   remain. Fleet cleanup on departure is retained; upstream disconnected-teammate
   fleet inheritance, diplomacy/alliance-request handling, optional unit-disable
   settings UI and Doomsday Clock are not implemented. No missile/SAM feature was added.
5. Route failures retain source refund/destruction behaviour. Difficult connected
   routes may hit the A* iteration cap or stall a tick. A* sparse scratch and the
   pre-existing rail/connectivity worst cases are Stage 7 performance risks, not
   solved by average fleet timings. Source state is static; dynamic water changes
   from future missiles require water-version cache invalidation before enabling them.
6. Live Studio multiplayer, UI/zoom/pan acceptance and Roblox memory/network
   profiling are unverified. Public corresponding-source hosting remains unconfigured.

## Roblox Studio acceptance procedure

1. Stop Play. In the root run `rojo serve default.project.json`; reconnect the
   existing Rojo plugin and sync. Alternatively open the built Stage 6 place.
   Keep Mesh/Image APIs enabled as required by the existing map renderer.
2. For a short **local test only**, optionally set `Economy.StartingGold="2000000"`
   in `src/shared/Config.luau`, sync and start a fresh server. Restore `"0"` after
   testing. No naval prices, troop rules or production default money were changed.
3. Use Studio **Test ? Server & Clients ? 2 clients ? Start**. Check server and both
   client Output windows. During the 20-second phase choose nearby opposite
   coastlines (for example southern England and northern France), with both
   spawns touching water. Verify markers stay on the chosen point while zooming,
   panning and resizing the windows. Wait through the 5-second human immunity.
4. With **no ports**, select allocation, **Navy ? Launch invasion**, then click
   unoccupied coastline on another landmass. Both clients must see the same
   coloured T move over water; arrival starts tiny-cell expansion from the landing.
   There must be no second reserve debit on arrival and no ocean ownership.
5. Launch another transport, choose **Navy ? Return transport**, click that T,
   and verify return to an owned shore and the 25% arrival loss. Try a fourth
   simultaneous transport, own-land invasion and an inland/disconnected lake
   destination: invalid orders must reject without a second charge.
6. Before fighting the other player, have each buy **Buildings ? Port** on owned
   coastline. Check approximately 5 seconds of construction, matching icons and
   balances. Warship purchase before completion must fail. Ports should begin
   automatic $ voyages, with matching movement and lump-sum payments in both
   accounts after arrival. Random spawn rolls and travel mean payments are not
   instantaneous; the HUD's base +income/s excludes these lump sums.
7. Use **Navy ? Buy warship** and click connected water. Verify $250K for the first
   purchased warship and scaling thereafter. Use **Move warship**, click W, then
   choose the new patrol area. Move opposing warships together; check shells,
   damaged health (shown on selecting W), repairs near ports and destruction.
   Send an invasion past the enemy W to test interception and lost embarked troops.
8. Launch against the other player's coast. Verify the same beachhead, casualties,
   ownership and counts on both clients. Counterattack or return a transport.
   Attacks embargo sea trade for five minutes; do not mistake that for broken ports.
9. For **piracy**, repeat with **3 clients**: trade between A/B, and a C warship
   with its own reachable port. C must intercept outside shoreline protection and
   take the $ ship home. A two-player test cannot pirate trade whose source or
   destination belongs to the pirate; that exclusion is intentional upstream behaviour.
10. Rejoin a client as spectator while ships move. Verify snapshot catch-up, no
    duplicate units and consistent icons at Fit, 1-cell-per-pixel and high zoom.
    Disconnect an active owner and check fleet cleanup. Test narrow window sizes
    and the mutual exclusion of building-placement/naval modes.
11. On the **server**, inspect `ReplicatedStorage.WorldConquestEvent` attributes:
    `TickMilliseconds`, `NavalMilliseconds`, `ShipCount`, `ShipDeltaBytes`,
    `WaterRouteCacheBytes`, `WaterSearchMilliseconds` (cumulative), `LuaHeapKiB`
    and `TickBacklogSeconds`. Use Studio MicroProfiler under
    `WorldConquest.FoundationTick`; record peak tick/backlog during simultaneous
    launches and first-time long routes, plus both clients' memory/network stats.

Acceptance requires no errors, consistent two-client ownership/unit state,
correct purchases/refunds/trade, accurate icons/clicks and acceptable frame/tick
behaviour on the intended devices. These steps have **not** been performed here.

## Attribution and source availability

Root `LICENSE`, `NOTICE`, upstream attribution and the preserved additional terms
remain in place. New translated modules identify OpenFront and the pinned revision.
Natural Earth public-domain and NOAA ETOPO CC0 provenance is unchanged. No manual
asset import is needed for this stage.

The existing AGPL source-offer requirement still applies to a public networked
adaptation: provide the complete corresponding source for the deployed version,
including modified server/client Luau and build/configuration/data-generation
materials, with the preserved licence and notices. `Config.SourceURL` is still
blank; a link only to upstream is not the adaptation's corresponding source.
This implementation does not publish the game or establish that source hosting.
