# Stage 13 implementation and acceptance — 24 November 2026

**Historical report, superseded by [Stage 12–13 acceptance](STAGE12_13_ACCEPTANCE.md).**
Statements below about missing nation names/communications, transient parties,
unrepairable rankings or a blank source URL describe the earlier candidate, not
the current implementation. Retained for the Stage 13 implementation history.

This is an implemented **acceptance candidate**, not a claim that the full Stage 13 brief or production acceptance is complete. The Rojo code contains the new systems described below. No experience was created or published, no product was created, no invitation was sent, and no purchase was made. All paid IDs remain zero. Native Studio access failed with `Computer Use native pipe is unavailable ... os error 2`, so there are no new rendered screenshots, device-emulator results, live purchase results or physical-device results.

## What was actually present

The inspected project contained Stage 1–11 simulation/matchmaking and the mobile startup/input/fallback patch. `Config.PortStage` remains **11**, preserving that simulation selection; `PremiumEnabled=true` enables the new menu. The public safe capacity remains **20**. The old root `WorldConquest.rbxlx` is not the release candidate.

No implemented Stage 12 custom nation-name service, moderated custom communication service, multilingual translation catalogue, persistent player profiles or permanent global leaderboard was found. Existing Roblox system communication was not replaced or bypassed. New Stage 13 profiles and global records were implemented here. Do not describe the absent Stage 12 features, voice eligibility, or mobile certification as completed.

## Implemented systems

| Area | Implemented behaviour |
|---|---|
| Main menu | Existing ScreenGui/navigation refactored to use a premium home: original colourful cached Earth backdrop, centred title, Party/Settings/Tutorial, Stars/profile/Arsenal/Shop, gold PLAY, Private Match, Global Rankings, desktop Daily/Starter shortcuts. Two cached backdrop images cross-fade only while the menu is enabled. |
| Navigation | Existing public/private lobby, invitations, host controls and gameplay HUD retained. New pages share the existing close control and safe-area composition; no second HUD. Phone layouts scroll when needed. |
| Party | Up to six humans, leader permissions, removal, leave/leadership transfer; supported Roblox friend invitations with expiring launch tokens, accept/decline, friendship checks, destination validation, and menu-server transfer. Group public reservations are atomic and precede bot fill. |
| Live lobby information | Current local public roster/capacity/deadline or actual public-directory human reservations. Directory unavailable/no advertised lobby states are explicit. No invented global online counts. Data refreshes every ten seconds. |
| Stars | Server-controlled permanent currency, separate from match gold, with atomic spending, ownership, daily rewards, eligible public completion/victory rewards and achievement rewards. |
| Arsenal and shop | Original graphical previews for missile, warship, transport, building, attack, explosion and victory cosmetics. Flags, territory colour/pattern/border/name-tag/crown styles and profile badges. Locked/owned/equipped states, Stars purchases and equip/unequip. |
| Match cosmetics | Server-projected equipment is frozen per match. Map/unit finishes, transparent flags/name tags, leaderboard/results flags, earned crown finishes, close-zoom weave/borders, attack pulses, confirmed-impact rings and local winner banner. All competitive formulas remain unchanged. |
| Inventory | Permanent ownership/equipment with server validation. Inventory/Flags/Arsenal/Territory categories; profile shows equipped previews. |
| Daily calendar | Seven fixed rewards, UTC midnight reset, missed-day reset, duplicate/cross-server protection, seven-day badge unlock. No paid random rewards. |
| Achievements | First Conquest, First Victory, Empire Builder, World Dominator, Veteran, Unstoppable and Naval Commander, evaluated from eligible authoritative match records. Optional Roblox badge IDs. |
| Starter Pack | Three permanent cosmetics: Gilded Vanguard missile, Golden Horizon flag, Pathfinder badge. One-time pass, optional, no automatic promotional interruptions, Not Now/Close. |
| General | Chosen implementation is a **permanent game pass**, not a subscription. Includes General badge and General's Standard flag. No competitive bonuses; no monthly/recurring billing represented. |
| Purchases | Product IDs disabled by default. Client-specific official product-price lookup, official prompts, server permanent-pass ownership verification, idempotent `ProcessReceipt` for optional Stars product. Failed persistence never acknowledges a receipt. |
| Records | OrderedDataStore top 25 for victories, eligible completed matches, territory record, human eliminations, best public win streak and highest reserve soldier count. Roblox usernames resolved from user IDs; no AI accounts. |
| Localisation | New text uses automatic localisation and a nonblocking cloud translator with bounded cache, English fallback and automatic text direction. Actual translated cloud content/RTL layouts still require configuration and review. |

