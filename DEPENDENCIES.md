# Dependencies, attribution and source provenance

| Component | Version/source | Licence and use |
|---|---|---|
| WorldConquest adaptation and original code/art | This source distribution | AGPL-3.0, with upstream Section 7 terms retained in `LICENSE`; modification notices in `NOTICE` |
| OpenFrontIO algorithms/formulas | `openfrontio/OpenFrontIO`, commit `8f1a0addc4b3ca7863dd370ba06dcafa17ba1f94` | Upstream AGPL and notices in `third_party/OpenFrontIO`; source mappings in `docs/OPENFRONT_SOURCE_INDEX.md`, stage reports and `tests` hashes |
| Natural Earth II shaded relief / idealized land cover | 3.2.0, source 10800x5400 | Public domain; original archive in `data/NE2_50M_SR.zip`, hash/method in `data/geography-manifest.json` |
| Pillow | 13.0.0 | MIT-CMU / HPND; build-only geography generation, not Roblox runtime |
| Natural Earth land/lakes | 1:10m 5.1.2 | Public domain; original GeoJSON and hashes in `data`; historical 110m input is not active |
| NOAA NCEI ETOPO | 2022 v1, 60 arc-second surface, DOI 10.25921/fd45-gt74 | CC0-1.0; external unmodified TIFF URL/hash plus modified generated data/scripts supplied |
| GUI icons | Lucide revision `164efbaf879fb29f55d88047efd49fc7725f53ab` | ISC and Feather MIT; full `assets/lucide/LICENSE`, pinned SVG hashes, PNGs and atlases supplied |
| SVG rasteriser | resvg-py 0.5.0 / resvg | MIT/Apache-2.0; build-only Python dependency, not Roblox runtime |
| Flag cosmetics | Existing WorldConquest designs / national flag geometry | Generated SVG/PNG source in `assets/flags`; existing AGPL project terms |
| Roblox runtime and Studio | Platform supplied, not redistributed | Roblox engine/services: TextService, TextChatService, VoiceChatService/audio, DataStoreService, MemoryStoreService, TeleportService, MarketplaceService, BadgeService, SocialService and standard UI/input/rendering APIs |
| Rojo | 7.7.1, pinned in `aftman.toml` | MPL-2.0 upstream tool; build only, not vendored |
| Luau CLI | Official `luau-lang/luau`; local binary version unrecorded | MIT tool; optional offline tests, not vendored |
| Python | 3.11+ | PSF; generators/tests/build verification, not runtime |
| Elevation decoder packages | `scripts/requirements-elevation.txt` | NumPy BSD-3-Clause; tifffile/imagecodecs BSD-3-Clause; optional generation only, consult dependency distributions for bundled-code notices |
| TypeScript oracle tools | Pinned upstream checkout/lockfile | Development-only; use its package licences; not installed in Roblox |

Roblox thumbnails refer to actual human accounts or the two configured game passes.
AI profiles use a locally selected colour and a licensed profile symbol; they do not
resolve or impersonate Roblox accounts or friendships.
System fonts are provided by Roblox. No custom audio, font binaries, API keys,
reserved-server codes, player records or purchase receipt databases are included.

The supplied upstream licence collection includes historical asset terms for
reference; it does not grant permission to import proprietary upstream artwork.
Keep the visible “© OpenFront and Contributors” notice and unofficial adaptation
description. WorldConquest must not claim official OpenFront endorsement.
