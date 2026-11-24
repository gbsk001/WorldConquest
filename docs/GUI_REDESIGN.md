# WorldConquest GUI redesign

The Rojo client now uses an original navy/charcoal command interface with translucent rounded surfaces, subtle borders, blue selection accents, gold economy cards, green recruitment and red demolition text. Earth remains the central input surface. Existing gameplay handlers and server APIs are retained; no gameplay or server files were changed for this redesign.

## Components and working controls

- Compact top bar: phase/countdown or match clock, soldiers, recruitment per second, gold, income per second, territory and authoritative rank. Six cards use one row on wide screens and two rows below 620 pixels. Values update from replicated profiles, with unchanged values left alone.
- Bottom toolbar: Army, Buildings, Navy, Missiles, Leaderboard and Settings. Existing module buttons are reparented, not duplicated. Only one panel is visible. Opening a different panel cancels other placement/target modes. Escape dismisses panels. Restrained 160 ms panel entrance motion can be disabled in Settings.
- Army: 1–100% allocation slider, selected attack cycling, stop/return through existing Cancel API. The slider tracks the initiating touch; other touch movement cannot change its value. Allocation also supplies transport launches.
- Buildings: original authoritative costs, effects, availability and affordability, all six supported building types, placement, upgrade and delayed demolition. Larger actions and scrolling support short windows.
- Navy: transport invasion, warship purchase, select/move warship and transport retreat; original quotes, selected-unit validation and order sequences remain.
- Missiles: atomic/hydrogen/MIRV quotes, target selection, silo slot/reload summary and automatic SAM status. No manual interception button or unsupported missile action was invented.
- Collapsible leaderboard/results: authoritative rankings, elimination/disconnect status and automatic result opening/restart reset. Text is rebuilt at most once per second while visible.
- Settings: fit map, zoom in/out and reduced panel motion. These change the actual existing camera and local presentation only; no fake audio/graphics controls.
- Notifications: bounded single server-result toast plus persistent map/placement instructions. Spawn countdown and select/move instructions remain, with rounded player-name badges on exact existing map coordinates.

## Layout and input

The existing ScreenInsets.None physical coordinate convention and GuiService inset layout are preserved. No second coordinate subtraction is added to map picking. Army/Settings join existing wheel blockers; visible panels also explicitly reject map press/release handling beneath their bounds. No full-screen input-capturing overlay was introduced. Panel rows scroll, toolbar targets are 44 pixels high and all six toolbar controls fit a 320-pixel-wide root. Buttons remain below the map; notifications do not capture clicks.

## Changed production files

- `src/client/StrategyUI.luau`: shared surfaces, status cards, toolbar, panel mounting, exclusive visibility, motion preference, settings and notifications.
- `src/client/Main.client.luau`: integrates the shell, reparents Army controls, tracks touch allocation, refreshes status cards and routes result notifications.
- `src/client/BuildingShop.luau`, `NavalControls.luau`, `MissileControls.luau`: expose existing panel/toggle handles, improve scrolling and touch targets without replacing order handlers.
- `src/client/MatchHUD.luau`: exposes existing handles and bounds leaderboard updates.
- `src/client/MapView.luau`: name badges and explicit panel input exclusion; transforms unchanged.

Automated checks: `python scripts/check_strategy_ui.py` executes production adapters with Instance/service stubs. It exercises all building types, upgrade/demolish, all naval/missile actions, spectator guards, shared sequence, exclusive panels, camera settings, results and round reset. Layout bounds are checked at 320×568, 390×844, 768×1024, 844×390, 1366×768 and 1920×1080. `python scripts/check_luau.py` compiles all production Luau and passes 1,184 screen/map/marker round trips plus renderer scheduling tests. Full Stage 1–8 regressions are also run. These checks are not rendered GUI, hit-testing, GPU, real multitouch or Studio multiplayer tests.

## Studio preview and acceptance

1. Stop Play and sync `default.project.json` using Rojo, or open the rebuilt `build/WorldConquest-stage8.rbxlx`. Confirm PortStage=8. The root place is still older.
2. Run Server & Clients with two clients. Verify only one HUD, map readiness, countdown, spawn selection/auto-spawn and readable status values on both clients.
3. Use Device Emulator at every size above, including landscape and a notched-device safe area. Check no clipping, reachable scrolling, toolbar labels and sufficient map space. Repeat on real touch hardware.
4. Drag the Army slider to 1%, 20% and 100%; send attacks/transports and compare their committed amounts. Test a second touch, release outside the slider, attack cycling and stop/return. No army order should fire from touching a panel.
5. Purchase every supported building with sufficient test gold; test unaffordable quotes, placement, upgrade/demolition, rapid menu changes and Escape. Restore test economy overrides afterward.
6. Exercise all four Navy actions and all three missile types. Verify the correct server charge, target, active mode and cancellation. SAM remains automatic.
7. Zoom/pan/fit with panels open and closed. Wheel over a panel must scroll it without zooming Earth. Tapping/dragging beneath panel bounds must never select land. Check spawn/player/unit labels remain aligned after resize.
8. Toggle leaderboard, receive notifications, end a match and restart three times. Check results, updated ranks, no stale placement or duplicate HUDs, and late-join behaviour. Follow the full Stage 8 checklist for gameplay.
9. Profile client frame/upload times, GUI instance count and memory over full matches. Check reduced motion. Record Studio/client versions and screenshots before visual sign-off.

No live Studio preview, rendered-resolution test or physical-device test was performed by this change. Existing 100-player tick/network and corresponding-source publication blockers remain. Existing AGPL notices remain; this UI introduces no uploaded artwork, audio, external fonts or third-party assets.
