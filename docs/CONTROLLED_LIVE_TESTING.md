# Controlled live purchase acceptance — 25 November 2026

The delivered candidate allows **Owi00013, Roblox UserId 11327713454**, to use
the six existing purchase offers in a published live server. Everyone else's
in-game paid prompts remain disabled. No Roblox publication or real purchase was
performed by the agent. This is preparation for acceptance, not live certification.

## Verified identity and code configuration

An anonymous POST to `https://users.roblox.com/v1/usernames/users` resolved
`Owi00013`; an independent GET to `https://users.roblox.com/v1/users/11327713454`
confirmed the same ID/name and `isBanned=false`. No credentials were used.
The local verification record is `build/controlled-test-account-verification.json`.
Authorization uses the numeric ID, never a display name or client-provided name.

`ServerScriptService.Server.CommerceConfig` in the rebuilt place contains:

```luau
EnablePaidPurchasePrompts=false,
PurchaseTestUserIDs={11327713454},
```

Studio always disables paid prompts and uses temporary progression storage,
including for this tester. In live servers, only the approved account receives
offers. Availability still requires Roblox to report that the item is on sale.
Already-owned passes show ownership rather than allowing repeat purchases.
The receipt handler continues to fulfil legitimate outstanding purchases for
everyone, irrespective of the prompt switch. Disabling prompts must not discard
money already paid. The allowlist is an in-game UI gate, not a Roblox-wide ban on
external purchases.

## Products and expected rewards

| Product | ID | Default price to configure | Verified grant expected |
|---|---:|---:|---|
| Starter Pack pass | 2098697285 | 49 Robux | Gilded Vanguard missile finish, Golden Horizon flag, Pathfinder profile badge |
| General pass | 2099891345 | 399 Robux | General's Standard flag, General profile badge |
| 100 Stars | 3735920468 | 19 Robux | Exactly +100 Stars |
| 500 Stars | 3735920863 | 79 Robux | Exactly +500 Stars |
| 1,000 Stars | 3735920948 | 149 Robux | Exactly +1,000 Stars |
| 5,000 Stars | 3735921042 | 599 Robux | Exactly +5,000 Stars |

Managed Pricing stays enabled: actual displayed prices come from Roblox on the
client, including a recheck immediately before a prompt. The official prompt is
the final price confirmation. Passes grant permanent cosmetics, no Stars or
combat advantage. General is not a subscription. Equip rewards in Inventory.

## Publish this candidate to the EXISTING place — owner only

1. Save a backup of the current published start place and note its version.
2. Open `build/WorldConquest-stage10.rbxlx` in Studio. Inspect CommerceConfig above
   and `ReplicatedStorage.Shared.Config.SourceURL`, which must be
   `https://github.com/gbsk001/WorldConquest`. Do not change the DataStore name
   `WorldConquestProfilesV1`; changing it would hide existing records.
3. Run Studio Play/device emulation and inspect Output for initialization errors.
   Verify menu, shop, Inventory, navigation and touch controls. Disabled paid
   buttons in Studio are intentional, not a reason to turn on the global switch.
4. When ready, choose **File → Publish As** (some versions label this **Publish
   to Roblox As**), select your existing **WorldConquest** experience, select its
   current **start place**, and confirm **Overwrite**. Do not choose Create New
   or Add as a new place. The four developer products report universe
   **10778763582**; verify that this is the selected experience in Dashboard.
5. Confirm the uploaded version in Dashboard. Join a fresh server running this
   version; existing servers retain old code. If needed, use the experience's
   server restart controls deliberately, accounting for active players.

