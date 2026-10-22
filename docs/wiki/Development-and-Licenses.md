# Development and licenses

The project uses Godot 4.5.1 and its Compatibility renderer. Open `godot/project.godot` to work from source. Runtime logic is separated into core state, activities, world streaming, actors and UI. Content and localization are JSON generated from the authored production scripts.

Run the Python tests, Godot runtime suite and live-scene integration suite before changes are published. Native visual suites capture language layouts and sprite animation at normal and quarter speed. The repository retains source artwork, hashes, audio composition recipes and verification reports. Performance figures apply to the hardware and scenarios recorded in those reports.

Art was created for this project with image generation, then normalized, inspected and revised. It is not represented as hand-drawn. Music is composed from original note/chord sequences and synthesized locally; effects use original synthesis and foley recipes. No copied commercial game sprites or audio samples are included.

The source is under the repository's MIT license. Godot is MIT licensed. Atkinson Hyperlegible, Lora and Noto Sans CJK are bundled under their respective SIL Open Font License texts. See `godot/fonts`, `docs/ASSETS.md`, and the license files in the Windows download.

See [design research](../DESIGN_RESEARCH.md) for the primary sources that informed the game structure, and [implementation status](../IMPLEMENTATION_STATUS.md) for verification limits and remaining work.
