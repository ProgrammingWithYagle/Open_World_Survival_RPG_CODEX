# Design research and decisions

Research informed the structure of this original game. It does not establish that this release can sustain thousands of hours; that needs player feedback and long-term iteration. Content quantity alone is a poor substitute for understandable, interacting systems.

## What the reference games teach

| Primary source | Observation | Application in The Mossbound Atlas |
| --- | --- | --- |
| [Minecraft: surviving the first night](https://www.minecraft.net/en-us/article/how-survive-your-first-night-minecraft) | A short survival goal makes gathering, tools and shelter meaningful immediately. | The first objectives introduce a traveler, nearby supplies, a workbench and a visible eastern trail. Starting supplies prevent a knowledge check from becoming an immediate failure. |
| [Terraria: official publisher description](https://store.steampowered.com/app/105600/Terraria/) | Exploration, combat and construction offer different reasons to return to the same world. | Wardens provide an authored progression spine; settlements, collecting, farming, requests and trials supply parallel pursuits. The main ending keeps the world playable. |
| [Valheim: developer FAQ](https://www.valheimgame.com/faq/) | Regional environments, preparation, outposts and crafting stations give journeys structure. | Five regions have different resources and opponents. Camps become supply points, food changes preparation, and restoring regions supports later travel and courier routes. |
| [Factorio: Friday Facts 327](https://www.factorio.com/blog/post/fff-327) | The developers explain why upgrades are more meaningful when players first understand the manual work they replace. | Gather and craft first; queued processing and couriers arrive after the player has used resources and storage. Nearby chests remove repeated inventory shuffling. |
| [RimWorld: developer overview](https://rimworldgame.com/) | Persistent people, needs, weather and consequences can produce stories through their interactions. | Named travelers, recurring supply requests, exposure, recoverable graves and persistent camps give exploration consequences. This game uses a simpler action-RPG simulation; it does not implement RimWorld's storyteller or colony model. |

The observations above are design interpretations of the cited sources. They are not claims that any single feature explains those games' success. No characters, maps, sprites, music, lore or item lists were copied.

## A distinct identity

The player is a surveyor rebuilding a waystone network after the old routes vanished beneath a growing wilderness. Three currents provide a local choice: **Bloom** supports cultivation and regrowth, **Ember** supports processing and mineral gathering, and **Gale** supports travel. The game's central reward is a world that becomes easier to understand and live in through the player's own camps and connections.

The loop is scout, prepare, venture, return and improve. Five wardens anchor progression without forcing combat on Peaceful players. Thirty sites mix one-time discovery with renewable groves and repeatable trials. Eight travelers and sixteen rotating requests create reasons to revisit regions without resetting their history. There are no daily login rewards or online timers; simulation time advances during active play.

Depth comes from relationships between systems. A garden can supply food, a meal can support an expedition, a warden unlocks better equipment, a restored waystone improves a camp, and a courier carries that camp's materials to the next one. Buildings with no production function are explicitly decorative or utility pieces; their descriptions do not promise absent systems.

## Visual and technical choices

The [official Eastward page](https://pixpil.com/en/games/eastward/) was studied for hierarchy, readable silhouettes, grounded palettes and the distinction between quiet terrain and important objects. These are broad visual principles. Its assets and compositions are not included. The surveyor's teal coat, ochre scarf, brass instruments and regional plant/stone palette form this project's own art direction.

The 640 × 360 world uses nearest filtering, shared animation scales, consistent foot anchors, clear attack poses and sparse effects. The UI renders separately so Chinese and Japanese text remains readable. Atlas slicing is checked against real alpha silhouettes rather than trusting a generator's nominal grid.

Godot 4.5.1 was retained because its scene, input, audio and export systems suit a modest offline 2D game. A rewrite in another engine would not by itself improve the player's understanding. The revamp replaces the runtime systems while keeping a data-driven structure. [TileMapLayer](https://docs.godotengine.org/en/4.5/classes/class_tilemaplayer.html), [multiple resolutions](https://docs.godotengine.org/en/4.5/tutorials/rendering/multiple_resolutions.html) and [Windows exporting](https://docs.godotengine.org/en/4.5/tutorials/export/exporting_for_windows.html) informed the implementation.

## Release acceptance

Acceptance requires content/translation validation, real Godot execution, save recovery tests, normal and slow sprite playback, five-language layout captures and a freshly extracted Windows export. [Implementation status](IMPLEMENTATION_STATUS.md) records what was actually exercised. Future work should prioritize player comprehension, balance and meaningful interactions before adding more catalog entries.
