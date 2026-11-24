# Stage 12–13 completion work and acceptance candidate

24 November 2026. This report supersedes `STAGE13_ACCEPTANCE.md` for current status.
**Implemented code and automated tests are ready for manual acceptance. The update
is not fully accepted for publication.** Rendered Studio, live Roblox services,
translation review and physical-device verification remain outstanding. Nothing
was uploaded or published. No new development stage or experience was created.

## What changed

| Area | Current implementation | Verification boundary |
|---|---|---|
| Custom nations | Profile input accepts 2–32 Unicode code points, up to 128 UTF-8 bytes. Rejects malformed UTF-8, controls, directional overrides, markup, links and filtered hashes. Server `TextService:FilterStringAsync` + broadcast non-chat filtering; failures retain the previous accepted name. Saved names are filtered again before display on rejoin. Reset to account name; changes locked during a match. | Eight writing-system examples and production server-adapter failure/rate-limit tests passed with a mock filter. Actual Roblox filtering remains a live test. No claim that a local profanity list replaces Roblox. |
| Identity integration | Filtered nation name enters the authoritative participant `Username`, hence map/spawn labels, combat metadata, rankings and results. Lobby projects the accepted name. Account IDs, friendships, receipts and global permanent records still use real Roblox identities. AI identities remain server-generated. | Replication and existing gameplay regressions passed. Visual Unicode shaping/long names require Studio and physical devices. |
| Native chat | Default `TextChatService` channels, commands, chat window and input enabled in Rojo; native chat CoreGui retained. The custom communication panel shows account permission status. | Platform filtering, age/parental permissions and native mute/report tools remain Roblox-controlled. No custom unfiltered text transport. |
| Voice | Nonspatial native AudioDeviceInput → AudioFader → AudioDeviceOutput for the character-free map game. Microphones start muted. Server access lists permit compatible Roblox chat groups only within the same lobby/match/menu scope; revoke immediately on scope changes and permission failure. Refresh every 15 seconds. | Adapter tests cover scopes, revocation, outage, cleanup and initial mute. No actual audio/voice eligibility test. Required platform settings are below. |
| Mic/mute/report | Settings → Communication & microphone in menu/gameplay; local mic mute, local receive mute per real player, native block prompt, instructions for native Roblox Report menu. Live mic/status property changes update the panel. | The panel cannot override microphone consent, Roblox safety restrictions or eligibility. Participant controls enumerate current real accounts when opened; reopen to refresh the roster. Reporting intentionally uses the native system menu. |
| Localisation | Independent all-screen localisation controller, bounded translator cache, English source retention across language changes, automatic text direction, manual Auto/English/Spanish/French selection. **289 unique authored source strings** with ES/FR translations, numeric templates, all 24 cosmetic names/descriptions, seven tutorial steps, common gameplay/building/naval/missile/communication controls. `data/localisation.csv` is ready for review/import. | Translation rules and cosmetic coverage tested. Some composed notifications/dynamic summaries still rely on Roblox cloud translation/English fallback. Other languages and complete linguistic/RTL/layout review are **not finished**. |
| Persistent progression | Existing atomic UpdateAsync profiles retain Stars, inventory, equipment, achievements, daily calendar, receipts, permanent pass grants and match records. Writes after departure do not resurrect the active cache. Studio intentionally uses temporary storage. | Independent adapters sharing simulated storage verify concurrency/idempotency, failure handling and rejoin state. No real cross-server DataStore verification. |
| Global rankings | Six OrderedDataStore metrics. Saved match profiles carry a persisted dirty marker and stats revision; failed indexing retries every 60 seconds for connected players and on next load. Monotonic max writes prevent old servers lowering cumulative/record metrics; stale revision acknowledgements cannot clear newer work. | Indexing outage, rejoin repair and stale acknowledgements tested. Boards can lag; prolonged total storage failure or a crash before match commit can still lose an uncommitted reward. |
| Parties | Human group reservations precede AI fill. Server-verified user-bound admission records carry party ID/leader across transfer; destination restores reordered arrivals and the original leader. Requeue sends leader first. Existing expiry, friendship, permission, rollback and teleport-failure paths retained. | Actual PartyServer restoration/permission tests and matchmaking regressions pass with simulated services. Real invitation delivery, group splitting and teleport recovery still require published-session tests. |
| Cosmetics | Existing server-frozen equipment, unit/building finishes, flags, territory patterns/borders, names/crowns and attack/impact/victory effects retained. No paid competitive advantage or gameplay formula changes. | Ownership/equip routes and projections passed. Actual rendering of every cosmetic on each device is pending. |
| Source offer | `Config.SourceURL` is `https://github.com/gbsk001/WorldConquest`. Source & licences panel in both Settings locations; attribution retained. Complete local source packaging, dependency/build instructions, hashes and secret-pattern audit prepared. | Owner upload and signed-out public availability verification are still required. No GitHub upload occurred. |

