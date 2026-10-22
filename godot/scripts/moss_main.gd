extends Node

var viewport: SubViewport
var container: SubViewportContainer
var world_view: MossWorldView
var ui: MossUI
var lighting: CanvasModulate
var qa: Dictionary = {}
var quitting := false
var trial_clock := 0.0
var theme_clock := 0.0
var using_controller := false


func _ready() -> void:
	get_tree().auto_accept_quit = false
	_bind_inputs()
	for argument in OS.get_cmdline_user_args():
		if "=" in argument:
			var parts := argument.trim_prefix("--").split("=", true, 1)
			qa[parts[0]] = parts[1]
	if qa.has("locale"):
		L.set_language(str(qa.locale), false)
	container = SubViewportContainer.new()
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.stretch = true
	container.stretch_shrink = 2
	container.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(container)
	viewport = SubViewport.new()
	viewport.size = Vector2i(640, 360)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.handle_input_locally = false
	container.add_child(viewport)
	ui = MossUI.new()
	add_child(ui)
	ui.begin_requested.connect(_begin)
	ui.load_requested.connect(_load)
	ui.title_requested.connect(_title)
	Activities.travel_requested.connect(_travel_to)
	Activities.expedition_requested.connect(_start_expedition)
	Session.new_journey("", "The old survey camp", "peaceful", "easycore", true)
	Session.active = false
	Session.paused = true
	_build_world()
	ui.show_title()
	if bool(L.preferences.fullscreen):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	if qa.has("capture") or qa.has("screen"):
		call_deferred("_qa_capture")
	elif qa.has("smoke"):
		call_deferred("_qa_smoke")


func _build_world() -> void:
	if world_view != null:
		world_view.retire()
		_release_view(world_view)
	world_view = MossWorldView.new()
	world_view.qa_mode = qa.has("capture")
	world_view.using_controller = using_controller
	world_view.trial_mode = not Session.state.get("expedition_run", {}).is_empty()
	viewport.add_child(world_view)
	lighting = CanvasModulate.new()
	world_view.add_child(lighting)
	ui.world_view = world_view
	world_view.interact_requested.connect(ui.show_interaction)


func _release_view(previous: MossWorldView) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if is_instance_valid(previous):
		previous.queue_free()


func _begin(name_: String, seed_: String, difficulty: String, death_mode: String) -> void:
	var saved := Session.new_journey(name_, seed_, difficulty, death_mode)
	_build_world()
	ui.show_hud()
	ui.show_message("ui.welcome" if saved else "ui.save_failed")


func _load(id: String) -> void:
	if Session.load_journey(id):
		_build_world()
		ui.show_hud()
		if Session.state.retired:
			ui.show_retired_atlas()
		elif Session.state.player.dead:
			ui.show_death()


func _title() -> void:
	Session.active = false
	Session.paused = true
	ui.show_title()


func _process(_delta: float) -> void:
	if lighting == null or Session.state.is_empty():
		return
	var phase := fposmod(float(Session.state.time), 1440.0) / 1440.0
	var daylight := clampf(sin((phase - .14) * TAU) * 1.4 + .45, .35, 1.0)
	lighting.color = Color(daylight, daylight * .96 + .04, daylight * .86 + .14)
	if Session.active and not Session.paused:
		trial_clock += _delta
		theme_clock += _delta
		if trial_clock > .3:
			trial_clock = 0
			_trial_tick()
		if theme_clock > 2:
			theme_clock = 0
			var region := Session.world_model.region_at(Vector2i(Session.player_position() / 32.0))
			Sound.theme(
				"combat" if world_view.has_hostiles(170) else str(Content.regions[region].id)
			)


func _travel_to(position_: Vector2) -> void:
	if world_view != null:
		world_view.persist_actors()
	var safe := Session.world_model.safe_position(position_, Session.state)
	Session.set_player_position(safe)
	_build_world()
	Session.save(false)


func _start_expedition(site_id: String, depth: int) -> void:
	if not Session.state.expedition_run.is_empty():
		return
	var region := int(Activities.site_definition(site_id).region)
	Session.state.expedition_run = {
		"site": site_id,
		"depth": depth,
		"wave": 1,
		"return": Session.state.player.position.duplicate(),
		"cleared": []
	}
	var position_ := Vector2(Session.world_model.arena_cell(region) * 32) + Vector2(16, 112)
	_travel_to(position_)
	ui.show_hud()


