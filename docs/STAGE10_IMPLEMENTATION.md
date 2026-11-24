# Stage 10 — Main menu, Public Match, Private Match and Friends

Stage 10 implements exactly **Public Match** and **Private Match** over the existing Stage 1–9 simulation. Tutorial and Settings are menu screens, not game modes. Stage 10 explicitly removes the earlier `Match.SinglePlayer` admission override when constructing a game. No ranked/solo menu, matchmaking category or third match type exists.

The Rojo candidate is for acceptance testing. No live Roblox service call, native invitation, published teleport or rendered Studio/mobile acceptance was performed by this implementation. Automated tests use deterministic service and GUI stubs. Existing performance and corresponding-source publication blockers remain.

## What is working in code

- A responsive navy/charcoal main menu with prominent Public Match, Private Match and Friends controls. Safe-area layout, scrolling small-screen content, Settings and a seven-step skippable tutorial.
- Public matchmaking prefers a visible online friend's eligible public lobby, then a listed open lobby. Capacity is atomically reserved before travel. An idle ordinary server can host a new public lobby locally. If it is already hosting a match or is a reserved/VIP server, a fresh reserved instance hosts a new **publicly listed Public Match**. Underlying server infrastructure does not determine the match's access policy; the session's authoritative type does.
- Public lobbies automatically start after 15 seconds, followed by the existing map-ready/spawn-selection flow. They start with five Normal bots, reduced only when necessary to keep humans plus bots at 20. They do not expose difficulty or host-start controls.
- Private hosting creates a separate reserved destination, a GUID-based 32-hex-character join code, and server-held membership. Guests can enter the code or follow a native invite. Reserved routing identifiers, admission tickets and membership records are never included in GUI projections. No legacy reserved access code is generated or shared.
- Private host controls: bot count 0–19 (subject to total capacity 20), Easy/Normal/Hard difficulty, Start and Leave. Guest controls: invite/share code, player/bot roster and Leave. Host departure transfers hosting deterministically to the lowest remaining user ID. Last-member departure closes the lobby.
- Public and private reservations are separate. Full, expired, closed, wrong-place and wrong-destination sessions reject admission. Public directories never include Private Match records. New code joins stop when a match starts; already-reserved arrivals can complete their admission.
- Friends are obtained through Roblox's permitted online-presence API. Join verifies friendship on the server and only follows eligible publicly listed lobbies. Private or hidden presence returns unavailable feedback; a private code/invitation is needed. No custom friendship database exists.
- Native invitation prompt with LaunchData: private code or public session hint. LaunchData is only a request hint; authoritative membership is claimed and checked server-side. Invitations do not automatically pull other people into a server. Joining friends is best effort, not an atomic party queue.
- Menu → Lobby → Spawn → Gameplay → Results → Menu. Only admitted users enter FoundationServer or receive its snapshots, deltas and reset events. Results return to the menu instead of starting another round automatically. A new selection creates a fresh simulation, bot state, seed/round ID and order sequences.
- Active players can leave through the existing in-game Settings panel. A 60-second membership grace supports reconnects while the same match instance remains alive; a gameplay reconnect uses normal late-join/spectator rules, not restoration of an abandoned army. Last-member closure or server loss does not pretend to resume the old simulation.

## Roblox APIs and storage

The API choice was checked against current official documentation on 2026-11-20:

