extends Node2D

## Main world controller: spawns resources, wires systems, and updates HUD.

const RESOURCE_NODE_SCENE := preload("res://scenes/ResourceNode.tscn")

@export var resource_count := 20
@export var spawn_radius := 420.0

var item_db: ItemDB
var inventory: Inventory
var needs: Needs
var crafting: Crafting

var player: CharacterBody2D
var hud: CanvasLayer
var world: Node2D

func _ready() -> void:
    randomize()
    world = $World
    player = $Player
    hud = $HUD

    item_db = ItemDB.new()
    add_child(item_db)

    inventory = Inventory.new()
    add_child(inventory)

    needs = Needs.new()
    add_child(needs)

    crafting = Crafting.new()
    add_child(crafting)

    player.set_systems(inventory, needs, crafting, item_db)
    hud.bind_systems(inventory, needs, item_db, crafting)

    _spawn_resources()
    _seed_starting_items()

func _process(delta: float) -> void:
    needs.tick(delta)

func _spawn_resources() -> void:
    var resource_types := ["wood", "stone", "berry", "fiber", "water"]
    for i in range(resource_count):
        var node := RESOURCE_NODE_SCENE.instantiate()
        node.resource_id = resource_types[randi() % resource_types.size()]
        node.global_position = _random_spawn_position()
        world.add_child(node)

func _random_spawn_position() -> Vector2:
    var angle := randf() * TAU
    var distance := randf_range(120.0, spawn_radius)
    return Vector2(cos(angle), sin(angle)) * distance

func _seed_starting_items() -> void:
    inventory.add_item("berry", 2)
