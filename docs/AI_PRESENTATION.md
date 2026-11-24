# Participant presentation ? 23 November 2026

Presentation-only update. No server source, AI decision rules, difficulty, identity flags, names, resource rules, matchmaking or gameplay mechanics changed.

- `src/client/MainMenu.luau`: combined player count; shared READY/HOST card status; no individual bot/difficulty captions; removed the Public Match bot-count sentence. Private host difficulty/count controls remain. Lobby match information discloses: ?Matches may include AI opponents.?
- `src/client/InterfaceArt.luau`: original abstract profile icons generated from the existing random username. Colour and geometry vary between identities and remain stable within a match. No Roblox account lookup, avatar ID or friendship association is used for generated profiles. Actual human cards retain their own avatar thumbnails.
- `src/client/MapView.luau`: identical transparent outlined name text for all participants; removed the AI suffix.
- `src/client/MatchHUD.luau`: identical rankings/results formatting; removed the BOT suffix. Existing combat notifications already use the same authoritative username without a bot prefix.

All existing usernames remain. Native Friends still comes exclusively from Roblox presence APIs, not the participant roster. Generated identities are not clickable Roblox profiles or purported friends.

Tests: full Stage 1?10 automated regressions passed. Added GUI checks cover generated icon count, human-only thumbnail IDs, aggregate count and general disclosure. Focused results tests verify identical formatting with server IsBot flags intact. Automated service/GUI tests are not live Roblox verification.

The rebuilt artifact is `build/WorldConquest-stage10.rbxlx`; the root place remains historical. Use connected Rojo with Play stopped, then restart Play, or open the rebuilt Stage 10 place.

Actual desktop Studio verification: inspected the connected Rojo menu, the 6 PLAYERS private lobby with original profile icons and general disclosure, changed private difficulty from Normal to Hard without changing names/icons, started the match, and inspected map tags and leaderboard without BOT/AI suffixes. The names JustJayX, NovaStormOne and CaptainPlays stayed consistent across these views. Results use the same formatter and passed automated checks; a full match ending was not manually replayed. Native multiplayer/live services and mobile rendering were not tested in this presentation-only update.
