extends CharacterBody2D
class_name Mob

## Lightweight, data-driven mob controller.
## Each mob is configured via JSON and receives its data through apply_definition().

enum Behavior { PASSIVE, AGGRESSIVE, RANGED, PATROL }

@export var mob_id := ""
@export var display_name := ""
@export var behavior := Behavior.PASSIVE
@export var max_health := 30.0
@export var move_speed := 90.0
@export var aggro_range := 160.0
@export var attack_range := 28.0
@export var attack_cooldown := 1.2
@export var damage := 6.0
@export var patrol_radius := 120.0
@export var body_color := Color(0.8, 0.8, 0.8)

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
const ATTACK_ANIM_DURATION := 0.35
const DEATH_ANIM_DURATION := 0.7

var current_health := 0.0
var target: Node2D
var target_needs: Needs
var rng := RandomNumberGenerator.new()
var wander_target := Vector2.ZERO
var patrol_points: Array = []
var patrol_index := 0
var attack_timer := 0.0
## When true, hostile behaviors are suppressed (used for Peaceful difficulty).
var peaceful_mode := false
var last_direction := DIRECTION_SOUTH
var attack_anim_timer := 0.0
var is_dead := false
var death_timer := 0.0

func _ready() -> void:
	rng.randomize()
	if current_health <= 0.0:
		current_health = max_health
	_configure_sprite()
	_configure_collision()
	_build_patrol_points()

func _physics_process(delta: float) -> void:
	if is_dead:
		death_timer = maxf(death_timer - delta, 0.0)
		if death_timer <= 0.0:
			queue_free()
		return
	attack_timer = maxf(attack_timer - delta, 0.0)
	attack_anim_timer = maxf(attack_anim_timer - delta, 0.0)
	_update_behavior(delta)
	_update_animation()
	move_and_slide()

func apply_definition(data: Dictionary) -> void:
	## Map JSON fields onto exported properties for easy tuning.
	mob_id = data.get("id", mob_id)
	display_name = data.get("name", display_name)
	behavior = _behavior_from_string(data.get("behavior", "passive"))
	max_health = float(data.get("health", max_health))
	move_speed = float(data.get("speed", move_speed))
	aggro_range = float(data.get("aggro_range", aggro_range))
	attack_range = float(data.get("attack_range", attack_range))
	attack_cooldown = float(data.get("attack_cooldown", attack_cooldown))
	damage = float(data.get("damage", damage))
	patrol_radius = float(data.get("patrol_radius", patrol_radius))
	if data.has("color"):
		body_color = Color(data["color"][0], data["color"][1], data["color"][2])
	current_health = max_health
	_configure_sprite()
	_build_patrol_points()

func set_target(new_target: Node2D, needs: Needs) -> void:
	target = new_target
	target_needs = needs

func set_peaceful_mode(enabled: bool) -> void:
	peaceful_mode = enabled
	if peaceful_mode and behavior != Behavior.PASSIVE:
		behavior = Behavior.PASSIVE
		_build_patrol_points()

func take_damage(amount: float) -> void:
	current_health = clampf(current_health - amount, 0.0, max_health)
	if current_health <= 0.0:
		_start_death()

func _update_behavior(delta: float) -> void:
	if peaceful_mode and behavior != Behavior.PASSIVE:
		_wander(delta)
		return
	match behavior:
		Behavior.PASSIVE:
			_wander(delta)
		Behavior.AGGRESSIVE:
			_chase_target()
		Behavior.RANGED:
			_kite_target()
		Behavior.PATROL:
			_patrol(delta)

func _wander(_delta: float) -> void:
	if wander_target == Vector2.ZERO or global_position.distance_to(wander_target) < 12.0:
		wander_target = global_position + Vector2(rng.randf_range(-80, 80), rng.randf_range(-80, 80))
	_move_towards(wander_target)

func _chase_target() -> void:
	if target == null:
		velocity = Vector2.ZERO
		return
	var distance := global_position.distance_to(target.global_position)
	if distance <= aggro_range:
		velocity = (target.global_position - global_position).normalized() * move_speed
		if distance <= attack_range:
			_try_attack()
	else:
		velocity = Vector2.ZERO

