# Open World Survival RPG (Codex)

A 2D top‑down open‑world survival RPG inspired by **devast.io** and **starve.io**. The long‑term goal is a highly replayable survival sandbox with deep progression (skills, tech tiers, factions), emergent exploration, and scalable multiplayer. The first milestone targets a polished **single‑player** experience, with a deliberate path to add multiplayer later.

---

## Table of Contents
1. [Current Status](#current-status)
2. [Vision](#vision)
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
14. [Contributing](#contributing)
15. [Getting Started](#getting-started)

---

## Current Status
- **Pre‑implementation**: no Godot project or gameplay code yet.
- **This README is the source of truth** for the project’s vision, scope, and intended systems.
- **Next step** is to create the Godot project skeleton and begin the first playable loop.

---

## Vision
Create a survival RPG that is **easy to start, hard to master**, where players:
- Feel *constant forward momentum* through clear, meaningful upgrades.
- Always have interesting, risky choices (where to explore, what to craft, who to ally with).
- Experience unique, emergent stories each run.

The **north star**: a game you can play for hundreds of hours without running out of reasons to keep exploring and evolving.

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
**Engine:** Godot 4 (best fit for 2D, open source, rapid iteration)

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
- **Unit tests** for systems (crafting recipes, stat calculations).
- **Simulation tests** for AI and progression balance.
- **Save/load tests** for persistence.
- **Performance profiling** to keep 60 FPS target.

---

## Repository Structure (Planned)
```
/README.md
/docs/               # design docs, milestones, balance notes
/godot/              # game project (future)
/godot/scenes/       # world, player, UI scenes
/godot/scripts/      # gameplay systems
/godot/data/         # items, recipes, biomes
/tests/              # unit + simulation tests
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

## Contributing
- **Propose features:** Open an issue or start a discussion describing the problem, the player impact, and any gameplay references or inspirations.
- **Coding conventions:** TBD. Before submitting code, open an issue so we can align on structure, style, and Godot/GDScript conventions.
- **Gameplay/system suggestions:** Please use a structured format:
  - Goal (what problem or experience this improves)
  - Affected systems (e.g., crafting, combat, world gen)
  - Mechanics summary (inputs → rules → outcomes)
  - Progression impact (early/mid/late game)
  - Balance concerns or risks

---

## Getting Started
This repository is currently in planning mode. There is no runnable game project yet. When the Godot project is initialized, this section will include:
- Setup steps for Godot 4.
- How to open the project and run a test scene.
- Any required tools or data sources.

For now, the recommended first action is to read this README to understand the intended scope and systems.

---

## Next Steps
1. Create the Godot project skeleton.
2. Establish the first playable loop (gather → craft → survive).
3. Begin iterative expansion based on feedback.

---

If you want anything expanded or adjusted, let me know and I’ll refine it further.
