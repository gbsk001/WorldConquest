# Stage 15 follow-up: configuration and evidence

This follows the initial Stage 15 candidate (`4fa9b126683486549c862c5971b7f07cefd30ff8`).
No desktop interaction, Studio launch, live purchase, heavy gameplay benchmark or Roblox
publication occurred. Build scripts do not start the simulation. Public settings remain
20 competitive participants and zero basic nations; this is the existing conservative
limit, not a new live performance certification.

## 1. Upload exactly four ready-made images

Prepared bundle: `build/WorldConquest-icon-atlases-upload.zip`.
Extracted folder: `build/Stage15-icon-upload`. It contains the four transparent PNGs,
checksums, licences and these instructions. Do not upload the ZIP as an asset.

| Position in AtlasAssetIDs | File / asset name | Pixel dimensions | Purpose |
|---|---|---|---|
| 1 | LucideAtlas1.png | 512 × 512 RGBA | Interface/building/unit icon cells |
| 2 | LucideAtlas2.png | 512 × 512 RGBA | Interface/building/unit icon cells |
| 3 | LucideAtlas3.png | 512 × 512 RGBA | Interface/building/unit icon cells |
| 4 | FlagAtlas.png | 512 × 256 RGBA | Existing original flag cosmetics |

The PNGs are finished assets already used by the embedded renderer. **The missing
items are Roblox uploads/IDs, not unfinished graphics.** Keep dimensions, transparency,
cell positions and filenames unchanged. No cropping, repacking or JPEG conversion.
Lucide ISC/Feather MIT notices and original project/flag attribution are included.

When you are ready to use Studio yourself:

1. Sign into the Roblox account that owns or can edit the **existing WorldConquest
   experience**. Open that experience; select its owning user/group inventory.
2. Open **Window → Asset Manager** (also available from Home). Click the asset import
   button and select the four PNGs above. Import as **Image** assets. Name each after
   its filename. Wait for moderation approval. Right-click each image → **Copy Asset ID**.
   Use the Image ID, not a game-pass ID, product ID or Decal wrapper ID. These controls
   are documented in Roblox's [Asset Manager guide](https://create.roblox.com/docs/projects/assets/manager).
3. If an image is restricted and the experience lacks access: Creator Dashboard →
   **Creations / Development Items → Images → that asset → Permissions → Experiences
   → Add experiences**. Enter the existing game's **universe ID**, click Add, then Done.
   Repeat for all four. User access alone is insufficient for a game to load restricted
   content. See [Roblox asset permissions](https://create.roblox.com/docs/projects/assets/privacy).
4. Enter the four copied IDs into `src/client/IconAssets.luau` in the exact order above:
   `AtlasAssetIDs={Atlas1ImageID, Atlas2ImageID, Atlas3ImageID, FlagImageID}`, replacing
   each identifier with its actual numeric ID. Current zeros intentionally remain
   unconfigured. Alternatively, from the project folder run these PowerShell commands
   **yourself later**:

   ```powershell
   $atlas1 = [long](Read-Host 'LucideAtlas1 Image asset ID')
   $atlas2 = [long](Read-Host 'LucideAtlas2 Image asset ID')
   $atlas3 = [long](Read-Host 'LucideAtlas3 Image asset ID')
   $flags = [long](Read-Host 'FlagAtlas Image asset ID')
   python scripts/configure_icon_atlases.py $atlas1 $atlas2 $atlas3 $flags
   python scripts/run_idle.py scripts/package_stage10.py
   python scripts/run_idle.py scripts/package_stage15_local.py
   ```

   This helper validates numeric IDs only; Roblox type, ownership, moderation and
   permissions must still be checked. It uploads/publishes nothing.
5. Later, inspect the menu, toolbar, building shop, ships/trains and flags in Studio.
   Check Output for moderation/permission failures. Configured images load through
   normal ImageLabels without EditableImage; `IconReady` now follows `IsLoaded`, rather
   than claiming readiness as soon as an ID is assigned. The embedded branch remains
   available for unconfigured pages, but cannot supply missing icons on an image-API-denied
   device. Test on the affected phone/tablet before declaring that fallback complete.
6. Update corresponding GitHub source after adding the IDs. Keep `Config.SourceURL`
   pointing at the existing public repository. Asset upload does **not** require creating
   a new experience or publishing this place update.

## 2. Exact gameplay/economic values

| Setting | Human | Competitive Normal AI | Basic grey nation |
|---|---:|---:|---:|
| Starting soldiers, before recruitment | 5,000 | 5,000 | Seeded integer 500–1,500 inclusive |
| Starting gold | 0 | 0 | 0 |
| Initial allocation | 20% | 20%; decisions can choose another legal allocation | 20% local neutral expansion |
| Base in-match gold | 100/tick = 1,000/second | Same | 0 |
| Recruitment adapter | 0.5 × upstream Human growth | Same, no difficulty resource boost | 0.2 × upstream Bot growth |
| Gold multiplier | 1 | 1 | No passive gold |

Simulation ticks are 0.1 seconds. For `land` owned cells and completed City levels:

`Human cap = 2 × (land^0.6 × 1000 + 50000) + 250000 × cityLevels`.

`G = (10 + reserve^0.73 / 4) × (1 - reserve / cap)`, subject to the source cap clamp.
Humans and competitive AI apply `0.5 × G`; basic nations use one-third capacity and
upstream Bot's `0.5 × G`, then the configured `0.2` adapter (effectively `0.1 × G`
with their own cap). Positive recruitment is floored per tick. Exact initial growth
therefore depends on current reserve and land, not a single advertised +N/second value.

