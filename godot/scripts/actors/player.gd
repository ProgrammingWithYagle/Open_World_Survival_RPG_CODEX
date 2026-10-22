extends Node2D
class_name MossPlayer

var world_view: MossWorldView
var sprite: Sprite2D
var facing := Vector2.DOWN
var direction_row := 0
var animation_clock := 0.0
var action_clock := 0.0
var dodge_clock := 0.0
var invulnerable := 0.0
var footsteps := 0.0
var weapon_hit := false
var attack_direction := Vector2.DOWN
var textures: Dictionary = {}
var moving := false
var sprinting := false
var velocity := Vector2.ZERO
var last_action := ""
var weapon_sprite: Sprite2D
var gather_target: Dictionary = {}


func _ready() -> void:
	sprite = Sprite2D.new()
	sprite.centered = false
	sprite.offset = Vector2(-32, -64)
	var material_ := ShaderMaterial.new()
	material_.shader = world_view.alpha_shader
	sprite.material = material_
	add_child(sprite)
	weapon_sprite = Sprite2D.new()
	weapon_sprite.centered = false
	weapon_sprite.offset = Vector2(-16, -29)
	weapon_sprite.material = material_
	add_child(weapon_sprite)


func _physics_process(delta: float) -> void:
	if Session.state.is_empty():
		return
	invulnerable = maxf(0.0, invulnerable - delta)
	if Session.paused or bool(Session.state.player.dead):
		velocity = Vector2.ZERO
		_animate(delta)
		return
	var input_direction := Input.get_vector("move_left", "move_right", "move_up", "move_down", .2)
	moving = input_direction.length() > .1
	sprinting = (
		moving and Input.is_action_pressed("sprint") and float(Session.state.player.stamina) > 10
	)
	if moving and action_clock <= 0:
		facing = input_direction.normalized()
	var speed := 93.0
	if Session.has_buff("haste"):
		speed *= 1.1
	if Session.has_charm("speed"):
		speed *= 1.08
	if Session.has_perk("trailfeet"):
		speed *= 1.12
	var region := Session.world_model.region_at(Vector2i(position / 32.0))
	if Session.state.restored[region] and Session.state.attunements[region] == "gale":
		speed *= 1.2
	if sprinting:
		speed *= 1.45
		var cost := 25.0 * (.7 if Session.has_buff("endurance") else 1.0)
		if Session.state.restored[region] and Session.state.attunements[region] == "gale":
			cost *= .8
		Session.state.player.stamina = maxf(0, float(Session.state.player.stamina) - delta * cost)
		Session.state.player.stamina_delay = float(Session.state.time) + .18
	if dodge_clock > 0:
		dodge_clock = maxf(0, dodge_clock - delta)
		velocity = attack_direction * 185
	else:
		velocity = input_direction * speed * (.45 if action_clock > 0 else 1.0)
	_move(velocity * delta)
	Session.set_player_position(position)
	if moving and dodge_clock <= 0:
		footsteps += delta
		if footsteps > (.22 if sprinting else .32):
			footsteps = 0
			Sound.effect("step_%d" % int((Time.get_ticks_msec() / 230) % 6), .98)
	if action_clock > 0:
		action_clock = maxf(0, action_clock - delta)
		if action_clock < .34 and not weapon_hit:
			weapon_hit = true
			_hit()
	_animate(delta)
	queue_redraw()


func _move(offset: Vector2) -> void:
	var horizontal := position + Vector2(offset.x, 0)
	if _fits(horizontal):
		position = horizontal
	var vertical := position + Vector2(0, offset.y)
	if _fits(vertical):
		position = vertical


func _fits(pos: Vector2) -> bool:
	if not Session.state.get("expedition_run", {}).is_empty():
		var region := int(Activities.site_definition(str(Session.state.expedition_run.site)).region)
		var center := Vector2(Session.world_model.arena_cell(region) * 32) + Vector2(16, 16)
		if absf(pos.x - center.x) > 275 or absf(pos.y - center.y) > 230:
			return false
	for corner in [Vector2(-5, -4), Vector2(5, -4), Vector2(-5, 3), Vector2(5, 3)]:
		if not Session.world_model.passable(Vector2i((pos + corner) / 32.0), Session.state):
			return false
	return true