The earlier description of missing Stage 12 adapters is now obsolete. The remaining
content and live acceptance gaps above are real; do not describe all Stage 12/13
requirements as fully completed merely because automated tests pass.

## Files changed in this completion pass

- New production modules: `src/server/NationNames.luau`, `IdentityServer.luau`,
  `CommunicationPolicy.luau`, `CommunicationServer.luau`, `LeaderboardStore.luau`;
  `src/client/CommunicationClient.luau`, `Localisation.client.luau`, `SourceOffer.luau`;
  `src/shared/LocaleStrings.luau`.
- Integration: `default.project.json`, `src/shared/Config.luau`;
  server `Main.server`, `LobbyServer`, `LobbyStore`, `LobbyState`, `PartyServer`,
  `ProfileStore`, `ProgressionRules`, `ProgressionServer`, `OpenFront/FoundationServer`;
  client `Main.client`, `MainMenu`, `PremiumMenu`, `Localisation`, `StrategyUI`,
  `MapView`, `MatchHUD` (all `.luau`).
- Tests/package: `scripts/check_stage12.py`, `stage12_checks.luau`,
  `stage12_services_checks.luau`, `check_stage13.py`, `party_server_checks.luau`,
  `check_stage10_all.py`, `package_stage10.py`, `package_source.py`,
  `export_localisation.py`, `data/localisation.csv`.
- Documentation/licensing: `README.md`, `NOTICE`, `.gitignore`, `BUILDING.md`,
  `DEPENDENCIES.md`, this report, historical report marker, `docs/SOURCE_RELEASE.md`.
- Rebuilt `build/WorldConquest-stage10.rbxlx`; integrity manifest compares all **93**
  production Luau files with the embedded XML. The SHA-256 is in
  `build/stage10-build-manifest.json` and the source manifest.

## Automated evidence

`python scripts/check_stage10_all.py` is the complete Stage 1–13 functional gate.
Latest full log: `build/stage12-13-full-regression.txt`. Focused logs:
`build/stage12-results.txt` and `build/stage13-results.txt`.

Coverage includes simulation formulas/parity, connectivity, rail/naval, missiles,
victory/restart/round validation, AI, spawn reservations/distribution/replay,
replication, private/public privacy, human priority, icon/name-label logic, mobile
gestures/EditableImage failure fallback, and the new rules/service tests above.
Premium GUI object tests exercise twelve pages at 390×844, 844×390, 768×1024,
1024×768 and 1920×1080, 44-pixel targets, scroll bounds, real MainMenu→Shop route,
party callbacks and disabled purchase offers. They do not render pixels.

The latest re-run also confirms existing performance limitations: the Stage 8
100-simulated-participant stress case recorded worst ticks around **121–141 ms**
on this machine. Functional pass does not mean the 100 ms performance gate passed.
Public safe capacity remains **20**, `PortStage=11`, `PremiumEnabled=true`.
No new higher-capacity qualification is claimed.

