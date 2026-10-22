extends Node

const SCHEMA := 1
const DIRECTORY := "user://journeys"
var last_error := ""


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(DIRECTORY)


func _path(id: String, suffix := "") -> String:
	assert(id.is_valid_int() or id.begins_with("test_"), "Invalid journey identifier")
	return "%s/%s%s.json" % [DIRECTORY, id, suffix]


func save_world(state: Dictionary) -> bool:
	last_error = ""
	var snapshot: Dictionary = state.duplicate(true)
	snapshot.schema_version = SCHEMA
	snapshot.game_version = Content.VERSION
	snapshot.saved_at = Time.get_unix_time_from_system()
	var target := _path(str(snapshot.id))
	var pending := target + ".pending"
	var file := FileAccess.open(pending, FileAccess.WRITE)
	if file == null:
		last_error = "ui.save_failed"
		return false
	var body := JSON.stringify(snapshot)
	var envelope := JSON.stringify({"sha256": body.sha256_text(), "body": body})
	file.store_string(envelope)
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK or not _read_valid(pending).ok:
		last_error = "ui.save_failed"
		return false
	# Keep complete generations, never a mixture of individual world files.
	for index in range(2, 0, -1):
		var old := target + ".bak%d" % index
		var new := target + ".bak%d" % (index + 1)
		if FileAccess.file_exists(old):
			if DirAccess.copy_absolute(old, new) != OK:
				last_error = "ui.save_failed"
				return false
	if FileAccess.file_exists(target):
		if DirAccess.copy_absolute(target, target + ".bak1") != OK:
			last_error = "ui.save_failed"
			return false
	if DirAccess.rename_absolute(pending, target) != OK:
		last_error = "ui.save_failed"
		return false
	return true


func _read_valid(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false}
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		return {"ok": false}
	var wrapper: Variant = parser.data
	if not wrapper is Dictionary or not wrapper.has("body") or not wrapper.has("sha256"):
		return {"ok": false}
	if str(wrapper.body).sha256_text() != str(wrapper.sha256):
		return {"ok": false}
	if parser.parse(str(wrapper.body)) != OK:
		return {"ok": false}
	var state: Variant = parser.data
	if not state is Dictionary:
		return {"ok": false}
	if int(state.get("schema_version", 0)) > SCHEMA:
		return {"ok": false, "error": "ui.newer_save"}
	if not _valid_state(state):
		return {"ok": false}
	return {"ok": true, "state": state}


func _valid_state(state: Dictionary) -> bool:
	for key in [
		"id",
		"seed",
		"seed_int",
		"player",
		"inventory",
		"settings",
		"structures",
		"restored",
		"wardens",
		"time",
		"equipped",
		"armor",
		"attunements",
		"discovered",
		"visited_regions",
		"npc_met",
		"perks",
		"xp",
		"level",
		"skill_points",
		"graves",
		"quest_stage",
		"gathered",
		"contracts",
		"retired",
		"completed",
		"mob_state",
		"nodes",
		"expeditions"
	]:
		if not state.has(key):
			return false
	if not (
		state.inventory is Dictionary
		and state.player is Dictionary
		and state.structures is Dictionary
		and state.settings is Dictionary
	):
		return false
	if not (str(state.id).is_valid_int() or str(state.id).begins_with("test_")):
		return false
	if not _number(state.time) or float(state.time) < 0 or not _number(state.seed_int):
		return false
	for key in ["discovered", "gathered", "contracts", "mob_state", "nodes", "expeditions"]:
		if not state[key] is Dictionary:
			return false
	for key in [
		"surfaces",
		"drops",
		"production",
		"bestiary",
		"fishing_records",
		"goodwill",
		"buffs",
		"sites"
	]:
		if state.has(key) and not state[key] is Dictionary:
			return false
	if state.has("shipments") and not state.shipments is Array:
		return false
	for key in ["xp", "level", "skill_points", "quest_stage"]:
		if (
			not _number(state[key])
			or float(state[key]) < 0
			or float(state[key]) != floorf(float(state[key]))
		):
			return false
	if int(state.level) < 1 or int(state.quest_stage) > 7:
		return false
	if (
		not state.retired is bool
		or not state.completed is bool
		or not state.player.get("dead") is bool
	):
		return false
	if not str(state.settings.get("difficulty", "")) in Content.difficulties:
		return false
	if not str(state.settings.get("death_mode", "")) in ["easycore", "mediumcore", "hardcore"]:
		return false
	for key in ["position", "home"]:
		var value: Variant = state.player.get(key)
		if not value is Array or value.size() != 2:
			return false
		for coordinate in value:
			if not (coordinate is float or coordinate is int) or not is_finite(float(coordinate)):
				return false
	for key in ["health", "food", "water", "stamina"]:
		var value: Variant = state.player.get(key)
		if not (value is float or value is int) or not is_finite(float(value)) or float(value) < 0:
			return false
	if not _valid_bag(state.inventory):
		return false
	for key in ["restored", "wardens"]:
		if not state[key] is Array or state[key].size() != 5:
			return false
		for value in state[key]:
			if not value is bool:
				return false
	if not state.attunements is Array or state.attunements.size() != 5:
		return false
	for current in state.attunements:
		if not current in ["bloom", "ember", "gale"]:
			return false
	for key in ["visited_regions", "npc_met", "perks", "graves"]:
		if not state[key] is Array:
			return false
	for region in state.visited_regions:
		if not _number(region) or int(region) < 0 or int(region) > 4:
			return false
	for id in state.perks:
		if not id in Content.perks:
			return false
	for key in ["equipped", "armor", "trinket"]:
		var id := str(state.get(key, ""))
		if (
			not id.is_empty()
			and (not Content.items.has(id) or int(state.inventory.get(id, 0)) <= 0)
		):
			return false
	for structure in state.structures.values():
		if not _valid_structure(structure):
			return false
	for structure in state.get("surfaces", {}).values():
		if not _valid_structure(structure):
			return false
	for grave in state.graves:
		if (
			not grave is Dictionary
			or not _valid_position(grave.get("position"))
			or not _valid_bag(grave.get("contents"))
		):
			return false
	for drop in state.get("drops", {}).values():
		if (
			not drop is Dictionary
			or not _valid_position(drop.get("position"))
			or not _valid_bag(drop.get("contents"))
		):
			return false
	for production in state.get("production", {}).values():
		if (
			not production is Dictionary
			or not production.get("queue") is Array
			or not _valid_bag(production.get("ready"))
		):
			return false
		for batch in production.queue:
			if (
				not batch is Dictionary
				or not Content.items.has(str(batch.get("result", "")))
				or not _number(batch.get("count"))
				or int(batch.count) <= 0
				or not _number(batch.get("finish"))
			):
				return false
	for shipment in state.get("shipments", []):
		if (
			not shipment is Dictionary
			or not _valid_bag(shipment.get("contents"))
			or not _number(shipment.get("arrive"))
			or not state.structures.has(str(shipment.get("destination", "")))
		):
			return false
	return true


