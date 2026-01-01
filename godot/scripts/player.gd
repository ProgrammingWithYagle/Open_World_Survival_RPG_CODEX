extends CharacterBody2D

## Player controller handling movement, interaction, and crafting input.

@export var move_speed := 180.0
@export var sprint_multiplier := 1.5
@export var sprint_min_stamina := 10.0
## Camera zoom for the player view (set on the Camera2D child in _ready()).
@export var zoom_level := Vector2(2.0, 2.0)

const ART_ROOT := "res://art"
const FRAME_SIZE := Vector2i(32, 32)
const ACTION_IDLE := "idle"
const ACTION_WALK := "walk"
const ACTION_ATTACK := "attack"
const ACTION_DEATH := "death"
const DIRECTION_NORTH := "north"
const DIRECTION_SOUTH := "south"
const DIRECTION_EAST := "east"
const DIRECTION_WEST := "west"
const ACTION_FRAME_COUNTS := {
	ACTION_IDLE: 1,
	ACTION_WALK: 4,
	ACTION_ATTACK: 4,
	ACTION_DEATH: 4
}
const ACTION_FPS := {
	ACTION_IDLE: 1.0,
	ACTION_WALK: 8.0,
	ACTION_ATTACK: 10.0,
	ACTION_DEATH: 6.0
}
const ACTION_LOOP := {
	ACTION_IDLE: true,
	ACTION_WALK: true,
	ACTION_ATTACK: false,
	ACTION_DEATH: false
}
const DIRECTIONS := [DIRECTION_NORTH, DIRECTION_SOUTH, DIRECTION_EAST, DIRECTION_WEST]

var inventory: Inventory
var needs: Needs
var crafting: Crafting
var item_db: ItemDB

var interact_area: Area2D
var current_target: Area2D
var last_direction := DIRECTION_SOUTH

func _ready() -> void:
	interact_area = $InteractArea
	interact_area.collision_layer = 0
	interact_area.collision_mask = 1
	_configure_collision()
	_configure_sprite()
	_configure_camera()
	interact_area.area_entered.connect(_on_area_entered)
	interact_area.area_exited.connect(_on_area_exited)

func _physics_process(delta: float) -> void:
	var direction := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)
	var is_moving := direction.length() > 0.0
	var wants_sprint := Input.is_action_pressed("sprint")
	var can_sprint := needs != null and needs.stamina >= sprint_min_stamina
	var is_sprinting := is_moving and wants_sprint and can_sprint
	var speed := move_speed * (sprint_multiplier if is_sprinting else 1.0)
	velocity = direction.normalized() * speed
	_update_animation(direction, is_moving)
	_update_stamina_from_movement(delta, is_moving, is_sprinting)
	move_and_slide()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("interact"):
		_try_harvest()
	if Input.is_action_just_pressed("craft"):
		_try_craft_first_recipe()
	if Input.is_action_just_pressed("consume"):
		_try_consume()

func set_systems(new_inventory: Inventory, new_needs: Needs, new_crafting: Crafting, new_item_db: ItemDB) -> void:
	inventory = new_inventory
	needs = new_needs
	crafting = new_crafting
	item_db = new_item_db

func _try_harvest() -> void:
	if current_target == null:
		return
	if current_target.has_method("harvest"):
		var result: Dictionary = current_target.harvest()
		if result.has("id"):
			var count := int(result["count"])
			if inventory.has_item("stone_knife", 1) and result["id"] in ["wood", "fiber"]:
				count += 1
			inventory.add_item(result["id"], count)
			_apply_action_stamina_cost()

func _try_craft_first_recipe() -> void:
	if crafting == null:
		return
	var recipe_ids := crafting.get_recipe_ids()
	if recipe_ids.is_empty():
		return
	recipe_ids.sort()
	var recipe_id: String = String(recipe_ids[0])
	if crafting.craft(inventory, recipe_id):
		_apply_recipe_effects(recipe_id)
		_apply_action_stamina_cost()

func _apply_recipe_effects(recipe_id: String) -> void:
	if recipe_id == "campfire":
		needs.temperature = clampf(needs.temperature + 5.0, -10.0, 45.0)
		needs.emit_signal("needs_changed")

func _try_consume() -> void:
	if inventory == null or needs == null or item_db == null:
		return
	var counts := inventory.get_counts()
	var best_item := ""
	var best_score := -1.0
	for item_id in counts.keys():
		if counts[item_id] <= 0:
			continue
		var effects := item_db.get_effects(item_id)
		if effects.is_empty():
			continue
		var score := 0.0
		score += maxf(float(effects.get("hunger", 0.0)), 0.0)
		score += maxf(float(effects.get("thirst", 0.0)), 0.0)
		score += maxf(float(effects.get("health", 0.0)), 0.0)
		score += maxf(float(effects.get("temperature", 0.0)), 0.0)
		if score > best_score:
			best_score = score
			best_item = item_id
	if best_item == "":
		return
	if inventory.remove_item(best_item, 1):
		needs.apply_item_effects(item_db.get_effects(best_item))
		_apply_action_stamina_cost(0.5)

