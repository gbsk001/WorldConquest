# GUI icons and Friends simplification — 24 November 2026

Replaced the 14 requested toolbar, statistics, invitation and exit symbols with original vector artwork rasterized at 4× supersampling into transparent 128×128 PNGs. Sources and exports are in `assets/gui-icons/`, with an AGPL licence notice. No external asset IDs, emojis or abbreviations are used for these icons.

The production GUI uses the same artwork through a single embedded 512×512 EditableImage atlas (1 MiB RGBA, 45,639 bytes of alpha RLE). It decodes once per client and uses one tinted ImageLabel per icon with ordinary filtered scaling. The retained colours, positions and dimensions come from the existing GUI. The separate map atlas and all map-rendering code are unchanged. EditableImage availability is the existing platform requirement; the legacy geometry remains an allocation-failure fallback.

Mappings: Army/crossed swords; Buildings/skyline; Navy/warship; Missiles/rocket; Leaderboard/trophy; Settings/gear; Soldiers/helmet; Recruitment/person-plus; Gold/stacked coins; Income/coins and up-arrow; Territory/flag; Rank/medal; Invite Friends/person-plus; Leave/exit arrow.

Removed the standalone Friends card from Home, both lobby Friends buttons and the now-unreachable custom Friends page. The Private Match button fills the freed row, and lobby actions close the gap. Invite Friends remains in both lobbies, using the unchanged Roblox SocialService prompt and public/private launch data. Server matchmaking and friendship APIs were not changed.

Changed production files: `src/client/InterfaceArt.luau`, `src/client/StrategyUI.luau`, `src/client/MainMenu.luau`. Supporting changes: original assets, `scripts/generate_gui_icons.py`, `scripts/menu_ui_checks.luau`, build-preview selection in `scripts/package_stage10.py`, this report and preview/build manifests.

Validation passed:

- `python scripts/check_stage10_ui.py`: menu navigation, private configuration, invitation availability and launch data, responsive layout stubs, countdown reuse, absence of the redundant controls.
- `python scripts/check_strategy_ui.py`: functional gameplay panels, leaderboard, settings and leave controls.
- `python scripts/check_unit_icons.py`: unchanged map unit atlas, pooling and culling.
- `python scripts/check_stage10.py`: matchmaking, privacy, invitation routing and round lifecycle with service stubs.
- Embedded atlas alpha decoded byte-for-byte equal to the PNG; antialiased coverage and 128-pixel cells verified.
- Rojo rebuild verified all 71 production sources in `build/WorldConquest-stage10.rbxlx`.

**Actual rendered verification completed in native Roblox Studio Play Solo.** An additional preview instance was cancelled at Studio's low-resource warning. Instead, the existing spawn-balanced place was connected to the current Rojo server and the source changes accepted before Play. Observed the revised main menu, public lobby, private lobby, all six toolbar icons, six HUD icons and exit/invitation symbols. Confirmed both lobbies have Invite Friends and Leave without a standalone Friends button. Invite Friends opened Roblox's actual invitation dialog; it was closed without sending invitations. Started the private match and inspected the live spawn-selection HUD. Play was stopped afterward.

This is desktop Studio visual acceptance, not published invitation delivery or physical-mobile testing. Responsive layouts were exercised by automated stubs; no new gameplay or large-load benchmarks were necessary for this scoped GUI change. Existing gameplay, AI, capacity and publication limitations remain unchanged.

To preview: open `build/WorldConquest-stage10.rbxlx`, press Play, inspect Home and either lobby, then start a match to inspect the toolbar/statistics. The root `WorldConquest.rbxlx` remains the obsolete prototype. Regenerate the original assets with `python scripts/generate_gui_icons.py` (standard library only), then rebuild with `python scripts/package_stage10.py`.
