# Sprite Sheet Assets

This folder stores 32×32 sprite sheets for the player and mobs. Each sheet is a
horizontal strip of frames (left to right) with a consistent frame size.

## Naming Convention

Use the format below for every action + direction:

```
player_<action>_<direction>.png
mob_<mob_id>_<action>_<direction>.png
```

- **Actions**: `idle`, `walk`, `attack`, `death`
- **Directions**: `north`, `south`, `east`, `west`

Example files:

```
player_walk_north.png
mob_boar_attack_west.png
mob_slime_idle_south.png
```

## Passive Wildlife

For passive wildlife that lacks self-defense, omit the `attack` sheets entirely.
The animation loader will skip missing files automatically.
