# Open World Survival RPG (Codex)

A 2D top‑down open‑world survival RPG inspired by **devast.io** and **starve.io**. The long‑term goal is a highly replayable survival sandbox with deep progression (skills, tech tiers, factions), emergent exploration, and scalable multiplayer. The first milestone targets a polished **single‑player** experience, with a deliberate path to add multiplayer later.

---

## Table of Contents
1. [Vision](#vision)
2. [Current Status](#current-status)
3. [Core Gameplay Loop](#core-gameplay-loop)
4. [Key Systems](#key-systems)
5. [Progression & Long‑Term Play](#progression--long-term-play)
6. [Art & UX Direction](#art--ux-direction)
7. [Tech Stack (Proposed)](#tech-stack-proposed)
8. [Architecture Overview](#architecture-overview)
9. [Development Roadmap](#development-roadmap)
10. [Testing & Quality](#testing--quality)
11. [Repository Structure (Planned)](#repository-structure-planned)
12. [Design Principles](#design-principles)
13. [Community & Feedback](#community--feedback)
14. [Getting Started](#getting-started)
15. [Next Steps](#next-steps)

---

## Vision
Create a survival RPG that is **easy to start, hard to master**, where players:
- Feel *constant forward momentum* through clear, meaningful upgrades.
- Always have interesting, risky choices (where to explore, what to craft, who to ally with).
- Experience unique, emergent stories each run.

The **north star**: a game you can play for hundreds of hours without running out of reasons to keep exploring and evolving.

---

## Current Status
- **Prototype available**: Godot 4 project skeleton with starter scenes and scripts.
- **Implemented**: top‑down movement, harvesting, inventory, expanded crafting, consumable items, survival needs (including health), procedural biome-based world generation, and a refreshed HUD with progress bars plus iconized inventory/crafting lists.
- **Recent improvements**: larger, stylized resource sprites; biome tile visuals (water, grassland, forest, desert, tundra); weighted resource placement per biome.
- **New additions**: data-driven mob definitions with initial passive/aggressive/ranged/patrol examples, plus a main menu with options (master volume + fullscreen).
- **Planned next**: expand world props (rocks/trees variants), add crafting stations with placement, and build a dedicated crafting/character stats panel.

---

## Core Gameplay Loop
1. **Explore** → find biomes, ruins, nodes, events.
2. **Gather** → harvest resources from the environment.
3. **Craft** → tools, weapons, structures, consumables.
4. **Survive** → manage hunger, cold/heat, fatigue, injuries.
5. **Fight / Flee** → tactical combat, wildlife threats, rival factions.
6. **Progress** → unlock skills, tech tiers, and world advantages.
7. **Build** → bases, outposts, automated production.

---

## Key Systems
### World & Exploration
- **Procedural 2D world** with hand‑crafted POIs (ruins, caves, camps, temples).
- **Biome diversity** (forest, desert, snow, swamp, coast) with unique resources.
- **Dynamic events** (storms, migration, faction skirmishes, caravan raids).

### Survival & Needs
- **Hunger, thirst, temperature, fatigue** as manageable, not punitive.
- **Injuries & conditions** (bleeding, infections) that create new goals.
- **Shelter & camp management** to reduce survival pressure.

### Crafting & Production
- **Modular crafting** (component upgrades, material variants).
- **Tech tiers** (primitive → iron → steel → advanced tech).
- **Automation** (mills, kilns, farms, traps) to reduce grind.

### Combat & AI
- **Top‑down tactical combat** with stamina, hit windows, and positioning.
- **AI behavior profiles** (predators, ambushers, pack hunters, sentries).
- **Weapon variety** (melee, thrown, bows, late‑game firearms).

### Factions & Reputation
- Multiple factions with **reputation systems** and **unique rewards**.
- **Dynamic faction conflicts** that reshape the world.
- Player can **ally**, **raid**, or **infiltrate**.

---

## Progression & Long‑Term Play
- **Skill trees**: survival, combat, crafting, exploration.
- **Base‑building tiers**: from basic camp to fortified settlement.
- **World escalation**: stronger enemies, harsher climates, rarer resources.
- **Meta‑progression** (optional): unlock starting perks or recipes after long runs.
- **Endgame goals**: world bosses, faction control, rare tech relics.

---

## Art & UX Direction
- **2D top‑down** with readable silhouettes and strong color coding.
- **Hand‑painted, grounded survival aesthetic** (not overly cartoonish).
- **UI clarity** (inventory, crafting, and stats always visible in 1–2 clicks).

---

## Tech Stack (Proposed)
**Engine:** Godot 4.5 (in use for the prototype project)

**Languages:**
- GDScript for gameplay
- Optional C# for performance‑critical systems

**Data & Tools:**
- JSON or Godot Resources for item definitions and progression data
- Tiled (optional) for POI layout

**Multiplayer (Phase 2):**
- Godot high‑level multiplayer API
- Dedicated server with deterministic or authoritative simulation

---

## Architecture Overview
### Core Modules (Planned)
- **World Generation**: seeds, biomes, spawn tables
- **Entity System**: player, NPCs, wildlife
- **Survival System**: needs, conditions, status effects
- **Combat System**: weapons, damage types, AI behavior
- **Crafting System**: recipes, tech tiers, workstations
- **Progression System**: XP, skills, faction rep
- **UI System**: inventory, crafting, minimap, quests

Each system should be **modular** and **data‑driven** so content expands without rewriting core code.

### Implemented Core Modules (Prototype)
- **World Controller** (`godot/scripts/game.gd`): spawns resources, owns system wiring.
- **Player** (`godot/scripts/player.gd`): movement, interaction, crafting input.
- **Inventory** (`godot/scripts/inventory.gd`): item storage with change signals.
- **Survival Needs** (`godot/scripts/needs.gd`): hunger, thirst, temperature decay, and health penalties.
- **Crafting** (`godot/scripts/crafting.gd`): recipe validation and crafting actions.
- **Item Database** (`godot/scripts/item_db.gd`): data loader for items/recipes.
- **Mob Database** (`godot/scripts/mob_db.gd`): data loader for mob definitions.
- **Mob Controller** (`godot/scripts/mob.gd`): lightweight AI behaviors (passive/aggressive/ranged/patrol).
- **Resource Nodes** (`godot/scripts/resource_node.gd`): harvestable entities.
- **HUD** (`godot/scripts/hud.gd`): needs, inventory, and craftable recipe readouts.
- **Main Menu** (`godot/scenes/MainMenu.tscn` + `godot/scripts/main_menu.gd`): start/quit flow and settings panel.

---

## Development Roadmap
### Phase 1 — Prototype (Single‑Player Core)
- Top‑down movement + basic interaction
- Simple world generation + 1–2 biomes
- Crafting, tools, hunger/temperature loop
- Basic combat with 2–3 enemy types

### Phase 2 — Vertical Slice
- Multi‑biome world
- Skill tree + tech tiers
- Base‑building tier 1–2
- Faction system v1
- Improved AI behaviors

### Phase 3 — Content Expansion
- New biomes & world events
- More items, weapons, armor
- Endgame encounters & bosses
- Base automation systems

### Phase 4 — Multiplayer (Optional)
- Co‑op foundations + persistence
- Dedicated server prototype
- Sync & performance testing

---

## Testing & Quality
- **Data validation tests** (Python/pytest) for items and recipes.
- **Unit tests** for systems (crafting recipes, stat calculations) planned.
- **Simulation tests** for AI and progression balance planned.
- **Save/load tests** for persistence planned.
- **Performance profiling** to keep 60 FPS target planned.

---

## Repository Structure
```
/AGENTS.md           # contributor guidance
/README.md
/docs/               # design docs, milestones, balance notes (planned)
/godot/              # Godot project root
/godot/scenes/       # main, player, HUD, resource node scenes
/godot/scripts/      # gameplay systems
/godot/data/         # items, crafting recipes, mob definitions
/tests/              # data validation tests
```

---

## Design Principles
- **Clarity before complexity**: depth comes from layered systems, not confusion.
- **No grind without payoff**: every task unlocks new options.
- **Player agency**: multiple viable playstyles.
- **Replayability**: procedural variation + meta progression.

---

## Community & Feedback
This project is a living experiment. Feedback will shape the game’s direction, balance, and content priorities. Share ideas, feature requests, and playtest notes as early as possible.

---

## Getting Started
Minimum steps:
1. **Clone the repo**: `git clone <repo-url>` and `cd Open_World_Survival_RPG_CODEX`.
2. **Install Godot 4.5** (standard build from godotengine.org).
3. **Open the project** in Godot by selecting the `/godot/` folder.
4. **Run the scene** to move with WASD, harvest with E, craft with C.

Optional tests:
- `pytest` (validates JSON data in `godot/data/`).

---

## Next Steps
1. Expand biome visuals with additional prop variants and decorative clutter.
2. Introduce placeable crafting stations and a crafting UI panel with recipe details.
3. Add simple enemies, combat feedback, and health recovery sources.
4. Add save/load support for player progress.
5. Create a lightweight audio pass (footsteps, harvest, ambient).

---

If you want anything expanded or adjusted, let me know and I’ll refine it further.
