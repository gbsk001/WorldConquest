# Stage 14 implementation candidate — 25 November 2026

**Visual acceptance is BLOCKED. This is not a visually approved release.**
Working changes are implemented in the existing Rojo project and the legacy-named
`WorldConquest-stage10.rbxlx` is rebuilt. No Roblox publication is authorized or
performed. Public paid prompts remain false, with only the previously approved
Owi00013 numeric tester exception. Capacity remains 20; simulation stays Stage 11
with existing Stage 12–13 identity, communications and progression adapters.

## Reference inspection and access limitation

All four supplied reference images were inspected: construction/gameplay overlays,
match-start presentation, spawn selection and the RoWorld menu. Their useful
principles are a dominant terrain map, small floating controls, strong text contrast,
compact construction and a gold primary action. WorldConquest uses original code,
existing original icons/cosmetics and public-domain geography. It does not copy
RoWorld logos, promotional discounts, prices, countdowns, extra modes or artwork.

The Windows computer-use skill was initialized and app enumeration attempted.
It failed with `Computer Use native pipe is unavailable: failed to connect native
pipe: The system cannot find the file specified. (os error 2)`. There is therefore
**no new Studio screenshot, emulator render, published-client profile or physical
device result**. The geography-only preview under `build` is an offline data
preview, not a game screenshot. Automated GUI tests do not certify appearance.

## Concrete defects found and changes

### Layers, menu and full-screen map

The deferred decorative map was added under a menu frame sharing default sibling
ordering with content. Its late-created branch could paint over the interface.
The former map also explicitly reserved large top/bottom regions for HUD bars.
These were active runtime modules, not unused theme files.

- Menu geography is now a dedicated ZIndex 0 background branch; its shade is below
  the separate ZIndex 10 interface composition. Content, page close and messages
  have explicit higher levels. No CanvasGroup opacity affects foreground text.
  Decorative map layers are passive, clipped within their background and cannot
  sit above the interface branch, regardless of asynchronous creation order.
- The gameplay MapViewport is a full-screen ScreenGui child at ZIndex 1. Safe-area
  interface content is a separate transparent, inactive branch at ZIndex 30.
  Floating panels use 40, menus 45, confirmation 70 and notifications 100 within
  that interface branch. Native Roblox controls remain native and visible.
- The menu has a bold title, Party, Settings/Tutorial, real Stars balance, Arsenal,
  Shop, original cosmetic previews for Flag Shop/Starter/General, Daily access,
  Global Rankings, a gold PLAY action and smaller Private Match action. Exactly
  Public and Private matches remain. Prices/rewards still come from the existing
  shop/Marketplace adapters. No invented promotional counters or discounts exist.
- PLAY and adjacent actions are positioned from the available content height.
  Normal desktop/landscape home layouts do not use a scrolling list. Very small
  portrait/short viewports retain scrolling when needed to keep controls reachable.
  Pages such as shop, inventory and results retain scrolling for real content.
- The new HUD has a compact timer/rank/territory summary and floating soldiers,
  recruitment, gold, troop-capacity bar, sends count, allocation presets and BUILD.
  The 10/25/35/50/75% presets feed the same allocation variable as the precise
  1–100% touch slider. Army recall, naval and missile actions remain accessible.
  Help, Settings, Leave confirmation and collapsible live rankings remain functional.
  Live rankings start closed; victory/results can still open automatically.

### Construction and selection

The existing building shop is a horizontal scrolling strip with original shared
icons, live server quotes and affordability styling. It includes the six building
types plus warship, atom bomb, hydrogen bomb and MIRV, routed through the existing
naval/missile adapters. Upgrade/demolish and building information remain available.
Selection preserves the placement preview and server validation. The strip has an
independent close button and consumes input only within its floating bounds.

Spawn selection has a small floating instruction panel, segmented circular
countdown, real selected/total count, selected-location acknowledgement and nation
name input. Military controls remain hidden during selection. Existing live spawn
markers, geographical balancing, human priority and countdown logic are unchanged.
The camera fits Earth on selection and focuses the local territory once on gameplay
start. User zoom/pan is not continually overridden by metadata updates.

### Identity and flags

Default participant labels continue to use actual Roblox usernames; a successfully
filtered custom nation name replaces the display name, while AccountUsername/UserId
remain available for identity/reporting. Soldiers remain beneath the name. Labels
are transparent, bold and outlined. Optional flags are offset beside the label,
not placed over its text. Existing top-three crowns remain.

