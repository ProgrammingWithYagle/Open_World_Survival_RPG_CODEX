extends Node

signal travel_requested(position_: Vector2)
signal expedition_requested(site_id: String, depth: int)
var tick_clock := 0.0
var fishing: Dictionary = {}
var warning_clock := 0.0


func ensure_state() -> void:
	var migrate_surfaces: bool = not Session.state.has("surfaces")
	for key in [
		"sites",
		"production",
		"bestiary",
		"fishing_records",
		"goodwill",
		"shipments",
		"drops",
		"buffs",
		"surfaces"
	]:
		if not Session.state.has(key):
			Session.state[key] = [] if key == "shipments" else {}
	if not Session.state.has("expedition_run"):
		Session.state.expedition_run = {}
	if not Session.state.has("weather_notified"):
		Session.state.weather_notified = -1
	if not Session.state.has("trinket"):
		Session.state.trinket = ""
	if migrate_surfaces:
		for key in Session.state.structures.keys():
			if (
				Content.structures[str(Session.state.structures[key].id)].kind
				in ["floor", "path", "bridge"]
			):
				Session.state.surfaces[key] = Session.state.structures[key]
				Session.state.structures.erase(key)


func _process(delta: float) -> void:
	if not Session.active or Session.paused or Session.state.is_empty() or Session.state.retired:
		return
	ensure_state()
	_update_fishing()
	tick_clock += delta
	if tick_clock < 1.0:
		return
	var elapsed := tick_clock
	tick_clock = 0
	_update_production()
	_update_shipments()
	_update_weather(elapsed)


func weather() -> String:
	if Session.state.is_empty():
		return "clear"
	var period := int(float(Session.state.time) / 360.0)
	var roll := Session.world_model.hash_cell(Vector2i(period, period / 4), 311) % 10
	return "storm" if roll == 0 else "rain" if roll < 3 else "clear"


func sheltered() -> bool:
	for structure in Session.state.structures.values():
		var kind := str(Content.structures[str(structure.id)].kind)
		if (
			kind in ["shelter", "hearth"]
			and Session.structure_position(structure).distance_to(Session.player_position()) < 100
		):
			return true
	return false


func _update_weather(delta: float) -> void:
	var condition := weather()
	var region := Session.world_model.region_at(Vector2i(Session.player_position() / 32.0))
	var exposed: bool = (
		not sheltered() and (condition == "storm" or (region == 3 and condition != "clear"))
	)
	if Session.has_buff("warmth"):
		exposed = false
	var armor := float(Content.items.get(str(Session.state.armor), {}).get("tier", 0))
	var rate := (.8 if condition == "storm" else .35) * (1.0 - armor * .15)
	var exposure := float(Session.state.player.exposure)
	Session.state.player.exposure = clampf(exposure + (rate if exposed else -2.0) * delta, 0, 100)
	warning_clock = maxf(0, warning_clock - delta)
	if float(Session.state.player.exposure) > 65 and warning_clock <= 0:
		Session.message.emit("ui.exposure_warning", {})
		warning_clock = 40
	if float(Session.state.player.exposure) > 85:
		Session.hurt(.8 * delta)
	var period := int(float(Session.state.time) / 360.0)
	if condition == "storm" and int(Session.state.weather_notified) != period:
		Session.state.weather_notified = period
		Session.message.emit("ui.storm", {})


func plant(key: String, seed_id: String = "seed") -> bool:
	var structure: Dictionary = Session.state.structures[key]
	if structure.has("planted_at"):
		return false
	if not Content.crops.has(seed_id) or not Session.pay({seed_id: 1}):
		return false
	structure.planted_at = Session.state.time
	structure.planted_seed = seed_id
	Session.changed.emit()
	return true


func grow_seconds(structure: Dictionary) -> float:
	var region := Session.world_model.region_at(
		Vector2i(int(structure.cell[0]), int(structure.cell[1]))
	)
	var seconds := float(
		Content.crops.get(str(structure.get("planted_seed", "seed")), {"seconds": 300}).seconds
	)
	if Session.has_perk("green_thumb"):
		seconds *= .7
	if Session.has_charm("garden"):
		seconds *= .85
	if Session.state.restored[region] and Session.state.attunements[region] == "bloom":
		seconds *= .75
	return seconds


