# Mobile startup and input repair — 24 November 2026

Implementation and automated verification are complete for this patch. **Full mobile compatibility is NOT certified.** Fresh Studio device emulation and physical iPhone/Android/iPad/tablet tests remain outstanding. Both native-control interfaces failed with `native pipe ... cannot find the file specified`; no screenshots or earlier desktop results have been presented as new mobile evidence. No public experience was created, published, or reconfigured by this task.

## Blank-screen investigation

The reported failure occurred on a published iPhone client. The phone model, client log and existing experience URL were not available, so the precise incident cause remains unconfirmed. Local code inspection found actionable failure paths:

1. `Main.client.luau` decoded map data and required renderer modules before constructing the menu. There was no independent startup/error UI.
2. `MapView` returned nil if EditableImage allocation failed; `Main.client` then returned before attaching game replication handlers. A permission or device-memory failure could strand the game.
3. Texture upload errors after initialization had no renderer recovery path.
4. Touch positions, which already account for the GUI inset, were transformed like raw mouse screen positions. This could offset map taps; the slider also subtracted an extra root offset.
5. There was no two-finger pinch state, and the layout selected phone mode mainly by width, leaving landscape phone screens with excessive header height.

The server retains its existing live MemoryStore/Teleport adapters and explicit Studio service substitutes. New client code has no Studio-only dependency. Static server inspection and server/replica regressions passed; actual published client/server logs were not available, so no claim is made that the reported live incident was reproduced.

## Changes

- `src/boot/Loading.client.luau`, `default.project.json`: a dependency-free ReplicatedFirst loading screen, delayed-start feedback and reconnect action. Unexpected initialization errors are caught and shown instead of silently aborting. The reconnect action rejoins the same place ID, subject to normal Roblox teleport availability; it does not create a new experience or promise to preserve a reserved-server seat.
- `src/client/Main.client.luau`: main menu before map initialization; initialization error capture; touch client budget; landscape orientation; hardware/core safe-area layout; correct slider coordinates, single-pointer ownership and scroll locking; bounded initial sync waits and an automatic stalled-connection resync watchdog.
- `src/client/MainMenu.luau`: optional decorative map loads asynchronously under error protection; handshake retries; compact landscape headers; scrollable lobby actions; larger close/invitation controls; safe-area margins. Public/private and invitations remain the same server APIs.
- `src/client/MapTiles.luau`: permission/allocation failure handling, initial-upload cleanup and automatic runtime-upload recovery. Avoids allocating display mip buffers before confirming an image can be allocated.
- `src/client/CompatibleTiles.luau`: image-free rendering fallback using pooled, merged visible row runs. Incremental work is budgeted at 1.5 ms between operations; no full-world scan and no object per ownership cell. Objects are capped at 8,192; the sampling grid is bounded around 96×64 visible samples plus edge coverage. Ownership, colours and fallout read the authoritative replica.
- `src/client/TouchGestures.luau`, `MapView.luau`: one-finger pan, two-finger focal zoom and movement, tap selection through the existing gameplay callbacks, suppression of taps after a drag/pinch, both finger-release orders, focus cancellation and touch-driven placement previews. Mouse wheel/click controls remain.
- `src/client/StrategyUI.luau`, `PanelChrome.luau`, `MatchHUD.luau`: compact landscape stats, readable abbreviated headings, 44-pixel close controls, scrollable panels and leaderboard initially collapsed on smaller map viewports. It can still be opened and closed; results remain available.
- `src/client/BuildingShop.luau`: bounded, scrollable building information with responsive upgrade/demolish/close buttons. Leave confirmation now uses the full safe content area instead of the short map viewport; its map-input guard follows the modal.
- `src/client/IconLayer.luau`: optional per-layer visible/pool cap; touch clients use 96 ship/building icons per layer versus 256 on desktop. All units remain in the replica and become visible as the view changes.
- `src/client/InterfaceArt.luau`: skips the optional decorative background silhouette when image creation fails, avoiding a large GUI fallback just for the menu background. Existing GUI icon fallback remains available.
- Tests: `scripts/check_mobile.py`, `tile_checks.luau`, `strategy_ui_scenarios.luau`, and `check_stage10_all.py`; rebuilt place and manifests.

All platforms still join the same public/private matches and use the same authoritative soldiers, combat, building, naval, missile, bot, victory and restart systems. No device-specific game mode was added. Public capacity remains 20. The 8192×4096 ownership grid, formulas and server simulation were not changed.

## Rendering limits and performance claims

Touch clients start with at most eight detail images instead of 32, plus one overview. This reduces the **configured** map image storage ceiling from about 8.38 MiB to 2.29 MiB, and detail scratch buffers from about 10.16 MiB to 2.54 MiB. Those calculations exclude terrain, replica, GUI atlases, engine overhead and total client heap. They are allocation-budget calculations, not measured physical-device memory savings.

Normal rendering retains exact high-zoom cell detail and the existing visible-chunk cache. The image-free fallback uses display LOD with hard-edged rectangles, updating visible regions in bounded increments. It is intentionally lower-detail at wide views; tiny islands or ownership features can be visually omitted at coarse sampling levels. Tap validation and simulation remain full resolution. It is a recovery renderer, not a claim of equal visual fidelity or measured 30–60 FPS. Extremely low-memory devices can still be terminated by Roblox/the OS before scripts can display recovery UI.

The 30–60 FPS target, startup time, sustained memory stability, device heat and full-match reliability have **not** been measured on physical mobile hardware. The desktop CLI timings in regression output are not mobile FPS measurements.

## Automated tests