func _on_area_entered(area: Area2D) -> void:
	current_target = area

func _on_area_exited(area: Area2D) -> void:
	if current_target == area:
		current_target = null

func _configure_collision() -> void:
	var body_collision := $Collision
	if body_collision.shape == null:
		body_collision.shape = CircleShape2D.new()
	if body_collision.shape is CircleShape2D:
		body_collision.shape.radius = 8.0
	var interact_collision := $InteractArea/InteractCollision
	if interact_collision.shape == null:
		interact_collision.shape = CircleShape2D.new()
	if interact_collision.shape is CircleShape2D:
		interact_collision.shape.radius = 18.0

func _configure_sprite() -> void:
	# Configure animation frames from sprite sheets in res://art without procedural textures.
	var sprite := $Sprite as AnimatedSprite2D
	if sprite == null:
		return
	sprite.sprite_frames = _build_sprite_frames()
	_play_directional_animation(sprite, ACTION_IDLE)

func _build_sprite_frames() -> SpriteFrames:
	## Loads directional sprite sheets into a SpriteFrames resource for the player.
	var frames := SpriteFrames.new()
	for action in ACTION_FRAME_COUNTS.keys():
		for direction in DIRECTIONS:
			var animation_name := "%s_%s" % [action, direction]
			var texture_path := "%s/player_%s_%s.png" % [ART_ROOT, action, direction]
			if _add_strip_animation(frames, animation_name, texture_path, ACTION_FRAME_COUNTS[action]):
				frames.set_animation_speed(animation_name, ACTION_FPS.get(action, 8.0))
				frames.set_animation_loop(animation_name, ACTION_LOOP.get(action, true))
	return frames

func _add_strip_animation(frames: SpriteFrames, animation_name: String, texture_path: String, frame_count: int) -> bool:
	if not ResourceLoader.exists(texture_path):
		return false
	var texture: Texture2D = load(texture_path)
	if texture == null:
		return false
	if not frames.has_animation(animation_name):
		frames.add_animation(animation_name)
	for frame_index in range(frame_count):
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2i(frame_index * FRAME_SIZE.x, 0, FRAME_SIZE.x, FRAME_SIZE.y)
		frames.add_frame(animation_name, atlas)
	return true

func _update_animation(direction: Vector2, is_moving: bool) -> void:
	var sprite := $Sprite as AnimatedSprite2D
	if sprite == null:
		return
	if direction.length() > 0.0:
		last_direction = _direction_label_from_vector(direction)
	var action := ACTION_WALK if is_moving else ACTION_IDLE
	_play_directional_animation(sprite, action)

func _direction_label_from_vector(direction: Vector2) -> String:
	if absf(direction.x) > absf(direction.y):
		return DIRECTION_EAST if direction.x > 0.0 else DIRECTION_WEST
	return DIRECTION_SOUTH if direction.y > 0.0 else DIRECTION_NORTH

func _play_directional_animation(sprite: AnimatedSprite2D, action: String) -> void:
	if sprite.sprite_frames == null:
		return
	var animation_name := "%s_%s" % [action, last_direction]
	if sprite.sprite_frames.has_animation(animation_name):
		if sprite.animation != animation_name or not sprite.is_playing():
			sprite.play(animation_name)
		return
	var fallback := "%s_%s" % [ACTION_IDLE, DIRECTION_SOUTH]
	if sprite.sprite_frames.has_animation(fallback):
		if sprite.animation != fallback or not sprite.is_playing():
			sprite.play(fallback)

func _configure_camera() -> void:
	var camera := $Camera2D
	if camera != null:
		# Godot 4 uses make_current() instead of a writable "current" property.
		camera.make_current()
		camera.zoom = zoom_level

func _update_stamina_from_movement(delta: float, is_moving: bool, is_sprinting: bool) -> void:
	if needs == null:
		return
	needs.is_resting = not is_moving
	var extra_drain := 0.0
	if is_moving:
		extra_drain += needs.stamina_move_drain
	if is_sprinting:
		extra_drain += needs.stamina_sprint_drain
	if extra_drain > 0.0:
		needs.apply_stamina_drain(extra_drain * delta)

func _apply_action_stamina_cost(multiplier: float = 1.0) -> void:
	if needs == null:
		return
	needs.apply_action_stamina_cost(multiplier)