func ready_in(structure: Dictionary) -> float:
	var kind := str(Content.structures[str(structure.id)].kind)
	if kind == "garden" and not structure.has("planted_at"):
		return -1
	var start := float(structure.get("planted_at", structure.placed_at))
	return maxf(0, grow_seconds(structure) - (float(Session.state.time) - start))


func harvest(key: String) -> bool:
	var structure: Dictionary = Session.state.structures[key]
	if ready_in(structure) != 0:
		return false
	var kind := str(Content.structures[str(structure.id)].kind)
	var seed_id := str(structure.get("planted_seed", "seed"))
	var id := (
		str(Content.crops[seed_id].produce)
		if kind == "garden"
		else "honey" if kind == "apiary" else "fish"
	)
	var rewards: Dictionary = {id: 3}
	if kind == "garden":
		rewards[seed_id] = 1
	if kind == "garden":
		for nearby in Session.state.structures.values():
			if (
				str(nearby.id) == "scarecrow"
				and (
					Session.structure_position(nearby).distance_to(
						Session.structure_position(structure)
					)
					<= 100
				)
			):
				rewards[id] = 4
				break
	if not Session.pay({}, "", 0, rewards):
		return false
	structure.placed_at = Session.state.time
	structure.erase("planted_at")
	structure.erase("planted_seed")
	Session.gain_xp(8)
	Sound.effect("pickup")
	return true


func queue_recipe(recipe_id: String, station_key: String) -> bool:
	ensure_state()
	if not Content.recipes.has(recipe_id) or not Session.state.structures.has(station_key):
		return false
	var recipe: Dictionary = Content.recipes[recipe_id]
	var structure: Dictionary = Session.state.structures[station_key]
	if str(structure.id) != str(recipe.station) or int(recipe.tier) > Session.unlocked_tier():
		return false
	if Session.structure_position(structure).distance_to(Session.player_position()) > 112:
		return false
	var production: Dictionary = Session.state.production.get(
		station_key, {"queue": [], "ready": {}}
	)
	if production.queue.size() >= 5:
		Session.message.emit("ui.queue_full", {})
		return false
	var costs: Dictionary = {}
	for ingredient in recipe.ingredients:
		costs[str(ingredient.id)] = int(ingredient.count)
	if not Session.pay(costs):
		return false
	var region := Session.world_model.region_at(
		Vector2i(int(structure.cell[0]), int(structure.cell[1]))
	)
	var duration := float(recipe.get("production_seconds", 20))
	if Session.state.restored[region] and Session.state.attunements[region] == "ember":
		duration *= .75
	for nearby in Session.state.structures.values():
		if (
			str(nearby.id) == "windmill"
			and (
				Session.structure_position(nearby).distance_to(
					Session.structure_position(structure)
				)
				<= 128
			)
		):
			duration *= .75
			break
	var start := (
		float(Session.state.time)
		if production.queue.is_empty()
		else float(production.queue[-1].finish)
	)
	production.queue.append(
		{
			"result": str(recipe.result.id),
			"count": int(recipe.result.count),
			"finish": start + duration
		}
	)
	Session.state.production[station_key] = production
	Session.changed.emit()
	Sound.effect("craft")
	return true


func _update_production() -> void:
	for production in Session.state.production.values():
		while (
			not production.queue.is_empty()
			and float(production.queue[0].finish) <= float(Session.state.time)
		):
			var batch: Dictionary = production.queue.pop_front()
			production.ready[batch.result] = (
				int(production.ready.get(batch.result, 0)) + int(batch.count)
			)


func collect_production(key: String) -> bool:
	ensure_state()
	_update_production()
	var production: Dictionary = Session.state.production.get(key, {"queue": [], "ready": {}})
	if production.ready.is_empty():
		return false
	if not Session.pay({}, "", 0, production.ready):
		return false
	production.ready = {}
	Session.state.production[key] = production
	Sound.effect("pickup")
	return true


func request_for(npc: String) -> Dictionary:
	ensure_state()
	var candidates: Array = Content.requests.filter(
		func(value: Dictionary): return str(value.npc) == npc
	)
	if candidates.is_empty():
		return {}
	var day := int(float(Session.state.time) / 1440.0)
	return candidates[
		(day + Session.world_model.hash_cell(Vector2i(npc.hash() % 100, 1))) % candidates.size()
	]


