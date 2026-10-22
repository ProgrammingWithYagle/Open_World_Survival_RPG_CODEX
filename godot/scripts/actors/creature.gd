extends Node2D
class_name MossCreature

var definition: Dictionary
var creature_id: String
var actor_id: String
var world_view: MossWorldView
var health := 30.0
var radius := 9.0
var dying := false
var mode := "wander"
var timer := 0.0
var animation_clock := 0.0
var hurt_timer := 0.0
var direction := Vector2.LEFT
var locked_direction := Vector2.LEFT
var sprite: Sprite2D
var wander_direction := Vector2.ZERO
var wander_timer := 0.0
var sheet: Texture2D
var velocity := Vector2.ZERO
var strike_clock := 0.0


func _ready() -> void:
	radius = 18.0 if definition.boss else 8.0
	sprite = Sprite2D.new()
	sprite.centered = false
	var path := "res://art/sprites/mob_%s.png" % creature_id
	if ResourceLoader.exists(path):
		sheet = load(path)
	if sheet != null:
		sprite.texture = sheet
		sprite.hframes = 8
		sprite.offset = Vector2(-24, -48) if not definition.boss else Vector2(-48, -96)
		var mat := ShaderMaterial.new()
		mat.shader = world_view.alpha_shader
		sprite.material = mat
	add_child(sprite)
	wander_timer = float(Session.world_model.hash_cell(Vector2i(position / 32.0), 17) % 30) / 10.0
	Activities.observe(creature_id, actor_id)


func _physics_process(delta: float) -> void:
	if Session.paused or Session.state.is_empty():
		return
	animation_clock += delta
	hurt_timer = maxf(0, hurt_timer - delta)
	timer = maxf(0, timer - delta)
	strike_clock = maxf(0, strike_clock - delta)
	if dying:
		modulate.a = maxf(0, timer / .55)
		if timer <= 0:
			queue_free()
		return
	var offset := world_view.player.position - position
	var distance := offset.length()
	var peaceful: bool = Session.state.settings.difficulty == "peaceful"
	velocity = Vector2.ZERO
	if definition.passive or peaceful:
		_wander(delta)
		if distance < 65:
			direction = -offset.normalized()
			velocity = direction * float(definition.speed) * 1.2
	elif mode == "windup":
		if timer <= 0:
			_execute_attack()
	elif mode == "charge":
		velocity = locked_direction * float(definition.speed) * 3.5
		if distance < radius + 9:
			world_view.player.take_hit(float(definition.damage), position)
			mode = "recover"
			timer = .7
		elif timer <= 0:
			mode = "recover"
			timer = .8
	elif mode == "recover":
		if timer <= 0:
			mode = "chase"
	elif distance < float(definition.aggro_range) or definition.boss:
		direction = offset.normalized()
		var ranged: bool = "ranged" in str(definition.pattern)
		var attack_distance := (
			150.0
			if ranged
			else (
				96.0
				if "charge" in str(definition.pattern) or "leap" in str(definition.pattern)
				else radius + 26
			)
		)
		if distance < attack_distance:
			mode = "windup"
			timer = .82 if definition.boss else .65
			locked_direction = direction
		else:
			mode = "chase"
			velocity = direction * float(definition.speed)
	else:
		_wander(delta)
	_move(velocity * delta)
	_animate()
	queue_redraw()


func _animate() -> void:
	if sheet != null:
		sprite.flip_h = direction.x > 0
		if mode == "windup":
			sprite.frame = 4 if timer > (.55 if definition.boss else .4) else 5
		elif strike_clock > 0 or mode == "charge":
			sprite.frame = 6
		elif mode == "recover":
			sprite.frame = 7
		else:
			sprite.frame = int(animation_clock * 8) % 4 if velocity.length() > 1 else 0
		sprite.modulate = Color(1.7, .65, .5) if hurt_timer > 0 else Color.WHITE


func _wander(delta: float) -> void:
	wander_timer -= delta
	if wander_timer <= 0:
		var hash_: int = Session.world_model.hash_cell(
			Vector2i(position / 32.0), int(Session.state.time) / 4
		)
		wander_direction = Vector2.from_angle(float(hash_ % 628) / 100.0)
		wander_timer = 2.0 + float(hash_ % 25) / 10.0
	velocity = wander_direction * float(definition.speed) * .35
	direction = wander_direction


func _move(offset: Vector2) -> void:
	var next := position + Vector2(offset.x, 0)
	if Session.world_model.passable(Vector2i(next / 32.0), Session.state):
		position = next
	else:
		wander_timer = 0
	next = position + Vector2(0, offset.y)
	if Session.world_model.passable(Vector2i(next / 32.0), Session.state):
		position = next
	else:
		wander_timer = 0


func _execute_attack() -> void:
	strike_clock = .18
	var pattern: String = str(definition.pattern)
	if "ranged" in pattern:
		var count := 3 if definition.boss and health < float(definition.health) * .5 else 1
		for i in range(count):
			var projectile := MossProjectile.new()
			projectile.position = position + Vector2(0, -14)
			projectile.direction = locked_direction.rotated((i - (count - 1) / 2.0) * .24)
			projectile.friendly = false
			projectile.damage = float(definition.damage)
			projectile.world_view = world_view
			projectile.magic = true
			world_view.entities.add_child(projectile)
		mode = "recover"
		timer = 1.2
	elif "charge" in pattern or "leap" in pattern:
		mode = "charge"
		timer = .42
	else:
		if position.distance_to(world_view.player.position) < radius + 33:
			world_view.player.take_hit(float(definition.damage), position)
		mode = "recover"
		timer = .95


func take_hit(damage: float, push: Vector2) -> void:
	if dying:
		return
	if definition.pattern == "shield" and mode != "recover":
		damage *= .55
	health -= damage
	hurt_timer = .16
	_move(push * 6)
	Sound.effect("hit")
	if health <= 0:
		_die()


func _die() -> void:
	dying = true
	timer = .55
	Session.state.mob_state[actor_id] = {"respawn": float(Session.state.time) + 420.0}
	var rewards: Dictionary = {}
	for drop in definition.drops:
		rewards[str(drop.id)] = int(rewards.get(str(drop.id), 0)) + int(drop.count)
	Session.reward_items(rewards, position)
	Activities.observe(creature_id, actor_id, true)
	Session.gain_xp(10 + int(definition.tier) * 6)
	if definition.boss:
		Session.warden_defeated(int(definition.region))
		Sound.theme(str(Content.regions[int(definition.region)].id))


func persist() -> void:
	if dying:
		return
	Session.state.mob_state[actor_id] = {
		"position": [position.x, position.y],
		"health": health,
		"mode": mode,
		"timer": timer,
		"animation_clock": animation_clock,
		"direction": [direction.x, direction.y]
	}


func _draw() -> void:
	if dying:
		return
	if mode == "windup":
		var color := Color(.93, .48, .27, .55)
		if "charge" in str(definition.pattern) or "leap" in str(definition.pattern):
			draw_line(Vector2.ZERO, locked_direction * 100, color, 15)
		else:
			draw_arc(Vector2.ZERO, 28 if not definition.boss else 43, 0, TAU, 28, color, 2)
	if health < float(definition.health) or definition.boss:
		var width := 42.0 if definition.boss else 24.0
		draw_rect(
			Rect2(-width / 2, -(91 if definition.boss else 48), width, 3), Color(.12, .17, .17)
		)
		draw_rect(
			Rect2(
				-width / 2,
				-(91 if definition.boss else 48),
				width * maxf(0, health / float(definition.health)),
				3
			),
			Color(.79, .38, .29)
		)
