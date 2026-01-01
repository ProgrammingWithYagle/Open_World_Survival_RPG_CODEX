extends Node2D

## Main world controller: spawns resources, wires systems, and updates HUD.

const RESOURCE_NODE_SCENE := preload("res://scenes/ResourceNode.tscn")
const MOB_SCENE := preload("res://scenes/Mob.tscn")
## Easy mode tuning values for survival decay and combat pressure.
const EASY_NEEDS_DECAY_MULTIPLIER := 0.7
const EASY_MOB_MULTIPLIER := 0.7

@export var resource_count := 20
@export var spawn_radius := 420.0
@export var resource_density := 0.08
@export var world_seed := 0
@export var mob_count := 10
@export var mob_spawn_radius := 480.0
@export var mob_density := 0.04

var item_db: ItemDB
var inventory: Inventory
var needs: Needs
var crafting: Crafting
var mob_db: MobDB
## Exposed to gameplay systems (spawns, needs, death flow) for world-specific tuning.
var world_settings: WorldSettings

var base_resource_count := 0
var base_resource_density := 0.0
var base_mob_count := 0
var base_mob_density := 0.0

var player: CharacterBody2D
var hud: CanvasLayer
var world: Node2D
var world_generator: WorldGenerator
var player_spawn_position := Vector2.ZERO
var player_dead := false

func _ready() -> void:
	randomize()
	world = $World
	player = $Player
	hud = $HUD
	world_generator = $World/WorldGenerator
	player_spawn_position = player.global_position

	item_db = ItemDB.new()
	add_child(item_db)

	inventory = Inventory.new()
	add_child(inventory)

	needs = Needs.new()
	add_child(needs)

	crafting = Crafting.new()
	add_child(crafting)

	mob_db = MobDB.new()
	add_child(mob_db)

	base_resource_count = resource_count
	base_resource_density = resource_density
	base_mob_count = mob_count
	base_mob_density = mob_density

	_apply_world_settings()

	player.set_systems(inventory, needs, crafting, item_db)
	hud.bind_systems(inventory, needs, item_db, crafting)

	_generate_world()
	_spawn_resources()
	_spawn_mobs()
	_seed_starting_items()

func _process(delta: float) -> void:
	needs.tick(delta)
	_check_player_death()

func _spawn_resources() -> void:
	if world_generator == null:
		_spawn_radial_resources()
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = world_generator.last_seed if world_generator != null else randi()
	var biome_weights := _build_biome_weights()
	var total_spawn := int(resource_density * world_generator.map_size.x * world_generator.map_size.y)
	for i in range(total_spawn):
		var biome := _pick_weighted_biome(biome_weights, rng)
		var resource_id := _pick_resource_for_biome(biome, rng)
		var cell := world_generator.get_random_cell_in_biome(biome)
		var spawn_position := world_generator.get_world_position_for_cell(cell)
		if player != null and spawn_position.distance_to(player.global_position) < 64.0:
			continue
		_spawn_resource_node(resource_id, spawn_position)
	for i in range(resource_count):
		var water_cell := world_generator.get_random_cell_in_biome("water")
		if water_cell != Vector2i.ZERO:
			_spawn_resource_node("water", world_generator.get_world_position_for_cell(water_cell))

func _random_spawn_position() -> Vector2:
	var angle := randf() * TAU
	var distance := randf_range(120.0, spawn_radius)
	return Vector2(cos(angle), sin(angle)) * distance

func _seed_starting_items() -> void:
	if world_settings != null and not world_settings.grant_starter_kit:
		return
	inventory.add_item("berry", 2)

func _spawn_radial_resources() -> void:
	var resource_types := ["wood", "stone", "berry", "fiber", "water"]
	for i in range(resource_count):
		var node := RESOURCE_NODE_SCENE.instantiate()
		node.resource_id = resource_types[randi() % resource_types.size()]
		node.global_position = _random_spawn_position()
		world.add_child(node)

func _spawn_radial_mobs() -> void:
	if mob_db == null:
		return
	var mob_ids := mob_db.all_mobs()
	if mob_ids.is_empty():
		return
	for i in range(mob_count):
		var mob_id: String = String(mob_ids[randi() % mob_ids.size()])
		var data: Dictionary = mob_db.get_mob(mob_id)
		if not _is_mob_behavior_allowed(data):
			continue
		var spawn_position := _random_mob_spawn_position()
		_spawn_mob(mob_id, spawn_position)

func _generate_world() -> void:
	if world_generator == null:
		return
	var generated_seed := world_seed if world_seed != 0 else randi()
	world_generator.generate(generated_seed)

func _spawn_resource_node(resource_id: String, spawn_position: Vector2) -> void:
	var node := RESOURCE_NODE_SCENE.instantiate()
	node.resource_id = resource_id
	node.global_position = spawn_position
	world.add_child(node)

func _spawn_mob(mob_id: String, spawn_position: Vector2) -> void:
	if mob_db == null:
		return
	var mob := MOB_SCENE.instantiate()
	if mob is Mob:
		var data := mob_db.get_mob(mob_id).duplicate(true)
		data["id"] = mob_id
		mob.apply_definition(data)
		## Peaceful mode ensures mobs never run aggressive logic, even if data slips through.
		if world_settings != null:
			mob.set_peaceful_mode(world_settings.difficulty == WorldSettings.Difficulty.PEACEFUL)
		if world_settings != null:
			var damage_multiplier := world_settings.get_mob_damage_multiplier()
			if world_settings.difficulty == WorldSettings.Difficulty.EASY:
				damage_multiplier = EASY_MOB_MULTIPLIER
			mob.damage *= damage_multiplier
		mob.set_target(player, needs)
	mob.global_position = spawn_position
	world.add_child(mob)

