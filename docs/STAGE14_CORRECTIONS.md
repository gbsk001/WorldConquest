# Stage 14 visual corrections — 25 November 2026

**Implementation candidate; visual acceptance is BLOCKED. Do not treat this as a
visually accepted or mobile-certified release. Nothing is published to Roblox.**

The new attachment contained the request text only, not the newly mentioned Studio
screenshots. The four earlier reference images were available. Actual Windows
Studio access was retried through the computer-use skill and failed with:
`Computer Use native pipe is unavailable: failed to connect native pipe: The system
cannot find the file specified. (os error 2)`.

## Changes in active runtime modules

- Replaced InterfaceArt's hand-built lines, frames, rings and procedural icon
  rasteriser with a central `IconAssets` registry. The same licensed image assets
  serve menu, lobby, HUD, buildings, naval/missiles, rankings, shop, Arsenal,
  inventory, rewards and close/help controls. There are 48 unique Lucide SVGs,
  256px transparent PNG exports and three shared 512px atlases. Runtime cells are
  128px with transparent gutters, smoothly filtered and aspect-preserving.
- Existing flag cosmetics now use their own shared 512x256 atlas and 320x192 PNGs,
  including shop previews and optional map flags. Designs and ownership are
  unchanged. AI profiles use a seeded colour and licensed profile silhouette;
  no real Roblox avatar/account/friend identity is assigned to AI.
- `Art.buttonContent` gives icons and text separate horizontal layout slots;
  `Art.cardContent` provides vertical image/name/price slots. Navy/missile actions,
  lobby actions and premium controls use these helpers. Small top controls use
  image-only buttons with readable hover tooltips, rather than wrapping
  “Leaderboard” or “Leave Game” into a tiny column. Touch actions are unchanged.
- Bold headings, medium-weight action labels, fixed readable text sizes and no
  automatic text shrinking in the gameplay label helper. HUD statistics, capacity,
  green recruitment, gold currency, current allocation, sent soldiers and BUILD
  have reserved regions. Exact preset choices highlight gold. Custom percentages
  remain visible beside the sent-soldier count and retain the existing exact slider.
- Starter/General promotions use Roblox's actual GamePass thumbnails for
  2098697285 and 2099891345. Both public thumbnail endpoints returned `Completed`;
  those downloaded thumbnails were inspected. This is asset inspection, not a
  rendered Studio menu inspection. Flag Shop uses its existing actual cosmetic.
  Cards use gradients and existing borders; no fabricated promotion/discount data.
- Spawn circles and their strokes disappear after selection while names remain.
  Soldier labels use compact K/M counts, bold white text and optional flags beside
  the name. Crown alignment and the existing username/filter/reporting identity
  remain intact. No server gameplay or commerce rules changed.

## Terrain and camera corrections

The visual terrain now retains the licensed Natural Earth II **10800x5400 source
resolution**. The authoritative ownership, terrain mechanics, clicks, land/lakes
and server simulation remain **8192x4096**. No geography was invented or enlarged
to claim additional detail. This remains a 128-colour idealized land-cover/shaded
relief dataset, not current satellite imagery or a new elevation model.

Each rendered tile carries a visual-to-simulation density. Sampling and dirty
invalidation project all affected simulation cells onto their full visual texel
footprint, including adjacent borders. Exact ownership remains server-derived.
Static terrain stays cached separately in CPU buffers; final composited textures
avoid a second full GPU layer. Filtering uses Roblox's default smooth mode instead
of nearest-neighbour magnification. The maximum zoom is limited to 1.5 screen
pixels per authoritative cell (about 1.14 screen pixels per native terrain texel).
Wheel, pinch, zoom buttons and viewport resizing all respect the cap.

There are seven terrain LODs, 64x64 decoded pages, a shared 2 MiB page cache and lazy
groups of at most 128 encoded pages. A first close-zoom sample no longer requires
parsing a single entire high-resolution layer module. Visible tile priority,
bounded per-frame painting, incremental uploads and pooling remain. This is lazy
runtime preparation, **not a claim that Roblox streams ModuleScript source bytes
only for the visible region**.

The earlier camera coalescing exposed two missed invalidations: moving units and
placement previews could wait for a camera move. Their changes now schedule a
frame update independently. Camera movement still does not recreate icon textures.

## Required asset upload configuration

The candidate embeds the real atlas pixel data for EditableImage-capable clients.
There is intentionally **no frame-drawn fallback** and **no invented asset ID**.
For clients without EditableImage permission/memory, the atlas images must be
uploaded and configured. Until then, affected icons can be blank: this is a
**publication blocker**, not completed universal icon availability.

1. Open the **existing** WorldConquest experience in Studio with its owning account
   or group selected. Do not create another experience.
2. Open **Window → Asset Manager** (or the Asset Manager toolbar entry in your
   Studio layout), choose **Import**, and select these four files together:
   - `assets/gui-icons/LucideAtlas1.png`
   - `assets/gui-icons/LucideAtlas2.png`
   - `assets/gui-icons/LucideAtlas3.png`
   - `assets/gui-icons/FlagAtlas.png`
3. Complete the image imports under the same creator as the experience and wait
   for moderation. In Asset Manager, select each image and use **Copy Asset ID**.
   Copy the **image asset ID**, not a game pass/product ID or a decal wrapper ID.
4. If an image is Restricted, use its asset permissions/Share controls to grant
   the existing experience access. It does not need to become a public store asset.
