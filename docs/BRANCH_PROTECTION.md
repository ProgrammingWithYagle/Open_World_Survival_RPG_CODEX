# Main branch protection

The active [Main branch protection ruleset](https://github.com/ProgrammingWithYagle/Open_World_Survival_RPG_CODEX/rules/11494557) applies to `refs/heads/main`. Its checked API response is retained in [verification/main_ruleset.json](../verification/main_ruleset.json).

Changes must arrive through a pull request with these five GitHub Actions checks passing:

- `data-validation`
- `asset-validation`
- `godot-tests`
- `windows-export`
- `docs-validation`

The checks are bound to the GitHub Actions application, and the branch must be up to date before merging. Review discussions must be resolved. Squash is the only allowed merge method, preserving linear history. Deleting main and force pushing are blocked. No account or application has a configured bypass.

The required approving-review count is zero because this repository currently has one maintainer, who cannot approve their own pull request. Pull requests and all automated checks remain mandatory. A second maintainer can raise that count when independent reviews are practical. Failed checks must be fixed before merging.

The [validation workflow](../.github/workflows/validate.yml) tests game data, asset integrity, Godot runtime and live-scene behavior, Windows export and fresh extraction, and documentation. Native art, animation and language-layout reviews supplement those hosted checks; CI does not replace player testing.

Release downloads are attached to [GitHub Releases](https://github.com/ProgrammingWithYagle/Open_World_Survival_RPG_CODEX/releases). Each Windows package includes its source commit in `manifest.json`, per-file SHA-256 checksums, an offline player guide, the Wiki, licenses and asset provenance. Verify a fresh extraction with `python tools/verify_download.py <archive.zip>` before publishing a new package.