func _build_biome_weights() -> Dictionary:
	var weights := {}
	for biome in WorldGenerator.BIOMES:
		if biome == "water":
			continue
		var cells: Array = world_generator.get_biome_cells(biome)
		if cells.is_empty():
			continue
		weights[biome] = cells.size()
	return weights

func _spawn_mobs() -> void:
	if mob_db == null:
		return
	var peaceful := world_settings != null and world_settings.difficulty == WorldSettings.Difficulty.PEACEFUL
	if world_settings != null and not world_settings.enable_hostile_mobs and not peaceful:
		return
	if world_generator == null:
		_spawn_radial_mobs()
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = world_generator.last_seed + 42
	var biome_weights := _build_biome_weights()
	var total_spawn := int(mob_density * world_generator.map_size.x * world_generator.map_size.y)
	total_spawn = max(total_spawn, mob_count)
	for i in range(total_spawn):
		var biome := _pick_weighted_biome(biome_weights, rng)
		var mob_id := _pick_mob_for_biome(biome, rng)
		if mob_id == "":
			continue
		var cell := world_generator.get_random_cell_in_biome(biome)
		var spawn_position := world_generator.get_world_position_for_cell(cell)
		if player != null and spawn_position.distance_to(player.global_position) < 120.0:
			continue
		_spawn_mob(mob_id, spawn_position)

func _pick_mob_for_biome(biome: String, rng: RandomNumberGenerator) -> String:
	if mob_db == null:
		return ""
	var candidates: Array = []
	for mob_id in mob_db.all_mobs():
		var data: Dictionary = mob_db.get_mob(String(mob_id))
		if not _is_mob_behavior_allowed(data):
			continue
		var biomes: Array = data.get("biomes", [])
		if biomes.has(biome):
			candidates.append(String(mob_id))
	if candidates.is_empty():
		return ""
	return String(candidates[rng.randi_range(0, candidates.size() - 1)])

func _random_mob_spawn_position() -> Vector2:
	var angle := randf() * TAU
	var distance := randf_range(140.0, mob_spawn_radius)
	return Vector2(cos(angle), sin(angle)) * distance

func _pick_weighted_biome(weights: Dictionary, rng: RandomNumberGenerator) -> String:
	var total := 0.0
	for value in weights.values():
		total += float(value)
	if total <= 0.0:
		return "grassland"
	var roll := rng.randf_range(0.0, total)
	var running := 0.0
	for biome in weights.keys():
		running += float(weights[biome])
		if roll <= running:
			return biome
	return "grassland"

func _pick_resource_for_biome(biome: String, rng: RandomNumberGenerator) -> String:
	var options := {
		"grassland": {"wood": 0.25, "fiber": 0.35, "berry": 0.2, "stone": 0.2},
		"forest": {"wood": 0.55, "fiber": 0.2, "berry": 0.15, "stone": 0.1},
		"desert": {"stone": 0.55, "fiber": 0.25, "wood": 0.1, "berry": 0.1},
		"tundra": {"stone": 0.4, "wood": 0.2, "berry": 0.2, "fiber": 0.2}
	}
	var pool: Dictionary = options.get(biome, options["grassland"])
	var total := 0.0
	for value in pool.values():
		total += float(value)
	var roll := rng.randf_range(0.0, total)
	var running := 0.0
	for resource_id in pool.keys():
		running += float(pool[resource_id])
		if roll <= running:
			return resource_id
	return "wood"

func get_world_settings() -> WorldSettings:
	return world_settings

func _apply_world_settings() -> void:
	if world_settings == null:
		world_settings = WorldSettings.new()
	if world_settings.difficulty == WorldSettings.Difficulty.HARDCORE:
		world_settings.allow_respawn = false
	var mob_multiplier := world_settings.get_mob_spawn_multiplier()
	if world_settings.difficulty == WorldSettings.Difficulty.EASY:
		mob_multiplier = EASY_MOB_MULTIPLIER
	var spawn_mobs := world_settings.enable_hostile_mobs or world_settings.difficulty == WorldSettings.Difficulty.PEACEFUL
	if spawn_mobs:
		mob_count = int(round(base_mob_count * mob_multiplier))
		mob_density = base_mob_density * mob_multiplier
	else:
		mob_count = 0
		mob_density = 0.0

	needs.enabled = world_settings.enable_needs
	if needs.enabled:
		needs.apply_difficulty_settings(world_settings)
		if world_settings.difficulty == WorldSettings.Difficulty.EASY:
			needs.hunger_decay_multiplier = EASY_NEEDS_DECAY_MULTIPLIER
			needs.thirst_decay_multiplier = EASY_NEEDS_DECAY_MULTIPLIER
	else:
		needs.reset_stats()

func _is_mob_behavior_allowed(data: Dictionary) -> bool:
	if world_settings == null:
		return true
	var allowed := world_settings.get_allowed_mob_behaviors()
	if allowed.is_empty():
		return true
	return allowed.has(String(data.get("behavior", "passive")))

func _check_player_death() -> void:
	## Minimal death handling: either respawn or lock controls based on world settings.
	if player_dead or needs == null:
		return
	if needs.health > 0.0:
		return
	player_dead = true
	if world_settings == null or world_settings.allow_respawn:
		_respawn_player()
	else:
		_disable_player()

func _respawn_player() -> void:
	if player == null or needs == null:
		return
	player.global_position = player_spawn_position
	needs.enabled = true
	needs.reset_stats()
	player_dead = false

func _disable_player() -> void:
	if player == null or needs == null:
		return
	needs.enabled = false
	player.set_physics_process(false)
	player.set_process(false)