The isolated progression-observer microbenchmark remains approximately 0.0003–0.004
ms average at 20–500 simulated participants; it excludes simulation, graphics,
network, DataStore latency and real users. There is no new measured Roblox FPS,
mobile memory, bandwidth or live save-latency result in this completion pass.

## Creator Dashboard configuration — existing experience only

Keep all paid IDs **zero** and `EnableStarsProduct=false` until products are created
and live acceptance is authorized. They remain disabled in this candidate.

| Product to create | Dashboard area within existing experience | Suggested price | Exact `CommerceConfig.luau` field | Contents / qualification |
|---|---|---:|---|---|
| WorldConquest Starter Pack | Monetization → Passes | 49 Robux, one time | `StarterPassID` | Gilded Vanguard missile, Golden Horizon flag, Pathfinder profile badge |
| WorldConquest General | Monetization → Passes | 149 Robux, one time | `GeneralPassID` | General profile badge and General's Standard flag; **permanent pass, not subscription** |
| 500 Stars, optional | Monetization → Developer Products | 49 Robux per purchase | `StarsProductID`; `StarsPerPurchase=500`; enable flag only after tests | Fixed Stars amount; repeatable; no random contents |
| First Conquest badge, optional | Engagement → Badges | Free award | `BadgeIDs.FirstConquest` | 10,000 territory record in an eligible public match |
| First Victory badge, optional | Engagement → Badges | Free award | `BadgeIDs.FirstVictory` | One eligible public win |
| Empire Builder badge, optional | Engagement → Badges | Free award | `BadgeIDs.EmpireBuilder` | 100,000 territory record |
| World Dominator badge, optional | Engagement → Badges | Free award | `BadgeIDs.WorldDominator` | 1,000,000 territory record |
| Veteran badge, optional | Engagement → Badges | Free award | `BadgeIDs.Veteran` | 25 eligible public matches |
| Unstoppable badge, optional | Engagement → Badges | Free award | `BadgeIDs.Unstoppable` | Best eligible public win streak of three |
| Naval Commander badge, optional | Engagement → Badges | Free award | `BadgeIDs.NavalCommander` | One authoritative ship construction in an eligible public match |

Prices above are proposed configuration choices, not market research or hardcoded
display prices. Roblox may charge creators for badge creation beyond platform
allowances; “Free award” means no player purchase. No subscription, paid private
server product or extra product per cosmetic is needed. Other cosmetics use the
in-game Stars catalogue; Seven Horizons is an in-game daily-reward item, not a
separate configured Roblox badge. Use original supplied artwork for listings.