func _trial_tick() -> void:
	var run: Dictionary = Session.state.get("expedition_run", {})
	if run.is_empty():
		return
	var region := int(Activities.site_definition(str(run.site)).region)
	var count := 2 + int(run.wave) + mini(3, int(run.depth) / 2)
	var remaining := 0
	for index in range(count):
		var actor_id := "trial_%s_%d_%d_%d" % [str(run.site), int(run.depth), int(run.wave), index]
		if actor_id in run.cleared:
			continue
		if world_view.actors.has(actor_id):
			var actor: MossCreature = world_view.actors[actor_id]
			if not is_instance_valid(actor) or actor.dying:
				run.cleared.append(actor_id)
				continue
			remaining += 1
			continue
		var saved: Dictionary = Session.state.mob_state.get(actor_id, {})
		if saved.has("respawn"):
			run.cleared.append(actor_id)
			continue
		var angle := float(index) * TAU / float(count)
		var position_ := (
			Vector2(Session.world_model.arena_cell(region) * 32)
			+ Vector2(16, 16)
			+ Vector2.from_angle(angle) * 160
		)
		var creature_id := str(Content.mobs.keys()[region * 3 + (index + int(run.wave)) % 3])
		var actor := world_view.spawn_creature(creature_id, position_, actor_id, saved)
		var scaling := 1.0 + minf(3.0, float(run.depth) * .12)
		actor.definition.health = float(actor.definition.health) * scaling
		actor.definition.damage = (
			float(actor.definition.damage) * (1.0 + minf(1.0, float(run.depth) * .06))
		)
		if saved.is_empty():
			actor.health = float(actor.definition.health)
		remaining += 1
	if remaining == 0:
		if int(run.wave) >= 3:
			end_expedition(true)
		else:
			run.wave = int(run.wave) + 1
			Session.message.emit("ui.wave", {"wave": run.wave, "depth": int(run.depth) + 1})
			Session.save(false)


func end_expedition(won: bool) -> void:
	var run: Dictionary = Session.state.get("expedition_run", {}).duplicate(true)
	if run.is_empty():
		return
	Session.state.expedition_run = {}
	var position_ := Vector2(float(run["return"][0]), float(run["return"][1]))
	_travel_to(position_)
	if won:
		Activities.complete_expedition(str(run.site))
	Session.save(false)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if ui.page == "hud":
			ui.show_pause()
		elif ui.page in ["pause", "panel", "dialogue", "settings", "changelog"] and Session.active:
			ui.show_hud()
		elif ui.page != "title" and not Session.active:
			ui.show_title()
		get_viewport().set_input_as_handled()
		return
	if ui.page != "hud" or Session.paused:
		return
	if event.is_action_pressed("inventory"):
		ui.show_panel("inventory")
	elif event.is_action_pressed("crafting"):
		ui.show_panel("crafting")
	elif event.is_action_pressed("building"):
		ui.show_panel("building")
	elif event.is_action_pressed("atlas"):
		ui.show_panel("atlas")
	elif event.is_action_pressed("interact"):
		world_view.interact()
	elif event.is_action_pressed("dodge"):
		if not world_view.placing.is_empty():
			world_view.placing = ""
		else:
			world_view.player.dodge()
	elif event.is_action_pressed("dismantle"):
		world_view.dismantle(Vector2i(world_view.aim_position() / 32.0))
	elif event.is_action_pressed("attack"):
		if not world_view.placing.is_empty():
			world_view.place_building(
				world_view.placing, Vector2i(world_view.aim_position() / 32.0)
			)
		else:
			world_view.player.attack()
	elif (
		event is InputEventMouseButton
		and event.button_index == MOUSE_BUTTON_RIGHT
		and event.pressed
	):
		world_view.placing = ""
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_1:
			_equip_style("blade")
		elif event.physical_keycode == KEY_2:
			_equip_style("axe")
		elif event.physical_keycode == KEY_3:
			_equip_style("pick")
		elif event.physical_keycode == KEY_4:
			_equip_style("bow")
		elif event.physical_keycode == KEY_5:
			Session.use_item("bandage")
		elif event.physical_keycode == KEY_6:
			Session.use_item("water")
	if event is InputEventJoypadButton and event.pressed:
		if event.button_index == JOY_BUTTON_LEFT_SHOULDER:
			_cycle_gear(-1)
		elif event.button_index == JOY_BUTTON_RIGHT_SHOULDER:
			_cycle_gear(1)


func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		using_controller = true
	elif event is InputEventKey or event is InputEventMouseButton or event is InputEventMouseMotion:
		using_controller = false
	if world_view != null:
		world_view.using_controller = using_controller


func _cycle_gear(step: int) -> void:
	var choices: Array = []
	for id in Session.state.inventory:
		if Content.items[id].kind in ["weapon", "tool"]:
			choices.append(str(id))
	if choices.is_empty():
		return
	var index := choices.find(str(Session.state.equipped))
	Session.use_item(str(choices[posmod(index + step, choices.size())]))


func _equip_style(style: String) -> void:
	var best := ""
	var tier := 0
	for id in Session.state.inventory:
		var item: Dictionary = Content.items[id]
		if str(item.get("style", "")) == style and int(item.tier) > tier:
			best = str(id)
			tier = int(item.tier)
	if not best.is_empty():
		Session.use_item(best)


