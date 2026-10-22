extends Node

signal changed
signal message(key: String, args: Dictionary)
signal journey_started
signal player_fell
signal victory
signal snapshot_requested
signal player_hurt
var state: Dictionary = {}
var active := false
var paused := false
var autosave_clock := 0.0
var world_model: MossWorld


func new_journey(
	journey_name: String,
	seed_text: String,
	difficulty: String,
	death_mode: String,
	preview := false
) -> bool:
	var seed_value := seed_text.strip_edges()
	if seed_value.is_empty():
		seed_value = str(Time.get_unix_time_from_system())
	var seed_number := seed_value.sha256_text().substr(0, 7).hex_to_int()
	state = {
		"id": str(Time.get_ticks_usec()) + str(randi_range(100, 999)),
		"name": journey_name.strip_edges(),
		"seed": seed_value,
		"seed_int": seed_number,
		"generator_version": 1,
		"schema_version": 1,
		"settings": {"difficulty": difficulty, "death_mode": death_mode},
		"time": 360.0,
		"player":
		{
			"position": [16384.0, 16640.0],
			"home": [16384.0, 16640.0],
			"health": 100.0,
			"stamina": 100.0,
			"food": 100.0,
			"water": 100.0,
			"exposure": 0.0,
			"dead": false
		},
		"inventory":
		{"field_blade": 1, "field_axe": 1, "field_pick": 1, "berry": 5, "water": 4, "bandage": 3},
		"equipped": "field_blade",
		"armor": "",
		"structures": {},
		"nodes": {},
		"mob_state": {},
		"restored": [false, false, false, false, false],
		"attunements": ["bloom", "bloom", "ember", "gale", "bloom"],
		"wardens": [false, false, false, false, false],
		"discovered": {},
		"visited_regions": [0],
		"npc_met": [],
		"perks": [],
		"xp": 0,
		"level": 1,
		"skill_points": 0,
		"graves": [],
		"quest_stage": 0,
		"gathered": {},
		"contracts": {},
		"retired": false,
		"completed": false,
		"world_events": [],
		"expeditions": {},
		"reputation": {"surveyors": 0, "gardeners": 0, "makers": 0}
	}
	if str(state.name).is_empty():
		state.name = L.t("ui.title")
	world_model = MossWorld.new(seed_number)
	Activities.ensure_state()
	Activities.fishing = {}
	_seed_camp()
	active = true
	paused = false
	autosave_clock = 0.0
	var saved := preview or Saves.save_world(state)
	journey_started.emit()
	changed.emit()
	return saved


func load_journey(id: String) -> bool:
	var result := Saves.load_world(id)
	if result.is_empty():
		message.emit(Saves.last_error, {})
		return false
	state = result
	world_model = MossWorld.new(int(state.seed_int))
	Activities.ensure_state()
	Activities.fishing = {}
	active = true
	paused = bool(state.get("retired", false))
	autosave_clock = 0.0
	journey_started.emit()
	changed.emit()
	return true


func _seed_camp() -> void:
	for entry in [
		["hearth", Vector2i(512, 520)],
		["tent", Vector2i(510, 519)],
		["bed", Vector2i(511, 519)],
		["chest", Vector2i(509, 521)],
		["lantern", Vector2i(514, 519)],
		["cooking_pot", Vector2i(511, 522)]
	]:
		state.structures[cell_key(entry[1])] = {
			"id": entry[0],
			"cell": [entry[1].x, entry[1].y],
			"placed_at": 0.0,
			"contents": {},
			"health": 150,
			"starter": true
		}
	state.structures["509:521"].contents = {"wood": 8, "stone": 6, "fiber": 6, "seed": 3}


func _process(delta: float) -> void:
	if not active or paused or state.is_empty() or bool(state.retired):
		return
	if bool(state.player.dead):
		return
	state.time = float(state.time) + delta
	autosave_clock += delta
	var settings: Dictionary = Content.difficulties.get(
		str(state.settings.difficulty), Content.difficulties.normal
	)
	var needs_rate: float = float(settings.needs)
	if has_buff("nourished"):
		needs_rate *= .7
	state.player.food = maxf(0.0, float(state.player.food) - delta * 0.024 * needs_rate)
	state.player.water = maxf(0.0, float(state.player.water) - delta * 0.036 * needs_rate)
	var regen := 19.0 * (1.3 if has_perk("second_wind") else 1.0)
	if has_buff("stamina"):
		regen *= 1.35
	if has_charm("stamina"):
		regen *= 1.2
	if float(state.time) >= float(state.player.get("stamina_delay", 0)):
		state.player.stamina = minf(max_stamina(), float(state.player.stamina) + delta * regen)
	if float(state.player.food) <= 0.0 or float(state.player.water) <= 0.0:
		state.player.health = maxf(0.0, float(state.player.health) - delta * 0.65)
	if has_perk("hearthkeeper") and near_structure("hearth", 100.0):
		state.player.health = minf(100.0, float(state.player.health) + delta * 0.8)
	if has_buff("healing"):
		state.player.health = minf(100, float(state.player.health) + delta)
	if has_charm("healing"):
		state.player.health = minf(100, float(state.player.health) + delta * .2)
	if float(state.player.health) <= 0.0:
		fall()
	_update_progress()
	if autosave_clock >= 60.0:
		autosave_clock = 0.0
		save(false)