The catalogue contains original fictional flags plus code-drawn Japanese and French national flags. There are no external image downloads, unmoderated flag uploads, emoji assets or extremist-symbol assets. There is no additional curated historical-flag collection. New artwork is authored in `CosmeticArt.luau`/`InterfaceArt.luau`, using the existing original graphical icon system. Existing notices/assets remain intact.

## Persistence, rewards and security

Production profiles use `DataStoreService:GetDataStore("WorldConquestProfilesV1")`, keys `u<UserId>`. Schema includes version, revision, Stars, owned/equipped items, achievements, UTC daily state, statistics, match receipts, purchase receipts and entitlement grant markers. Mutations operate on the latest value inside **UpdateAsync**; cached profiles are never blindly saved over another server's changes. Unknown schema versions and storage failures fail closed.

Studio deliberately uses an in-memory profile store, displays **temporary progression**, and disables paid offers/grants. Enabling Studio API access does not switch this code into production persistence.

Current configurable reward values in `ProgressionCatalog.luau`:

- Eligible public completion: **40 Stars**; victory adds **60**.
- Each first achievement unlock: **50 Stars**, plus an item where configured.
- Daily calendar: **25, 35, 50, 65, 80, 100, 150 Stars**. Day seven also unlocks Seven Horizons.
- Eligibility: public match, human account, still connected at finalisation, at least **180 simulation seconds**, **1,000 peak territory cells**, and meaningful actions in **six distinct 30-second windows**. Expansion/combat commands require authoritative tile-version progress; fresh nonzero-cost gameplay purchases and successful missile launches also qualify. Idle commands, invalid commands, spectators, private matches and bots do not qualify.
- Human eliminations are observed from actual conquest and missile-elimination callbacks, once per defeated human. Naval Commander uses server ship-construction counters. No client supplies records, timestamps, reward amounts or ownership.

This activity gate is an anti-idle heuristic, not a general anti-automation or collusion detector. Eligible records are sampled once per simulation second; brief sub-second peaks can be missed. Soldier record means the reserve count used by the HUD, not reserve plus every expedition/ship stack.

Match rewards deduplicate by server session ID and reject events older than one day. Old match IDs may be pruned only once they are outside the accepted event window. Receipt IDs are **not pruned**; at 8,000 receipts the store defers further receipts until a schema/ledger migration, rather than risk double grants. No receipt/history ledger is replicated to clients. Remote operations are bounded/type checked and rate limited. Equipment changes are allowed between matches.

Profiles are cached per connected player. Ordered rankings are cached for 60 seconds and updated after a successful eligible match commit; they are not authoritative for awards. Ordered-store update failures can leave rankings stale even when a profile saved correctly. Match saves retry four times; a prolonged outage/server crash can still lose an uncommitted match reward. No success is reported for a failed commit. This needs failure-injection/live recovery acceptance before enabling monetisation.

Party invitations use a 120-second MemoryStore token, current Roblox friendship checks, current leader/token validation and server routing checks. No custom friendship database or reserved access code is exposed. Actual platform invitation delivery and cross-server group teleports remain unverified. Parties are transient to their menu server, rather than a durable cross-server social service; recreate a party after a server transfer/round where membership was not retained. Full-party reservation/admission rollback and existing individual teleport-failure release are implemented; Roblox can still deliver group members at different times. A match cannot start while valid human reservations are outstanding.

## Automated evidence and performance

Run `python scripts/check_stage10_all.py` for the Stage 1–11 gate plus Stage 13, mobile fallback/input and geographic-spawn checks. `python scripts/check_stage13.py` runs the new focused suite. Logs: `build/stage13-full-regression.txt`, `build/stage13-results.txt`; packaging verifies each production source against the rebuilt XML.

New executable tests cover atomic profile retries, shared-store duplicate daily/receipt/match grants, insufficient funds, ownership/equip rejection, unknown schemas, private/AFK exclusion, verified public wins, trial exclusion and permanent-pass idempotency. GUI tests execute twelve premium pages at 390×844, 844×390, 768×1024, 1024×768 and 1920×1080, button callbacks, 44-pixel touch targets, scroll bounds, hidden-menu allocation, and the **actual MainMenu → PremiumMenu → Shop** route. Party tests exercise create/accept, friend and expiry validation, nonleader queue/kick rejection, leadership transfer, human group reservation capacity and private isolation.

All purchase/persistence/party service tests use **stubs**. They do not spend Robux, contact a real DataStore or deliver a Roblox invite. GUI object tests do not render pixels or measure device FPS.