Configuration: `src/shared/Config.luau` → `Balance`, `BasicNations`, `Economy`.
These recruitment/starting-balance values are proposed balance; long-match acceptance
is still outstanding. In-match gold and permanent Stars remain separate.

Economic costs remain upstream:

- Cities: 125,000 → 250,000 → 500,000 → 1,000,000 cap, using source owned/constructed
  counts and upgrade rules. Factory and Port share the same escalation pool. Thus
  building a Factory for 125,000 makes the next Factory/Port cost 250,000; City is separate.
- Defense Posts: 50,000 increments capped at 250,000. Silo: 1,000,000.
  SAM: 1,500,000 increments capped at 3,000,000. Warships: 250,000 increments capped at 1,000,000.
- Basic construction durations: City/Factory 20 ticks (2 seconds), Port/Defense 50
  (5 seconds), Silo 100 (10 seconds), SAM 300 (30 seconds), plus source execution scheduling.
- No price, premium purchase, ownership/combat or trade formula was rebalanced in this follow-up.

## 3. Actual income and conquest evidence

Small production-module fixtures passed; Roblox services/rendering are not involved:

| Check | Observed result |
|---|---|
| Factory + City, bounded rail path, moving train | Both purchases debit 125,000. First self delivery credits **10,000 gold**: 750,000 → 760,000, independently of passive income. |
| Destroyed rail destination | Functioning route count becomes zero; 300 further execution ticks grant no additional trade gold. |
| Maritime trade, two eligible foreign ports | **191 water steps**, **12,296 gold to each endpoint owner**. Actual balances and per-building ledger match, ship is removed. |
| Destroyed maritime source | Pending delivery is cancelled without another payout. |
| Normal AI vs grey defender | **5,000 vs 500 starting soldiers** in a 32×16 controlled fixture; grey eliminated at tick **82**, resumed neutral expansion by tick **158**, 128 → 229 cells, three orders. No free troops/gold were granted during the run. |

A Factory has no unconditional passive trade payout: it needs eligible connected
City/Port destinations and completed train deliveries. Ports need valid water routes
to eligible **other owners' ports**; self-port maritime trade is not supported by the
pinned upstream rule. Trains may trade with own or allowed foreign stations.

Rail payout is `floor(max(5000, base - max(0, stops - 9) × 5000) × multiplier)`,
with base 10,000 self / 35,000 allied / 25,000 other or team. Maritime payout is
`floor((75000/(1+exp(-0.03×(distance-300))) + 50×distance) × multiplier)`.
Trade dispatch is seeded and saturation-dependent, so these are delivery amounts,
not guaranteed per-second rates. The economy panel reports the last 30 seconds of
completed deliveries. Individual contributions are private authoritative data.