func player_position() -> Vector2:
	if state.is_empty():
		return Vector2.ZERO
	return Vector2(float(state.player.position[0]), float(state.player.position[1]))


func set_player_position(pos: Vector2) -> void:
	state.player.position = [pos.x, pos.y]
	var cell := Vector2i(pos / 32.0)
	var chunk := Vector2i(floori(float(cell.x) / 32.0), floori(float(cell.y) / 32.0))
	state.discovered[cell_key(chunk)] = true
	var region := world_model.region_at(cell)
	if not region in state.visited_regions:
		state.visited_regions.append(region)
		gain_xp(70)
		message.emit("region." + str(Content.regions[region].id), {})


func cell_key(cell: Vector2i) -> String:
	return "%d:%d" % [cell.x, cell.y]


func has_perk(id: String) -> bool:
	return not state.is_empty() and id in state.perks


func has_buff(id: String) -> bool:
	return float(state.get("buffs", {}).get(id, 0)) > float(state.get("time", 0))


func has_charm(effect: String) -> bool:
	return Content.items.get(str(state.get("trinket", "")), {}).get("charm", "") == effect


func max_stamina() -> float:
	return 125.0 if has_perk("deep_breath") else 100.0


func capacity() -> int:
	return 32 if has_perk("packcraft") else 24


func used_slots(bag: Dictionary) -> int:
	var count := 0
	for id in bag:
		if not Content.items.has(id):
			continue
		count += ceili(float(bag[id]) / float(Content.items[id].stack))
	return count


func add_item(id: String, count: int, notify := true) -> bool:
	if not Content.items.has(id) or count <= 0:
		return false
	var proposed: Dictionary = state.inventory.duplicate()
	proposed[id] = int(proposed.get(id, 0)) + count
	if used_slots(proposed) > capacity():
		message.emit("ui.bag_full", {})
		return false
	state.inventory = proposed
	if notify:
		message.emit("ui.gained", {"name": Content.item_name(id), "count": count})
	changed.emit()
	return true


func remove_item(id: String, count: int) -> bool:
	if count <= 0 or int(state.inventory.get(id, 0)) < count:
		return false
	state.inventory[id] = int(state.inventory[id]) - count
	if int(state.inventory[id]) <= 0:
		state.inventory.erase(id)
	changed.emit()
	return true


func nearby_chests() -> Array:
	var result: Array = []
	for key in state.structures:
		var structure: Dictionary = state.structures[key]
		if (
			structure.id == "chest"
			and structure_position(structure).distance_to(player_position()) < 112.0
		):
			result.append(key)
	result.sort()
	return result


func available_items() -> Dictionary:
	var result: Dictionary = state.inventory.duplicate()
	for key in nearby_chests():
		for id in state.structures[key].contents:
			result[id] = int(result.get(id, 0)) + int(state.structures[key].contents[id])
	return result


func pay(costs: Dictionary, result_id := "", result_count := 0, rewards: Dictionary = {}) -> bool:
	# Plan the entire transaction on copies. Failure changes no source container.
	var bags: Array = [state.inventory.duplicate(true)]
	var keys := nearby_chests()
	for key in keys:
		bags.append(state.structures[key].contents.duplicate(true))
	for id in costs:
		var remaining := int(costs[id])
		for bag in bags:
			var take := mini(int(bag.get(id, 0)), remaining)
			if take > 0:
				bag[id] = int(bag[id]) - take
				remaining -= take
				if int(bag[id]) <= 0:
					bag.erase(id)
		if remaining > 0:
			message.emit("ui.missing", {})
			return false
	var grant := rewards.duplicate()
	if not result_id.is_empty():
		grant[result_id] = int(grant.get(result_id, 0)) + result_count
	for id in grant:
		if not Content.items.has(id) or int(grant[id]) <= 0:
			return false
		bags[0][id] = int(bags[0].get(id, 0)) + int(grant[id])
	if used_slots(bags[0]) > capacity():
		message.emit("ui.bag_full", {})
		return false
	state.inventory = bags[0]
	for i in range(keys.size()):
		state.structures[keys[i]].contents = bags[i + 1]
	changed.emit()
	return true