The focused observer microbenchmark uses **one human plus simulated AI**, 1,000 samples, and measures only the new once-per-second progression observer—not complete gameplay. Representative local CPU averages were approximately **0.0004 / 0.0009 / 0.0020 / 0.0039 ms** at 20/100/250/500 participants. See the raw latest log for p95/worst and individual run values. The measured heap change of approximately 63–64 KiB includes harness allocations; it is not a production server/client memory estimate. Ten thousand fresh-profile/daily transformations took approximately 3.5–3.7 ms locally.

There is **no measured Roblox FPS, GPU time, new live network-bandwidth result, phone memory result or new higher-capacity qualification**. Public capacity stays 20. Existing large naval/missile simulation limits remain as documented in the scalability report.

Bounded work: no per-cell cosmetic objects, close-zoom pattern shading only during existing texture painting, at most 20 concurrent transient map effects, capped localisation cache, on-demand shop previews, paused hidden menu repainting, two 256×128 cached backdrop images (256 KiB raw RGBA combined when available). EditableImage failure still leaves navigation available and the existing gameplay compatibility renderer intact.

## Creator Dashboard configuration — do not activate before acceptance

Open **your existing WorldConquest experience** in Creator Dashboard. No new experience, external payment provider or custom card form is needed.

| Create/configure | Configuration field | Contents/terms |
|---|---|---|
| Monetization → Passes → Create pass: WorldConquest Starter Pack | `StarterPassID` | Gilded Vanguard, Golden Horizon, Pathfinder. One-time permanent cosmetics. Suggested initial price **49 Robux**, set in Dashboard; never hardcoded into UI. |
| A second pass: WorldConquest General | `GeneralPassID` | General badge + General's Standard. One-time permanent pass. Choose a price and explain the exact contents. No subscription is required. |
| Optional Monetization → Developer Products: 500 Stars | `StarsProductID`, `EnableStarsProduct=true` | Repeatable fixed **500 Stars**; adjust `StarsPerPurchase` and product description together before offering it. Leave disabled if unwanted. |
| Optional Roblox achievement badges | `BadgeIDs` entries | FirstConquest, FirstVictory, EmpireBuilder, WorldDominator, Veteran, Unstoppable, NavalCommander. Zero IDs skip platform badge awards but retain in-game achievements. |