New profiles do not equip a flag automatically. Existing automatic `flag_horizon`
equipment is cleared unless an explicit equip marker exists; ownership, Stars and
all purchased cosmetics are preserved. Other equipped flags are preserved. There
was no historical marker distinguishing an intentional selection of the free
default flag from auto-equipping it: such users may need to equip that flag once
again. Subsequent explicit choices survive rejoining, and Unequip stays respected.
Bots receive no default cosmetic flag.

The nation-name service now permits edits during authoritative Selecting phase.
It checks permissions again after filtering, uses the same broadcast-safe Roblox
filter and atomic persistence, and updates the selection roster's display name.
Gameplay-phase changes and a filter returning after the phase boundary are rejected.
The main-menu Profile editor remains available. No client text is trusted directly.

## Geography and rendering architecture

Natural Earth II v3.2.0 supplies real shaded relief and idealized land cover at
10800×5400 source pixels. Its public-domain archive is included in `data`, with
source hash, georeferencing, generation method and limitations in
`data/geography-manifest.json`. The source is downsampled, never enlarged, to
8192×4096. It is not contemporary satellite imagery or a fabricated elevation DEM.
Existing NOAA ETOPO gameplay heights and all gameplay formulas remain unchanged.

The presentation uses 128 palette colours, seven prefiltered display levels and
independently decoded 64×64 pages. A shared LRU retains at most 512 decoded pages
(2 MiB of pixel indices, excluding tables, encoded source and engine overhead).
Natural greens/deserts/mountain shading come from the dataset; blue water and
exact high-zoom coastlines/lakes come from the existing detailed land mask.

Static colour pixels are cached separately from dynamic ownership in each rendered
tile. Ownership updates blend over that cache and do not resample geographical
data. Existing ownership-cell boundaries still determine borders. Releasing land
restores its cached terrain colour exactly. The final display uses a composited
EditableImage per tile, avoiding a second GPU texture per ownership layer.

Camera input now schedules one layout update per rendered frame; multiple touch
events cannot trigger redundant property/layout passes. Cached tiles survive
camera movement. Visible tiles have priority, dirty ownership rectangles retain
partial uploads and at most one changed image uploads per frame. Terrain-aware
painting checks the CPU budget after each row instead of every eight rows.

Unit icons use spatial buckets at close zoom and stable source-order culling; wide
views use the simpler scan where gathering/sorting would cost more. Label overlap
uses spatial buckets. Existing icon pools, off-screen culling, hidden-menu pauses,
touch budgets and fallback rendering are preserved. The image-free fallback also
uses geographical colours, with reduced display colour/detail to merge GUI runs.
The simulation grid is never reduced.

## Tests and measurements

The full Stage 1–13 automated functional suite passed, including simulation/parity,
matchmaking, human priority, deterministic spawn distribution, identity/filtering,
voice policy, persistence, all six commerce products, mobile gestures, icon pooling
and failure recovery. Logs: `build/stage14-full-regression.txt` and focused
`stage14-ui-tests.txt`, `stage14-identity-tests.txt`, `stage14-progression-tests.txt`,
`stage14-mobile-tests.txt`. Production Luau compilation and Rojo source embedding
are also checked.

New checks cover horizontal construction routes, exact allocation callbacks,
spawn/gameplay visibility, one-time camera fit/focus, name submission through the
server filter, phase-boundary rejection, optional-flag migration/equip/unequip,
palette/LOD decoding, longitude wrapping, cached ownership recolouring, restoration
of released terrain and spatial icon candidates. Tests use actual modules with
explicit Roblox service/GUI substitutes, not engine render emulation.

Local CLI CPU comparison from this work session:

| Workload | Before average / p95 / worst | After average / p95 / worst |
|---|---|---|
| Cold geography row, 64 sampled rows; first 256-page implementation versus final 64-page implementation | 1.200 / 5.609 / 6.345 ms | 0.361 / 1.029 / 1.136 ms |
| 5000 units, 300 close-zoom camera steps; previous public IconLayer versus spatial index | 0.259 / 0.297 / 0.407 ms | 0.040 / 0.064 / 0.206 ms |

These measurements isolate CPU functions. They exclude GPU rendering, actual
texture upload cost, Roblox scheduling, replication, asset loading and physical
device memory. The geography comparison is against the first new decoder, not
the previous published flat-colour renderer. Final lossless run packing is
checked by `scripts/check_stage14.py`; latest output is in
`build/stage14-results.txt`. Timing noise prevents treating one run as a frame-time
guarantee. **Actual gameplay FPS, frame p95/worst, startup, network and total client
memory before/after remain unmeasured. Zoom lag is not claimed solved in production.**

