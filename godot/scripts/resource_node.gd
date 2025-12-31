extends Area2D

## Harvestable resource nodes (trees, rocks, bushes) placed in the world.

@export var resource_id: String = "wood"
@export var amount := 3
@export var yield_per_hit := 1

var sprite: Sprite2D
var collision: CollisionShape2D

func _ready() -> void:
    sprite = $Sprite
    collision = $Collision
    _apply_visuals()
    _configure_collision()

func _apply_visuals() -> void:
    var color := _color_for_resource(resource_id)
    var image := Image.create(24, 24, false, Image.FORMAT_RGBA8)
    image.fill(color)
    var texture := ImageTexture.create_from_image(image)
    sprite.texture = texture

func _configure_collision() -> void:
    if collision.shape == null:
        collision.shape = CircleShape2D.new()
    if collision.shape is CircleShape2D:
        collision.shape.radius = 14.0

func harvest() -> Dictionary:
    if amount <= 0:
        return {}
    amount -= yield_per_hit
    if amount <= 0:
        queue_free()
    return {"id": resource_id, "count": yield_per_hit}

func _color_for_resource(kind: String) -> Color:
    match kind:
        "wood":
            return Color(0.34, 0.23, 0.1)
        "stone":
            return Color(0.45, 0.45, 0.48)
        "berry":
            return Color(0.6, 0.1, 0.35)
        "fiber":
            return Color(0.2, 0.55, 0.25)
        "water":
            return Color(0.1, 0.35, 0.7)
        _:
            return Color(0.2, 0.4, 0.2)
