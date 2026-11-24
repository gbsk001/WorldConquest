# GUI and rendering acceptance ? 23 November 2026

Implemented in the actual client entry point and Rojo source. Stage 11 remains enabled; server simulation, formulas, ownership resolution, matchmaking and AI configuration are unchanged. The release is `build/WorldConquest-stage10.rbxlx`, not the historical root prototype. This update is ready for further manual acceptance, **not a claim that all performance problems are solved**.

## Changes
- `src/shared/TerritoryRanking.luau`: shared territory-only ranking, deterministic SmallId/UserId ties, excluded eliminated/spectator/disconnected/zero-land participants; top-three crowns only during gameplay.
- `src/client/InterfaceArt.luau`: original graphical gold/silver/bronze crown geometry, Play, Close and Exit graphics.
- `MainMenu.luau`: dominant PLAY routes directly to Public, smaller Private and prominent Friends, secondary Settings/Tutorial; pending-request duplicate guard and timeout feedback; optional page close/Escape.
- `MatchHUD.luau`: pooled live top ten, local participant outside top ten, territory percentages and owner-colour progress, locate action, animated reorder, adaptive row height, auto-open once at gameplay start. Closing remains respected on metadata updates. Results continue using server rankings.
- `PanelChrome.luau`, `StrategyUI.luau`, `BuildingShop.luau`: fixed graphical X controls outside scroll content, close/reopen and cancellation of unconfirmed actions, notification visibility control, permanent Leave Game with Stay/Leave Match confirmation. Existing building/naval/missile commands retained.
- `Main.client.luau`: exact replica counts update rankings/crowns immediately after ownership deltas; menu return clears the old replica/selection/UI and ignores foundation traffic until the next authorized MatchReset.
- `MapView.luau`: map crowns, conditional roster/palette property writes, cached name-layout invalidation, eased cursor-anchored wheel zoom, rendering pause in menus, round cleanup and roster timing attributes.
- `MapTiles.luau`, `DirtyTiles.luau`: coalesced dirty rectangles, retained bounded cross-LOD tile cache, visible cached fallback, one new EditableImage allocation per heartbeat, pending-allocation readiness guard, centre-first fresh tile painting, full-tile buffer reuse. Pixelated rendering and exact 8192?4096 ownership preserved; overview LOD remains a visual overview, not a substitute ownership grid.
- `IconLayer.luau`: bounded reuse for 256 visible decluttered icons and cache skips when immutable replica lists/palette have not changed.
- Tests: `check_strategy_ui.py`, `strategy_ui_checks.luau`, `strategy_ui_scenarios.luau`, `check_stage10_ui.py`, `menu_ui_checks.luau`, `check_luau.py`, `tile_checks.luau`.
- Native benchmark fixture: `scripts/render_acceptance.client.luau`, `scripts/package_render_acceptance.py`; never included in the release.

## Measured rendering
Actual native Roblox Studio desktop renderer, **500 synthetic participant records and 3,000 buildings**, 48-second scripted workload (12 seconds per phase), periodic 1,024-cell changes and repeated detail/zoom/pan. No server gameplay simulation in this fixture. FPS is 1000/mean RenderStepped interval. Memory is cumulative observed peak within a run.

| Phase | Before FPS | After FPS | Before mean/p95/worst ms | After mean/p95/worst ms |
|---|---:|---:|---|---|
| Initial warmup | 57.2 | 57.1 | 17.47 / 18.14 / 406.02 | 17.53 / 18.26 / 423.89 |
| Overview | 60.0 | 60.0 | 16.67 / 17.90 / 20.89 | 16.67 / 18.10 / 23.67 |
| Detail | 57.8 | 57.0 | 17.29 / 32.70 / 67.74 | 17.54 / 34.25 / 51.54 |
| Zoom/pan | 57.2 | 56.7 | 17.49 / 34.01 / 47.37 | 17.62 / 34.58 / 60.28 |

Final phase Luau heap peak: **48.8 ? 54.0 MiB**. Stats total reported memory: **2604.7 ? 2283.4 MiB**; this includes Studio/native resources and is not attributable solely to the map. Several preview places were open and Studio subsequently reported low system resources; these runs do not establish a controlled FPS improvement. An intermediate optimization run had a 202.28 ms warmup worst frame, but the final run did not reproduce that gain. No sustained FPS improvement is claimed. Initial allocation/GC/native image work and detail repaint remain bottlenecks. Retaining icon/tile caches trades some heap for less repeated construction.