func _bind_inputs() -> void:
	var keys: Dictionary = {
		"move_up": KEY_W,
		"move_down": KEY_S,
		"move_left": KEY_A,
		"move_right": KEY_D,
		"interact": KEY_E,
		"sprint": KEY_SHIFT,
		"dodge": KEY_SPACE,
		"inventory": KEY_TAB,
		"crafting": KEY_C,
		"building": KEY_B,
		"atlas": KEY_M,
		"pause": KEY_ESCAPE,
		"dismantle": KEY_R
	}
	for action in keys:
		if not InputMap.has_action(action):
			InputMap.add_action(action, .22)
		InputMap.action_erase_events(action)
		var event := InputEventKey.new()
		event.physical_keycode = keys[action]
		InputMap.action_add_event(action, event)
	for entry in [
		["move_left", JOY_AXIS_LEFT_X, -1.0],
		["move_right", JOY_AXIS_LEFT_X, 1.0],
		["move_up", JOY_AXIS_LEFT_Y, -1.0],
		["move_down", JOY_AXIS_LEFT_Y, 1.0]
	]:
		var event := InputEventJoypadMotion.new()
		event.axis = entry[1]
		event.axis_value = entry[2]
		InputMap.action_add_event(entry[0], event)
	for action in ["interact", "dodge", "inventory", "pause", "crafting", "atlas"]:
		var event := InputEventJoypadButton.new()
		event.button_index = {
			"interact": JOY_BUTTON_A,
			"dodge": JOY_BUTTON_B,
			"inventory": JOY_BUTTON_Y,
			"pause": JOY_BUTTON_START,
			"crafting": JOY_BUTTON_X,
			"atlas": JOY_BUTTON_BACK,
			"sprint": JOY_BUTTON_LEFT_STICK,
			"dismantle": JOY_BUTTON_RIGHT_STICK
		}[action]
		InputMap.action_add_event(action, event)
	if not InputMap.has_action("attack"):
		InputMap.add_action("attack")
	var mouse := InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	InputMap.action_add_event("attack", mouse)
	var trigger := InputEventJoypadMotion.new()
	trigger.axis = JOY_AXIS_TRIGGER_RIGHT
	trigger.axis_value = 1
	InputMap.action_add_event("attack", trigger)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		quit_game()
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if ui != null and Session.active and ui.page == "hud" and qa.is_empty():
			ui.show_pause()


func quit_game(persist := true) -> void:
	if quitting:
		return
	if persist and Session.active and not Session.save():
		return
	quitting = true
	Session.paused = true
	if world_view != null:
		world_view.retire()
	Sound.shutdown()
	await get_tree().create_timer(.12).timeout
	get_tree().quit()


func _qa_capture() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if qa.get("screen", "title") != "title":
		Session.new_journey("QA journey", "Mossbound reference seed", "normal", "easycore", true)
		Session.paused = true
		_build_world()
		ui.show_hud()
		Session.paused = true
		match str(qa.screen):
			"inventory", "crafting", "building", "atlas", "journal", "perks":
				ui.show_panel(str(qa.screen))
			"settings":
				ui.last_page = "pause"
				ui.show_settings()
			"new":
				ui.show_new()
			"changelog":
				ui.show_changelog()
			"dialogue":
				ui.show_interaction({"data": {"npc": "mara"}})
	await get_tree().process_frame
	RenderingServer.force_draw(false)
	if qa.has("capture"):
		var path := str(qa.capture)
		DirAccess.make_dir_recursive_absolute(path.get_base_dir())
		var image := get_viewport().get_texture().get_image()
		var error := image.save_png(path)
		print("QA_CAPTURE ", path, " ", error)
	if qa.has("exit"):
		quit_game(false)


func _qa_smoke() -> void:
	var errors: Array = []
	for id in Content.items:
		if not ResourceLoader.exists("res://art/icons/%s.png" % id):
			errors.append("Missing item icon: " + str(id))
	for locale in L.LANGUAGES:
		L.set_language(str(locale), false)
		if L.t("ui.title") == "ui.title":
			errors.append("Missing locale: " + str(locale))
	Session.new_journey("Package verification", "Portable package seed", "normal", "easycore", true)
	Session.state.id = "test_export_smoke"
	Session.paused = true
	if not Session.save(false) or Saves.load_world("test_export_smoke").is_empty():
		errors.append("Save round trip failed")
	if errors.is_empty():
		print("EXPORT_SMOKE passed: ", Content.items.size(), " icons, 5 languages, save round trip")
	else:
		printerr("EXPORT_SMOKE failed: ", errors)
	Sound.shutdown()
	await get_tree().create_timer(.12).timeout
	get_tree().quit(0 if errors.is_empty() else 1)
