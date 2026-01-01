extends Resource
class_name WorldSettings

## WorldSettings is a data container that travels from the main menu into the game scene.
## It will be serialized alongside world saves later, so keep new fields deterministic and data-only.

enum Difficulty { PEACEFUL, EASY, NORMAL, HARDCORE }

@export var difficulty: Difficulty = Difficulty.NORMAL
@export var enable_needs := true
@export var enable_hostile_mobs := true
@export var allow_respawn := true
@export var grant_starter_kit := true

func apply_recommended_flags() -> void:
	match difficulty:
		Difficulty.PEACEFUL:
			enable_needs = false
			enable_hostile_mobs = false
			allow_respawn = true
			grant_starter_kit = true
		Difficulty.EASY:
			enable_needs = true
			enable_hostile_mobs = true
			allow_respawn = true
			grant_starter_kit = true
		Difficulty.NORMAL:
			enable_needs = true
			enable_hostile_mobs = true
			allow_respawn = true
			grant_starter_kit = true
		Difficulty.HARDCORE:
			enable_needs = true
			enable_hostile_mobs = true
			allow_respawn = false
			grant_starter_kit = false

func get_needs_multiplier() -> float:
	match difficulty:
		Difficulty.PEACEFUL:
			return 0.0
		Difficulty.EASY:
			return 0.8
		Difficulty.NORMAL:
			return 1.0
		Difficulty.HARDCORE:
			return 1.35
	return 1.0

func get_mob_multiplier() -> float:
	match difficulty:
		Difficulty.PEACEFUL:
			return 0.0
		Difficulty.EASY:
			return 0.85
		Difficulty.NORMAL:
			return 1.0
		Difficulty.HARDCORE:
			return 1.4
	return 1.0
