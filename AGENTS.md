# Agent Notes

## Project Status
The Godot 4 project skeleton now lives in `/godot`, with starter scenes, scripts, data-driven items/recipes, mob definitions, a WorldSettings resource for world creation, and a main menu scene with options. The player scene now includes a Camera2D with a 2× default zoom, plus scaled player/mob sprites and tuned collision radii for readability. The new sprite sheet assets live in `/godot/art` and are loaded by name at runtime. Keep this file updated whenever the repo structure or workflows change.

## Conventions
- Use `godot/scripts/` for gameplay logic and keep systems modular.
- Prefer JSON in `godot/data/` for item/recipe definitions.
- Update `README.md` after meaningful gameplay progress.

## Testing
- `pytest` validates JSON data in `godot/data/`.
