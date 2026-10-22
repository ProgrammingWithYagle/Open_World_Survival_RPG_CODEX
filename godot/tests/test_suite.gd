extends Node

var checks := 0
var failures: Array[String] = []


func _ready() -> void:
	call_deferred("_run")


func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures.append(description)
		printerr("FAIL: ", description)


func fresh(difficulty: String = "normal", death: String = "easycore") -> void:
	Session.new_journey("Runtime test", "repeatable test seed", difficulty, death, true)
	Session.state.id = "test_" + difficulty + "_" + death
	Session.paused = true
	Session.active = false


func _run() -> void:
	_test_crafting()
	_test_world_seeds()
	_test_death_modes()
	_test_save_recovery()
	_test_locales()
	_test_activities()
	_test_provisions_and_progression()
	_test_backup_generations()
	print("RUNTIME_TESTS ", checks, " checks; ", failures.size(), " failures")
	Sound.shutdown()
	await get_tree().create_timer(.12).timeout
	get_tree().quit(0 if failures.is_empty() else 1)


func _test_activities() -> void:
	fresh()
	Session.state.wardens[0] = true
	Session.state.inventory = {"copper_ore": 6, "wood": 6, "seed": 3, "fiber": 30}
	Session.state.structures["513:522"] = {
		"id": "smelter", "cell": [513, 522], "contents": {}, "placed_at": 0
	}
	Session.state.structures["514:522"] = {
		"id": "garden", "cell": [514, 522], "contents": {}, "placed_at": 0
	}
	check(
		Activities.queue_recipe("copper", "513:522"),
		"Production queue accepts available materials at the right station"
	)
	check(int(Session.state.inventory.copper_ore) == 4, "Queue charges materials exactly once")
	check(not Activities.collect_production("513:522"), "Unfinished production cannot be collected")
	Session.state.time = float(Session.state.time) + 40
	Activities._update_production()
	check(Activities.collect_production("513:522"), "Finished production is collectible")
	check(int(Session.state.inventory.copper) == 1, "Collected batch has exact output")
	check(not Activities.collect_production("513:522"), "Production cannot be collected twice")
	check(Activities.plant("514:522"), "Garden accepts one seed")
	check(not Activities.plant("514:522"), "Cannot plant twice in one growing garden")
	check(not Activities.harvest("514:522"), "Unripe crops cannot be harvested")
	Session.state.time = float(Session.state.time) + 310
	check(Activities.harvest("514:522"), "Ripe crop can be harvested")
	check(int(Session.state.inventory.vegetable) == 3, "Crop grants vegetables")
	check(not Activities.harvest("514:522"), "Garden requires replanting after harvest")
	fresh()
	Session.state.inventory = {"wood": 100, "fiber": 100, "amber": 0}
	check(
		Activities.deliver("mara"),
		"Traveler request accepts exact costs and grants rewards atomically"
	)
	var after: Dictionary = Session.state.inventory.duplicate(true)
	check(not Activities.deliver("mara"), "Only one request per traveler per day")
	check(
		Session.state.inventory == after,
		"Repeated delivery cannot duplicate rewards or charge materials"
	)
	check(int(Session.state.goodwill.mara) == 10, "Request grants camp goodwill")
	check(Activities.trade("mara", "hide", 3, 3, 0), "Camp trade uses its declared price")
	check(
		not Activities.trade("mara", "hide", 99, 1, 0),
		"Trade cannot override stock quantities or prices"
	)
	fresh()
	Session.state.restored[0] = true
	for entry in [
		["courier_board", Vector2i(510, 522)],
		["hearth", Vector2i(520, 520)],
		["chest", Vector2i(520, 521)],
		["courier_board", Vector2i(521, 522)]
	]:
		Session.state.structures[Session.cell_key(entry[1])] = {
			"id": entry[0], "cell": [entry[1].x, entry[1].y], "contents": {}, "placed_at": 0
		}
	Session.state.structures["509:521"].contents = {"wood": 17, "stone": 9}
	check(
		Activities.send_shipment("510:522", "521:522"), "Courier shipment connects restored camps"
	)
	check(
		Session.state.structures["509:521"].contents.is_empty(),
		"Shipment removes exactly the shipped materials"
	)
	check(Session.state.shipments.size() == 1, "Shipment is persisted while in transit")
	Session.state.time = float(Session.state.time) + 31
	Activities._update_shipments()
	check(
		Session.state.structures["520:521"].contents == {"wood": 17, "stone": 9},
		"Courier delivers exact contents to destination chest"
	)
	Activities._update_shipments()
	check(
		Session.state.structures["520:521"].contents == {"wood": 17, "stone": 9},
		"Courier arrival cannot duplicate materials"
	)
	fresh()
	Activities.discover_site("bracken_puzzle")
	Session.state.sites.bracken_puzzle.seals = Activities.puzzle_solution("bracken_puzzle")
	check(Activities.site_action("bracken_puzzle"), "Correct seal order opens the site reward")
	check(not Activities.site_action("bracken_puzzle"), "One-time site cache cannot be reopened")
	Session.state.equipped = "fishing_rod"
	Activities.cast_line(Vector2i(512, 521))
	Session.state.time = float(Activities.fishing.bite) + .2
	Activities.cast_line(Vector2i(512, 521))
	check(int(Session.state.fishing_records.count) == 1, "A timed reel records a caught fish")
	check(
		int(Session.state.inventory.get("pond_perch", 0)) == 1,
		"Fishing grants one regional fish per bite"
	)
	check(Activities.fishing.is_empty(), "Reeling clears the cast and prevents duplicate catches")
	Session.state.inventory = {}
	for id in Content.items:
		if (
			Content.items[id].stack == 1
			and Session.used_slots(Session.state.inventory) < Session.capacity()
		):
			Session.state.inventory[id] = 1
	Session.reward_items({"wood": 5}, Session.player_position())
	check(Session.state.drops.size() == 1, "Full inventory preserves rewards as a world drop")
	var drop_id := str(Session.state.drops.keys()[0])
	check(not Session.collect_drop(drop_id), "Full bag does not consume world drops")
	Session.state.inventory = {}
	check(Session.collect_drop(drop_id), "World drop can be collected after making room")
	check(
		int(Session.state.inventory.wood) == 5 and Session.state.drops.is_empty(),
		"World drop collection preserves exact contents"
	)


