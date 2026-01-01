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

var current_health := 0.0
var target: Node2D
var target_needs: Needs
var rng := RandomNumberGenerator.new()
var wander_target := Vector2.ZERO
var patrol_points: Array = []
var patrol_index := 0
var attack_timer := 0.0

func _ready() -> void:
	rng.randomize()
	if current_health <= 0.0:
		current_health = max_health
	_configure_sprite()
	_configure_collision()
	_build_patrol_points()

func _physics_process(delta: float) -> void:
	attack_timer = maxf(attack_timer - delta, 0.0)
	_update_behavior(delta)
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

func take_damage(amount: float) -> void:
	current_health = clampf(current_health - amount, 0.0, max_health)
	if current_health <= 0.0:
		queue_free()

func _update_behavior(delta: float) -> void:
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
	if attack_timer > 0.0:
		return
	attack_timer = attack_cooldown
	if target_needs != null:
		target_needs.health = clampf(target_needs.health - damage, 0.0, target_needs.max_health)
		target_needs.emit_signal("needs_changed")

func _configure_sprite() -> void:
	var sprite := $Sprite
	var size := 20
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(body_color)
	image.set_pixel(6, 7, body_color.lightened(0.2))
	image.set_pixel(13, 7, body_color.lightened(0.2))
	image.set_pixel(10, 14, body_color.darkened(0.2))
	sprite.texture = ImageTexture.create_from_image(image)

func _configure_collision() -> void:
	var body_collision := $Collision
	if body_collision.shape == null:
		body_collision.shape = CircleShape2D.new()
	if body_collision.shape is CircleShape2D:
		body_collision.shape.radius = 10.0

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