The combat fixture proves that the existing competitive AI can conquer a basic nation
and keep expanding. It does **not** prove eventual Earth-wide victory, good long-term
economy choices or reliable performance at hundreds of nations.

## 4. Separate 300-grey / 20-competitive local configuration

- Editable profile: `tests/stage15/local-profile.json`.
- Rebuild command: `python scripts/run_idle.py scripts/package_stage15_local.py`.
- Output: `build/WorldConquest-stage15-LOCAL-300-grey-20-competitive.rbxlx`.
- Generated Rojo project: `build/stage15-local.project.json`; Config overlay only.
- The overlay applies **only when RunService:IsStudio() is true**. Public source Config
  is untouched; a live server uses the original zero-grey/20-competitive settings.
- Normal Public lobby: humans take priority within 20 competitive slots; smart AI fill
  the remainder. With one human this means 19 smart AI + one human + 300 grey nations.
  Exactly 20 competitive participants total, not 20 humans plus 20 smart AI.
- Private matches retain their existing host-controlled bot count. Use Public Match
  for the fixed 20-total population test.
- Existing Studio lobby/profile adapters use local memory and block paid prompts.
  No new monetisation product IDs, storage names or public match settings are needed.

**The file was built, not played or benchmarked.** Opening it for edit does not start
300 nations. When ready to authorise that workload, use Studio Play / Start Server,
then Public Match; the normal lobby and spawn countdown create the roster. Do not
publish the LOCAL file. Leave the production SafeCount at zero until load acceptance.

## 5. Worldwide geographical coverage

The existing Earth atlas/land-area quotas and geographic spatial reservations are shared
by both controllers; combined population 320 yields a **450 km minimum centre spacing**.
Tests sampled complete spawn layouts without running 320 AI simulations or scanning the
whole ownership grid. Real valid-land footprints were checked for overlap.

| Seed | North America | South America | Europe | Africa | Asia | Oceania | Grey total |
|---|---:|---:|---:|---:|---:|---:|---:|
| 150027 | 50 | 39 | 20 | 70 | 102 | 19 | 300 |
| 150028 | 52 | 42 | 20 | 66 | 100 | 20 | 300 |
| 150029 | 53 | 40 | 21 | 70 | 97 | 19 | 300 |

There are also 20 competitive reservations in each layout. Combined regional quotas
matched exactly; all grey regions were represented, Antarctica excluded, disjoint valid
land footprints and identical-seed replay passed. More than 300 of 320 centres changed
between seeds 150027/150028. Playable islands are eligible according to land area; this
does not guarantee a nation on every small island. Human selection priority and live
reservation changes remain covered by the existing Stage 11 tests.

## 6. Manual configuration and remaining acceptance

Required for this follow-up:

1. Upload/approve the four images, grant existing experience access where necessary,
   and configure their four real Image IDs.
2. Rebuild both files after configuring IDs; update corresponding source before any
   later Roblox release.
3. Run the LOCAL population candidate only when you are ready for its load. Test
   full gameplay, spawn timing, zoom/pan, income, conquest, defeat/victory/restart,
   phone/tablet layouts, and physical mobile devices.
4. Authorise and complete the deferred CPU/memory/network and actual rendered load tests
   before increasing the public BasicNations.SafeCount or competitive capacity.
5. Keep general paid prompts disabled until controlled live receipt/rejoin testing passes.
   Existing chat/voice, native invitation/teleport and mobile permission checks remain in
   [controlled live testing](CONTROLLED_LIVE_TESTING.md) and
   [Stage 15 acceptance](STAGE15_ACCEPTANCE.md). This follow-up requires no new products.

Source remains AGPL-attributed and publicly hosted at
`https://github.com/gbsk001/WorldConquest`. No new experience was created and no game
update was automatically published. Rendering, sustained FPS, actual 320-participant
capacity, long-match balance and eventual worldwide AI conquest remain unverified.
