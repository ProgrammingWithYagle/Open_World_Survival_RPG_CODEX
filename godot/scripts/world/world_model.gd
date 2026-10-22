extends RefCounted
class_name MossWorld

const SIZE := 1024
const TILE := 32
const SPAWN := Vector2i(512, 520)
var seed_number: int
var terrain_noise := FastNoiseLite.new()
var detail_noise := FastNoiseLite.new()
var landmarks: Array[Vector2i] = []
var chunk_cache: Dictionary = {}
var tile_cache: Dictionary = {}
var region_cache: Dictionary = {}
var tile_slots: Array[Vector2i] = []
var region_slots: Array[Vector2i] = []
var tile_cursor := 0
var region_cursor := 0
var points_of_interest: Dictionary = {}
var road_segments: Array = []
const START_RESOURCES: Dictionary = {
	Vector2i(-7, -4): ["wood", 0],
	Vector2i(7, -4): ["wood", 2],
	Vector2i(-6, 4): ["stone", 4],
	Vector2i(6, 4): ["stone", 4],
	Vector2i(-5, 5): ["fiber", 9],
	Vector2i(5, 5): ["fiber", 9],
	Vector2i(-7, 2): ["berry", 8],
	Vector2i(7, 2): ["berry", 8],
	Vector2i(6, -5): ["amber", 3],
	Vector2i(-6, -5): ["amber", 3],
	Vector2i(4, 6): ["mushroom", 10]
}


func _init(value: int) -> void:
	seed_number = value
	terrain_noise.seed = value
	terrain_noise.frequency = 0.026
	detail_noise.seed = value + 7151
	detail_noise.frequency = 0.077
	landmarks = [
		Vector2i(535, 520),
		Vector2i(690 + int(hash_cell(Vector2i(1, 1)) % 35), 510),
		Vector2i(530, 715 + int(hash_cell(Vector2i(2, 2)) % 30)),
		Vector2i(325 - int(hash_cell(Vector2i(3, 3)) % 30), 490),
		Vector2i(510, 295 - int(hash_cell(Vector2i(4, 4)) % 30))
	]
	for landmark in landmarks:
		_add_road(SPAWN, landmark)
	for site in Content.points_of_interest:
		var offset := Vector2i(int(site.offset[0]), int(site.offset[1]))
		var cell := landmarks[int(site.region)] + offset
		points_of_interest[str(site.id)] = cell
		_add_road(landmarks[int(site.region)], cell)


func _add_road(from: Vector2i, to: Vector2i) -> void:
	var minimum := Vector2(mini(from.x, to.x) - 2, mini(from.y, to.y) - 2)
	var maximum := Vector2(maxi(from.x, to.x) + 2, maxi(from.y, to.y) + 2)
	road_segments.append(
		{"from": Vector2(from), "to": Vector2(to), "bounds": Rect2(minimum, maximum - minimum)}
	)


func poi_cell(id: String) -> Vector2i:
	return points_of_interest.get(id, SPAWN)


func arena_cell(region: int) -> Vector2i:
	return Vector2i(90 + region * 170, 90)


func safe_position(position_: Vector2, state: Dictionary) -> Vector2:
	var origin := Vector2i(position_ / 32.0)
	for distance in range(5):
		for y in range(-distance, distance + 1):
			for x in range(-distance, distance + 1):
				var cell := origin + Vector2i(x, y)
				if passable(cell, state):
					return Vector2(cell * 32) + Vector2(16, 20)
	return Vector2(SPAWN * 32)


func hash_cell(cell: Vector2i, salt := 0) -> int:
	var value: int = (
		(cell.x * 374761393 + cell.y * 668265263 + seed_number + salt * 1274126177) & 0x7fffffff
	)
	value = ((value ^ (value >> 13)) * 1274126177) & 0x7fffffff
	return (value ^ (value >> 16)) & 0x7fffffff