CPU microbenchmark: 10,000 ownership changes, existing five-walk invalidation workload **9.741 ms**, batched path **0.654 ms**. This compares the named workloads, not a native frame-time speedup. Exact ownership, concurrent dirty updates, single-pixel upload and cancelled tile-job recovery tests pass. Existing 5,000-unit icon CPU fixture measured mean 0.807 / p95 0.971 / worst 1.462 ms with at most 256 visible icons; excludes GPU.

Raw native results: `build/render-before-native.txt`, `build/render-after-first-native.txt`, `build/render-after-final-native.txt`. The original `render-before` fixture was invalidated by ResetOnSpawn destroying its GUI; only `render-before-valid` is used above.

## Automated acceptance
`python scripts/check_stage10_all.py`: all Stage 1?11 functional regressions passed. The first run exposed the previous closed-by-default leaderboard test assumption; corrected it to verify auto-open once, then explicit close persistence, and reran successfully. `check_strategy_ui.py` passed again after adaptive row sizing; `check_luau.py` passed compilation and map/dirty-tile checks after final source changes.

New tests cover 500 participant ranking records, top ten plus own row, crown transfer, ties, elimination, locate, hidden-panel allocation, result-close persistence, Leave/Stay callback isolation and fixed panel close. Existing tests cover authoritative gameplay, missiles, SAM/MIRV, economy, navigation, deterministic replay, round isolation, replication/recovery, lobby permissions, generated identities, spawn reservations and existing UI actions. Service/GUI stubs are not live Roblox certification.

Performance gates are separate: the latest automated 100-player simultaneous-impact stress observed worst ticks **136.071/147.676 ms**, despite functional pass. Safe public population stays **20**, not 250 or 500. Previous Stage 11 large-population frontier/pathfinding limitations remain. This task did not re-certify production server capacity or network fanout.

## Native acceptance evidence
Actual rebuilt release opened by its build path in Studio. Verified PLAY ? 20-player Public lobby ? staggered spawn selection ? gameplay, no spawn crowns, original graphical live crowns, changing territory ranks/crown recipients, transparent labels, leaderboard close/reopen, row click locating the correct crowned participant, Stay retaining the match, Leave Match returning to the main menu, and PLAY forming a fresh lobby/spawn round afterward. Detailed coastline tiles replaced temporary cached overview tiles after camera relocation. No multi-client/live teleport acceptance is claimed.

After accepting the final source sync in the native Rojo plugin, also verified Friends page/X, Private host lobby/code/host Start, private gameplay, and building/naval/missile panel opening and X closure. Native Escape initially failed because CoreGui marked the key processed. Removed that guard for Escape only; after restarting, Friends closed back to Home on Escape while the Roblox system menu remained available. Added a processed=true Escape regression. The six-player private match exercised the final adaptive row code; the ten-plus-local short-viewport case still needs native retesting. Native screenshots were displayed during verification and exported under `build/gui-evidence/`. The benchmark is a synthetic renderer fixture, not a 500-player real match.

## Remaining acceptance and blockers
- Repeat controlled before/after runs with one Studio process, cold/warm caches and MicroProfiler; eliminate startup stalls and repeat detail p95/worst tests. The current evidence does not support calling rendering performance fully fixed.
- Test final adaptive leaderboard at desktop and mobile sizes; mobile touch/safe-area/performance and maximum zoom require device acceptance. Confirm top ten plus local row, long usernames, close targets and no panel click-through.
- Run two real Studio clients through selections, battles, elimination, crown transfer, complete victory/results, leave/rejoin and stale-round delivery. All optional panels: X, toolbar reopen, Escape, cancellation of only unconfirmed placement/targeting, notification dismissal; keep Roblox system controls intact.
- Exercise Private host/configuration and Friends UI; real invitations, MemoryStore/Teleport/reserved-server behaviour require published staging and supported accounts.
- Test large mature games, missiles, navigation and network recovery. 500 records rendered is not 500 production participants supported.
- Preserve NOTICE/LICENSE, original graphical assets and existing upstream mappings. `Config.SourceURL` remains blank: publish the corresponding AGPL source and source offer before publication. Existing Stage 9 upstream deviations and Stage 11 capacity restrictions remain documented in their reports.