All fields are in `src/server/CommerceConfig.luau`. Copy actual IDs from the existing experience's Dashboard; none have been invented. Do **not** enable pass free trials for this permanent-item configuration. The server checks the documented `GetPassOwnershipAsync(...).Owned`, not trial access. If that API is unavailable in the deployed engine, pass offers fail closed: verify support before making products purchasable. See Roblox's current [pass ownership and free-trial guidance](https://create.roblox.com/docs/production/monetization/passes).

Prices are queried on the client with `GetProductInfoAsync`, including player-specific pricing; the official purchase prompt remains the final price confirmation. `ProcessReceipt` controls developer-product grants, never the client prompt result. See [MarketplaceService](https://create.roblox.com/docs/reference/engine/classes/MarketplaceService) and [developer products](https://create.roblox.com/docs/production/monetization/developer-products). Keep offers off sale until successful, cancelled, deferred and repeated delivery flows have been tested in a controlled published session. No live purchase verification occurred here.

Configure the experience's supported languages and review cloud translations using [Roblox localisation](https://create.roblox.com/docs/production/localization). The code can consume the cloud translator, but no fully translated/reviewed language catalogue was supplied or created. English fallback is intentional; do not market full multilingual/RTL support before review. No new custom-text input or moderation bypass was introduced.

For device access, EditableImage permissions and existing-experience publishing, retain [MOBILE_ACCEPTANCE.md](MOBILE_ACCEPTANCE.md). Phone and Tablet access must remain enabled. Studio API access is not a mobile fix and should not be enabled against production data merely to try these menus.

## Manual acceptance checklist — all pending

1. Open `build/WorldConquest-stage10.rbxlx`, or sync `default.project.json`; confirm `PremiumEnabled=true` and the ten new modules exist in the runtime tree. Test the actual gold PLAY home, not the old root prototype or a preview fixture. Check Output and the loading/recovery screen.
2. Capture the home, Shop, Arsenal, Flag Shop, Daily, Party and Profile pages at desktop, small landscape phone, portrait phone, iPad and Android tablet presets. Verify safe areas, text wrapping, close buttons, visible prices/status, scroll reachability and no overlaid duplicate HUD.
3. Repeat with EditableImage creation denied/exhausted using the existing local fallback-test procedure. Menu navigation must work and gameplay must use the compatibility renderer. Inspect the colourful background when image support succeeds.
4. In Studio temporary mode, earn/claim/spend Stars, equip/unequip every category, test insufficient funds, repeat daily claim and confirm no Roblox purchase prompt. Stop/restart: the temporary store should reset. Do not interpret it as persistence testing.
5. In a controlled published session in the **existing experience**, verify rejoin/cross-server profile persistence, concurrent daily claim, product ownership and receipt redelivery after an injected store failure. Confirm pass trial status does not grant permanent items. Test cancellations and unrecognised product receipts. Record IDs/build hash and outcomes without publishing player payment details.
6. Use two actual Roblox friends: create party, invite, accept/decline, expire invite, remove member, leader disconnect, nonleader PLAY rejection, public queue together, nearly-full server, human slot reservations, admission rollback and individual/group teleport failures. Verify no private/public crossover. Re-form parties after transfers as necessary; test that limitation explicitly.
7. Complete eligible and ineligible public/private matches. Verify Stars, seven achievements, reserve/territory records, human conquest and missile elimination credit, victory, results, menu return and restart. Verify a spectator, an idle account and a bot receive no permanent progression. Check stale round rejection and paid cosmetics never change troops, cost, speed, damage or pathfinding.
8. Inspect flags on map/leaderboard/results, colour separation, close-zoom weave/ink borders, attack and impact pulses, crowns and victory banner. Pan/pinch while effects play; confirm exact map coordinates and no blocked input. Verify no effect for a missile that was intercepted rather than impacted.
9. Profile full gameplay with the shop closed, then with each menu visible. Record FPS/frame p95/worst, startup, map memory, UI instance count, network traffic and save/query throttling. No current synthetic number certifies this step.
10. Repeat complete public/private matches on physical iPhone, Android phone, iPad, Android tablet and PC together, including resume/network interruptions. Device emulation does not certify physical mobile compatibility.

## Files changed

New production modules: `shared/ProgressionCatalog.luau`; `server/ProgressionRules.luau`, `ProfileStore.luau`, `CommerceConfig.luau`, `ProgressionServer.luau`, `PartyState.luau`, `PartyServer.luau`; `client/PremiumMenu.luau`, `CosmeticArt.luau`, `Localisation.luau` (all under `src/`).

Integration changes: `src/shared/Config.luau`; `src/server/Main.server.luau`, `LobbyStore.luau`, `LobbyServer.luau`, `OpenFront/FoundationServer.luau`, `OpenFront/Simulation.luau`, `OpenFront/Missiles.luau`; `src/client/MainMenu.luau`, `InterfaceArt.luau`, `MapView.luau`, `OwnershipRaster.luau`, `MatchHUD.luau`.

Tests/build/report: `scripts/check_stage13.py`, `progression_checks.luau`, `premium_ui_checks.luau`, `progression_server_checks.luau`, `party_server_checks.luau`, `lobby_scenarios.luau`, `check_strategy_ui.py`, `check_stage10_all.py`, `package_stage10.py`; this report, README, rebuilt `build/WorldConquest-stage10.rbxlx` and its build manifest/logs.

## Remaining completion/publication blockers

- No rendered Studio acceptance, screenshots, real platform invitations/teleports, real persistence/paid transactions, or physical mobile validation.
- No completed Stage 12 nation-name/custom communication implementation or reviewed multilingual/RTL catalogue. Cloud localisation plumbing is not a translation-content certification.
- Party membership is transient; live group failure/recovery and post-transfer recreation need acceptance. Persistent global ranking updates can lag after storage failures. Prolonged outages can prevent match reward completion.
- Permanent pass APIs/IDs/prices must be configured and verified against the actual deployed Roblox engine. Subscription/monthly rewards are not part of the selected permanent-pass implementation.
- No exhaustive historic-flag collection; catalogue intentionally contains a small original/approved set.
- `Config.SourceURL` remains blank. Preserve LICENSE/NOTICE and provide the corresponding modified source, assets, build scripts and licence notices through an accessible source distribution before treating the public release's AGPL source-availability requirement as resolved. No source repository was published automatically.
- Full gameplay capacity/performance remains subject to prior reports; Stage 13 does not raise it.

Once those checks are accepted, rebuild after entering real configuration with `python scripts/package_stage10.py`. In Studio open the rebuilt file, choose **File → Publish to Roblox As…**, select the **existing WorldConquest experience and its existing start place**, and overwrite that place only. Verify the experience/place selection before confirming. Restart old servers at an appropriate time and rejoin the same public experience URL. **This implementation did not publish anything.**
