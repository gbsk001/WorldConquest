# Six-product monetisation integration — 24 November 2026

All six owner-supplied IDs are connected. **Public purchase prompts are disabled**.
Controlled-test update, 25 November 2026: `src/server/CommerceConfig.luau` retains
`EnablePaidPurchasePrompts=false` and now contains `PurchaseTestUserIDs={11327713454}`
for verified Owi00013 only. See [the current owner checklist](CONTROLLED_LIVE_TESTING.md).
This candidate has not been published to Roblox by the agent.

## Products and exact contents

| Product | Roblox ID | Intended/base price | Permanent grant |
|---|---:|---:|---|
| WorldConquest Starter Pack pass | 2098697285 | 49 Robux | **Gilded Vanguard** gold missile finish (`missile_founder`), **Golden Horizon** original navy/gold/ivory flag (`flag_founder`), **Pathfinder** profile badge (`badge_founder`) |
| WorldConquest General pass | 2099891345 | 399 Robux | **General's Standard** original flag (`flag_general`), **General** profile badge (`badge_general`) |
| 100 Stars developer product | 3735920468 | 19 Robux | Exactly 100 Stars |
| 500 Stars developer product | 3735920863 | 79 Robux | Exactly 500 Stars |
| 1,000 Stars developer product | 3735920948 | 149 Robux | Exactly 1,000 Stars |
| 5,000 Stars developer product | 3735921042 | 599 Robux | Exactly 5,000 Stars |

The passes contain **no Stars, soldiers, gold, damage, speed, capacity or other
competitive bonuses**. General is a one-time permanent pass, not a subscription.
Profile badges are in-game cosmetics, not separate platform achievement badges.
Players equip cosmetics through Inventory; a purchase does not replace their
currently equipped items. No additional developer products are required for the
existing cosmetic catalogue: those items are bought with earned/purchased Stars,
unlocked through achievements, or supplied by these two passes.

Read-only public Roblox metadata confirmed both pass names/IDs and `IsForSale=false`;
their public prices were null while off sale, so 49/399 are intended prices, not
verified player-specific sale prices. All four developer-product names, IDs and
base prices matched the table and returned `IsForSale=true`, belonging to universe
**10778763582**. This public metadata check made no purchases and did not verify
an account's Managed Pricing, ownership or DataStore state.

## Implemented behaviour

- A single server-owned `StarsProducts` table maps each developer-product ID to its
  exact quantity. Pass contents are shared in `ProgressionCatalog.PassItems` so
  reward grants and shop previews use the same list.
- The existing Featured Shop, Arsenal, Flags, Territory and Inventory pages include
  four 48-pixel Stars purchase controls when offers are enabled/available. Existing
  Starter and General pages open official pass prompts. No parallel HUD was added.
- The **client** calls `MarketplaceService:GetProductInfoAsync` with the appropriate
  `InfoType`. No intended/base Robux price is hardcoded into purchase display logic.
  Prices are fetched again immediately before prompting. If Roblox changed a price,
  the display updates and the player reviews/reselects it before the prompt opens.
  The official Roblox prompt remains the final price confirmation.
- Disabled/Studio offers do not open prompts. A disabled offer cannot be revived
  by a delayed price response or old button callback. Double taps do not open a
  second active prompt; cancellation/failure produces no rewards or success message.
- Passes are checked **on the server**, on join, explicit ownership refresh and a
  successful official pass-prompt event. The event itself is not proof of ownership.
  Permanent rewards require `GetPassOwnershipAsync(player, passID).Owned == true`.
  `Active=true` alone is rejected, including free trials. Unsupported, malformed or
  failed ownership responses never grant new items.
- A pass grant commits inventory and its entitlement marker together through
  `UpdateAsync`. Repeated verification cannot duplicate grants. Fresh server
  instances reload saved inventory/equipment; genuine existing buyers can restore
  benefits while new prompts are disabled.
- **Only `ProcessReceipt` grants purchased Stars.** The client cannot choose an
  amount or submit a reward/receipt endpoint. `CurrencySpent` does not determine
  quantity: Managed Pricing changes the Robux price, not the Stars pack.
- Receipt ID and Stars balance are written in the **same atomic profile update**.
  Repeated, interleaved and cross-server delivery are idempotent. A lost save response
  after a successful commit does not double-credit on retry.
- Storage/busy failures retry up to three times within the receipt callback. A
  failed/uncommitted grant returns `NotProcessedYet`, never `PurchaseGranted`.
  Unknown products, malformed receipts and absent players are deferred. Receipts
  already owed remain processable even when new purchase prompts are disabled.
- The UI shows a purchase confirmation only after a server-confirmed saved receipt
  or verified permanent pass ownership. A successful prompt-close event only shows
  that verification/save is pending. For deferred developer receipts, rejoin the
  same experience to trigger Roblox redelivery; do not buy again to fix a delay.

