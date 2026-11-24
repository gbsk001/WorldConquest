# GUI and identity polish — 2026-11-21

Implemented in the existing Stage 10 Rojo GUI; no second HUD or new gameplay mode. Stage 10 remains enabled. OpenFront gameplay formulas, ownership resolution, command APIs and existing panel animations are retained.

## Changes

- `src/client/StrategyUI.luau`: shared charcoal/navy translucent surfaces, quieter borders, consistent 12-pixel corners and reusable decorators. Existing Army, Buildings, Navy, Missiles, leaderboard/results and Settings mounts inherit the styling. Existing restrained slide animations and reduced-motion setting remain.
- `src/client/MainMenu.luau`: bounded desktop menu height, lighter backdrop, smaller title, left-aligned padded touch controls. Public/Private and Friends remain prominent; their actual callbacks are unchanged.
- `src/client/MapView.luau`: every player/bot map label has a fully transparent background, white text, subtle dark text outline, small territory-colour dot and available soldier count. Bots are explicitly marked `[AI]`. Labels and dots are passive; map input remains on the existing map surface. Spawn dots retain a larger white ring. Unit icons have rounded corners rather than square borders.
- Labels retain exact map-to-screen transforms and constant text size. Deterministic priority hides overlapping text instead of shifting anchors away from owned land. Offscreen text is culled; colour dots remain. Culling is cached between camera/roster changes. This prioritizes legibility over showing every name simultaneously; zoom in to reveal hidden text.
- `src/server/OpenFront/Simulation.luau`: separate presentation coordinates retain the original exact spawn point while owned, then choose an owned tile if it is lost. Searches inspect at most 64 ordered-set slots per metadata call, never the full world. A label can briefly disappear while tombstones are skipped. Original spawn coordinates and simulation state ownership remain unchanged. This is an owned-cell anchor, not a computed territory centroid.
- `src/server/OpenFront/Bots.luau`: 400 gaming-style prefix/suffix combinations, deterministic per-round ordering, case-insensitive collision checks and suffix fallback. A separate cosmetic seed does not consume the AI PRNG. Names stay stable throughout a match and vary with the next match seed. Existing authoritative username propagation supplies map labels, leaderboard, combat messages and results. Current human names are reserved at generation; an unforeseen later spectator can share a base name, but `[AI]` / `[BOT]` labels distinguish the bot without renaming it mid-match.
- `src/client/OwnershipRaster.luau`: stronger full-resolution territory-border contrast; no ownership/grid changes.

## Automated evidence

`python scripts/check_stage10_all.py` passed the Stage 1–10 simulation, server/replica and GUI adapter regressions. New identity tests in `scripts/bot_checks.luau` passed 100-name uniqueness, case-insensitive human collision, deterministic replay, round variation, stability and anchor ownership after territory loss. Existing AI workload digests matched across repeat runs.

`scripts/check_map_labels.py` checks transparent/passive label construction and executes the production overlap-culling function at zoom/pan offsets and five viewport sizes. It is now included in the full gate. Menu tests cover five sizes and existing gameplay GUI tests six sizes. Final menu, label and Stage 10 integration/compilation checks passed again after the final presentation refinements.

The initial regression run caught changed original spawn-coordinate metadata. This was fixed by introducing separate label coordinates; the original fractional-coordinate regression now passes unchanged.

`python scripts/package_stage10.py` rebuilt `build/WorldConquest-stage10.rbxlx` and verified all 64 production sources against the manifest. Tests use local Luau and service/GUI stubs, not rendered Roblox Studio or live multiplayer. No visual acceptance or live capacity claim is made. The latest 100-player impact stress still reached 210.606 ms; existing performance/publication blockers remain.

## Studio preview and acceptance

1. Stop Play. Sync `default.project.json` with Rojo, or open `build/WorldConquest-stage10.rbxlx` (the root place is historical).
2. Start Server & Clients with two clients. Exercise Public, Private, Friends, lobby settings, countdown and host start. Studio's local-only lobby adapter does not validate cloud teleports or native invitations.
3. Inspect menu and gameplay at 320×568, 390×844, 768×1024, 1920×1080 and 2560×1440, including safe areas and touch. Confirm controls fit, scroll and retain readable text; inspect the translucent panels against bright/dark territory.
4. Spawn nearby with bots. Verify no rectangular name backgrounds, white outlined text, colour dots, truthful soldier counts and AI markers. Pan, zoom, resize and tap/drag through labels. Labels must track owned cells and never steal clicks. Zoom into crowded areas to reveal culled names.
5. Capture an original spawn and eliminate a player. Verify the surviving label moves to owned land, eliminated labels disappear, and both clients agree on names. Finish and restart a match; confirm stable names within the round and a fresh roster afterward.
6. Test Army allocation, building placement/upgrade/demolition, naval and missile targeting, settings, notifications, leaderboard/results and return to menu. Check reduced motion and graphics settings. Run full-match/live-service acceptance from `STAGE10_ACCEPTANCE.md` before publication.

No new third-party image, font, audio or model assets were imported. Existing Roblox fonts and generated GUI geometry are used. AGPL notices remain; public corresponding-source hosting is still a publication requirement.