`python scripts/check_stage10_all.py` runs the full Stage 1–11 functional suite, now including mobile gestures/fallback rendering and balanced spawn checks. It covers the existing gameplay, deterministic simulation, missiles/SAM, elimination/victory/results/restart, networking/replicas, matchmaking/privacy, GUI actions and icon pooling. Complete output is retained in `build/mobile-full-regression.txt` and the existing per-suite files.

New targeted tests cover permission-denied image creation, nil allocations, failed initial upload, failed runtime upload/recovery notification, taps, drag-return without attack, pinches with either finger lifted first, single-finger continuation after pinch, cancellation, fallback pan/zoom sampling, bounded GUI objects, hidden pause and cleanup. All Luau sources compile. Layout tests exercise phone/tablet/desktop dimensions with GUI stubs; these are **not rendered emulator tests**.

The full gate passed, followed by targeted GUI/gesture/fallback checks after the final short-screen building-information and confirmation adjustments. The final package verifies all 74 current production Luau sources, including the ReplicatedFirst loading script. The build manifest deliberately records no current Studio render preview because older desktop source hashes no longer match.

## Required Roblox settings and existing-place update

1. Open your **existing WorldConquest experience** in Creator Dashboard. In **Audience → Access Settings → Devices**, ensure **Computer, Phone and Tablet** are enabled. In Studio versions exposing it, the equivalent field is **Experience/Game Settings → Basic Info → Playable Devices**. These device categories cover iOS and Android; there is no separate mobile experience to create.
2. For the high-detail renderer, enable **Experience Settings → Security → Allow Mesh / Image APIs** (Creator Dashboard may label it **Enable Mesh / Image APIs**). The owning account/group owner must satisfy Roblox's current eligibility/verification requirements if the control is unavailable. The fallback is intended to keep this patch usable when permission or memory allocation fails. See [Roblox EditableImage documentation](https://create.roblox.com/docs/reference/engine/classes/EditableImage/WritePixelsBuffer).
3. **Enable Studio Access to API Services is not a mobile-rendering fix and is not needed for live players.** The existing Studio matchmaking adapter uses local substitutes. No new HTTP, third-party teleport, or API key setting is required by this patch. [Roblox distinguishes Studio API access from live data-store access](https://create.roblox.com/docs/cloud-services/data-stores).
4. Open `build/WorldConquest-stage10.rbxlx` in Studio. Select **File → Publish As…** (older versions: **Publish to Roblox As…**), select the **existing WorldConquest experience**, select its **existing start place**, and choose **Overwrite**. Verify the experience/place identity before confirming. Do not select Create New or Add as a new place. If instead you open the existing cloud place and sync `default.project.json` with Rojo, normal **File → Publish** updates that already-linked place. [Roblox documents overwriting an existing start place](https://create.roblox.com/docs/production/publishing/publish-games-and-places).
5. After publishing, restart the existing experience's servers so players do not remain on the old version, then rejoin from the Roblox app. Restarting ends active matches; schedule it accordingly. Confirm the same experience URL and start place are still in use. No changes to cloud settings or publication were made by the assistant.

## Studio emulator acceptance — PENDING

Use Studio's Device Emulator/Device Simulator (Test menu; labels vary by Studio version). Test an iPhone preset, an Android phone preset, an iPad preset, an Android tablet preset, and desktop. Include a small landscape phone and notched landscape screen, both landscape orientations, portrait transition, and tablet rotation. [Roblox testing documentation](https://create.roblox.com/docs/studio/testing-modes) distinguishes device and network simulation from live clients.

For **each** device profile:

1. Cold start: loading screen appears, menu becomes usable, no script errors, attribution remains, and notch/core controls do not cover actionable UI.
2. Public and private lobby: names/counters, invite prompt, private code/configuration, Start and Leave; all controls reachable by touch/scroll.
3. Spawn: tap exact land, change selection, reject water, observe other players' markers; drag and pinch must never select/attack on release. Test both finger-release orders and a third finger.
4. Gameplay: pan/zoom, move allocation slider across its range without scrolling the Army panel, expand/attack, cancel/return, inspect/build/upgrade, naval transport/warship targets, missile purchase/targeting/SAM, crowns and collapsible live rankings. Confirm panel taps never reach the map.
5. Finish a match: elimination, victory, results, return to menu, new round, Leave Game confirmation; old-round actions remain rejected. Check foreground/background/resume and connection interruption recovery.
6. Repeat in **local test only** with `ForceCompatibleRenderer=true` temporarily added to Config, then remove that override before publishing. Compare selection coordinates with normal rendering; test gameplay ownership updates, zoom/pan and map icon selection. Do not disable security settings just to simulate failure.
7. Use two local clients (one touch profile, one desktop) in the same match. Confirm both replicas agree on selections, territory, attacks, purchases and results. Published teleports/invitation delivery require a subsequent live test.

## Physical-device acceptance — PENDING

Run the same full-match checklist on an actual iPhone, Android phone, iPad and Android tablet, with at least one PC player in the same public/private match. Record model/OS/Roblox version, cold startup time, average/p95/worst frame time, memory trend over a complete match, normal/fallback renderer, and failures. Test Wi-Fi/mobile network interruption, background/resume, charging/thermal load and both rotations. A device emulator does not reproduce iOS/Android graphics memory, GPU drivers or thermal behaviour. Do not mark compatibility complete until these results exist.

Remaining blockers: no reproduced physical iPhone failure log, no fresh rendered emulator evidence, no measured mobile FPS/memory, no live cross-device full-match/teleport acceptance. Existing AGPL notices and assets are retained; `Config.SourceURL` now points to https://github.com/gbsk001/WorldConquest, whose corresponding source is public. That source must continue to match the version the owner publishes. See `CONTROLLED_LIVE_TESTING.md` for the current candidate.