func deliver(npc: String) -> bool:
	var day := int(float(Session.state.time) / 1440.0)
	if int(Session.state.contracts.get(npc, -1)) == day:
		Session.message.emit("ui.request_today", {})
		return false
	var request := request_for(npc)
	if request.is_empty() or not Session.pay(request.cost, "", 0, request.reward):
		return false
	Session.state.contracts[npc] = day
	Session.state.goodwill[npc] = int(Session.state.goodwill.get(npc, 0)) + int(request.goodwill)
	Session.gain_xp(int(request.xp))
	Session.message.emit("ui.contract_done", {})
	return true


func trade(npc: String, id: String, count: int, price: int, goodwill: int) -> bool:
	ensure_state()
	var allowed: Dictionary = Content.trade_stock.get(id, {})
	if (
		allowed.is_empty()
		or int(allowed.count) != count
		or int(allowed.price) != price
		or int(allowed.goodwill) != goodwill
	):
		return false
	if int(Session.state.goodwill.get(npc, 0)) < goodwill:
		return false
	return Session.pay({"amber": price}, id, count)


func courier_chest(board_key: String) -> String:
	if not Session.state.structures.has(board_key):
		return ""
	var board: Dictionary = Session.state.structures[board_key]
	var position_ := Session.structure_position(board)
	var hearth := false
	var chest := ""
	var region := Session.world_model.region_at(Vector2i(int(board.cell[0]), int(board.cell[1])))
	if not Session.state.restored[region]:
		return ""
	for key in Session.state.structures:
		var structure: Dictionary = Session.state.structures[key]
		if Session.structure_position(structure).distance_to(position_) > 100:
			continue
		var kind := str(Content.structures[str(structure.id)].kind)
		if kind == "hearth":
			hearth = true
		if kind == "chest":
			chest = str(key)
	return chest if hearth else ""


func send_shipment(from_board: String, to_board: String) -> bool:
	ensure_state()
	var source := courier_chest(from_board)
	var destination := courier_chest(to_board)
	if source.is_empty() or destination.is_empty() or source == destination:
		Session.message.emit("ui.route_incomplete", {})
		return false
	var contents: Dictionary = {}
	for id in Session.state.structures[source].contents:
		if Content.items[id].kind == "material":
			contents[id] = Session.state.structures[source].contents[id]
	if contents.is_empty():
		Session.message.emit("ui.missing", {})
		return false
	for id in contents:
		Session.state.structures[source].contents.erase(id)
	Session.state.shipments.append(
		{
			"destination": destination,
			"origin": source,
			"contents": contents,
			"arrive": float(Session.state.time) + 30
		}
	)
	Session.message.emit("ui.shipment_sent", {})
	Session.changed.emit()
	return true


func _update_shipments() -> void:
	for index in range(Session.state.shipments.size() - 1, -1, -1):
		var shipment: Dictionary = Session.state.shipments[index]
		if float(shipment.arrive) > float(Session.state.time):
			continue
		if not Session.state.structures.has(shipment.destination):
			continue
		var contents: Dictionary = Session.state.structures[shipment.destination].contents
		for id in shipment.contents:
			contents[id] = int(contents.get(id, 0)) + int(shipment.contents[id])
		Session.state.shipments.remove_at(index)
		Session.message.emit("ui.shipment_arrived", {})


func cast_line(cell: Vector2i) -> void:
	if not fishing.is_empty():
		if (
			float(Session.state.time) >= float(fishing.bite)
			and float(Session.state.time) <= float(fishing.bite) + 1.8
		):
			var region := Session.world_model.region_at(cell)
			var hash_ := Session.world_model.hash_cell(cell, int(Session.state.time))
			var weight := snappedf(.3 + float(hash_ % 400) / 100.0 + region * .2, .01)
			var species := str(Content.fish_species[region])
			Session.reward_items({species: 1}, Session.player_position())
			Session.state.fishing_records.count = (
				int(Session.state.fishing_records.get("count", 0)) + 1
			)
			Session.state.fishing_records.best = maxf(
				float(Session.state.fishing_records.get("best", 0)), weight
			)
			Session.state.fishing_records[species] = (
				int(Session.state.fishing_records.get(species, 0)) + 1
			)
			Session.gain_xp(12)
			Sound.effect("pickup")
		else:
			Session.message.emit("ui.fish_missed", {})
		fishing = {}
		return
	var wait := (
		2.0 + float(Session.world_model.hash_cell(cell, int(Session.state.time)) % 30) / 10.0
	)
	fishing = {
		"position": Session.player_position(),
		"cell": [cell.x, cell.y],
		"bite": float(Session.state.time) + wait,
		"notified": false
	}
	Session.message.emit("ui.fish_wait", {})