func _kite_target() -> void:
	if target == null:
		velocity = Vector2.ZERO
		return
	var distance := global_position.distance_to(target.global_position)
	if distance <= aggro_range:
		if distance < attack_range * 0.8:
			velocity = (global_position - target.global_position).normalized() * move_speed
		else:
			velocity = (target.global_position - global_position).normalized() * move_speed * 0.6
		if distance <= attack_range:
			_try_attack()
	else:
		velocity = Vector2.ZERO

func _patrol(_delta: float) -> void:
	if patrol_points.is_empty():
		_build_patrol_points()
	var target_point: Vector2 = patrol_points[patrol_index]
	if global_position.distance_to(target_point) < 16.0:
		patrol_index = (patrol_index + 1) % patrol_points.size()
		target_point = patrol_points[patrol_index]
	_move_towards(target_point)
	if target != null and global_position.distance_to(target.global_position) <= aggro_range:
		_try_attack()

func _move_towards(target_point: Vector2) -> void:
	var direction := (target_point - global_position).normalized()
	velocity = direction * move_speed

func _try_attack() -> void:
	if peaceful_mode:
		return
	if attack_timer > 0.0:
		return
	attack_timer = attack_cooldown
	if _has_directional_animation(ACTION_ATTACK):
		attack_anim_timer = ATTACK_ANIM_DURATION
	if target_needs != null:
		target_needs.health = clampf(target_needs.health - damage, 0.0, target_needs.max_health)
		target_needs.emit_signal("needs_changed")

func _configure_sprite() -> void:
	# Configure animation frames from sprite sheets in res://art without procedural textures.
	var sprite := $Sprite as AnimatedSprite2D
	if sprite == null:
		return
	sprite.sprite_frames = _build_sprite_frames()
	_play_directional_animation(sprite, ACTION_IDLE)

func _build_sprite_frames() -> SpriteFrames:
	## Loads directional sprite sheets into a SpriteFrames resource for this mob.
	var frames := SpriteFrames.new()
	if mob_id == "":
		return frames
	for action in ACTION_FRAME_COUNTS.keys():
		for direction in DIRECTIONS:
			var animation_name := "%s_%s" % [action, direction]
			var texture_path := "%s/mob_%s_%s_%s.png" % [ART_ROOT, mob_id, action, direction]
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

func _update_animation() -> void:
	var sprite := $Sprite as AnimatedSprite2D
	if sprite == null:
		return
	if velocity.length() > 0.0:
		last_direction = _direction_label_from_vector(velocity)
	var action := ACTION_WALK if velocity.length() > 0.1 else ACTION_IDLE
	if attack_anim_timer > 0.0:
		action = ACTION_ATTACK
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

func _has_directional_animation(action: String) -> bool:
	var sprite := $Sprite as AnimatedSprite2D
	if sprite == null or sprite.sprite_frames == null:
		return false
	return sprite.sprite_frames.has_animation("%s_%s" % [action, last_direction])

func _start_death() -> void:
	var sprite := $Sprite as AnimatedSprite2D
	if sprite != null and sprite.sprite_frames != null:
		var animation_name := "%s_%s" % [ACTION_DEATH, last_direction]
		if sprite.sprite_frames.has_animation(animation_name):
			is_dead = true
			death_timer = DEATH_ANIM_DURATION
			velocity = Vector2.ZERO
			sprite.play(animation_name)
			var collision := $Collision
			if collision != null:
				collision.disabled = true
			return
	queue_free()

func _configure_collision() -> void:
	var body_collision := $Collision
	if body_collision.shape == null:
		body_collision.shape = CircleShape2D.new()
	if body_collision.shape is CircleShape2D:
		body_collision.shape.radius = 7.0

func _build_patrol_points() -> void:
	patrol_points.clear()
	patrol_index = 0
	if behavior != Behavior.PATROL:
		return
	for i in range(4):
		var angle := i * TAU / 4.0
		var offset := Vector2(cos(angle), sin(angle)) * patrol_radius
		patrol_points.append(global_position + offset)

func _behavior_from_string(value: String) -> Behavior:
	match value:
		"aggressive":
			return Behavior.AGGRESSIVE
		"ranged":
			return Behavior.RANGED
		"patrol":
			return Behavior.PATROL
		_:
			return Behavior.PASSIVE