- [TeleportOptions](https://create.roblox.com/docs/reference/engine/classes/TeleportOptions) and [reserved-server routing](https://create.roblox.com/docs/projects/teleport-private-servers): server-generated GUIDs in `ReservedServerId`, or `ServerInstanceId` for an ordinary public destination; `TeleportAsync` and `TeleportInitFailed` for travel/failure handling. Current docs recommend this over the legacy ReserveServer/access-code flow.
- [MemoryStoreHashMap](https://create.roblox.com/docs/reference/engine/classes/MemoryStoreHashMap): `UpdateAsync` atomically validates capacity, host settings, ticket admission and membership. Callbacks do not yield. Short TTL records refresh during live sessions.
- `MemoryStoreSortedMap`: directory of eligible public lobbies with count, place, job and freshness checks. Private routing records are never written to that directory.
- [Player online friends](https://create.roblox.com/docs/reference/engine/classes/Player): `GetFriendsOnlineAsync`, server `IsFriendsWithAsync`, and server `GetJoinData`.
- [Native invite prompts](https://create.roblox.com/docs/production/promotion/invite-prompts): `CanSendGameInviteAsync`, `PromptGameInvite` and `ExperienceInviteOptions.LaunchData`.

MemoryStore namespaces: `WC10SessionsV1`, `WC10CodesV1`, `WC10PublicV1`. Sessions/codes use 120-second refreshed TTLs, pending reservations 90 seconds, public listings 30-second freshness/40-second TTL, destination-instance leases 45 seconds, reconnect grace 60 seconds. The routing records are transient matchmaking state, not durable player progress. Restarted match servers fail closed instead of reconstructing a lost battle from metadata.

The same published place can act as menu, public lobby and match destination. No hard-coded place ID is required: routing stays in `game.PlaceId`. Configure the experience's human server limit to at least 20, use a current Roblox client/Studio supporting `ReservedServerId`, and publish all server/client modules together. Roblox browser placement alone is not the admission authority.

## Security and failure handling

Each joining account receives its own random ticket stored against its server-provided UserId. A ticket must match the session, user, destination place, reserved ID or public job, lease and expiry. A client-supplied match type or friend ID cannot bypass those checks. Host settings are validated atomically against current and pending membership. Difficulty is limited to Easy/Normal/Hard; bot count must be an integer and fit capacity.

Remote requests use monotonic sequence numbers, a 0.75-second per-player throttle and a per-player in-flight lock. Only one teleport may be pending for a player. Failed/timed-out teleports release the reserved slot and provide a retry message; stale failure callbacks cannot cancel a newer ticket. No automatic retry loop silently moves the player to a private destination. There is no resource charge for matchmaking.

MemoryStore failures reject new cloud admission/start requests. Existing admitted gameplay can continue while discovery expires. Error replies use an allowlist/generic fallback, not raw service exceptions or routing records. Gameplay traffic is filtered to admitted recipients even if nonmembers share the same ordinary server. Menu-only users cannot start the old automatic game simply by sending Sync.

Studio uses a clearly labelled **local-only in-memory lobby adapter** because teleports are not available there. It supports one active lobby per local server, real local host/guest controls and the gameplay handoff. It does not simulate success for cross-server matchmaking or native invitations. Live mode uses MemoryStore and TeleportService; it does not fall back silently to insecure local cloud admission when services fail.

## Settings and tutorial

Menu scale is 90/100/110%, with viewport reflow. This scales the menu, not map coordinates or the gameplay canvas. Map frame budget toggles the existing client paint budget between balanced (3 ms) and low CPU (1.5 ms), retaining full map resolution. Native Roblox graphics quality and device audio remain in Roblox's system settings. This build has no custom soundtrack, so it displays that limitation rather than adding a fake volume slider.

The tutorial explains spawn selection, expansion, allocation, combat, economy/buildings, naval actions and missiles/SAM/fallout. Next, Previous, Finish and Skip are functional local navigation. It does not create a third match mode or fabricate a tutorial battle.

## Automated tests and performance scope

Run `python scripts/check_stage10_all.py` for Stage 1–9 regressions plus lobby/store/runtime/GUI tests. `check_stage10.py` compiles all Luau and executes the production store, lobby state, LobbyServer and FoundationServer/Replica with service stubs. Tests include private/public separation, forged/expired/user-mismatched tickets, full capacity, host permissions/transfer, bot settings, friend joins, countdown, disconnect/reconnect, stale/failed teleports, results/menu return, fresh rounds, and an outside client receiving no game snapshots.

`check_stage10_ui.py` executes the actual menu callbacks with GUI/API stubs: all navigation, private codes, host settings, friend join/invite requests, tutorial progression/skip, settings, five viewport sizes and game/menu transitions. Countdown changes create no new GUI instances. These are not rendered layout or real social/privacy API tests.

No MemoryStore/teleport latency or real network-throughput benchmark is claimed. Lobby broadcasts are at 1 Hz; directory/lease refresh is every 10 seconds. Friend UI fetches at most 50 permitted online entries when opened/refreshed, not every frame. Lobby capacity bounds rosters to 20 participants; no per-cell GUI is introduced. Existing bot/land/naval/missile performance remains documented in Stage 9 and Stage 8 reports, including failures at larger stress loads. Timing assertions are sensitive to machine load; keep first-run failures and rerun evidence in the test logs rather than discarding them.

## Files and verification

New production modules: `src/server/LobbyStore.luau`, `LobbyState.luau`, `LobbyServer.luau`, and `src/client/MainMenu.luau`.

Modified production modules: `src/server/Main.server.luau`, `OpenFront/FoundationServer.luau`, `src/shared/Config.luau`, and client `Main.client.luau`, `StrategyUI.luau`, `MapView.luau`, `MatchHUD.luau`. Existing Foundation harness extraction scripts were updated for the optional session argument. New test/build scripts are `check_stage10*.py`, `lobby_*.luau`, `menu_ui_*.luau`, `package_stage10.py`; the shared GUI stub gained child enumeration/destruction. Reports, README and NOTICE record the integration. Existing game formulas, bot algorithms, terrain cache and map transforms are retained.

`python scripts/package_stage10.py` builds `build/WorldConquest-stage10.rbxlx` and checks every current embedded Luau source. Its hash manifest is `build/stage10-build-manifest.json`. The root place and older staged artifacts remain historical. See [Stage 10 acceptance checklist](STAGE10_ACCEPTANCE.md) before any publication claim.

AGPL copyright/additional terms and geographical-data provenance remain. No new third-party image, font, audio or model asset was imported. Public corresponding-source hosting and a configured visible offer (`Config.SourceURL`) remain required; this work does not publish the experience.
