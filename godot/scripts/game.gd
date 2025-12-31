extends Node2D

## Main world controller: spawns resources, wires systems, and updates HUD.

const RESOURCE_NODE_SCENE := preload("res://scenes/ResourceNode.tscn")
const MOB_SCENE := preload("res://scenes/Mob.tscn")

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

var player: CharacterBody2D
var hud: CanvasLayer
var world: Node2D
var world_generator: WorldGenerator

func _ready() -> void:
	randomize()
	world = $World
	player = $Player
	hud = $HUD
	world_generator = $World/WorldGenerator

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

	player.set_systems(inventory, needs, crafting, item_db)
	hud.bind_systems(inventory, needs, item_db, crafting)

	_generate_world()
	_spawn_resources()
	_spawn_mobs()
	_seed_starting_items()

func _process(delta: float) -> void:
	needs.tick(delta)

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
		var position := world_generator.get_world_position_for_cell(cell)
		if player != null and position.distance_to(player.global_position) < 64.0:
			continue
		_spawn_resource_node(resource_id, position)
	for i in range(resource_count):
		var water_cell := world_generator.get_random_cell_in_biome("water")
		if water_cell != Vector2i.ZERO:
			_spawn_resource_node("water", world_generator.get_world_position_for_cell(water_cell))

func _random_spawn_position() -> Vector2:
	var angle := randf() * TAU
	var distance := randf_range(120.0, spawn_radius)
	return Vector2(cos(angle), sin(angle)) * distance

func _seed_starting_items() -> void:
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
		var position := _random_mob_spawn_position()
		_spawn_mob(mob_id, position)

func _generate_world() -> void:
	if world_generator == null:
		return
	var seed := world_seed if world_seed != 0 else randi()
	world_generator.generate(seed)

func _spawn_resource_node(resource_id: String, position: Vector2) -> void:
	var node := RESOURCE_NODE_SCENE.instantiate()
	node.resource_id = resource_id
	node.global_position = position
	world.add_child(node)

func _spawn_mob(mob_id: String, position: Vector2) -> void:
	if mob_db == null:
		return
	var mob := MOB_SCENE.instantiate()
	if mob is Mob:
		var data := mob_db.get_mob(mob_id).duplicate(true)
		data["id"] = mob_id
		mob.apply_definition(data)
		mob.set_target(player, needs)
	mob.global_position = position
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
		var position := world_generator.get_world_position_for_cell(cell)
		if player != null and position.distance_to(player.global_position) < 120.0:
			continue
		_spawn_mob(mob_id, position)

func _pick_mob_for_biome(biome: String, rng: RandomNumberGenerator) -> String:
	if mob_db == null:
		return ""
	var candidates: Array = []
	for mob_id in mob_db.all_mobs():
		var data: Dictionary = mob_db.get_mob(String(mob_id))
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