func reward_items(rewards: Dictionary, position_: Vector2) -> void:
	Activities.ensure_state()
	var next: Dictionary = state.inventory.duplicate(true)
	for id in rewards:
		next[id] = int(next.get(id, 0)) + int(rewards[id])
	if used_slots(next) <= capacity():
		state.inventory = next
		for id in rewards:
			message.emit("ui.gained", {"name": Content.item_name(str(id)), "count": rewards[id]})
	else:
		var id := str(Time.get_ticks_usec())
		state.drops[id] = {
			"position": [position_.x, position_.y], "contents": rewards.duplicate(true)
		}
		message.emit("ui.bag_full", {})
	changed.emit()


func collect_drop(id: String) -> bool:
	Activities.ensure_state()
	if not state.drops.has(id):
		return false
	var drop: Dictionary = state.drops[id]
	var position_ := Vector2(float(drop.position[0]), float(drop.position[1]))
	if position_.distance_to(player_position()) > 60:
		return false
	if not pay({}, "", 0, drop.contents):
		return false
	state.drops.erase(id)
	Sound.effect("pickup")
	return true


func unlocked_tier() -> int:
	return mini(4, 1 + int(state.wardens.count(true)))


func near_structure(id: String, radius := 96.0) -> bool:
	for structure in state.structures.values():
		if (
			str(structure.id) == id
			and structure_position(structure).distance_to(player_position()) < radius
		):
			return true
	return false


func structure_position(structure: Dictionary) -> Vector2:
	return Vector2(float(structure.cell[0]) * 32.0 + 16.0, float(structure.cell[1]) * 32.0 + 24.0)


func craft(id: String) -> bool:
	if not Content.recipes.has(id):
		return false
	var recipe: Dictionary = Content.recipes[id]
	if int(recipe.tier) > unlocked_tier():
		message.emit("ui.locked", {})
		return false
	var station: String = str(recipe.get("station", ""))
	if not station.is_empty() and not near_structure(station):
		message.emit("ui.requires", {"name": Content.item_name(station)})
		return false
	var costs: Dictionary = {}
	if recipe.has("production_seconds"):
		for key in state.structures:
			if (
				str(state.structures[key].id) == station
				and structure_position(state.structures[key]).distance_to(player_position()) < 96
			):
				return Activities.queue_recipe(id, str(key))
		return false
	for ingredient in recipe.ingredients:
		costs[ingredient.id] = int(costs.get(ingredient.id, 0)) + int(ingredient.count)
	if not pay(costs, str(recipe.result.id), int(recipe.result.count)):
		return false
	message.emit(
		"ui.crafted",
		{"name": Content.item_name(str(recipe.result.id)), "count": recipe.result.count}
	)
	Sound.effect("craft")
	return true


func use_item(id: String) -> bool:
	if int(state.inventory.get(id, 0)) <= 0:
		return false
	var definition: Dictionary = Content.items[id]
	if definition.kind == "consumable":
		if not remove_item(id, 1):
			return false
		var effects: Dictionary = definition.get("effects", {})
		state.player.health = minf(
			100.0, float(state.player.health) + float(effects.get("health", 0))
		)
		state.player.food = minf(100.0, float(state.player.food) + float(effects.get("hunger", 0)))
		state.player.water = minf(
			100.0, float(state.player.water) + float(effects.get("thirst", 0))
		)
		state.player.stamina = minf(
			max_stamina(), float(state.player.stamina) + float(effects.get("stamina", 0))
		)
		if definition.has("buff"):
			state.buffs[str(definition.buff)] = float(state.time) + float(definition.duration)
		Sound.effect("eat")
	elif definition.kind == "armor":
		state.armor = id
	elif definition.kind == "trinket":
		state.trinket = id
	elif definition.kind in ["weapon", "tool"]:
		state.equipped = id
	else:
		return false
	changed.emit()
	return true


func gain_xp(amount: int) -> void:
	state.xp = int(state.xp) + amount
	while int(state.xp) >= int(state.level) * 100:
		state.xp = int(state.xp) - int(state.level) * 100
		state.level = int(state.level) + 1
		state.skill_points = int(state.skill_points) + 1
		message.emit("ui.level", {"level": state.level})
	changed.emit()


func learn_perk(id: String) -> bool:
	if not id in Content.perks or has_perk(id) or int(state.skill_points) <= 0:
		return false
	state.perks.append(id)
	state.skill_points = int(state.skill_points) - 1
	changed.emit()
	return true


func hurt(amount: float) -> void:
	if bool(state.player.dead) or paused:
		return
	var armor := (
		int(Content.items.get(str(state.armor), {}).get("armor", 0))
		+ (2 if has_perk("thick_coat") else 0)
	)
	if has_buff("armor"):
		armor += 2
	if has_charm("armor"):
		armor += 2
	var multiplier: float = float(Content.difficulties[str(state.settings.difficulty)].damage)
	if multiplier <= 0:
		return
	state.player.health = maxf(
		0.0, float(state.player.health) - maxf(1.0, amount * multiplier - armor)
	)
	Sound.effect("hurt")
	player_hurt.emit()
	changed.emit()
	if float(state.player.health) <= 0.0:
		fall()