func region_at(cell: Vector2i) -> int:
	if region_cache.has(cell):
		return region_cache[cell]
	if cell.y > 78 and cell.y < 103:
		for region in range(5):
			if cell.distance_squared_to(arena_cell(region)) < 144:
				return region
	if cell.distance_to(Vector2i(512, 520)) < 100.0:
		return 0
	var best := INF
	var region := 0
	for i in range(landmarks.size()):
		var distance := cell.distance_to(landmarks[i])
		if i == 0:
			distance *= 1.08
		distance += detail_noise.get_noise_2d(cell.x + i * 33, cell.y) * 12.0
		if distance < best:
			best = distance
			region = i
	region_cache[cell] = region
	if region_slots.size() < 32768:
		region_slots.append(cell)
	else:
		region_cache.erase(region_slots[region_cursor])
		region_slots[region_cursor] = cell
		region_cursor = (region_cursor + 1) % 32768
	return region


func is_road(cell: Vector2i, width := .75) -> bool:
	var point := Vector2(cell)
	for segment in road_segments:
		if not segment.bounds.has_point(point):
			continue
		var nearest := Geometry2D.get_closest_point_to_segment(point, segment.from, segment.to)
		if nearest.distance_to(point) < width:
			return true
	return false


func is_clearing(cell: Vector2i) -> bool:
	if cell.y > 78 and cell.y < 103:
		for region in range(5):
			if cell.distance_to(arena_cell(region)) < 12:
				return true
	if cell.distance_to(SPAWN) < 6:
		return true
	for landmark in landmarks:
		if cell.distance_to(landmark) < 6:
			return true
	for point in points_of_interest.values():
		if cell.distance_squared_to(point) < 10:
			return true
	return false


func tile_at(cell: Vector2i) -> Dictionary:
	if tile_cache.has(cell):
		return tile_cache[cell]
	if cell.x < 0 or cell.y < 0 or cell.x >= SIZE or cell.y >= SIZE:
		return {"kind": "water", "region": 0, "variant": 0}
	var region := region_at(cell)
	var kind: String = ["grass", "marsh", "ash", "pine", "ruin"][region]
	for arena_region in range(5):
		if cell.distance_squared_to(arena_cell(arena_region)) < 144:
			var arena_result: Dictionary = {
				"kind": "ruin", "region": arena_region, "variant": hash_cell(cell, 5) % 4
			}
			return _cache_tile(cell, arena_result)
	if is_road(cell):
		kind = "path"
	elif not is_clearing(cell) and not is_road(cell, 1.2):
		var height := terrain_noise.get_noise_2d(cell.x, cell.y)
		if height < (-0.13 if region == 1 else -0.43):
			kind = "water"
		elif height > 0.36:
			kind = "dirt"
	var result: Dictionary = {"kind": kind, "region": region, "variant": hash_cell(cell, 5) % 4}
	return _cache_tile(cell, result)


func _cache_tile(cell: Vector2i, result: Dictionary) -> Dictionary:
	tile_cache[cell] = result
	if tile_slots.size() < 32768:
		tile_slots.append(cell)
	else:
		tile_cache.erase(tile_slots[tile_cursor])
		tile_slots[tile_cursor] = cell
		tile_cursor = (tile_cursor + 1) % 32768
	return result


