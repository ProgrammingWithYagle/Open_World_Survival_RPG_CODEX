# Agent Notes

## Current project
The Mossbound Atlas is an offline Godot 4.5.1 wilderness RPG in `godot/`. Open `project.godot` and run `scenes/Mossbound.tscn`. Autoloads are L, Content, Saves, Session, Activities and Sound. A 640 x 360 world viewport sits beneath a separate readable interface. The former prototype remains in Git history; caches are ignored.

## Conventions
- Keep gameplay modular in `godot/scripts/core`, `world`, `actors` and `ui`.
- Author content through `tools/build_content.py`, `expand_content.py`, `expand_provisions.py`, `polish_text.py` and `release_content.py`. Regenerate JSON in `godot/data` and all five `godot/locale` catalogs together.
- Generate the repository Wiki and root changelog with `python tools/build_wiki.py`. The native GitHub Wiki can be synchronized with `tools/publish_wiki.py` after its checkout is initialized.
- Preserve source art and provenance. Use complete animation strips with a shared scale and foot anchors, then inspect normal and quarter-speed native playback. Runtime icons are 32 x 32; player cells are 64 x 64; creature/warden cells are 48/96.
- Cancel world streaming before retiring a view. Let suspended jobs resume and release resources before freeing it; disconnect old snapshot handlers immediately.
- Keep multiline UI callbacks in named methods or local Callables. Godot 4.5.1 can reject formatter-generated multiline lambdas nested inside calls; validate with the actual engine.
- Update README, implementation status and release notes after meaningful gameplay changes. Separate implemented, verified and prospective work.
- Never commit credentials, Godot caches, local dependency downloads or playable exports. Downloads belong in GitHub Releases.

## Verification and packaging
- `python -m pytest tests` validates data, five-language catalogs, sprite borders/anchors, provenance and actual audio PCM.
- `python tools/check_godot.py --godot PATH` imports the project and runs runtime plus live-scene integration tests.
- `tools/run_visual.ps1 -Godot PATH -Suite ui` captures five-language screens; `-Suite animation` records sprite playback. `tools/encode_animation_reviews.py` packages playback MP4s. Python 3.12 is used for gdtoolkit formatting.
- `python tools/build_wiki.py --check` and `python tools/check_docs.py` validate documentation and version agreement.
- `python tools/build_windows.py --godot PATH` prepares official pinned templates, exports/stamps the executable and includes the offline Wiki, guide, licenses, provenance and checksums.
- `python tools/verify_download.py ARCHIVE` verifies a fresh extraction and runs the standalone save/load startup smoke. Also use `tools/test_export.ps1` for native packaged screens.
- PowerShell wrappers accept `-Godot PATH` or the `GODOT` environment variable. `tools/prepare_godot.py` installs a pinned official editor into ignored `.tools`.
- CI jobs are `data-validation`, `asset-validation`, `godot-tests`, `windows-export` and `docs-validation`. Main protection must require those checks and pull requests. Preserve no-force-push/no-deletion protection and do not bypass failing checks.
- CI dependency metadata uses the read-only GITHUB_TOKEN through tools/build_release_metadata.py to avoid shared anonymous API limits. Asset downloads remain separate unauthenticated requests; never log or forward the token.
- Project synchronization must verify saved item IDs directly before creating cards: GitHub can return an empty aggregate item list immediately after successful writes. Preserve those IDs in the publication receipt.