func _test_crafting() -> void:
	fresh()
	var before: Dictionary = Session.state.inventory.duplicate(true)
	check(not Session.pay({"wood": 99999}), "Insufficient materials must fail")
	check(Session.state.inventory == before, "Failed crafting must preserve inventory")
	check(Session.craft("workbench"), "Crafting uses nearby chest supplies")
	check(
		int(Session.state.inventory.get("workbench", 0)) == 1, "Crafted building enters inventory"
	)
	check(
		int(Session.state.structures["509:521"].contents.get("wood", 0)) == 0,
		"Chest materials are charged exactly once"
	)
	check(not Session.craft("iron_blade"), "Locked tiers cannot be crafted")
	Session.state.inventory = {"water": 1}
	Session.state.player.water = 4
	check(Session.use_item("water"), "Selected consumable can be used")
	check(
		float(Session.state.player.water) == 39, "Consumption applies the selected item's effects"
	)
	check(not Session.state.inventory.has("water"), "Consumption removes exactly one item")
	Session.state.inventory = {"stone": 99, "wood": 99}
	check(not Session.remove_item("stone", 100), "Cannot remove more items than owned")
	Session.state.skill_points = 1
	check(Session.learn_perk("packcraft"), "Skill can be purchased with a point")
	check(not Session.learn_perk("packcraft"), "Skill cannot be purchased twice")
	check(Session.capacity() == 32, "Backpack perk changes capacity")


func _test_world_seeds() -> void:
	for seed_ in range(30):
		var model := MossWorld.new(seed_)
		var sample: Array = []
		for region in range(5):
			var landmark: Vector2i = model.landmarks[region]
			check(
				model.tile_at(landmark).kind != "water",
				"Landmark is dry for seed %d region %d" % [seed_, region]
			)
			var steps := ceili(Vector2(MossWorld.SPAWN).distance_to(Vector2(landmark)))
			var dry := true
			for step in range(steps + 1):
				var cell := Vector2i(
					Vector2(MossWorld.SPAWN).lerp(Vector2(landmark), float(step) / maxi(1, steps))
				)
				if model.tile_at(cell).kind == "water":
					dry = false
					break
			check(dry, "Critical route is dry for seed %d region %d" % [seed_, region])
			sample.append(model.tile_at(landmark))
		check(
			model.node_at(MossWorld.SPAWN + Vector2i(7, -4)).id == "wood",
			"Starting wood guaranteed"
		)
		check(
			model.node_at(MossWorld.SPAWN + Vector2i(6, 4)).id == "stone",
			"Starting stone guaranteed"
		)
		check(
			model.node_at(MossWorld.SPAWN + Vector2i(6, -5)).id == "amber",
			"Starting restoration amber guaranteed"
		)
		var repeat := MossWorld.new(seed_)
		check(repeat.landmarks == model.landmarks, "Identical seeds reproduce landmarks")