This is the manual overwrite workflow from [Roblox publishing documentation](https://create.roblox.com/docs/production/publishing/publish-games-and-places).
Do not enable sales against an older version without this receipt handler.

## Enable the two passes for sale — Creator Dashboard

1. Go to **Creator Dashboard → Creations → WorldConquest → Monetization → Passes**.
2. Open **Starter Pack**, check asset/pass ID **2098697285**, then open **Sales**.
   Enable **Item for Sale**, set the default price to **49**, and save changes.
3. Open **General**, check pass ID **2099891345**, then **Sales**. Enable **Item
   for Sale**, set default price **399**, and save changes.
4. Retain **Managed Pricing**. Keep pass free trials disabled: these rewards are
   permanent saved inventory. Do not mark test offers **Listed** in
   **Monetization → Shop** or advertise external sales during controlled testing.
5. Check the four existing products under **Monetization → Developer Products**;
   use the IDs and default prices above. Do not create replacements. They already
   reported on sale in the previous public metadata check. Review Shop/external
   availability separately; the allowlist cannot prevent an external transaction.
6. Start a fresh test session after changing sale status. Offer availability is
   loaded at server startup; a running server may retain its earlier off-sale list.

The private Dashboard has not been inspected in this task; labels can differ
between Dashboard versions. See [passes](https://create.roblox.com/docs/production/monetization/passes)
and [Managed Pricing/Sales settings](https://create.roblox.com/docs/production/monetization/regional-pricing).
Making a pass on sale is not an account-specific Roblox sale restriction. Keep
external listings off and public in-game prompts disabled throughout acceptance.

## Enable native text and voice communication

1. In Studio Explorer, select **TextChatService**. The candidate already sets
   **CreateDefaultTextChannels=true** and **CreateDefaultCommands=true**. Its
   **ChatWindowConfiguration.Enabled** and **ChatInputBarConfiguration.Enabled**
   are true. If your Studio exposes a ChatVersion selector, use TextChatService,
   not LegacyChatService. Do not add a second chat script or disable Chat CoreGui.
2. Open **File → Experience Settings → Communication**. Enable **Voice Chat**.
   Enable **Chat & Voice Groups APIs**, review and accept Roblox's required terms.
   This game's server requires the groups API to route permitted voice safely.
3. In Explorer select **VoiceChatService** (Show Services if necessary). Keep
   **UseAudioApi=Enabled**, **EnableDefaultVoice=false** as delivered. The map
   game creates its own audio inputs/routes without 3D character proximity.
   Do not enable a second default voice route over this implementation.
4. In Dashboard **Configurations → Places → [current place] → Access**, retain
   the current tested capacity and ensure **Maximum Visitor Count ≤100** for
   voice support. Do not raise gameplay capacity as part of this task.
5. Save settings and manually publish to the same place. Use two eligible accounts
   in the same lobby/match. Each must enable Roblox communication/voice in their
   own account settings and permit microphone access in their OS. Account age
   checks, region, parental controls and communication compatibility still apply.
6. In the game's **Settings → Communication**, test microphone toggle, receiving
   mute and blocking. Inputs begin muted. Use Roblox's native microphone controls
   if required; the custom button cannot override denied platform permission.
   Test native chat using its top-bar control on touch devices. Reporting remains
   in the Roblox system menu's Report flow.
7. Check mute and communication isolation when leaving/changing lobbies. The groups
   API can be tested in **Studio Team Test**, not ordinary Solo Play; final voice
   and native chat acceptance must occur with real eligible accounts.

References: [native text chat](https://create.roblox.com/docs/chat/in-experience-text-chat),
[voice setup](https://create.roblox.com/docs/chat/voice-chat),
[group API prerequisites](https://create.roblox.com/docs/reference/engine/classes/VoiceChatService#GetChatGroupsAsync).

## Live purchase and persistence checklist — NOT YET EXECUTED

Use Roblox Player signed in as Owi00013, not Studio. These are real transactions.
Do not reset production profiles or inject synthetic receipts into live storage.

1. Record the opening Stars balance and equipped/owned cosmetics. Open all six
   offers and compare the client price with the native prompt. Cancel one Stars
   prompt: no reward, charge or success confirmation should follow cancellation.
2. Buy each Stars pack once. Wait for **Purchase verified** before the next one.
   With no spending/rewards in between, the balance must increase by **6,600**.
   Closing a successful prompt alone must not show a saved-purchase confirmation.
3. Verify each pass and its exact reward set above. If already owned, use
   **Refresh verified ownership** and confirm restoration. You cannot repurchase
   an owned pass; a fresh-purchase test would require a separately approved,
   non-owner account added by numeric ID. No additional tester is authorized here.
4. Leave and rejoin a different fresh server. Confirm the same Stars balance,
   both entitlements and all five cosmetics. Equip a pass flag/badge/missile finish,
   enter gameplay and inspect it. Return to menu, buy an existing Stars cosmetic,
   record its cost and equip it. Rejoin again: ownership/equipment persist and
   Stars equal the recorded previous balance minus the actual cost.
5. Join with an account not on the list: no paid in-game offers/prompts. Existing
   genuine ownership and any previously owed receipt must still restore normally.
6. If saving/verification is pending, record the error and rejoin; do not purchase
   again to repair it. Real DataStore outages and receipt redelivery remain live
   acceptance cases. Automated tests already simulate failed saves, retry and
   lost responses without double credits. Do not deliberately disrupt production.
7. Record date, place version, device/OS, actual prices, before/after balances,
   cosmetic results and rejoin outcome privately. Do not upload purchase receipts,
   private player profiles or account credentials to the public source repository.

## Mobile/tablet coverage and release boundaries

The candidate retains the existing independent bootstrap/loading/recovery screen,
menu-before-map initialization, lower touch image budget, pooled image-free
fallback, touch tap/drag/pinch suppression, army slider, safe-area layouts and
scrollable shop panels. No mobile fixes or gameplay systems were removed.
See [mobile acceptance](MOBILE_ACCEPTANCE.md) for detailed full-match checks.

In Dashboard enable **Computer, Phone and Tablet** under **Audience → Access
Settings → Devices**. Enable **Allow Mesh / Image APIs** under Studio Experience
Settings → Security when eligible, for the detailed renderer. The fallback remains
available if image allocation/permission fails. Studio API access is not required
to make live DataStores or the renderer work; this project's Studio progression
intentionally remains temporary.

Run desktop, iPhone, Android phone, iPad and Android tablet emulation, then the same
purchase/rejoin/full-match checks on physical devices. Check notches, shop scrolling,
native prompt dismissal, rotation, microphone permission, background/resume,
connection interruption and drag/pinch without accidental map actions.
No rendered Studio, emulator, physical-device, real-purchase or live DataStore
results are claimed here. Native UI automation was unavailable in this session.

Automated coverage includes the production allowlist with the actual verified ID,
all six offers, same-name/different-ID denial, exact grants, duplicate receipts,
fresh service instances, Studio denial, five shop viewports and mobile gestures/
fallback. Results are in `build/controlled-purchase-tests.txt` and the complete
Stage 1–13 gate in `build/controlled-full-regression.txt`.

Keep public prompts false during acceptance. To suspend new tester prompts too,
clear `PurchaseTestUserIDs`, rebuild/update matching source and manually deploy.
Keep receipt fulfilment intact. Public activation is a later deliberate decision
after live acceptance; this task does not authorize automatic Roblox publication.