func fall() -> void:
	if bool(state.player.dead):
		return
	snapshot_requested.emit()
	state.player.dead = true
	var mode: String = str(state.settings.death_mode)
	if mode == "mediumcore" and not state.inventory.is_empty():
		state.graves.append(
			{
				"position": state.player.position.duplicate(),
				"contents": state.inventory.duplicate(true),
				"id": str(Time.get_ticks_usec())
			}
		)
		state.inventory = {}
		state.equipped = ""
		state.armor = ""
		state.trinket = ""
	if mode == "hardcore":
		state.retired = true
		if not Saves.retire(str(state.id)):
			message.emit("ui.save_failed", {})
	paused = true
	if not Saves.save_world(state):
		message.emit("ui.save_failed", {})
	player_fell.emit()
	changed.emit()


func respawn() -> bool:
	if bool(state.retired):
		return false
	if not Saves.save_world(state):
		message.emit("ui.save_failed", {})
		return false
	state.player.position = state.player.home.duplicate()
	state.expedition_run = {}
	state.player.health = 100.0
	state.player.stamina = max_stamina()
	state.player.food = maxf(50.0, float(state.player.food))
	state.player.water = maxf(50.0, float(state.player.water))
	state.player.dead = false
	var safe := world_model.safe_position(player_position(), state)
	state.player.position = [safe.x, safe.y]
	paused = false
	Saves.save_world(state)
	changed.emit()
	return true


func recover_grave(index: int) -> bool:
	if index < 0 or index >= state.graves.size():
		return false
	var grave: Dictionary = state.graves[index]
	var next: Dictionary = state.inventory.duplicate()
	for id in grave.contents:
		next[id] = int(next.get(id, 0)) + int(grave.contents[id])
	if used_slots(next) > capacity():
		message.emit("ui.bag_full", {})
		return false
	state.inventory = next
	state.graves.remove_at(index)
	message.emit("ui.recovered", {})
	changed.emit()
	return true


func save(notify := true) -> bool:
	if state.is_empty():
		return false
	snapshot_requested.emit()
	var success := Saves.save_world(state)
	if notify or not success:
		message.emit("ui.saved" if success else "ui.save_failed", {})
	return success


func _update_progress() -> void:
	var stage := int(state.quest_stage)
	if stage == 0 and "mara" in state.npc_met:
		state.quest_stage = 1
	elif (
		stage == 1
		and int(state.gathered.get("wood", 0)) >= 8
		and int(state.gathered.get("stone", 0)) >= 6
	):
		state.quest_stage = 2
	elif stage == 2:
		for structure in state.structures.values():
			if structure.id == "workbench":
				state.quest_stage = 3
				break
	elif stage == 3 and bool(state.restored[0]):
		state.quest_stage = 4
	elif stage == 4 and bool(state.wardens[0]):
		state.quest_stage = 5
	elif stage == 5 and state.wardens.slice(0, 4).count(true) == 4:
		state.quest_stage = 6
	elif stage == 6 and bool(state.wardens[4]):
		state.quest_stage = 7


func quest_key() -> String:
	if int(state.quest_stage) == 4 and state.settings.difficulty == "peaceful":
		return "quest.peaceful_warden"
	return (
		"quest."
		+ ["talk", "gather", "camp", "waystone", "warden", "regions", "meridian", "free"][int(
			state.quest_stage
		)]
	)


func restore(region: int) -> bool:
	if bool(state.restored[region]):
		return true
	if not pay({"wood": 8, "stone": 6, "amber": 2}):
		return false
	state.restored[region] = true
	gain_xp(100)
	message.emit("ui.restored", {})
	Sound.effect("restore")
	changed.emit()
	return true


func attune(region: int, current: String) -> bool:
	if not current in ["bloom", "ember", "gale"] or not bool(state.restored[region]):
		return false
	state.attunements[region] = current
	changed.emit()
	return true


func warden_defeated(region: int) -> void:
	state.wardens[region] = true
	gain_xp(180 + region * 80)
	message.emit("ui.warden_down", {})
	if region == 4 and not bool(state.completed):
		state.completed = true
		victory.emit()
	changed.emit()
	save(false)


func peaceful_offering(region: int) -> bool:
	if not bool(state.restored[region]):
		return false
	if region == 4 and state.wardens.slice(0, 4).count(true) < 4:
		message.emit("quest.regions", {})
		return false
	if not pay({"wood": 12, "stone": 10, "fiber": 8, "amber": 4}):
		return false
	warden_defeated(region)
	return true