## Mandatory rendered acceptance — all rows PENDING

Open the rebuilt place, verify the embedded modules/CommerceConfig, and use Studio
Device Emulator for desktop, landscape phone and iPad separately. Then repeat on
actual iPhone, Android phone, iPad and Android tablet in the same matches as PC.

| Required screenshot | Acceptance checks |
|---|---|
| Desktop main menu | Background behind title/cards; PLAY fully visible; no desktop scrollbar; attribution readable |
| Phone main menu | Safe areas, 44px targets, reachable Party/Shop/Arsenal/promos; no text/button overlap |
| iPad main menu | Balanced composition in landscape and portrait; no clipped PLAY or page close |
| Spawn selection | Entire Earth fitted; live markers/countdown; military controls hidden; filtered name input works |
| Active gameplay | Full viewport map; compact floating HUD; correct sends/capacity/rank/timer; native chat/voice |
| Maximum zoom | Crisp cell-coincident boundaries/coastlines; stable touch picking; no texture holes after settling |
| Construction | Ten graphical items with real quotes; affordability; horizontal touch scrolling without map movement; preview/upgrade/close |
| Global leaderboard | Real records, categories, close/back navigation; no fabricated records |
| Shop and Arsenal | Actual catalogue/art, equip/unequip, disabled public prompts, approved tester gate retained |
| Nation names/optional flags | Username default; filtered Unicode name; soldiers; explicit flag only; crowns; reporting identity retained |

Run public and private matches end-to-end, including invites/party, selection
changes, expansion/combat, buildings, naval, missiles/SAM, elimination, results,
restart and Leave. Drag/pinch must never attack on release. Verify all settings,
notifications and menus close and return control to the map. Exercise image-API
failure using the existing local diagnostic override, then remove the override.

For actual performance, temporarily add `scripts/profile_actual_gameplay.client.luau`
as a LocalScript under StarterPlayerScripts in a local acceptance copy. It observes
the existing game without creating synthetic participants, moving the camera or
changing ownership. Record 15-second intervals during cold start, settled overview,
active battles, slow pan, rapid pinch/wheel zoom and maximum zoom; save Output rows
prefixed `WC_ACTUAL_GAMEPLAY`. Record device/OS/Roblox version and participant count.
Use MicroProfiler scopes `WC.CameraAndIcons`, `WC.TilePaint`, `WC.TextureUpload` and
the normal frame/graphics scopes to attribute long frames. Network fields are
included only if Roblox exposes those Stats counters. Remove the diagnostic before
normal distribution. Do not substitute the old synthetic 500-player FPS result.

## Remaining risks and publication blockers

- No mandatory rendered screenshots or real gameplay/device performance evidence.
  Visual quality and the original published lag cannot be signed off yet.
- Rich geography adds encoded source/download and cache memory compared with flat
  colouring. Physical mobile startup, publication/loading limits, texture budget
  and long-match memory must be verified. The 2 MiB
  page limit is not a claim about total client memory.
- Very small screens may need home scrolling; full-screen fit preserves Earth’s
  2:1 projection and may leave ocean-coloured letterboxing. Recovery graphics are
  intentionally less detailed than the normal renderer.
- Engine Marketplace ownership API availability, live purchases/DataStores,
  native chat/voice and translation review remain existing acceptance obligations.
  No purchases were performed, no receipt data exported, no paid prompts enabled
  for the public, and no new capacity claim is made.
- Source is rebuilt/audited and uploaded to the already authorized public GitHub
  repository. The owner must publish the matching candidate manually only after
  accepting the outstanding visual/live checks.

## Changed files

UI: `MainMenu`, `PremiumMenu`, `StrategyUI`, `Main.client`, `BuildingShop`,
`NavalControls`, `MissileControls`, `MatchHUD`, `InterfaceArt`.
Rendering: `MapView`, `MapTiles`, `TilePainter`, `TerrainColors`, `IconLayer`,
`CompatibleTiles`, generated `src/shared/Geography/*`.
Identity/persistence: `IdentityServer`, `OpenFront/FoundationServer`,
`ProgressionRules`, `ProgressionServer` (presentation/equip defaults only).
Tests/build/data: Stage 14 checks and gameplay profiler, existing regression
fixtures, geography generator/source archive/manifest, locale strings/CSV,
package manifest, README, BUILDING, DEPENDENCIES, NOTICE and this acceptance report.