Roblox references: [pass ownership and free trials](https://create.roblox.com/docs/production/monetization/passes),
[MarketplaceService receipt contract](https://create.roblox.com/docs/reference/engine/classes/MarketplaceService#ProcessReceipt),
[developer products](https://create.roblox.com/docs/production/monetization/developer-products).
The current pass guide documents `GetPassOwnershipAsync`; its availability on the
deployed engine is still a live acceptance check. The implementation intentionally
does not fall back to a trial-inclusive ownership boolean for permanent grants.

## Tests and limits

The Stage 1–13 automated functional gate passed; log:
`build/monetisation-full-regression.txt`. Final focused purchase/rules/UI tests are
in `build/stage13-results.txt`; Stage 12 persistence and filtering checks also passed.
These use production modules with explicit service/GUI stubs, not real purchases.

Purchase tests cover all four real IDs/quantities, both exact pass contents,
wrong/cancelled/trial events, failed saves/retry, lost post-commit response,
interleaved/cross-server duplicates, rejoining, saved cosmetic spending/equipment,
disabled offers, individual tester permissions and unknown/malformed receipts.
Five shop pages and all four pack controls run at 390×844, 844×390, 768×1024,
1024×768 and 1920×1080, including touch targets, scroll reachability, non-base
Managed Prices, price changes, stale responses and confirmation ordering.

Native Studio inspection was attempted again but failed with
`Computer Use native pipe is unavailable ... os error 2`. **No rendered Studio,
device-emulator, physical-device, live DataStore or real paid-transaction tests
were completed. No Robux were spent.** The established gameplay capacity remains
20; this change does not certify increased simulation or rendering capacity.

Existing storage bounds remain explicit: receipts are never pruned, and an 8,000
receipt ledger requires migration before more purchases can commit. A purchase
that would exceed the one-billion Stars balance limit stays pending; it is never
acknowledged after silently dropping part of the paid quantity. Monitor/migrate
these limits before they become reachable. An outage can delay fulfilment until
receipt redelivery. Legacy already-published code must not receive newly enabled
sales before its receipt handler supports these IDs.

## Safe activation and live acceptance — owner action required

1. Confirm all six products belong to the **existing WorldConquest experience**.
   Confirm developer-product universe 10778763582 is that experience. Keep pass
   free trials disabled for this permanent-inventory model.
2. Leave both code switches at their delivered values: global prompts **false**,
   tester list **Owi00013 only**. Keep passes off sale and do not advertise/enable external
   Store-tab or native Shop purchases until the correct receipt-handler build is
   manually deployed. The four products currently report for sale in public metadata;
   an in-game prompt switch cannot change Roblox Dashboard/off-platform availability.
3. Open the rebuilt `build/WorldConquest-stage10.rbxlx` or sync this Rojo project.
   Check Output and the current modules. Verify disabled controls, Inventory, earned
   Stars spending and temporary progression on phone/tablet/desktop viewports.
   Studio uses temporary storage and cannot certify live fulfilment in this build.
4. Owi00013 is already configured as the only approved tester by numeric UserId.
   Leave `EnablePaidPurchasePrompts=false`. The owner must explicitly publish this candidate
   to the **existing experience/start place**, retaining a known rollback build.
   No new experience or automatic publication is part of this task.
5. Configure the intended base pass prices in Creator Dashboard → Monetization →
   Passes and the four product prices under Developer Products. Managed Pricing
   remains authoritative. Make the required test offers available deliberately;
   external-sale controls are separate from the in-game tester allowlist. Use an
   approved account/session; these are genuine chargeable purchases, not free tests.
6. Test all six official prompts, cancellation, actual account-specific price,
   one receipt/grant per purchase, rejoin into a second server, equip each pass
   cosmetic, spend Stars, and confirm saved balances/ownership. Verify an unlisted
   player receives no in-game offers. Check unknown/deferred receipts and storage
   recovery in controlled test conditions without corrupting production records.
7. On PC, iPhone, Android phone, iPad and Android tablet, check keyboard/safe areas,
   scroll and tap targets, native prompt dismissal, background/resume and network
   interruption. Confirm no success before saved verification. Record results.
8. Only after accepting those results should the owner change
   `EnablePaidPurchasePrompts=true`, clear the tester list, rebuild/update source
   and manually publish to the same place. To stop new in-game sales, set it false
   and clear testers; keep receipt fulfilment enabled for outstanding purchases.

## Changed files

Production: `src/server/CommerceConfig.luau`, `ProgressionServer.luau`,
`ProgressionRules.luau`; `src/shared/ProgressionCatalog.luau`, `LocaleStrings.luau`;
`src/client/PremiumMenu.luau`.
Tests: `scripts/check_stage13.py`, `progression_checks.luau`,
`progression_server_checks.luau`, `premium_ui_checks.luau`.
Also updated `data/localisation.csv`, README/build/acceptance documentation, the
Rojo artifact, source archive/manifests and public corresponding source.

No additional products, passes or subscriptions are needed for the implemented
features. No gameplay costs, combat formulas, troops, map resolution or AI behaviour
were changed. Remaining release blockers are live paid-service acceptance and
rendered/physical-device validation, plus the previously documented broader
translation/game acceptance work. **Public purchase prompts remain disabled; Owi00013 alone is allowlisted.**