func attack() -> void:
	if action_clock > 0 or dodge_clock > 0 or Session.paused:
		return
	var definition: Dictionary = Content.items.get(str(Session.state.equipped), {})
	if str(definition.get("style", "")) == "fish":
		world_view.interact()
		return
	if float(Session.state.player.stamina) < 7:
		return
	var aim := world_view.aim_position() - global_position
	var stick := Vector2(
		Input.get_joy_axis(0, JOY_AXIS_RIGHT_X), Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
	)
	facing = _aim_direction(aim, stick)
	attack_direction = facing
	Session.state.player.stamina = float(Session.state.player.stamina) - 7
	Session.state.player.stamina_delay = float(Session.state.time) + .3
	action_clock = .63
	animation_clock = 0
	weapon_hit = false
	gather_target = {}
	Sound.effect(
		(
			"bow"
			if definition.get("style", "") == "bow"
			else "spell" if definition.get("style", "") == "focus" else "swing"
		)
	)


func _aim_direction(pointer_delta: Vector2, stick: Vector2) -> Vector2:
	if stick.length() > .25:
		return stick.normalized()
	return pointer_delta.normalized() if pointer_delta.length() >= 8 else facing


func gather(target: Dictionary) -> void:
	if action_clock > 0 or dodge_clock > 0:
		return
	var node := Session.world_model.node_at(target.cell)
	var style := (
		"axe" if node.get("id", "") == "wood" else "pick" if bool(node.get("solid", false)) else ""
	)
	var best := 0
	for id in Session.state.inventory:
		var item: Dictionary = Content.items[id]
		if not style.is_empty() and item.get("style", "") == style and int(item.tier) > best:
			best = int(item.tier)
			Session.state.equipped = id
	attack()
	if action_clock <= 0:
		return
	gather_target = target.duplicate()
	attack_direction = (Vector2(target.position) - position).normalized()
	facing = attack_direction


func dodge() -> void:
	if dodge_clock > 0 or Session.paused or float(Session.state.player.stamina) < 24:
		return
	Session.state.player.stamina = float(Session.state.player.stamina) - 24
	Session.state.player.stamina_delay = float(Session.state.time) + .45
	var input_direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	attack_direction = input_direction.normalized() if input_direction.length() > .1 else facing
	dodge_clock = .36
	invulnerable = .25
	animation_clock = 0
	Sound.effect("swing", 1.15)


func _hit() -> void:
	if bool(Session.state.player.dead):
		return
	if not gather_target.is_empty():
		if position.distance_to(gather_target.position) < 62:
			world_view.harvest(gather_target)
		gather_target = {}
		return
	var definition: Dictionary = Content.items.get(str(Session.state.equipped), {})
	var style: String = str(definition.get("style", "blade"))
	var damage := (
		float(definition.get("damage", 3)) * (1.15 if Session.has_perk("steady_hand") else 1.0)
	)
	if Session.has_buff("focus"):
		damage *= 1.1
	if Session.has_charm("damage"):
		damage *= 1.12
	if style in ["bow", "focus"]:
		var projectile := MossProjectile.new()
		projectile.position = position + Vector2(0, -16) + attack_direction * 13
		projectile.direction = attack_direction
		projectile.damage = damage
		projectile.friendly = true
		projectile.world_view = world_view
		projectile.magic = style == "focus"
		world_view.entities.add_child(projectile)
		return
	var reach := float(definition.get("reach", 45))
	for actor in world_view.actors.values():
		if not is_instance_valid(actor) or actor.dying:
			continue
		var offset: Vector2 = actor.position - position
		if (
			offset.length() < reach + float(actor.radius)
			and offset.normalized().dot(attack_direction) > .05
		):
			if _clear_path(actor.position):
				actor.take_hit(damage, attack_direction)
	world_view._find_target()
	if not world_view.target.is_empty() and world_view.target.has("data"):
		var data: Dictionary = world_view.target.data
		if not data.has("npc") and not data.has("waystone") and not data.has("structure"):
			world_view.harvest(world_view.target)


