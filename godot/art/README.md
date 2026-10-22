# Runtime art and source atlases

`source/` preserves the original generated candidates and SHA-256 provenance. Runtime assets are prepared by `tools/normalize_assets.py`; the source images are excluded from playable exports.

The player has 64 × 64 cells with a 44-pixel body envelope. Direction rows are south, west, east and north. Idle has four frames per row, walk and attack eight, dodge six and defeat eight. Creatures have eight 48 × 48 cells, or 96 × 96 for wardens. Creature frames 0–3 provide locomotion; 4–5 telegraph attacks, 6 strikes and 7 recovers. Creatures mirror horizontally; they do not have four independent direction sets.

`animation_manifest.json` records source bounds, shared scale, frame dimensions, direction order and timing. All frames in an action use one scale and a consistent foot baseline. Nearest-neighbor preparation and binary runtime alpha prevent blurred pixel edges. No frame may touch its cell border or lose a body part to atlas slicing.

`icons/` contains a distinct 32 × 32 icon for every item. `environment/` contains terrain, flat building surfaces, structures, resource props, growth stages and discovery sites. Flat foundations render below furniture. The application icon derives from the original relic-compass icon.

Validation combines Python frame/alpha checks, Godot gameplay tests, full language-screen captures and in-engine normal/quarter-speed playback. The corrected Reedmother source replaces a rejected row where neighboring silhouettes touched. Some earlier source candidates are retained only for provenance; they are not all used at runtime. See [asset notes](../../docs/ASSETS.md).
