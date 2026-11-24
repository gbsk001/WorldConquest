# Stage 8 manual Studio acceptance — not yet performed

Record Studio/client versions, OS/device, server/client counts, test settings,
territory/unit counts, server tick and client frame timings, network/heap peaks,
Output errors and pass/fail evidence. Automated service stubs are not these tests.

1. **Load the candidate.** Stop Play. Sync `default.project.json` through Rojo,
   or open `build/WorldConquest-stage8.rbxlx`. The root `WorldConquest.rbxlx` is
   older. Confirm `Shared.Config.PortStage=8`. Enable Mesh/Image APIs where
   required and verify the map finishes painting before the countdown starts.
   Preserve the copyright/unofficial-adaptation label.
2. **Two-client full round.** Use Server & Clients with two real clients. Choose
   nearby land spawns during the 20-second countdown; move one spawn and leave
   the other to auto-select in a repeat run. Verify both start together, five-second
   spawn immunity, allocation, soldiers, income, neutral expansion, enemy combat,
   retreat, buildings and matching ownership. Check the existing naval/rail cases
   from the Stage 5/6 checklists. Inspect both client and server Output.
3. **Test-only money.** In a local unpublished test copy, temporarily set
   `Economy.StartingGold="200000000"` to avoid waiting for income. Keep
   `Buildings.InstantBuild=false` for construction checks. Restore all test
   overrides before creating a release build; they are not production defaults.
4. **Structures/inventory.** Buy a silo on owned land. Verify $1M debit, construction
   near ten seconds plus execution boundaries, no launch before completion and
   one ready slot. Build a SAM: first $1.5M, subsequent price capped at $3M,
   construction near 30 seconds. Upgrade each; check slot reload, 90-tick cooldown,
   and gradual SAM range growth over 45 ticks. Try water, enemy land, insufficient
   gold, invalid placement, rapid duplicate clicks and demolition/capture.
5. **Atomic/hydrogen.** With no defending SAM, launch atomic ($750K), then hydrogen
   ($5M) at an enemy territory containing a city, construction site and ships.
   Verify one charge/one launch, source silo selection, visible travel, impact,
   lost land/troops/buildings/ships, no negative armies and fallout shading.
   Terrain must remain land in this default mode. Reclaim fallout: verify slower/
   costlier expansion and that reclaimed cells lose fallout shading.
6. **Defence.** Place SAMs near the destination and repeat both launches. Observe
   interceptors and interception notification; intercepted bombs must not apply
   blast damage. Test upgraded SAMs, simultaneous competing targets, queues,
   destruction/capture of the launcher, and targets outside SAM coverage.
   Check both clients see the same surviving projectiles and structures.
7. **MIRV.** Launch at substantial enemy territory. Verify $25M for the first
   global MIRV and $40M for the next, even when another player launches it.
   Observe carrier/separation, distinct child destinations and staggered impacts;
   SAMs may intercept warheads but not the carrier. Change target ownership
   during flight. Disconnect the launcher while children are queued/in flight;
   check cleanup and absence of ghost projectiles or further charges.
8. **Camera/UI.** Follow missiles while panning, zooming, fitting and resizing.
   Icons must stay on the map, interpolate without jumping between pooled labels,
   and disappear on removal. Building/Navy/Missile menus must not overlap when
   switching; Escape cancels selection. A map pan must not accidentally purchase
   or fire. Inspect soldier/gold labels, notifications, leaderboard and all controls
   on a narrow window and a physical mobile device. Check touch and wheel blocking
   over menus. No per-cell GUI objects should appear in Explorer.
9. **Victory/elimination.** In one normal round, exceed 80% of non-fallout land.
   Exactly 80% must not win. Check the leader, ordered ranks, eliminated/spectating
   state and matching results on both clients. In a separate local test set a
   short `Match.MaxTimerMinutes` to exercise timer victory without a long match.
   For teams, set `Match.Mode="Team"` and server `Match.Teams[userId]` entries;
   verify combined land wins for the team and friendly targeting rejects.
   Restore normal FFA/no timer after the local tests.
10. **Results/restart.** Gameplay must freeze at victory. Results appear after
    three seconds and a new round begins 18 seconds after victory. Confirm fresh
    gold, armies, ownership, fallout, IDs, inventories, buildings, ships, MIRV price,
    selection countdown and cleared placement modes. Repeat at least three rounds.
    Confirm no previous-round intent can charge, fire or change the new round.
11. **Late joins/recovery.** Join while projectiles move and while results show.
    The player must spectate the current round and participate in the next.
    Disconnect/rejoin an active player, then disconnect everyone and rejoin.
    Check snapshot catch-up, no duplicates, no old-round results/tiles and bounded
    transfer queues. Exercise Sync during change bursts using local test tooling.
12. **Performance.** Inspect `WorldConquestEvent` attributes: rolling average/p95,
    lifetime worst tick, backlog, missile/building/naval/connectivity/rail times,
    grid bytes, Lua heap, unit/ownership delta bytes, fragments and active snapshots.
    Compare `UnitAndOwnershipDeltaBytes` (raw) with `EncodedDeltaBytes` (encoded
    buffer bytes); neither measures transport bandwidth. Sync both server and
    client sources while Play is stopped so all clients understand uniform fragments.
    Use MicroProfiler and Developer Console to measure actual server CPU and
    transport, not only buffer lengths. On the Earth canvas inspect paint/upload,
    visible/pooled icon counts and frame times. Capture simultaneous atom/hydrogen
    impacts and several MIRVs during active land and naval combat.
13. **Scale gradually.** Start with 2 clients, then 10 and 20. Only attempt 50/100
    real clients where supported by tooling and lower counts pass. Require average
    tick <20 ms, p95 <50 ms, worst <100 ms without sustained backlog; separately
    record desktop/mobile frame, input-latency, bandwidth and memory requirements.
    The simulated 100-player gate currently fails worst tick and does not certify
    a live player limit. Run a long soak to assess memory recovery across restarts.

Release requires recorded acceptance evidence, fixes for outstanding performance/
network issues, restored production settings and a working corresponding-source
offer. This checklist is preparation, not a test completion record.
