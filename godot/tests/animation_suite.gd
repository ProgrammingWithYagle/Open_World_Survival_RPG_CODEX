extends Node

var main: Node
var stage: Node2D
var output := ""
var players: Array = []
var creatures: Array = []
var actions: Array = ["idle", "walk", "attack", "dodge", "death"]
var faces: Array = [Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT, Vector2.UP]


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--animation_out="):
			output = argument.trim_prefix("--animation_out=")
	if output.is_empty():
		output = ProjectSettings.globalize_path("res://../verification/frames")
	call_deferred("_run")


func _run() -> void:
	main = load("res://scenes/Mossbound.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	Session.active = false
	Session.paused = true
	main.ui.hide()
	main.world_view.hide()
	await get_tree().process_frame
	stage = Node2D.new()
	main.viewport.add_child(stage)
	stage.position = (
		main.world_view.camera.get_screen_center_position() - Vector2(main.viewport.size) / 2
	)
	var background := ColorRect.new()
	background.position = Vector2.ZERO
	background.size = Vector2(640, 360)
	background.color = Color("1b302d")
	stage.add_child(background)
	for row in range(4):
		for col in range(5):
			var actor := MossPlayer.new()
			actor.world_view = main.world_view
			actor.position = Vector2(78 + col * 119, 100 + row * 78)
			stage.add_child(actor)
			actor.set_physics_process(false)
			players.append({"actor": actor, "action": actions[col], "face": faces[row], "row": row})
	for index in range(Content.mobs.size()):
		var id := str(Content.mobs.keys()[index])
		var actor := MossCreature.new()
		actor.world_view = main.world_view
		actor.creature_id = id
		actor.actor_id = "animation_" + id
		actor.definition = Content.mobs[id].duplicate(true)
		var region := int(actor.definition.region)
		var col := 4 if actor.definition.boss else 3 if actor.definition.passive else index % 3
		actor.position = Vector2(70 + col * 123, 78 + region * 67)
		stage.add_child(actor)
		actor.set_physics_process(false)
		actor.hide()
		creatures.append(actor)
	var caption := Label.new()
	caption.position = Vector2(17, 5)
	caption.add_theme_font_override("font", L.font())
	caption.add_theme_font_size_override("font_size", 11)
	caption.modulate = Color("eddfbd")
	stage.add_child(caption)
	for mode in ["player", "creature", "warden"]:
		for value in players:
			value.actor.visible = mode == "player"
		var boss_index := 0
		for actor in creatures:
			actor.visible = (
				(mode == "creature" and not actor.definition.boss)
				or (mode == "warden" and actor.definition.boss)
			)
			if actor.definition.boss:
				actor.position = Vector2(70 + boss_index * 123, 220)
				boss_index += 1
		for speed in [1.0, .25]:
			var folder: String = output + "/" + str(mode) + ("_normal" if speed == 1.0 else "_slow")
			DirAccess.make_dir_recursive_absolute(folder)
			for frame in range(180):
				var time := float(frame) / 30.0 * float(speed)
				caption.text = (
					(
						"IDLE             WALK             ATTACK             DODGE             DEFEAT"
						if mode == "player"
						else "REGIONAL CREATURES: 3 HOSTILES / WILDLIFE / WARDEN"
					)
					+ "   "
					+ str(speed)
					+ "x"
				)
				if mode == "player":
					_pose_players(time)
				else:
					_pose_creatures(time)
				await get_tree().process_frame
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png(folder + "/%04d.png" % frame)
			print("ANIMATION_RECORDED ", mode, " ", speed, " 180 frames")
	Session.state.player.dead = false
	main.quit_game(false)


func _pose_players(time: float) -> void:
	for value in players:
		var actor: MossPlayer = value.actor
		var action := str(value.action)
		Session.state.equipped = ["field_blade", "copper_spear", "iron_bow", "storm_focus"][int(
			value.row
		)]
		Session.state.player.dead = action == "death"
		actor.facing = value.face
		actor.moving = action == "walk"
		actor.action_clock = (
			.63 - fposmod(time, 1.2) if action == "attack" and fposmod(time, 1.2) < .63 else 0
		)
		actor.dodge_clock = (
			.36 - fposmod(time, .95) if action == "dodge" and fposmod(time, .95) < .36 else 0
		)
		actor.animation_clock = fposmod(time, 1.6) if action == "death" else time
		actor.attack_direction = value.face
		actor._animate(0)
	Session.state.player.dead = false


func _pose_creatures(time: float) -> void:
	for actor in creatures:
		actor.direction = Vector2.LEFT if fposmod(time, 3) < 1.5 else Vector2.RIGHT
		actor.animation_clock = time
		var phase := fposmod(time, 2.5)
		actor.velocity = Vector2(10, 0) if phase < 1.0 else Vector2.ZERO
		actor.mode = "wander" if phase < 1 else "windup" if phase < 1.65 else "recover"
		actor.timer = maxf(0, 1.65 - phase) if actor.mode == "windup" else maxf(0, 2.5 - phase)
		actor.strike_clock = .18 if phase >= 1.65 and phase < 1.83 else 0
		actor._animate()
