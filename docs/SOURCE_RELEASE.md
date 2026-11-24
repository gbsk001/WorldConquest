# Corresponding-source release procedure

The owner authorized the upload to `gbsk001/WorldConquest`; initial source upload
and unauthenticated full-download verification succeeded on 24 November 2026.
See [publication evidence](SOURCE_PUBLICATION.md). The procedure below remains
applicable to future source updates; no Roblox game publication was performed.

Configured source offer: **https://github.com/gbsk001/WorldConquest**.
The main menu shows attribution and the address; both menu and gameplay Settings
have a **Source & licences** panel with a selectable address and licence notice.
The repository and uploaded candidate contents were verified publicly accessible
without signing in. Preparation of future archives alone does not make them public.

## Prepared distribution

Run `python scripts/package_stage10.py`, then `python scripts/package_source.py`.
`build/source-package.json` identifies the versioned ZIP, its SHA-256 and matching
place hash. The ZIP contains all server/client/shared Luau, generated runtime data,
original graphical sources, available original geography inputs, generators,
test fixtures, build configuration/instructions, licence notices and dependencies.
`SOURCE-MANIFEST.json` hashes every included file. `SOURCE-AUDIT.json` records the
allowlist and credential-pattern check. The source is directly buildable with Rojo.
`python scripts/verify_source_package.py` extracts the prepared archive into an
isolated local build folder, checks its hashes, rebuilds with Rojo and requires a
byte-identical place hash. Its result is `build/source-build-verification.json`.

Excluded: the entire development `build` directory, local tools/caches, previous
place binaries, performance traces, runtime player/profile data, credentials,
environment files and authentication state. Known credential-pattern scans are
not a substitute for reviewing the exact upload; the packager stops on findings
without printing possible secret values. The initial upload used this audited allowlist.

## Exact owner upload steps

1. Extract the ZIP named in `build/source-package.json` into a **new clean folder**.
   Review `SOURCE-AUDIT.json`, `SOURCE-MANIFEST.json`, `LICENSE`, `NOTICE` and the
   extracted files. Do not upload the development workspace or its `build` folder.
2. Sign into GitHub as the repository owner. Confirm the exact existing repository
   `gbsk001/WorldConquest` is public. Do not replace an unrelated repository.
3. With GitHub Desktop, clone that repository into another clean folder. Copy the
   extracted files into the clone, retaining any existing repository history. Inspect
   the Changes view, especially configuration and all deletions. Commit the candidate
   source and manifest, then **Push origin only when you approve that upload**.
   Alternatively use Git locally; no force push is needed. If the repository is empty,
   the first commit creates its default branch.
4. In GitHub, create a tag/release for this candidate, using the source manifest's
   place hash to identify the corresponding build. Attach the prepared source ZIP
   and include that hash in release notes. Preserve this version when future updates
   are released; upload matching source for every deployed modification.
5. Open the repository and tagged source ZIP in a signed-out browser. Verify no login
   is required, download it, and rebuild using `BUILDING.md`. Check the in-game source
   offer and notices in Studio and on each supported device. A repository that only
   links upstream or contains just a compiled `.rbxlx` is insufficient.
6. Only after the source is accessible and the acceptance blockers are cleared,
   manually update the **existing** experience as described in the acceptance report.
   This task does not authorize an upload or game publication.

Keep AGPL and upstream additional terms intact. The source release cannot supply
Roblox's proprietary engine source; it provides this adaptation, its modifications,
build/data scripts, asset sources and dependency provenance. Unmodified external
ETOPO data can be fetched by its pinned URL/hash as documented in `BUILDING.md`.
