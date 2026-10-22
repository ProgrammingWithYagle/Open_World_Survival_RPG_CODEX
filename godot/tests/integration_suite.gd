extends Node

var main: Node
var checks := 0
var failures: Array = []


func _ready() -> void:
	call_deferred("_run")


func check(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures.append(description)
		printerr("FAIL: ", description)


func _run() -> void:
	main = load("res://scenes/Mossbound.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	main.qa["capture"] = "integration"
	Session.new_journey(
		"Integration journey", "Mossbound reference seed", "normal", "easycore", true
	)
	Session.state.id = "test_integration"
	main._build_world()
	main.ui.show_hud()
	var start := Session.player_position()
	main.world_view.player.facing = Vector2.UP
	check(
		main.world_view.player._aim_direction(Vector2(200, 0), Vector2.LEFT).x < -.9,
		"Right-stick direction takes priority over mouse and previous facing"
	)
	check(
		main.world_view.player._aim_direction(Vector2.ONE, Vector2(.05, 0)) == Vector2.UP,
		"Small aim inputs respect the controller deadzone and preserve facing"
	)
	Input.action_press("move_right")
	await get_tree().create_timer(.25).timeout
	Input.action_release("move_right")
	check(
		Session.player_position().x > start.x + 10,
		"Input movement updates the live player and session"
	)
	var target_cell := MossWorld.SPAWN + Vector2i(7, -4)
	main._travel_to(Vector2(target_cell * 32) + Vector2(-16, 27))
	main.ui.show_hud()
	var target: Dictionary = {
		"cell": target_cell,
		"key": Session.cell_key(target_cell),
		"position": Vector2(target_cell * 32) + Vector2(16, 28)
	}
	main.world_view.player.gather(target)
	await get_tree().create_timer(.7).timeout
	check(
		int(Session.state.inventory.get("wood", 0)) == 1,
		"Gather animation produces one resource at its hit window"
	)
	check(
		Session.state.equipped == "field_axe",
		"Interact gathering selects the best appropriate owned tool"
	)
	main._travel_to(Vector2(MossWorld.SPAWN * 32) + Vector2(80, 80))
	main.ui.show_hud()
	Session.state.inventory = {
		"field_blade": 1, "wood": 100, "stone": 100, "fiber": 100, "amber": 100, "seed": 20
	}
	Session.use_item("field_blade")
	var actor: MossCreature = main.world_view.spawn_creature(
		"thornling", Session.player_position() + Vector2(35, 0), "integration_target"
	)
	actor.set_physics_process(false)
	var health: float = actor.health
	var player: MossPlayer = main.world_view.player
	player.attack()
	player.attack_direction = Vector2.RIGHT
	player.facing = Vector2.RIGHT
	await get_tree().create_timer(.7).timeout
	check(actor.health < health, "Aimed melee attack damages a nearby creature")
	check(actor.health >= health - 9, "One attack cannot apply its damage repeatedly")
	var stamina := float(Session.state.player.stamina)
	player.dodge()
	check(float(Session.state.player.stamina) < stamina, "Dodge consumes stamina")
	check(player.invulnerable > 0, "Dodge supplies a bounded invulnerability window")
	var hp := float(Session.state.player.health)
	player.take_hit(20, player.position + Vector2.RIGHT * 10)
	check(float(Session.state.player.health) == hp, "Dodge invulnerability blocks damage")
	await get_tree().create_timer(.5).timeout
	main.ui.show_panel("inventory")
	var paused_pos := Session.player_position()
	Input.action_press("move_right")
	await get_tree().create_timer(.2).timeout
	Input.action_release("move_right")
	check(Session.player_position() == paused_pos, "Opening an overlay pauses player movement")
	var search := _find_line_edit(main.ui.root)
	check(search != null, "Backpack exposes recipe and item search")
	if search != null:
		search.text = "wood"
		search.text_changed.emit("wood")
	await get_tree().process_frame
	check(
		_count_text(main.ui.root, Content.item_name("wood")) > 0,
		"Search callback keeps the matching item visible"
	)
	main.ui.search_text = ""
	main.ui.show_hud()
	var cell := Vector2i(Session.player_position() / 32.0) + Vector2i(2, 0)
	check(
		main.world_view.place_building("floor", cell), "A foundation can be placed before furniture"
	)
	check(
		main.world_view.place_building("workbench", cell),
		"Building placement crafts and places one piece"
	)
	check(
		Session.state.structures.has(Session.cell_key(cell)),
		"Placed structure enters persistent world state"
	)
	check(main.world_view.dismantle(cell), "Placed empty structure can be dismantled")
	check(
		int(Session.state.inventory.get("workbench", 0)) == 1,
		"Dismantling returns exactly one building piece"
	)
	check(
		Session.state.surfaces.has(Session.cell_key(cell)),
		"Removing furniture preserves its foundation"
	)
	actor = main.world_view.actors.get("integration_target")
	if is_instance_valid(actor):
		actor.health = 13
	check(Session.save(false), "Live world snapshot saves successfully")
	if is_instance_valid(actor):
		check(
			int(Saves.load_world("test_integration").mob_state.integration_target.health) == 13,
			"Saving snapshots live creature health"
		)
	Session.state.restored[0] = true
	main._start_expedition("bracken_expedition", 0)
	check(not Session.state.expedition_run.is_empty(), "Trial entry records a resumable expedition")
	for wave in range(3):
		main._trial_tick()
		for value in main.world_view.actors.values():
			if is_instance_valid(value) and str(value.actor_id).begins_with("trial_"):
				value.take_hit(10000, Vector2.ZERO)
		main._trial_tick()
	check(
		Session.state.expedition_run.is_empty(),
		"Completing three waves returns the player from the trial"
	)
	check(
		int(Session.state.expeditions.get("bracken_expedition", 0)) == 1,
		"Trial victory unlocks exactly one next depth"
	)
	check(not main.world_view.trial_mode, "Overworld rendering resumes after trial completion")
	for site in Content.points_of_interest:
		var site_cell := Session.world_model.poi_cell(str(site.id))
		main._travel_to(Vector2(site_cell * 32) + Vector2(16, 28))
		main.ui.show_hud()
		main.world_view._find_target()
		check(
			main.world_view.target.get("data", {}).get("site", "") == site.id,
			"A player can approach and target discovery site " + str(site.id)
		)
		check(
			main.ui._target_name(main.world_view.target) == L.t(str(site.name_key)),
			"Discovery HUD hint uses its localized name"
		)
		main.world_view.interact()
		check(
			main.ui.page == "dialogue" and main.ui.dialog_target.data.site == site.id,
			"Interacting opens the actual discovery screen"
		)
		main.ui.show_hud()
	var dropped_at := Session.player_position()
	Session.state.drops["integration_supplies"] = {
		"position": [dropped_at.x, dropped_at.y], "contents": {"wood": 2}
	}
	main.world_view._find_target()
	check(
		main.world_view.target.has("drop"),
		"Nearby dropped supplies become the live interaction target"
	)
	check(
		main.ui._target_name(main.world_view.target) == L.t("ui.collect"),
		"Supply bundle hints do not require resource-node data"
	)
	main.world_view.interact()
	check(
		not Session.state.drops.has("integration_supplies"),
		"The actual interact action collects a supply bundle"
	)
	main.world_view.player.position.x += 1024
	Session.set_player_position(main.world_view.player.position)
	main.world_view.refresh()
	var previous: MossWorldView = main.world_view
	check(previous.streaming_pending, "A cold chunk starts an incremental streaming job")
	main._build_world()
	check(
		previous.retiring and not Session.snapshot_requested.is_connected(previous.persist_actors),
		"Retiring a view cancels jobs and disconnects old snapshots"
	)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	check(
		not is_instance_valid(previous),
		"A retired view is freed after suspended jobs can release resources"
	)
	print("INTEGRATION_TESTS ", checks, " checks; ", failures.size(), " failures")
	Sound.shutdown()
	await get_tree().create_timer(.12).timeout
	get_tree().quit(0 if failures.is_empty() else 1)


func _find_line_edit(node: Node) -> LineEdit:
	if node is LineEdit:
		return node
	for child in node.get_children():
		var value := _find_line_edit(child)
		if value != null:
			return value
	return null


func _count_text(node: Node, text_: String) -> int:
	var count := 1 if node is Label and text_ in str(node.text) else 0
	for child in node.get_children():
		count += _count_text(child, text_)
	return count