func node_at(cell: Vector2i) -> Dictionary:
	var offset := cell - SPAWN
	if START_RESOURCES.has(offset):
		var entry: Array = START_RESOURCES[offset]
		return {
			"id": entry[0],
			"art": entry[1],
			"tier": 1,
			"amount": 8,
			"solid": entry[0] in ["wood", "stone"],
			"icon": "amber" if entry[0] == "amber" else ""
		}
	if is_road(cell, 1.2) or is_clearing(cell):
		return {}
	var tile := tile_at(cell)
	if tile.kind == "water":
		return {}
	var roll := hash_cell(cell, 11) % 1000
	var region := int(tile.region)
	var resource := ""
	var art := 0
	var tier := 1
	if roll < 95:
		resource = "wood"
		art = [0, 2, 3, 1, 3][region]
	elif roll < 125:
		resource = "stone"
		art = 4
	elif roll < 155:
		resource = "fiber"
		art = 9
	elif roll < 178:
		resource = "berry"
		art = 8
	elif roll < 195:
		resource = "mushroom"
		art = 10
	elif roll < 203:
		resource = "amber"
		art = 3
	elif region == 1 and roll < 242:
		resource = "reed"
		art = 11
	elif region == 1 and roll < 269:
		resource = "copper_ore"
		art = 5
	elif region == 1 and roll < 283:
		resource = "clay"
		art = 4
	elif region == 2 and roll < 245:
		resource = "iron_ore"
		art = 6
		tier = 2
	elif region == 3 and roll < 243:
		resource = "storm_shard"
		art = 7
		tier = 3
	elif region == 4 and roll < 242:
		resource = "relic"
		art = 7
		tier = 4
	elif roll >= 295 and roll < 310:
		resource = ["mint", "mint", "sunblossom", "sage", "orchid"][region]
		art = 10
	elif region == 2 and roll >= 310 and roll < 325:
		resource = "sunroot"
		art = 10
	if resource.is_empty():
		return {}
	return {
		"id": resource,
		"art": art,
		"tier": tier,
		"amount": 3,
		"solid": resource in ["wood", "stone", "copper_ore", "iron_ore", "storm_shard", "relic"],
		"icon":
		resource if resource in ["amber", "mint", "sunblossom", "sage", "orchid", "sunroot"] else ""
	}


func nodes_in_chunk(chunk: Vector2i) -> Array:
	var key := "%d:%d" % [chunk.x, chunk.y]
	if chunk_cache.has(key):
		return chunk_cache[key]
	var result: Array = []
	for y in range(chunk.y * 32, (chunk.y + 1) * 32):
		for x in range(chunk.x * 32, (chunk.x + 1) * 32):
			var cell := Vector2i(x, y)
			var node := node_at(cell)
			if not node.is_empty():
				node.cell = [x, y]
				result.append(node)
	cache_chunk(key, result)
	return result


func cache_chunk(key: String, result: Array) -> void:
	chunk_cache[key] = result
	if chunk_cache.size() > 64:
		chunk_cache.erase(chunk_cache.keys()[0])


func passable(cell: Vector2i, state: Dictionary) -> bool:
	if cell.x < 1 or cell.y < 1 or cell.x >= SIZE - 1 or cell.y >= SIZE - 1:
		return false
	if not state.get("expedition_run", {}).is_empty():
		var region := int(Activities.site_definition(str(state.expedition_run.site)).region)
		var center := arena_cell(region)
		if absi(cell.x - center.x) > 8 or absi(cell.y - center.y) > 7:
			return false
	var key := "%d:%d" % [cell.x, cell.y]
	var bridge: bool = (
		state.get("surfaces", {}).has(key)
		and str(Content.structures[str(state.surfaces[key].id)].kind) == "bridge"
	)
	if state.structures.has(key):
		var definition: Dictionary = Content.structures[str(state.structures[key].id)]
		if definition.kind == "bridge":
			return true
		if definition.kind == "gate" and not bool(state.structures[key].get("closed", true)):
			return true
		if definition.kind == "gate":
			return false
		if bool(definition.solid):
			return false
	if tile_at(cell).kind == "water" and not bridge:
		return false
	var node := node_at(cell)
	if node.is_empty() or not bool(node.solid):
		return true
	if state.nodes.has(key):
		var saved: Dictionary = state.nodes[key]
		if (
			int(saved.get("remaining", 3)) <= 0
			and float(saved.get("regrow", 0)) > float(state.time)
		):
			return true
	return false