func _test_death_modes() -> void:
	for difficulty in Content.difficulties:
		for mode in ["easycore", "mediumcore", "hardcore"]:
			fresh(str(difficulty), mode)
			var inventory: Dictionary = Session.state.inventory.duplicate(true)
			Session.state.player.position = [16480, 16640]
			Session.fall()
			check(bool(Session.state.player.dead), "Death recorded for %s/%s" % [difficulty, mode])
			if mode == "easycore":
				check(Session.state.inventory == inventory, "Easycore retains all belongings")
				check(Session.respawn(), "Easycore respawns")
			elif mode == "mediumcore":
				check(Session.state.inventory.is_empty(), "Mediumcore removes carried belongings")
				check(Session.state.graves.size() == 1, "Mediumcore creates exactly one grave")
				check(
					Session.state.graves[0].contents == inventory, "Grave contains exact inventory"
				)
				check(Session.respawn(), "Mediumcore respawns")
				check(Session.recover_grave(0), "Grave can be recovered")
				check(Session.state.inventory == inventory, "Recovery restores exact inventory")
				check(not Session.recover_grave(0), "Grave recovery cannot duplicate items")
			else:
				check(bool(Session.state.retired), "Hardcore retirement recorded")
				check(not Session.respawn(), "Hardcore does not respawn")
			check(
				(
					Saves.load_world(str(Session.state.id)).get("settings", {}).get(
						"death_mode", ""
					)
					== mode
				),
				"Death mode persists independently of difficulty"
			)


func _test_save_recovery() -> void:
	fresh()
	Session.state.id = "test_generation_recovery"
	Session.state.inventory = {"amber": 7}
	Session.state.equipped = ""
	Session.state.armor = ""
	Session.state.trinket = ""
	check(Session.save(false), "Initial generation saves")
	Session.state.inventory.amber = 11
	check(Session.save(false), "Second generation saves")
	var loaded := Saves.load_world(str(Session.state.id))
	check(int(loaded.inventory.amber) == 11, "Save round trip preserves inventory")
	check(loaded.seed == Session.state.seed, "Seed survives round trip verbatim")
	var path := Saves._path(str(Session.state.id))
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("interrupted write")
	file.close()
	var backup := Saves.load_world(str(Session.state.id))
	check(not backup.is_empty(), "Damaged primary recovers a valid backup")
	check(int(backup.inventory.amber) == 7, "Recovery selects previous complete generation")
	check(
		Saves.list_worlds().all(
			func(entry: Dictionary): return not str(entry.id).begins_with("test_")
		),
		"Test worlds never appear in player journey list"
	)


func _test_locales() -> void:
	for language in L.LANGUAGES:
		L.set_language(language, false)
		check(L.t("ui.title") != "ui.title", "Title localized in " + language)
		check(
			not "{count}" in L.t("ui.gained", {"name": "x", "count": 3}),
			"Placeholders expand in " + language
		)
		var font := L.font()
		var missing: Array = []
		for value in L.catalog.values():
			var string := str(value)
			for index in range(string.length()):
				var codepoint := string.unicode_at(index)
				if codepoint > 32 and not font.has_char(codepoint):
					missing.append(codepoint)
		check(missing.is_empty(), "All translated glyphs exist in " + language)
	L.set_language("en", false)


