# Stage 10 Studio and live acceptance — pending

No item here is a completed live test. Record server/client versions, account/device permissions, place/universe IDs, test settings, screenshots, Output/MicroProfiler evidence and pass/fail results. Use a staging experience; do not enable Studio API access against production matchmaking state for these tests.

## Local Studio

1. Stop Play, sync Rojo or open `build/WorldConquest-stage10.rbxlx`. Confirm PortStage=10. Start Server & Clients with two or three clients. The menu must explicitly say local lobby test.
2. Verify exactly two match choices: Public and Private. Friends must be prominent. Test menu scrolling, 90/100/110% menu scale and tutorial Next/Previous/Finish/Skip at 320×568, 390×844, 844×390, 1366×768 and 1920×1080, including safe-area emulation.
3. Public: join both clients, see both names and five Normal bots, observe the 15-second lobby countdown and then the normal map-ready/spawn countdown. No private host controls should appear.
4. Private: after leaving/ending the first lobby, host another. Copy the join code to the second client. Check correct/incorrect codes, guest denial of host settings/Start, bot count limits, all three difficulties, player/bot list, host Start and Leave. Host departure must transfer control; last departure closes it.
5. Verify menu-only clients do not receive private FoundationBegin/Chunk/Delta data. Attempt malformed/replayed/rapid requests in a local test harness. Only admitted players should create simulation players or issue game orders.
6. Run gameplay with the existing HUD; wheel over menu panels must not zoom the hidden map. Test army/building/naval/missile controls, results, return to menu and a different second match. Check fresh inventories, bots, ownership, round IDs and no old membership.
7. Confirm audio/graphics limitations are honestly labelled; map frame budget must affect painting budget without changing resolution. Check a low-end device and rendering memory separately.

## Published staging experience — required for service acceptance

1. Publish the exact candidate to a staging universe, with at least 20 human server slots. Use a current runtime supporting ReservedServerId. Native teleports cannot be accepted based on Studio results.
2. Open several distinct ordinary servers/accounts. Public matchmaking should join a listed eligible lobby, prefer a visible friend's lobby when possible, and create another destination when existing ones are full/playing. Verify no private lobby is returned by discovery.
3. Create a private lobby from an ordinary and from a reserved/VIP context. Confirm the reserved destination matches the server-held record. Join through a code from another server; inspect client-visible state and TeleportData for absence of reserved routing identifiers/access codes. Only user-bound tickets may be admitted.
4. Test native invitations on allowed and restricted accounts/devices. Accept a private invite and a public invite; reject/expire them too. Verify hidden/private friend presence yields unavailable feedback rather than a privacy workaround. No custom friendship records should exist.
5. Race enough joins to fill a lobby, including pending teleports. Verify no oversubscription, cross-type entry, duplicate membership or stale directory acceptance. Race host bot-setting changes with guest joins; capacity must stay valid.
6. Exercise TeleportInitFailed and synchronous teleport rejection in a staging fault-injection adapter, not by weakening production validation. Verify reservation release, useful retry feedback, ignored stale callbacks and no duplicate teleport. Test the 45-second timeout.
7. Disconnect/reconnect while another player keeps the match alive. Verify grace admission and the documented spectator behaviour after gameplay starts. Close the last member's client; the room should close. Restart/terminate a match server: old battles must not silently restart or admit against stale leases.
8. Make MemoryStore temporarily unavailable using staging-only injected failures. New joins/starts should fail closed. Existing battles may continue, stale directory entries must expire, and access/routing secrets must never be printed to clients.
9. Complete three Public/Private match cycles through results and menu, using all Stage 1–9 mechanics. Test invitation arrivals during spawn and after start, and native cross-play settings that may split reserved instances. The lease policy must reject inconsistent duplicate instances with feedback.
10. Measure actual server tick/backlog, MemoryStore request/error rates, teleport success/latency, lobby bytes, snapshots, GUI frame time and long-session memory. Start at 2–5 participants; only increase after lower-count acceptance. Include rich naval/missile combat, not only early bot expansion.

## Publication blockers

- Live TeleportService, MemoryStore, friendship/privacy and invitation behaviour has not been verified.
- Rendered desktop/mobile, safe-area, touch and full-match acceptance is pending.
- No atomic multi-server party queue or seamless army restoration after disconnect/server loss; current joining is best effort and documented.
- Existing large-player bot, naval-search, simultaneous-impact, broadcast and memory risks remain. A 20-participant lobby limit is not a certified live capacity.
- Configure public corresponding-source hosting and the visible AGPL offer, preserve all notices/additional terms and verify the deployed artifact's source manifest.
- Restore all temporary test economy/timer/API overrides and deploy matching client/server versions together. Do not treat passing service stubs as a publication approval.
