# Public corresponding-source verification — 24 November 2026

The owner authorized the source upload to the existing public repository:
**https://github.com/gbsk001/WorldConquest**.

Initial complete source commit:
[`16304dfece2754ba192156ff58f3f92f0637e0da`](https://github.com/gbsk001/WorldConquest/commit/16304dfece2754ba192156ff58f3f92f0637e0da).
This follow-up documentation records that verified upload; the gameplay code is unchanged.

The initial upload contained 333 audited source/documentation/asset/test files and
two generated manifests. Verification used unauthenticated requests to the GitHub
repository API and the full codeload archive at the exact commit. All 335 uploaded
files matched the audited source archive byte for byte. `Config.SourceURL` was
verified inside the downloaded source, not merely in the local workspace.

The updated Rojo place contains all 93 current production Luau files. Its SHA-256 is:

`345c6c46848b4c852dc77ac03ecc1650564e41f8dd1fcb7fcb0ba11a573d5c07`

A clean extraction of the prepared source built a byte-identical place. It includes
AGPL-3.0 and preserved upstream additional terms, attribution, modified server/client
code, original artwork sources, generated/runtime geography, test fixtures,
dependencies and build instructions. The allowlist excludes development caches,
credentials, environment/authentication state, compiled places and runtime player
data. Known credential-pattern and private-data filename checks found no findings.
These checks are scoped audits, not a mathematical guarantee of detecting every secret.

`SOURCE-AUDIT.json` and `SOURCE-MANIFEST.json` are **pre-upload packaging snapshots**;
their `uploaded: false` fields describe the packager's action, which never publishes.
The actual upload and anonymous verification are recorded here and in the local
`build/source-upload-status.json`. Future source updates need fresh packaging and
verification; retain commit history so each deployed version remains available.

**No Roblox experience was created or published.** This clears source hosting for
this rebuilt candidate, not all release acceptance. Rendered Studio, physical mobile,
real platform communication/persistence/teleports, translation review and disabled
purchase configuration remain as documented in `STAGE12_13_ACCEPTANCE.md`.