Official native prompts determine the actual price. The server checks permanent
pass ownership (`GetPassOwnershipAsync(...).Owned`), not trial entitlement; leave
free trials off. Developer products use idempotent `ProcessReceipt`; never grant
from a client purchase-complete message. See Roblox's [pass guidance](https://create.roblox.com/docs/production/monetization/passes)
and [developer products](https://create.roblox.com/docs/production/monetization/developer-products).

Additional required configuration:

1. **Communication:** In Studio Experience Settings → Communication, enable Voice
   Chat for the existing experience. Enable the **Chat & Voice Groups APIs** option
   and accept Roblox's required terms where offered. This implementation fails closed
   if group permissions cannot be obtained. `VoiceChatService.UseAudioApi=Enabled`
   and `EnableDefaultVoice=false` are already in Rojo because there are no characters.
   Eligible real accounts and microphone OS consent remain mandatory. Roblox voice
   experience player limits apply to real connected users, not simulated AI. Use
   Studio **Team Test** for the group API, then actual eligible accounts in a
   controlled published session. See [VoiceChatService](https://create.roblox.com/docs/reference/engine/classes/VoiceChatService)
   and [voice setup](https://create.roblox.com/docs/chat/voice-chat).
2. **Text:** Preserve the rebuilt TextChatService channels/configurations and native
   Chat CoreGui. Test actual parental/blocking restrictions; the game must not
   work around them. [Text filtering](https://create.roblox.com/docs/reference/engine/classes/TextService/FilterStringAsync)
   is called on the server for every submitted nation name; failures reject it.
3. **Localisation:** Creator Dashboard → experience → Localization: set source
   language English, add supported target languages, import/review
   `data/localisation.csv` and capture remaining runtime strings into the Roblox
   translation table. Review long text, interpolated summaries and any RTL locale
   before advertising it. Bundled ES/FR works without a cloud request; missing strings
   fall back safely. See [Roblox localisation](https://create.roblox.com/docs/production/localization).
4. **Devices/rendering:** Keep Computer, Phone and Tablet support enabled for the
   existing experience. Enable Mesh/Image APIs for the sharper renderer where
   eligible; compatibility rendering remains available. Follow
   `MOBILE_ACCEPTANCE.md`. Do not enable Studio production DataStore access as a
   workaround; this build deliberately uses temporary Studio profiles.
5. **Source:** Follow `SOURCE_RELEASE.md`. Upload corresponding source only after
   owner approval, and verify public access before the update is released.

## Manual acceptance checklist — not performed in this pass

Native Studio discovery was retried and failed with `Computer Use native pipe is
unavailable ... os error 2`. No rendered preview or device emulation was obtained.

- Open the rebuilt place or connect Rojo to this project. Confirm the 93-source
  manifest and the actual Premium menu, Profile nation input, Communication and
  Source panels. Check server and client Output for errors.
- Test desktop, iPhone, Android phone, iPad and Android tablet presets in portrait
  and landscape: safe areas, keyboard opening/closing, input focus, long names,
  scrolling, closing every modal and returning to unchanged map coordinates.
- Submit Unicode nation names in multiple scripts, filtered/offensive inputs,
  33-character input, links, rapid requests and filter failure. Verify rejected text
  never reaches other clients; accepted names agree on lobby, map, combat/results.
- Switch English/Spanish/French and cloud locales across every screen and after
  returning from matches. Check dynamic prices, daily countdown, results, leaderboard,
  tutorial, empty/error states and long descriptions. Confirm user identities are
  never translated. Record untranslated strings and complete the table before release.
- With two real eligible accounts, test text, voice on/off, native microphone consent,
  per-player receive mute, blocking and native reporting. Test unavailable voice,
  restricted text, disconnect/rejoin and transitions between lobby/game/menu. Verify
  no voice crossing a private/match scope. Basic Solo Play cannot certify this.
- With actual friends, test invite/decline/expiry, leader leave, group queue, full
  lobbies, reordered arrivals, one-member teleport failure, retry, results→menu and
  requeue. Verify human reservations continue displacing AI before start.
- In the existing published experience under controlled testing, verify real rejoin
  and cross-server Stars, inventory, equipment, daily UTC rollover, achievements and
  all six permanent record boards. Inject a failed index write, reconnect and verify
  repair. Never test live receipt grants against real players without approval.
- Inspect every cosmetic on real map/building/ship/missile/crown objects, including
  interception vs impact, attack pulses, victory, zoom, pan and fallback rendering.
  Confirm prices, costs, attack damage and timings remain unchanged.
- Repeat full public/private match flow on **physical** iPhone, Android, iPad,
  Android tablet and PC in the same matches. Test OS suspend/resume and network loss.
  Physical tests are separate from emulator/layout tests; none were done here.

## Publication blockers and next release

Still blocking a full completion claim: rendered Studio and physical-device tests;
real filtering/voice/invites/teleports/DataStore/receipt acceptance; remaining dynamic
translation coverage and language review; owner-approved source upload and public
availability verification. Prolonged storage outages can still leave an uncommitted
match reward unsaved. No new performance capacity claim is supported.

After acceptance and approved configuration changes, rebuild again. In Studio use
**File → Publish to Roblox As…**, choose the **existing WorldConquest experience
and its existing start place**, confirm that exact destination, and overwrite only
that place. Rejoin the same public experience URL and handle old servers at an
appropriate time. Do not create a separate mobile experience. **No automatic
publication, source push or account configuration was performed.**
