extends Node

var main: Node
var output := ""
var issues: Array = []
var captures := 0


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--visual_out="):
			output = argument.trim_prefix("--visual_out=")
	if output.is_empty():
		output = ProjectSettings.globalize_path("res://../verification/ui_matrix")
	call_deferred("_run")


func _run() -> void:
	main = load("res://scenes/Mossbound.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	main.qa["capture"] = "visual-suite"
	Session.new_journey("Visual test", "Mossbound reference seed", "normal", "easycore", true)
	Session.active = false
	Session.paused = true
	main._build_world()
	for id in Content.items:
		Session.state.inventory[id] = 1
	for id in Content.mobs:
		Activities.observe(str(id), "visual_" + str(id))
	Session.state.skill_points = 3
	Session.state.restored[0] = true
	for definition in Content.points_of_interest:
		Activities.discover_site(str(definition.id))
	var screens: Array = [
		"title",
		"new",
		"hud",
		"inventory",
		"crafting",
		"building",
		"atlas",
		"journal",
		"perks",
		"activities",
		"bestiary",
		"settings",
		"changelog",
		"dialogue",
		"waystone",
		"station",
		"garden",
		"courier",
		"site",
		"death",
		"retired",
		"night",
		"region1",
		"region2",
		"region3",
		"region4"
	]
	for language in L.LANGUAGES:
		L.set_language(str(language), false)
		for screen in screens:
			print("VISUAL_CAPTURE ", language, "/", screen)
			main.ui.toast_timer = 0
			Session.state.time = 360.0
			if str(screen).begins_with("region"):
				var region := str(screen).trim_prefix("region").to_int()
				Session.set_player_position(
					Vector2(Session.world_model.landmarks[region] * 32) + Vector2(60, 55)
				)
				main._build_world()
			elif str(screen) == "night":
				Session.state.time = 1100.0
				Session.set_player_position(Vector2(MossWorld.SPAWN * 32))
				main._build_world()
			else:
				Session.set_player_position(Vector2(MossWorld.SPAWN * 32))
				main.world_view.player.position = Session.player_position()
				main.world_view.refresh()
			Session.state.player.dead = false
			Session.state.retired = false
			match str(screen):
				"title":
					main.ui.show_title()
				"new":
					main.ui.show_new()
				"hud":
					main.ui.show_hud()
					Session.paused = true
				"night", "region1", "region2", "region3", "region4":
					main.ui.show_hud()
					Session.paused = true
				"settings":
					Session.active = true
					main.ui.last_page = "pause"
					main.ui.show_settings()
					Session.active = false
				"changelog":
					main.ui.show_changelog()
				"dialogue":
					main.ui.show_interaction({"data": {"npc": "mara"}})
				"waystone":
					main.ui.show_interaction({"data": {"waystone": 0}})
				"station":
					main.ui.show_interaction({"key": "511:522", "data": {"structure": true}})
				"garden":
					Session.state.structures["516:522"] = {
						"id": "garden", "cell": [516, 522], "placed_at": 0, "contents": {}
					}
					main.ui.show_interaction({"key": "516:522", "data": {"structure": true}})
				"courier":
					main.ui._courier("511:522")
				"site":
					main.ui.show_interaction({"data": {"site": "bracken_puzzle"}})
				"death":
					Session.state.player.dead = true
					main.ui.show_death()
				"retired":
					Session.state.player.dead = true
					Session.state.retired = true
					main.ui.show_retired_atlas()
				_:
					main.ui.show_panel(str(screen))
			await get_tree().process_frame
			await get_tree().process_frame
			# Hidden/occluded Windows test windows may skip automatic draws.
			RenderingServer.force_draw(false)
			_check_layout(main.ui.root, str(language) + "/" + str(screen), false)
			var path := output + "/" + str(language) + "/" + str(screen) + ".png"
			DirAccess.make_dir_recursive_absolute(path.get_base_dir())
			var capture := get_viewport().get_texture().get_image()
			if capture.is_empty():
				issues.append(
					{"screen": str(language) + "/" + str(screen), "error": "Empty renderer capture"}
				)
			else:
				capture.save_png(path)
			captures += 1
	var report := {
		"captures": captures, "issues": issues, "languages": L.LANGUAGES, "screens": screens
	}
	var file := FileAccess.open(output + "/report.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("VISUAL_SUITE ", captures, " captures; ", issues.size(), " layout issues")
	main.quit_game(false)


func _check_layout(node: Node, screen: String, scroll_content: bool) -> void:
	if node is CanvasItem and not node.is_visible_in_tree():
		return
	if node is ScrollContainer:
		scroll_content = true
	if node is Control and not scroll_content:
		var control := node as Control
		var rect := control.get_global_rect()
		var viewport_size := get_viewport().get_visible_rect().size
		if (
			rect.position.x < -2
			or rect.position.y < -2
			or rect.end.x > viewport_size.x + 2
			or rect.end.y > viewport_size.y + 2
		):
			issues.append(
				{
					"screen": screen,
					"node": str(node.get_path()),
					"rect": [rect.position.x, rect.position.y, rect.size.x, rect.size.y]
				}
			)
	for child in node.get_children():
		_check_layout(child, screen, scroll_content)