func _test_provisions_and_progression() -> void:
	fresh()
	Session.state.wardens[0] = true
	Session.state.inventory.reed_charm = 1
	check(Session.use_item("reed_charm"), "A charm equips from the backpack")
	Session.state.structures["513:522"] = {
		"id": "garden", "cell": [513, 522], "contents": {}, "placed_at": 0
	}
	Session.state.structures["514:522"] = {
		"id": "scarecrow", "cell": [514, 522], "contents": {}, "placed_at": 0
	}
	var garden: Dictionary = Session.state.structures["513:522"]
	for seed_id in Content.crops:
		Session.add_item(str(seed_id), 1, false)
		var produce := str(Content.crops[seed_id].produce)
		var before := int(Session.state.inventory.get(produce, 0))
		check(
			Activities.plant("513:522", str(seed_id)), "Each crop can be planted: " + str(seed_id)
		)
		check(
			is_equal_approx(
				Activities.grow_seconds(garden), float(Content.crops[seed_id].seconds) * .85
			),
			"Equipped garden charm changes actual growth time"
		)
		Session.state.time = float(Session.state.time) + Activities.grow_seconds(garden) + 1
		check(Activities.harvest("513:522"), "Each crop can be harvested: " + str(seed_id))
		check(
			int(Session.state.inventory.get(produce, 0)) == before + 4,
			"Nearby scarecrow adds one crop to the harvest"
		)
		check(
			int(Session.state.inventory.get(seed_id, 0)) >= 1,
			"Harvest replenishes the planted seed"
		)
	Session.state.structures.erase("513:522")
	Session.state.structures["513:522"] = {
		"id": "mill", "cell": [513, 522], "contents": {}, "placed_at": 0
	}
	Session.state.structures["514:522"] = {
		"id": "windmill", "cell": [514, 522], "contents": {}, "placed_at": 0
	}
	Session.state.restored[0] = true
	Session.state.attunements[0] = "ember"
	Session.state.inventory.grain = 3
	var started := float(Session.state.time)
	check(Activities.queue_recipe("flour", "513:522"), "Grown grain enters the milling queue")
	check(
		is_equal_approx(
			float(Session.state.production["513:522"].queue[0].finish) - started, 25 * .75 * .75
		),
		"Windmill and Ember reduce real batch duration"
	)
	Session.state.time = started + 30
	check(Activities.collect_production("513:522"), "Milled flour can be collected")
	check(Session.craft("flatbread"), "Milled flour becomes bread at the camp cooking pot")
	Session.state.player.food = 10
	Session.state.player.health = 45
	check(Session.use_item("flatbread"), "Baked bread can be eaten")
	check(
		float(Session.state.player.food) == 55 and float(Session.state.player.health) == 53,
		"Bread restores its declared food and health"
	)
	Session.add_item("mint_cordial", 1, false)
	check(
		Session.use_item("mint_cordial") and Session.has_buff("haste"),
		"A cordial applies its declared timed benefit"
	)
	check(Session.save(false), "Crops, production and a timed benefit survive save validation")
	var saved := Saves.load_world(str(Session.state.id))
	check(
		(
			saved.production.has("513:522")
			and saved.trinket == "reed_charm"
			and saved.buffs.has("haste")
		),
		"Extended activity state survives a full save round trip"
	)
	Session.state.time = float(Session.state.time) + 241
	check(not Session.has_buff("haste"), "Timed benefits expire at the correct world time")
	fresh("peaceful")
	Session.state.inventory.merge({"wood": 300, "stone": 300, "fiber": 300, "amber": 100}, true)
	check(not Session.peaceful_offering(4), "Final offering requires a restored waystone")
	for region in range(5):
		check(Session.restore(region), "Progression can restore region " + str(region))
		check(
			Session.attune(region, ["bloom", "ember", "gale"][region % 3]),
			"Each restored region accepts a current"
		)
		check(Session.peaceful_offering(region), "Peaceful progression can overcome every warden")
		check(
			Session.unlocked_tier() == mini(4, region + 2),
			"Warden progression unlocks the next equipment tier"
		)
	check(Session.state.completed, "All five regions produce a completed, persistent journey")
	check(not Session.state.retired, "Finishing the main journey preserves continued play")
	check(
		Session.save(false) and Saves.load_world(str(Session.state.id)).completed,
		"The ending survives save and load"
	)


func _test_backup_generations() -> void:
	fresh()
	Session.state.id = "test_backup_matrix"
	Session.state.inventory = {"amber": 1}
	Session.state.equipped = ""
	Session.state.armor = ""
	Session.state.trinket = ""
	for generation in range(1, 5):
		Session.state.inventory.amber = generation
		check(Session.save(false), "Write complete backup generation " + str(generation))
	var path := Saves._path(str(Session.state.id))
	for generation in range(4):
		var damaged_path := path if generation == 0 else path + ".bak%d" % generation
		var damaged := FileAccess.open(damaged_path, FileAccess.WRITE)
		damaged.store_string("Interrupted generation")
		damaged.close()
		var loaded := Saves.load_world(str(Session.state.id))
		if generation < 3:
			check(
				not loaded.is_empty() and int(loaded.inventory.amber) == 3 - generation,
				"Recover the newest remaining valid generation"
			)
		else:
			check(
				loaded.is_empty() and Saves.last_error == "ui.load_failed",
				"All damaged generations fail cleanly"
			)
	check(Session.save(false), "Restore a valid primary after corruption testing")
	var future: Dictionary = Session.state.duplicate(true)
	future.schema_version = Saves.SCHEMA + 1
	var body := JSON.stringify(future)
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"body": body, "sha256": body.sha256_text()}))
	file.close()
	check(
		Saves.load_world(str(Session.state.id)).is_empty() and Saves.last_error == "ui.newer_save",
		"A future save version fails without silently rolling progress back"
	)
	fresh("normal", "hardcore")
	Session.state.id = "test_hardcore_recovery"
	check(Session.save(false) and Session.save(false), "Hardcore has an intact living backup")
	check(Saves.retire(str(Session.state.id)), "Hardcore writes a permanent retirement marker")
	var damaged := FileAccess.open(Saves._path(str(Session.state.id)), FileAccess.WRITE)
	damaged.store_string("Interrupted death save")
	damaged.close()
	var retired := Saves.load_world(str(Session.state.id))
	check(
		retired.retired and retired.player.dead,
		"Recovering a living backup cannot resurrect a retired Hardcore character"
	)