func _clear_path(to: Vector2) -> bool:
	var count := maxi(1, ceili(position.distance_to(to) / 12.0))
	for i in range(1, count):
		var cell := Vector2i(position.lerp(to, float(i) / count) / 32.0)
		if not Session.world_model.passable(cell, Session.state):
			return false
	return true


func take_hit(damage: float, from: Vector2) -> void:
	if invulnerable > 0:
		return
	invulnerable = .55
	Session.hurt(damage)
	_move((position - from).normalized() * 8)


func _animate(delta: float) -> void:
	animation_clock += delta
	if absf(facing.x) > absf(facing.y):
		direction_row = 2 if facing.x > 0 else 1
	else:
		direction_row = 0 if facing.y >= 0 else 3
	var action := "walk" if moving else "idle"
	var frames := 8 if moving else 4
	var fps := 12.0 if sprinting else 9.0 if moving else 5.0
	if action_clock > 0:
		action = "attack"
		frames = 8
		fps = 12.0
	if dodge_clock > 0:
		action = "dodge"
		frames = 6
		fps = 18.0
	if bool(Session.state.player.dead):
		action = "death"
		frames = 8
		fps = 9.0
	if action != last_action:
		animation_clock = 0
		last_action = action
	var texture := _sheet(action)
	if texture == null:
		texture = _sheet("walk")
		frames = 8
	if texture == null:
		return
	sprite.texture = texture
	sprite.hframes = frames
	sprite.vframes = 4
	var index := int(animation_clock * fps) % frames
	if action == "attack":
		index = mini(frames - 1, int((1.0 - action_clock / .63) * frames))
	if action == "dodge":
		index = mini(frames - 1, int((1.0 - dodge_clock / .36) * frames))
	if not moving and action == "idle" and _sheet("idle") == null:
		index = 0
	if action == "death":
		index = mini(frames - 1, int(animation_clock * fps))
	sprite.frame = direction_row * frames + index
	sprite.modulate = Color(1, .55, .45) if invulnerable > .36 else Color.WHITE
	_animate_weapon(action, index)


func _animate_weapon(action: String, index: int) -> void:
	var definition: Dictionary = Content.items.get(str(Session.state.equipped), {})
	weapon_sprite.visible = not definition.is_empty() and not action in ["dodge", "death"]
	if not weapon_sprite.visible:
		return
	weapon_sprite.texture = Content.icon(str(Session.state.equipped))
	var hand := Vector2(-10, -21) if direction_row == 1 else Vector2(11, -21)
	weapon_sprite.z_index = -1 if direction_row == 3 else 1
	weapon_sprite.position = hand
	weapon_sprite.rotation = (-.3 if direction_row in [0, 2] else .3)
	if action == "attack":
		var style := str(definition.get("style", "blade"))
		var progress := float(index) / 7.0
		var thrust := sin(clampf((progress - .2) / .65, 0, 1) * PI)
		weapon_sprite.position = hand + attack_direction * thrust * (20 if style == "spear" else 8)
		weapon_sprite.rotation = attack_direction.angle() + PI / 2
		if style in ["blade", "axe", "pick"]:
			weapon_sprite.rotation += lerpf(-1.1, 1.1, clampf((progress - .15) / .6, 0, 1))
	weapon_sprite.position = weapon_sprite.position.round()


func _sheet(action: String) -> Texture2D:
	if textures.has(action):
		return textures[action]
	var path := "res://art/sprites/player_%s.png" % action
	if not ResourceLoader.exists(path):
		return null
	var texture: Texture2D = load(path)
	textures[action] = texture
	return texture


func _draw() -> void:
	# A readable weapon arc is gameplay feedback, independent of the sprite pose.
	if action_clock > .15 and action_clock < .38:
		var angle := attack_direction.angle()
		draw_arc(Vector2(0, -13), 27, angle - .75, angle + .75, 12, Color(.98, .86, .58, .8), 2)