5. Set `src/client/IconAssets.luau`:
   `AtlasAssetIDs={LucideAtlas1_ID,LucideAtlas2_ID,LucideAtlas3_ID,FlagAtlas_ID}`,
   replacing those names with the four actual numeric IDs. The current zeros are
   unconfigured entries, not Roblox asset IDs. Uploaded assets are preferred over
   embedded EditableImages once configured.
6. Run `python scripts/package_stage10.py`, then test the rebuilt place with image
   APIs unavailable as well as enabled. Confirm all icons load and that there are
   no permission/moderation errors. Update corresponding source after entering IDs.
7. Do not publish the game until the rendered and device acceptance below passes.

Individual 256px icons and editable upstream SVGs are also supplied for review;
uploading all of them individually is unnecessary. Game-pass card artwork uses
supported `rbxthumb://type=GamePass` URLs and needs no duplicate upload.

Official references: [asset identifiers and permissions](https://create.roblox.com/docs/projects/assets),
[current Asset Manager](https://devforum.roblox.com/t/full-release-asset-manager-with-folders-search-and-more/4844672/1),
[image filtering](https://create.roblox.com/docs/reference/engine/classes/ImageLabel).

## Tests and measured limits

- Full Stage 1–13 automated regression gate passed after the primary corrections.
  Later flag/HUD changes passed focused icon, progression/purchase, UI and compile
  checks. Native-density dirty updates and released-territory restoration match a
  full repaint. All production Luau compiles.
- All registered icon cells decode to nonempty transparent images; map icons share
  four atlas images, with no per-icon texture. Image-API failure sets an explicit
  upload-required diagnostic instead of substituting fake assets or frame art.
- Premium navigation, purchases, cancellation/verification, permanent profile
  rules, party routes, HUD actions and phone/tablet/desktop bounds remain covered.
  Home button bounds and pairwise overlap are checked numerically at five sizes.
  These substitutes do not measure Roblox font rasterization or UI rendering.
- Local CPU samples after native-resolution/lazy-group changes:
  geography cold-row average **0.547 ms**, p95 **1.467 ms**, worst **2.127 ms**;
  5000-unit close-zoom lookup average **0.046 ms**, p95 **0.085 ms**, worst
  **0.113 ms**, 127 candidates, 80 created pooled objects.
  Previous lower-resolution terrain sample was 0.361 / 1.029 / 1.136 ms. The new
  geography is more detailed and this sample is slower; no rendering performance
  improvement is inferred from it. These are CPU functions, **not actual FPS**.
- Actual Studio/live FPS, frame percentiles, zoom responsiveness, startup time,
  GPU cost and physical mobile memory remain **unmeasured**. More source detail
  increases encoded data/download and potential module memory. Lazy preparation
  and the 2 MiB decoded cache do not establish a total client memory bound.

Local logs: `build/stage14-corrections-regression.txt`, `corrections-ui.txt`,
`corrections-stage13.txt`, `corrections-icons.txt`, `corrections-compile.txt`,
`stage14-results.txt`. The icon contact sheet is asset-only, not a Studio screenshot.

## Mandatory manual rendered acceptance — pending

Open `build/WorldConquest-stage10.rbxlx`. Inspect and capture main menu, public
lobby, spawn selection, active gameplay, construction, maximum zoom, Shop,
phone and iPad layouts. Compare with the supplied references. Check every icon,
label, price, tooltip, modal close and selected allocation state. Inspect desktop,
phone landscape/portrait and tablet landscape/portrait separately; then repeat on
physical iPhone, Android and iPad. Emulator results must be labelled as such.

Run a complete match and verify tap/drag/pinch, spawn changes, expansion/attacks,
build/upgrade/demolish, ships, missiles, rankings, results and leave/restart.
Specifically verify moving ships while the camera is stationary and placement
preview tracking without panning. Verify overlays never intercept empty map space.

Temporarily add `scripts/profile_actual_gameplay.client.luau` as a LocalScript in
StarterPlayerScripts of an acceptance copy. Record its 15-second
`WC_ACTUAL_GAMEPLAY` samples during cold loading, active gameplay, repeated zoom/pan
and maximum zoom. Record device, viewport and player count. Use MicroProfiler's
WC.CameraAndIcons, WC.TilePaint and WC.TextureUpload scopes to locate frame spikes.
Remove the diagnostic before release. Neither prior synthetic FPS nor this turn's
CPU measurements satisfy this rendered acceptance requirement.

Public paid prompts remain false, existing approved tester unchanged, public
capacity remains 20, and no Roblox publication or purchase was performed.

## Source, licences and changed files

Lucide is pinned to revision `164efbaf879fb29f55d88047efd49fc7725f53ab`;
full ISC and inherited Feather MIT notices are in `assets/lucide/LICENSE` and
`assets/gui-icons/LICENSE.txt`. Original OpenFront AGPL notices remain. Corresponding
source includes SVGs, PNGs, generated data, pinned build dependencies and scripts.
Actual game-pass artwork stays referenced through Roblox, not redistributed as
third-party files. No RoWorld artwork or closed-source code was used.

Runtime: InterfaceArt, IconAssets/IconData, CosmeticArt, StrategyUI, PremiumMenu,
MainMenu, Main.client, BuildingShop, NavalControls, MissileControls, SourceOffer,
MapView, MapTiles, TilePainter, OwnershipRaster, DirtyTiles, TerrainColors,
CompatibleTiles and generated Geography modules.
Build/tests: import_lucide, generate_gui_icons, generate_geography, gui_harness,
unit-icon/UI/premium/tile checks, requirements-icons, dependency/build/data notices.

This report supersedes the earlier Stage 14 visual/asset-resolution description;
its older measured data remains historical. Visual completion is not claimed.
