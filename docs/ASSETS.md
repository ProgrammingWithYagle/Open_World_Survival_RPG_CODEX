# Art, audio and third-party notices

The game contains original project-specific imagery prepared with the built-in image generation tool, followed by deterministic slicing, scale/anchor normalization, alpha preparation, native inspection and revisions. It is not described as human-drawn art. No sprites, music or sound samples from the researched commercial games are distributed.

## Art pipeline

The preserved source atlases are under `godot/art/source`; [provenance](../godot/art/source/provenance.json) records their SHA-256 hashes. `tools/normalize_assets.py` is the reproducible source-to-runtime mapping. It detects actual silhouettes and gutters, checks counts and preserves one scale for a complete action. Runtime alpha is binary and transparent pixels have zero RGB. The animation manifest records 336 frames, dimensions, source bounds and timing.

The accepted character specification is a wilderness surveyor in a teal coat, ochre scarf, dark trousers and leather boots, with readable small-scale anatomy and a brass field instrument. Player sheets cover idle, walking, attacks, dodging and defeat in four directions. Creature sheets use eight deliberate poses: four locomotion, two windup, one strike and one recovery. Wardens are larger, with a distinct silhouette for each region. Some creature motion uses horizontal mirroring rather than four independent directional sheets.

Environment assets include 41 building pieces, five continuous floor surfaces, eight landmark types, nine garden stages, woodland/resource props, terrain and eight travelers. Every one of the 143 items has its own icon. The grain atlas contains a spare rotor candidate that is not used in the game.

Rejected or corrected examples include soft glowing concept edges, nominal-grid crops that cut off bodies, and a Reedmother pose whose tongue touched the adjacent sprite. The runtime uses detected source bounds and a replacement Reedmother strip. Source candidates retained for audit are excluded from the playable package. Native animation recordings and frame/anchor checks are described in [verification](IMPLEMENTATION_STATUS.md).

## Original audio

`tools/compose_audio.py` authors six musical themes using explicit notes, chords, rhythms and instrument envelopes. They share a rising-fourth/falling-third motif with regional instrumentation. The tool also synthesizes footsteps, impacts, pickups, actions and a forest ambience bed. No downloaded samples, licensed commercial tracks or music-generation service outputs are included.

There are 27 WAV assets: six musical loops and 21 effects/ambience files. Audio is 22,050 Hz stereo PCM. The [score description](ORIGINAL_AUDIO_SCORE.json) and [audio manifest](../godot/audio/audio_manifest.json) record composition and signal statistics. Peak, DC, silent-output and loop-boundary checks can detect technical defects; they do not replace human listening across speakers and headphones.

## Fonts and engine

| Component | Origin and license |
| --- | --- |
| Godot 4.5.1 | [Official source](https://github.com/godotengine/godot/tree/4.5.1-stable), MIT; [engine notice](../third_party/Godot-MIT.txt) and [third-party notices](../third_party/Godot-Third-Party.txt) are included in downloads. |
| Atkinson Hyperlegible | Google Fonts distribution; [SIL Open Font License](../godot/fonts/Atkinson-OFL.txt). |
| Lora | Google Fonts distribution; [SIL Open Font License](../godot/fonts/Lora-OFL.txt). |
| Noto Sans CJK SC, TC and JP | Noto CJK project; [SIL Open Font License](../godot/fonts/OFL.txt). Separate regional files avoid dependence on the player's installed fonts. |

[Font provenance](../godot/fonts/provenance.json) records source URLs and hashes. Python, NumPy, Pillow, pytest and gdtoolkit are development tools and are not embedded in the playable Windows application. Official Godot export templates and Electron rcedit are build tools; their download receipts and checksums are retained locally. Rcedit is not distributed with the game.

The repository's [MIT license](../LICENSE) applies to the source and project-authored material, subject to the separately licensed components above and applicable rights in generated output.
