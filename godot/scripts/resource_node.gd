extends Area2D

## Harvestable resource nodes (trees, rocks, bushes) placed in the world.

@export var resource_id: String = "wood"
@export var amount := 3
@export var yield_per_hit := 1
@export var sprite_size := 32

var sprite: Sprite2D
var collision: CollisionShape2D

func _ready() -> void:
	sprite = $Sprite
	collision = $Collision
	_apply_visuals()
	_configure_collision()

func _apply_visuals() -> void:
	var base_color := _color_for_resource(resource_id)
	var shadow := base_color.darkened(0.25)
	var highlight := base_color.lightened(0.25)
	var image := Image.create(sprite_size, sprite_size, false, Image.FORMAT_RGBA8)
	image.fill(base_color)
	_draw_border(image, shadow)
	_add_detail_speckles(image, highlight)
	if resource_id == "water":
		_add_ripple(image, highlight)
	var texture := ImageTexture.create_from_image(image)
	sprite.texture = texture
	sprite.rotation = randf_range(-0.2, 0.2)
	sprite.scale = Vector2.ONE * randf_range(0.9, 1.1)

func _configure_collision() -> void:
	if collision.shape == null:
		collision.shape = CircleShape2D.new()
	if collision.shape is CircleShape2D:
		collision.shape.radius = sprite_size * 0.45

func harvest() -> Dictionary:
	if amount <= 0:
		return {}
	amount -= yield_per_hit
	if amount <= 0:
		queue_free()
	return {"id": resource_id, "count": yield_per_hit}

func _draw_border(image: Image, color: Color) -> void:
	for x in range(sprite_size):
		image.set_pixel(x, 0, color)
		image.set_pixel(x, sprite_size - 1, color)
	for y in range(sprite_size):
		image.set_pixel(0, y, color)
		image.set_pixel(sprite_size - 1, y, color)

func _add_detail_speckles(image: Image, color: Color) -> void:
	var speckle_count := int(sprite_size * 1.5)
	for i in range(speckle_count):
		var px := randi_range(2, sprite_size - 3)
		var py := randi_range(2, sprite_size - 3)
		image.set_pixel(px, py, color)

func _add_ripple(image: Image, color: Color) -> void:
	var center := int(sprite_size * 0.5)
	for x in range(4, sprite_size - 4, 6):
		image.set_pixel(x, center - 3, color)
		image.set_pixel(x + 2, center + 2, color)

func _color_for_resource(kind: String) -> Color:
	match kind:
		"wood":
			return Color(0.42, 0.3, 0.16)
		"stone":
			return Color(0.5, 0.5, 0.55)
		"berry":
			return Color(0.72, 0.2, 0.42)
		"fiber":
			return Color(0.22, 0.58, 0.3)
		"water":
			return Color(0.2, 0.45, 0.85)
		_:
			return Color(0.25, 0.45, 0.25)
