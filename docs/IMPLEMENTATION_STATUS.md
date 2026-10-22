# Release implementation and verification

The Mossbound Atlas replaces the original prototype runtime with a Godot 4.5.1 single-player wilderness RPG. The original source remains in Git history at baseline `9c3dbb97c7f092ef9ad62fcda9da0b8616833ae6`.

## Implemented

Five regions, five wardens, eight travelers, 30 discovery sites, 16 rotating requests, 25 creatures, 143 items, 115 recipes, 41 building pieces, six crops, five regional fish, nine perks and six charms. Farms, queued processing, cooking, storage, courier shipments, region restoration and repeatable three-wave expeditions form the main activity systems. Finishing the restoration journey preserves continued play.

The runtime includes independent five-level difficulty and three-rule death settings, multiple journey slots, automatic saves, three backup generations and permanent Hardcore retirement markers. English, Simplified Chinese, Traditional Chinese, Spanish and Japanese have 642 catalog keys each. Original art supplies 336 animation frames; the soundtrack contains six themes and 21 effects/ambience assets.

## Verified locally

| Check | Evidence and result |
| --- | --- |
| Python data, translation and asset tests | 12 tests passed; recipe graph, catalog/placeholder parity, distinct Chinese scripts, all item icons, source hashes, binary alpha and complete frame borders/anchors. |
| Godot runtime | 650 checks passed. Includes 30 seeded critical-route scenarios, crafting transactions, all 15 difficulty/death combinations, farming/milling/bread progression, ending persistence, all three backup generations, future-version rejection and Hardcore backup retirement. |
| Live-scene integration | 121 checks passed. Actual movement, gathering animation, single hit timing, dodge, search, construction layers, dismantling, live creature snapshots, three-wave trials, every discovery site's approach/interaction, dropped-supply collection, aim priority/deadzone behavior and safe cancellation of world-streaming jobs. Controller direction tests exercise the game's aim calculation; they do not emulate a physical controller driver. |
| Five-language rendering | [130 native 1280 × 720 captures](../verification/ui_matrix/report.json), 26 screens per language; zero detected layout overflow. Representative title, inventory, crafting, farming, settings, dialogue, site, night and regional captures were visually inspected. This is not a claim that every catalog sentence received native-speaker review. |
| Animation | [Six normal/quarter-speed recordings](../verification/animation_playback_manifest.json), 1,080 native captures, plus source/runtime contact sheets. The review covers every player action/direction and every creature sheet. Clipped source crops and the touching Reedmother row were corrected. |
| Standalone Windows export | A freshly extracted 32-file package passes every member hash, every local documentation link, standalone startup and save/load. Fresh native HUD captures pass in all five languages from a copied installation; startup and quit have no engine errors or resource-leak warnings. |
| Performance | [Five-region report](../verification/performance.json), Intel Graphics, 1280 × 720 window with a 640 × 360 world and 24 creatures per region. Initial builds were 205–325 ms; sampled frame-interval p95 was 10.4–11.3 ms. Cold chunk preparation was spread over frames. These are scenario measurements on one machine, not universal minimum requirements. |

The runtime and integration suites use automated scenarios and controlled state. They do not constitute an uninterrupted human playthrough or a measurement of real progression length. Native animation recordings are inspection material, not trailers. Performance monitor values that include loading spikes should not be treated as steady gameplay CPU time.

## Publication checks

The [GitHub Wiki](https://github.com/ProgrammingWithYagle/Open_World_Survival_RPG_CODEX/wiki) and [public development Project](https://github.com/users/ProgrammingWithYagle/projects/2) are published. Local Windows package and native export checks have passed. Hosted CI, release upload and strengthened main rules are being finalized. Publication is verified separately from local files.

## Limits and next work

Long-duration balancing, native-speaker editorial review, broad controller/audio hardware tests and additional display configurations still need player testing. The release does not claim industry-level perfection, thousands of proven play hours, multiplayer or a colony simulation. Coats affect protection without a separate appearance for every armor tier; creature animation uses mirrored horizontal movement rather than four complete direction sets.

The [development board](PROJECT.md) records follow-up work. A release should only advertise features implemented in source and exercised by the relevant checks. Save schema and world generator versions must be considered before future changes; the original prototype's world state is not imported.