func _number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))


func _valid_position(value: Variant) -> bool:
	return (
		value is Array
		and value.size() == 2
		and _number(value[0])
		and _number(value[1])
		and float(value[0]) >= 0
		and float(value[1]) >= 0
		and float(value[0]) < 32768
		and float(value[1]) < 32768
	)


func _valid_bag(value: Variant) -> bool:
	if not value is Dictionary:
		return false
	for id in value:
		if (
			not Content.items.has(id)
			or not _number(value[id])
			or float(value[id]) <= 0
			or float(value[id]) != floorf(float(value[id]))
		):
			return false
	return true


func _valid_structure(value: Variant) -> bool:
	if (
		not value is Dictionary
		or not Content.structures.has(str(value.get("id", "")))
		or not _valid_bag(value.get("contents"))
	):
		return false
	var cell: Variant = value.get("cell")
	return (
		cell is Array
		and cell.size() == 2
		and _number(cell[0])
		and _number(cell[1])
		and int(cell[0]) >= 0
		and int(cell[1]) >= 0
		and int(cell[0]) < 1024
		and int(cell[1]) < 1024
	)


func load_world(id: String, recover := true) -> Dictionary:
	last_error = ""
	var path := _path(id)
	var primary := _read_valid(path)
	if primary.ok:
		if FileAccess.file_exists(path + ".retired"):
			primary.state.retired = true
			primary.state.player.dead = true
		return primary.state
	if primary.get("error", "") == "ui.newer_save":
		last_error = "ui.newer_save"
		return {}
	var retired := FileAccess.file_exists(path + ".retired")
	if recover:
		for index in range(1, 4):
			var backup := _read_valid(path + ".bak%d" % index)
			if backup.ok:
				if retired:
					backup.state.retired = true
					backup.state.player.dead = true
				return backup.state
	last_error = "ui.load_failed"
	return {}


func retire(id: String) -> bool:
	var file := FileAccess.open(_path(id) + ".retired", FileAccess.WRITE)
	if file == null:
		last_error = "ui.save_failed"
		return false
	file.store_string("This character's journey has ended.")
	file.flush()
	return file.get_error() == OK


func list_worlds() -> Array:
	var result: Array = []
	var directory := DirAccess.open(DIRECTORY)
	if directory == null:
		return result
	var identifiers: Dictionary = {}
	for file in directory.get_files():
		for suffix in [".json", ".json.bak1", ".json.bak2", ".json.bak3"]:
			if file.ends_with(suffix):
				var id := file.trim_suffix(suffix)
				if id.is_valid_int():
					identifiers[id] = true
	for id in identifiers:
		var state := load_world(str(id))
		if not state.is_empty():
			result.append(
				{
					"id": state.id,
					"name": state.get("name", ""),
					"saved_at": state.get("saved_at", 0),
					"retired": state.get("retired", false),
					"day": int(float(state.time) / 1440.0) + 1,
					"settings": state.settings
				}
			)
		else:
			result.append({"id": id, "name": id, "saved_at": 0, "error": last_error})
	result.sort_custom(
		func(a: Dictionary, b: Dictionary): return float(a.saved_at) > float(b.saved_at)
	)
	return result