func _update_fishing() -> void:
	if fishing.is_empty():
		return
	if (
		Session.player_position().distance_to(fishing.position) > 20
		or str(Session.state.equipped) != "fishing_rod"
	):
		fishing = {}
		return
	if float(Session.state.time) > float(fishing.bite) + 1.8:
		fishing = {}
		Session.message.emit("ui.fish_missed", {})
		return
	if float(Session.state.time) >= float(fishing.bite) and not fishing.notified:
		fishing.notified = true
		Session.message.emit("ui.bite", {})
		Sound.effect("pickup")


func observe(id: String, actor_id: String, killed := false) -> void:
	ensure_state()
	var entry: Dictionary = Session.state.bestiary.get(id, {"observed": [], "kills": 0})
	if not actor_id in entry.observed:
		entry.observed.append(actor_id)
	if killed:
		entry.kills = int(entry.kills) + 1
	Session.state.bestiary[id] = entry


func site_definition(id: String) -> Dictionary:
	for value in Content.points_of_interest:
		if str(value.id) == id:
			return value
	return {}


func discover_site(id: String) -> void:
	ensure_state()
	if not Session.state.sites.has(id):
		Session.state.sites[id] = {
			"discovered": true, "searched": false, "day": -1, "seals": [0, 0, 0]
		}
		Session.gain_xp(25)
		Session.message.emit(str(site_definition(id).name_key), {})


func site_action(id: String) -> bool:
	ensure_state()
	discover_site(id)
	var site := site_definition(id)
	var saved: Dictionary = Session.state.sites[id]
	var region := int(site.region)
	var kind := str(site.kind)
	if kind == "spring":
		return Session.add_item("water", 4)
	if kind == "grove":
		var day := int(float(Session.state.time) / 1440.0)
		if int(saved.day) == day:
			Session.message.emit("ui.grove_done", {})
			return false
		if not Session.pay({"seed": 3, "water": 4}, "amber", 5):
			return false
		saved.day = day
		Session.gain_xp(60)
		return true
	if kind == "expedition":
		if Session.state.settings.difficulty == "peaceful":
			if not Session.pay({"stone": 6, "amber": 2}):
				return false
			complete_expedition(id)
			return true
		expedition_requested.emit(id, int(Session.state.expeditions.get(id, 0)))
		return true
	if saved.searched:
		Session.message.emit("ui.searched", {})
		return false
	if kind == "puzzle" and saved.seals != puzzle_solution(id):
		Session.message.emit("ui.puzzle_wrong", {})
		return false
	if kind == "survey":
		var position_ := Session.world_model.poi_cell(id)
		var chunk := Vector2i(position_.x / 32, position_.y / 32)
		for y in range(chunk.y - 2, chunk.y + 3):
			for x in range(chunk.x - 2, chunk.x + 3):
				Session.state.discovered[Session.cell_key(Vector2i(x, y))] = true
		Session.message.emit("ui.surveyed", {})
	else:
		var reward: Dictionary = {"amber": 3 + region * 2, "ration": 2, "bandage": 2}
		if region > 0:
			reward[["copper_ore", "iron_ore", "storm_shard", "relic"][region - 1]] = 5
		if kind == "puzzle":
			reward.relic = 3 + region
		Session.reward_items(reward, Session.player_position())
	saved.searched = true
	Session.gain_xp(55 + region * 20)
	Sound.effect("restore")
	return true


func puzzle_solution(id: String) -> Array:
	var base := Session.world_model.hash_cell(Vector2i(id.hash() % 1000, 29), 55)
	return [base % 3, (base / 3) % 3, (base / 9) % 3]


func complete_expedition(id: String) -> void:
	var depth := int(Session.state.expeditions.get(id, 0)) + 1
	Session.state.expeditions[id] = depth
	var region := int(site_definition(id).region)
	var rewards: Dictionary = {"amber": 5 + region * 2 + mini(depth, 20), "tonic": 1}
	rewards[["wood", "copper_ore", "iron_ore", "storm_shard", "relic"][region]] = (
		8 + mini(depth, 20)
	)
	Session.reward_items(rewards, Session.player_position())
	Session.gain_xp(90 + region * 30 + mini(depth, 20) * 10)
	Session.message.emit("ui.expedition_win", {})
	Session.changed.emit()
