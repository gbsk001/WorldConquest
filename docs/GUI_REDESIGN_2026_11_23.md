# Runtime GUI redesign ? 23 November 2026

This replaces the previous incremental polish. It is implemented in the modules actually loaded by `Main.client.luau` and the server lobby adapter.

## Runtime findings

The lobby did not use the gameplay bot names. `MainMenu.luau` explicitly formatted difficulty plus index; `Bots.luau` generated names only near the end of spawn selection. The fix is a server-owned lobby roster, projected as `BotNames` and passed through `LobbyServer` into `BotSettings.Names`, then used by the normal authoritative Join command. Difficulty never becomes a username. Existing map, notifications, rankings and results consume the same player Username.

The Studio window was an AutoRecovery place, connected to WorldConquest through Rojo at localhost:34872. Stopping and restarting Play visibly loaded the changed modules. The root `WorldConquest.rbxlx` is an old 2.8 MB prototype without PortStage; it is not the Stage 10 build. Use `build/WorldConquest-stage10.rbxlx` or the connected Rojo project. No user Studio place was overwritten or published.

## Changed production files

- `src/client/MainMenu.luau`: full-screen world backdrop and large title; side-by-side Public/Private cards on desktop; large Friends control; secondary Settings/Tutorial; pointer hover tweens. Lobby participant cards with Roblox avatar thumbnails and bot icons, distinct difficulty labels, large countdown, private code and host controls. Desktop home/lobby have no visible scrollbars; mobile stacks and scrolls when necessary. Native invitation/friend handlers remain intact.
- `src/client/InterfaceArt.luau`: original line icons and bounded decorative world silhouette sampled once from existing Earth data. It uses merged runs on a 256?128 decorative sampling grid, not one GUI object per gameplay cell. No new external asset dependency.
- `src/server/LobbyState.luau`: 512 seeded username candidates with collision suffixes. Names are generated before gameplay and remain stable through bot-count/difficulty changes. Names are reserved against humans present at creation. Session ID entropy varies new lobbies; replaying the same roster is deterministic. A later human may share a base name, but BOT indicators distinguish identities without renaming existing bots.
- `src/server/LobbyServer.luau`, `src/server/OpenFront/Bots.luau`: carry exact lobby identities into the match without consuming the AI RNG.
- `src/client/Main.client.luau`: suppress default player list, backpack, health and emotes through supported client APIs; preserve Roblox system controls/chat. Full-screen backdrop covers the inset region; interactive content retains inset padding. Army allocation has a thin track and thumb while retaining its original allocation calculation and input surface.
- `src/client/StrategyUI.luau`: shorter statistics bar, original line icons, icon-labelled command toolbar, retained functional panels and slide transitions.
- `src/client/BuildingShop.luau`: larger building cards with icons, readable effects, actual price/affordability colours and unchanged placement actions.
- `src/client/MatchHUD.luau`: pooled ranking cards with separate rows and highlighted first place; same authoritative rankings/results and restart timing.

Transparent outlined map name tags and exact map coordinate handling from the previous change remain. The high-resolution simulation grid, formulas, costs, match types and server permissions are unchanged.

## Verification

`python scripts/check_stage10_all.py` passed the full Stage 1?10 regression suite, including bot deterministic replay, multiplayer replica/server adapters and GUI callbacks. Stage 10 tests now assert that lobby names are passed unchanged into the production simulation/replica. Added tests cover 19 unique lobby names, stable count/difficulty changes and new-session variation. Final focused menu, gameplay GUI and Stage 10 checks passed after visual corrections.

Actual Roblox Studio desktop rendering was inspected through the connected Rojo AutoRecovery place. Observed main menu, Public/Private navigation, private participant cards/code/host controls, public countdown, spawn selection, gameplay, leaderboard cards, Army slider and transparent bot map labels. Clicking the slider changed allocation from 20% to 71% and moved the thumb. Lobby names AlexProRush/xShadow101/RookieX appeared unchanged on the gameplay map. No default player list or grey inset strip appeared in the updated view. The corrected building-card icons were inspected again without text overlap. Visual inspection caught clipped Leave controls and icon/text overlaps; those were corrected and the menu/public lobby checked again.

This was a local one-client Studio preview with bots, not live Roblox matchmaking or a complete multiplayer acceptance run. Native invites were not sent. Mobile/touch safe areas, multiple real clients, full match results/restart and live teleport/service behaviour remain manual acceptance tasks. Automated GUI stubs do not certify those cases.

The large-load performance risks remain: the latest local 100-player simultaneous-impact stress reached 130.294 ms worst tick with a 2,203,700-byte encoded maximum delta. This visual work does not claim to resolve those pre-existing capacity limits.

## Preview

1. Stop Play and verify Rojo shows WorldConquest connected on port 34872. Restart Play, or open the newly rebuilt Stage 10 place.
2. Verify the large WORLD CONQUEST title and two desktop match cards. If the old scrolling column appears, the loaded place/scripts are stale.
3. Create Private, change count/difficulty, note names, then start. Compare those names on the map and leaderboard. Exercise public countdown and Leave.
4. Test Army slider, building purchase/placement, naval/missile controls, leaderboard and settings. Complete a match and verify results/menu return.
5. Repeat with two Studio clients and mobile portrait/landscape emulation. Use published staging for native friends/invites/teleports.

AGPL attribution remains visible. No new third-party artwork/audio was imported. The existing public corresponding-source offer, licensing review, live service acceptance and performance blockers still apply before publication.

The source-hash-bound preview record is `build/studio-preview-2026-11-23.json`. The build manifest carries its limited scope only when hashes still match. Final small Friends-icon centering and mobile right/bottom inset adjustments were covered by focused automated tests; native mobile rendering remains unverified.
