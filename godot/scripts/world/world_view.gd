extends Node2D
class_name MossWorldView

signal interact_requested(target: Dictionary)
signal action_effect(position_: Vector2, kind: String)
var ground: TileMapLayer
var entities: Node2D
var camera: Camera2D
var player: MossPlayer
var props: Dictionary = {}
var actors: Dictionary = {}
var current_chunk := Vector2i(-999, -999)
var prop_clock := 0.0
var target: Dictionary = {}
var textures: Dictionary = {}
var placing := ""
var preview_cell := Vector2i.ZERO
var qa_mode := false
var alpha_shader: Shader
var active_cells: Dictionary = {}
var terrain_material: ShaderMaterial
var harvest_ready := 0.0
var trial_mode := false
var using_controller := false
var light_texture: GradientTexture2D
var shake_time := 0.0
var streaming_generation := 0
var streaming_pending := false
var retiring := false


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	alpha_shader = Shader.new()
	alpha_shader.code = "shader_type canvas_item; void fragment(){float a=texture(TEXTURE,UV).a; if(a<0.83){discard;} COLOR.a=COLOR.a/max(a,0.001);}"
	light_texture = GradientTexture2D.new()
	var gradient := Gradient.new()
	gradient.set_color(0, Color.WHITE)
	gradient.set_color(1, Color(1, 1, 1, 0))
	light_texture.gradient = gradient
	light_texture.width = 64
	light_texture.height = 64
	light_texture.fill = GradientTexture2D.FILL_RADIAL
	light_texture.fill_from = Vector2(.5, .5)
	light_texture.fill_to = Vector2(1, .5)
	ground = TileMapLayer.new()
	terrain_material = ShaderMaterial.new()
	terrain_material.shader = load("res://scripts/world/terrain.gdshader")
	ground.material = terrain_material
	add_child(ground)
	_build_tileset()
	entities = Node2D.new()
	entities.y_sort_enabled = true
	add_child(entities)
	player = MossPlayer.new()
	player.world_view = self
	entities.add_child(player)
	player.position = Session.player_position()
	camera = Camera2D.new()
	camera.position = player.position
	camera.position_smoothing_enabled = false
	add_child(camera)
	camera.make_current()
	refresh(true)
	Session.snapshot_requested.connect(persist_actors)
	Session.player_hurt.connect(_on_player_hurt)


func _on_player_hurt() -> void:
	shake_time = .12


func retire() -> void:
	# Let suspended chunk jobs observe cancellation while this node is still alive.
	retiring = true
	streaming_generation += 1
	streaming_pending = false
	process_mode = Node.PROCESS_MODE_DISABLED
	hide()
	if Session.snapshot_requested.is_connected(persist_actors):
		Session.snapshot_requested.disconnect(persist_actors)
	if Session.player_hurt.is_connected(_on_player_hurt):
		Session.player_hurt.disconnect(_on_player_hurt)


func persist_actors() -> void:
	for actor in actors.values():
		if is_instance_valid(actor):
			actor.persist()


func _build_tileset() -> void:
	var path := "res://art/environment/terrain.png"
	if not ResourceLoader.exists(path):
		return
	var tiles := TileSet.new()
	tiles.tile_size = Vector2i(32, 32)
	var atlas := TileSetAtlasSource.new()
	atlas.texture = load(path)
	atlas.texture_region_size = Vector2i(32, 32)
	for y in range(4):
		for x in range(4):
			atlas.create_tile(Vector2i(x, y))
	tiles.add_source(atlas, 0)
	ground.tile_set = tiles


func _process(delta: float) -> void:
	if Session.state.is_empty():
		return
	camera.position = player.position.round()
	shake_time = maxf(0, shake_time - delta)
	camera.offset = (
		Vector2.ZERO
		if bool(L.preferences.reduce_motion)
		else (
			Vector2(sin(Time.get_ticks_msec() * .064), cos(Time.get_ticks_msec() * .057)).round()
			* 2
			* shake_time
			/ .12
		)
	)
	prop_clock += delta
	if prop_clock > .2:
		prop_clock = 0
		refresh(false)
		_find_target()
	preview_cell = Vector2i(aim_position() / 32.0)
	queue_redraw()


func _draw() -> void:
	if Activities.weather() != "clear" and not bool(L.preferences.reduce_motion):
		var time := float(Session.state.time)
		for index in range(28):
			var x := fposmod(float(index * 73) + time * 32, 640.0) - 320
			var y := fposmod(float(index * 47) + time * 155, 360.0) - 180
			var pos: Vector2 = player.position + Vector2(x, y)
			draw_line(pos, pos + Vector2(-2, 6), Color(.65, .79, .79, .23), 1)
	if trial_mode:
		var region := int(Activities.site_definition(str(Session.state.expedition_run.site)).region)
		var center := Vector2(Session.world_model.arena_cell(region) * 32) + Vector2(16, 16)
		var wall := structure_texture("stone_wall")
		if wall != null:
			for x in range(-9, 10):
				for y in [-8, 8]:
					draw_texture(wall, center + Vector2(x * 32 - 16, y * 32 - 32))
			for y in range(-7, 8):
				for x in [-9, 9]:
					draw_texture(wall, center + Vector2(x * 32 - 16, y * 32 - 32))
	if not placing.is_empty():
		var valid := can_place(placing, preview_cell)
		var color := Color(.6, .85, .57, .5) if valid else Color(.95, .35, .25, .5)
		draw_rect(Rect2(Vector2(preview_cell * 32), Vector2(32, 32)), color)
		var texture := structure_texture(placing)
		if texture != null:
			draw_texture(
				texture,
				(
					Vector2(preview_cell * 32)
					+ Vector2(16 - texture.get_width() / 2.0, 28 - texture.get_height())
				),
				Color(1, 1, 1, .65)
			)
	if not target.is_empty():
		var pos: Vector2 = target.position
		draw_arc(pos + Vector2(0, 1), 11.0, 0, TAU, 20, Color(.91, .78, .48, .9), 1.0)
	for grave in Session.state.graves:
		var pos := Vector2(float(grave.position[0]), float(grave.position[1]))
		draw_line(pos + Vector2(-4, -10), pos + Vector2(4, -10), Color(.91, .83, .64), 2)
		draw_line(pos + Vector2(0, -14), pos + Vector2(0, -2), Color(.91, .83, .64), 2)
	for drop in Session.state.get("drops", {}).values():
		var pos := Vector2(float(drop.position[0]), float(drop.position[1]))
		var texture := _texture("res://art/icons/ration.png")
		if texture != null:
			draw_texture_rect(texture, Rect2(pos - Vector2(10, 20), Vector2(20, 20)), false)
	for i in range(Session.world_model.landmarks.size()):
		var pos := Vector2(Session.world_model.landmarks[i] * 32) + Vector2(16, 24)
		if player.position.distance_to(pos) < 600:
			var color := Color(.49, .8, .72) if Session.state.restored[i] else Color(.56, .6, .54)
			draw_arc(pos, 20, 0, TAU, 24, color.darkened(.3), 2)
			if Session.state.restored[i]:
				draw_arc(
					pos,
					24 + sin(Time.get_ticks_msec() * .001) * 1.5,
					0,
					TAU,
					24,
					Color(.67, .85, .68, .4),
					1
				)


func refresh(force := false) -> void:
	if retiring:
		return
	var cell := Vector2i(player.position / 32.0)
	var chunk := Vector2i(floori(float(cell.x) / 32.0), floori(float(cell.y) / 32.0))
	if chunk != current_chunk or force:
		current_chunk = chunk
		_stream_ground(chunk, force)
	var wanted: Dictionary = {}
	for cy in range(chunk.y - 1, chunk.y + 2):
		for cx in range(chunk.x - 1, chunk.x + 2):
			var cache_key := "%d:%d" % [cx, cy]
			if not force and not Session.world_model.chunk_cache.has(cache_key):
				continue
			for definition in Session.world_model.nodes_in_chunk(Vector2i(cx, cy)):
				var node_cell := Vector2i(int(definition.cell[0]), int(definition.cell[1]))
				if absi(node_cell.x - cell.x) > 17 or absi(node_cell.y - cell.y) > 12:
					continue
				var key := Session.cell_key(node_cell)
				if Session.state.structures.has(key):
					continue
				var saved: Dictionary = Session.state.nodes.get(key, {})
				if (
					int(saved.get("remaining", 3)) <= 0
					and float(saved.get("regrow", 0)) > float(Session.state.time)
				):
					continue
				wanted[key] = true
				if not props.has(key):
					_add_prop(
						key,
						node_cell,
						(
							Content.icon(str(definition.icon))
							if not str(definition.get("icon", "")).is_empty()
							else resource_texture(int(definition.art))
						),
						definition
					)
	for key in Session.state.structures:
		var data: Dictionary = Session.state.structures[key]
		var node_cell := Vector2i(int(data.cell[0]), int(data.cell[1]))
		if absi(node_cell.x - cell.x) > 18 or absi(node_cell.y - cell.y) > 13:
			continue
		wanted[key] = true
		if not props.has(key):
			_add_prop(
				key, node_cell, structure_texture(str(data.id)), {"structure": true, "id": data.id}
			)
		if data.id == "garden" and props.has(key):
			var stage := 0
			if data.has("planted_at"):
				var progress := 1.0 - Activities.ready_in(data) / Activities.grow_seconds(data)
				stage = 1 if progress < .4 else 2
				if progress >= 1.0:
					stage = int(
						(
							{
								"seed": 3,
								"berry_seed": 4,
								"reed_seed": 5,
								"mushroom_spawn": 6,
								"sunroot_seed": 7,
								"grain_seed": 8
							}
							. get(str(data.get("planted_seed", "seed")), 3)
						)
					)
			var texture := _texture("res://art/environment/garden_%d.png" % stage)
			if texture != null:
				props[key].node.texture = texture
				props[key].node.offset = Vector2(-20, -40)
	for cell_key in Session.state.get("surfaces", {}):
		var data: Dictionary = Session.state.surfaces[cell_key]
		var node_cell := Vector2i(int(data.cell[0]), int(data.cell[1]))
		if absi(node_cell.x - cell.x) > 18 or absi(node_cell.y - cell.y) > 13:
			continue
		var key := "surface_" + str(cell_key)
		wanted[key] = true
		if not props.has(key):
			_add_prop(
				key,
				node_cell,
				_texture("res://art/environment/surface_%s.png" % str(data.id)),
				{"surface": true, "id": data.id}
			)
			if props.has(key):
				props[key].node.z_index = -3
	for i in range(Session.world_model.landmarks.size()):
		var landmark: Vector2i = Session.world_model.landmarks[i]
		if absi(landmark.x - cell.x) < 18 and absi(landmark.y - cell.y) < 13:
			var key := "waystone_" + str(i)
			wanted[key] = true
			var texture := _texture(
				(
					"res://art/environment/site_waystone_%s.png"
					% ("restored" if Session.state.restored[i] else "broken")
				)
			)
			if not props.has(key):
				_add_prop(key, landmark, texture, {"waystone": i})
			elif texture != null:
				props[key].node.texture = texture
	for index in range(Content.npcs.size()):
		var npc: Dictionary = Content.npcs[index]
		var npc_cell := npc_cell_at(index)
		if absi(npc_cell.x - cell.x) > 17 or absi(npc_cell.y - cell.y) > 12:
			continue
		var key := "npc_" + str(npc.id)
		wanted[key] = true
		if not props.has(key):
			_add_prop(
				key,
				npc_cell,
				_texture("res://art/sprites/npc_%d.png" % index),
				{"npc": str(npc.id), "index": index}
			)
	for site in Content.points_of_interest:
		var site_cell := Session.world_model.poi_cell(str(site.id))
		if absi(site_cell.x - cell.x) > 18 or absi(site_cell.y - cell.y) > 13:
			continue
		var key := "site_" + str(site.id)
		wanted[key] = true
		if not props.has(key):
			_add_prop(
				key,
				site_cell,
				_texture("res://art/environment/site_%s.png" % str(site.kind)),
				{"site": str(site.id)}
			)
		if site_cell.distance_to(cell) < 7:
			Activities.discover_site(str(site.id))
	for key in props.keys():
		if not wanted.has(key):
			props[key].node.queue_free()
			props.erase(key)
		else:
			var sprite: Sprite2D = props[key].node
			var canopy := Rect2(sprite.position + sprite.offset, Vector2(sprite.texture.get_size()))
			sprite.modulate.a = (
				.4
				if (
					sprite.position.y > player.position.y
					and canopy.has_point(player.position + Vector2(0, -25))
				)
				else 1.0
			)
			if props[key].data.has("structure"):
				var structure: Dictionary = Session.state.structures.get(str(key), {})
				if structure.get("id", "") == "gate" and not bool(structure.get("closed", true)):
					sprite.modulate.a = .45
			if sprite.has_node("Lamplight"):
				var phase := fposmod(float(Session.state.time), 1440.0) / 1440.0
				sprite.get_node("Lamplight").enabled = phase < .23 or phase > .65
	if not qa_mode and not trial_mode:
		_stream_creatures(chunk)


func _stream_ground(chunk: Vector2i, immediate := false) -> void:
	if retiring or ground.tile_set == null:
		return
	streaming_generation += 1
	var generation := streaming_generation
	streaming_pending = true
	var budget_started := Time.get_ticks_usec()
	var wanted: Dictionary = {}
	var type_index: Dictionary = {
		"grass": 0, "marsh": 2, "ash": 4, "pine": 6, "ruin": 8, "path": 10, "dirt": 12, "water": 14
	}
	var origin := (chunk - Vector2i.ONE) * 32
	var kind_image := Image.create(98, 98, false, Image.FORMAT_R8)
	for y in range(98):
		for x in range(98):
			var tile := Session.world_model.tile_at(origin + Vector2i(x - 1, y - 1))
			kind_image.set_pixel(x, y, Color(float(int(type_index[tile.kind]) / 2) / 255.0, 0, 0))
		if not immediate and Time.get_ticks_usec() - budget_started > 2200:
			await get_tree().process_frame
			if generation != streaming_generation:
				return
			budget_started = Time.get_ticks_usec()
	terrain_material.set_shader_parameter("kind_map", ImageTexture.create_from_image(kind_image))
	terrain_material.set_shader_parameter("tile_origin", origin)
	for y in range((chunk.y - 1) * 32, (chunk.y + 2) * 32):
		for x in range((chunk.x - 1) * 32, (chunk.x + 2) * 32):
			var cell := Vector2i(x, y)
			wanted[cell] = true
			if active_cells.has(cell):
				continue
			var tile := Session.world_model.tile_at(cell)
			var index := int(type_index[tile.kind]) + int(tile.variant) % 2
			ground.set_cell(cell, 0, Vector2i(index % 4, index / 4))
		if not immediate and Time.get_ticks_usec() - budget_started > 2200:
			await get_tree().process_frame
			if generation != streaming_generation:
				return
			budget_started = Time.get_ticks_usec()
	for cell in active_cells:
		if not wanted.has(cell):
			ground.erase_cell(cell)
	active_cells = wanted
	for cy in range(chunk.y - 1, chunk.y + 2):
		for cx in range(chunk.x - 1, chunk.x + 2):
			var key := "%d:%d" % [cx, cy]
			if Session.world_model.chunk_cache.has(key):
				continue
			var definitions: Array = []
			for y in range(cy * 32, (cy + 1) * 32):
				for x in range(cx * 32, (cx + 1) * 32):
					var node := Session.world_model.node_at(Vector2i(x, y))
					if not node.is_empty():
						node.cell = [x, y]
						definitions.append(node)
				if not immediate and Time.get_ticks_usec() - budget_started > 2200:
					await get_tree().process_frame
					if generation != streaming_generation:
						return
					budget_started = Time.get_ticks_usec()
			Session.world_model.cache_chunk(key, definitions)
	streaming_pending = false


func _add_prop(key: String, cell: Vector2i, texture: Texture2D, data: Dictionary) -> void:
	if texture == null:
		return
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	sprite.offset = Vector2(-texture.get_width() / 2.0, -texture.get_height())
	sprite.position = Vector2(cell * 32) + Vector2(16, 28)
	var material_ := ShaderMaterial.new()
	material_.shader = alpha_shader
	sprite.material = material_
	entities.add_child(sprite)
	props[key] = {"node": sprite, "data": data, "cell": cell}
	if data.has("structure") and Content.structures[str(data.id)].kind in ["hearth", "light"]:
		var light := PointLight2D.new()
		light.name = "Lamplight"
		light.texture = light_texture
		light.texture_scale = 3.2
		light.color = Color(1, .79, .53)
		light.energy = .8
		light.position = Vector2(0, -16)
		sprite.add_child(light)


func npc_cell_at(index: int) -> Vector2i:
	if index == 0:
		return Vector2i(514, 521)
	if index == 1:
		return Vector2i(508, 518)
	var region := int(Content.npcs[index].region)
	return Session.world_model.landmarks[region] + Vector2i(-3, 3 + index % 2)


func _texture(path: String) -> Texture2D:
	if textures.has(path):
		return textures[path]
	if not ResourceLoader.exists(path):
		return null
	var texture: Texture2D = load(path)
	textures[path] = texture
	return texture


func resource_texture(index: int) -> Texture2D:
	return _texture("res://art/environment/prop_%02d.png" % index)


func structure_texture(id: String) -> Texture2D:
	var texture := _texture("res://art/environment/build_%s.png" % id)
	if texture != null:
		return texture
	var fallback: Dictionary = {
		"hearth": 12, "stone_hearth": 12, "chest": 13, "workbench": 14, "tent": 15
	}
	return resource_texture(int(fallback.get(id, 14)))


func _find_target() -> void:
	target = {}
	var best := 54.0
	for key in props:
		var prop: Dictionary = props[key]
		if prop.data.has("surface"):
			continue
		var distance: float = player.position.distance_to(prop.node.position)
		if distance < best:
			best = distance
			target = {
				"key": key, "position": prop.node.position, "data": prop.data, "cell": prop.cell
			}
	for id in Session.state.get("drops", {}):
		var drop: Dictionary = Session.state.drops[id]
		var pos := Vector2(float(drop.position[0]), float(drop.position[1]))
		if player.position.distance_to(pos) < best:
			best = player.position.distance_to(pos)
			target = {"drop": str(id), "position": pos}
	for i in range(Session.state.graves.size()):
		var pos := Vector2(
			float(Session.state.graves[i].position[0]), float(Session.state.graves[i].position[1])
		)
		if player.position.distance_to(pos) < best:
			best = player.position.distance_to(pos)
			target = {"grave": i, "position": pos}


func interact() -> void:
	if Session.paused:
		return
	_find_target()
	if not target.is_empty():
		if target.has("drop"):
			Session.collect_drop(str(target.drop))
			return
		if target.has("grave"):
			Session.recover_grave(int(target.grave))
			return
		var data: Dictionary = target.data
		if data.has("npc") or data.has("waystone") or data.has("structure") or data.has("site"):
			interact_requested.emit(target)
			return
		player.gather(target)
	else:
		var cell := Vector2i(player.position / 32.0)
		for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			if Session.world_model.tile_at(cell + offset).kind == "water":
				if str(Session.state.equipped) == "fishing_rod":
					Activities.cast_line(cell + offset)
				else:
					Session.add_item("water", 1)
					Sound.effect("pickup")
				return


func harvest(value: Dictionary) -> void:
	if float(Session.state.time) < harvest_ready:
		return
	var cell: Vector2i = value.cell
	var node: Dictionary = Session.world_model.node_at(cell)
	if node.is_empty():
		return
	var equipped: Dictionary = Content.items.get(str(Session.state.equipped), {})
	var tool_tier := int(equipped.get("tier", 1)) if str(equipped.get("style", "")) == "pick" else 1
	if int(node.tier) > tool_tier:
		Session.message.emit("ui.need_tool", {})
		return
	var key: String = str(value.key)
	var saved: Dictionary = Session.state.nodes.get(
		key, {"remaining": int(node.amount), "regrow": 0.0}
	)
	if int(saved.remaining) <= 0:
		if float(saved.regrow) > float(Session.state.time):
			return
		saved.remaining = int(node.amount)
	var amount := (
		1
		+ (
			1
			if (
				Session.has_perk("forager")
				and str(node.id) in ["fiber", "berry", "mushroom", "reed"]
			)
			else 0
		)
	)
	var region := Session.world_model.region_at(cell)
	if (
		Session.state.restored[region]
		and Session.state.attunements[region] == "ember"
		and str(node.id) in ["stone", "copper_ore", "iron_ore", "storm_shard"]
	):
		amount += 1
	if not Session.add_item(str(node.id), amount):
		return
	harvest_ready = float(Session.state.time) + .45
	saved.remaining = int(saved.remaining) - 1
	saved.regrow = (
		float(Session.state.time)
		+ (
			220.0
			if Session.state.restored[region] and Session.state.attunements[region] == "bloom"
			else 330.0
		)
	)
	Session.state.nodes[key] = saved
	Session.state.gathered[node.id] = int(Session.state.gathered.get(node.id, 0)) + amount
	Sound.effect("wood" if str(node.id) in ["wood", "fiber", "reed"] else "stone")
	Session.gain_xp(2)
	refresh()


func can_place(id: String, cell: Vector2i) -> bool:
	if trial_mode:
		return false
	if not Content.structures.has(id) or cell.distance_to(Vector2i(player.position / 32.0)) > 4.2:
		return false
	var key := Session.cell_key(cell)
	var kind := str(Content.structures[id].kind)
	var surface := kind in ["floor", "path", "bridge"]
	if Session.state.get("surfaces", {}).has(key) and surface:
		return false
	if Session.state.structures.has(key) and not surface:
		return false
	if cell == Vector2i(player.position / 32.0) and not surface:
		return false
	for landmark in Session.world_model.landmarks:
		if cell.distance_to(landmark) < 2.5:
			return false
	for index in range(Content.npcs.size()):
		if cell == npc_cell_at(index):
			return false
	var water: bool = Session.world_model.tile_at(cell).kind == "water"
	if kind == "bridge":
		return water
	if (
		Session.state.surfaces.has(key)
		and Content.structures[str(Session.state.surfaces[key].id)].kind == "bridge"
	):
		water = false
	if water:
		return false
	if str(Content.structures[id].kind) == "trap":
		var adjacent_water := false
		for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			if Session.world_model.tile_at(cell + offset).kind == "water":
				adjacent_water = true
		if not adjacent_water:
			return false
	return (
		true
		if surface and Session.state.structures.has(key)
		else Session.world_model.passable(cell, Session.state)
	)


func place_building(id: String, cell: Vector2i) -> bool:
	if not can_place(id, cell):
		Session.message.emit("ui.no_placement", {})
		return false
	if int(Session.state.inventory.get(id, 0)) <= 0:
		if not Session.craft(id):
			return false
	if not Session.remove_item(id, 1):
		return false
	var data: Dictionary = {
		"id": id,
		"cell": [cell.x, cell.y],
		"placed_at": Session.state.time,
		"contents": {},
		"health": Content.structures[id].health
	}
	if Content.structures[id].kind in ["floor", "path", "bridge"]:
		Session.state.surfaces[Session.cell_key(cell)] = data
	else:
		Session.state.structures[Session.cell_key(cell)] = data
	Sound.effect("build")
	refresh()
	Session.changed.emit()
	return true


func dismantle(cell: Vector2i) -> bool:
	var key := Session.cell_key(cell)
	var surface: bool = not Session.state.structures.has(key) and Session.state.surfaces.has(key)
	if not Session.state.structures.has(key) and not surface:
		return false
	if cell.distance_to(Vector2i(player.position / 32.0)) > 4:
		return false
	var structure: Dictionary = (
		Session.state.surfaces[key] if surface else Session.state.structures[key]
	)
	if surface and structure.id == "bridge" and cell == Vector2i(player.position / 32.0):
		return false
	if not structure.contents.is_empty():
		return false
	for shipment in Session.state.get("shipments", []):
		if str(shipment.destination) == key:
			Session.message.emit("ui.route_pending", {})
			return false
	var production: Dictionary = Session.state.get("production", {}).get(
		key, {"queue": [], "ready": {}}
	)
	if not production.queue.is_empty() or not production.ready.is_empty():
		return false
	if not Session.add_item(str(structure.id), 1, false):
		return false
	if surface:
		Session.state.surfaces.erase(key)
	else:
		Session.state.structures.erase(key)
	Session.state.production.erase(key)
	var prop_key := "surface_" + key if surface else key
	if props.has(prop_key):
		props[prop_key].node.queue_free()
		props.erase(prop_key)
	Sound.effect("build")
	refresh()
	return true


func _stream_creatures(chunk: Vector2i) -> void:
	for actor_id in actors.keys():
		if not is_instance_valid(actors[actor_id]):
			actors.erase(actor_id)
			continue
		var actor: MossCreature = actors[actor_id]
		if actor.position.distance_to(player.position) > 800:
			actor.persist()
			actor.queue_free()
			actors.erase(actor_id)
	if actors.size() > 45:
		return
	for region in range(5):
		var key := "warden_" + str(region)
		if actors.has(key):
			continue
		var saved: Dictionary = Session.state.mob_state.get(key, {})
		if saved.has("position") and not saved.has("respawn"):
			var pos := Vector2(float(saved.position[0]), float(saved.position[1]))
			if pos.distance_to(player.position) < 650:
				spawn_creature(str(Content.mobs.keys()[20 + region]), pos, key, saved)
	var density := float(Content.difficulties[str(Session.state.settings.difficulty)].density)
	var budget := (
		2 if Session.state.settings.difficulty == "peaceful" else maxi(2, roundi(3 * density))
	)
	for cy in range(chunk.y - 1, chunk.y + 2):
		for cx in range(chunk.x - 1, chunk.x + 2):
			for index in range(budget):
				var hash_: int = Session.world_model.hash_cell(Vector2i(cx, cy), 77 + index)
				var cell := Vector2i(cx * 32 + hash_ % 32, cy * 32 + (hash_ / 32) % 32)
				if (
					cell.distance_to(MossWorld.SPAWN) < 12
					or not Session.world_model.passable(cell, Session.state)
				):
					continue
				var pos := Vector2(cell * 32) + Vector2(16, 24)
				if pos.distance_to(player.position) > 550 or pos.distance_to(player.position) < 85:
					continue
				var region := Session.world_model.region_at(cell)
				var peaceful: bool = Session.state.settings.difficulty == "peaceful"
				var passive := index == budget - 1 or peaceful
				var id: String = str(
					(
						["hare", "crane", "fox", "deer", "tortoise"][region]
						if passive
						else Content.mobs.keys()[region * 3 + hash_ % 3]
					)
				)
				var actor_id := "%d:%d:%d" % [cx, cy, index]
				if actors.has(actor_id):
					continue
				var saved: Dictionary = Session.state.mob_state.get(actor_id, {})
				if float(saved.get("respawn", 0)) > float(Session.state.time):
					continue
				spawn_creature(id, pos, actor_id, saved)


func spawn_creature(
	id: String, pos: Vector2, actor_id: String, saved: Dictionary = {}
) -> MossCreature:
	var creature := MossCreature.new()
	creature.definition = Content.mobs[id].duplicate(true)
	if not creature.definition.passive:
		creature.definition.health = (
			float(creature.definition.health)
			* float(
				{"peaceful": 1.0, "easy": .8, "normal": 1.0, "hard": 1.2, "insane": 1.45}[str(
					Session.state.settings.difficulty
				)]
			)
		)
	creature.creature_id = id
	creature.actor_id = actor_id
	creature.world_view = self
	creature.position = (
		Vector2(float(saved.position[0]), float(saved.position[1]))
		if saved.has("position")
		else pos
	)
	creature.health = float(saved.get("health", creature.definition.health))
	creature.animation_clock = float(saved.get("animation_clock", 0))
	if saved.has("direction"):
		creature.direction = Vector2(float(saved.direction[0]), float(saved.direction[1]))
	entities.add_child(creature)
	actors[actor_id] = creature
	return creature


func challenge(region: int) -> void:
	var key := "warden_" + str(region)
	if actors.has(key):
		return
	if region == 4 and Session.state.wardens.slice(0, 4).count(true) < 4:
		Session.message.emit("quest.regions", {})
		return
	var id: String = Content.mobs.keys()[20 + region]
	var saved: Dictionary = Session.state.mob_state.get(key, {})
	if saved.has("respawn"):
		saved = {}
	spawn_creature(
		id, Vector2(Session.world_model.landmarks[region] * 32) + Vector2(72, -48), key, saved
	)
	Sound.theme("combat")


func has_hostiles(radius_: float) -> bool:
	for actor in actors.values():
		if (
			is_instance_valid(actor)
			and not actor.dying
			and not actor.definition.passive
			and actor.position.distance_to(player.position) < radius_
		):
			return true
	return false


func aim_position() -> Vector2:
	if using_controller:
		var stick := Vector2(
			Input.get_joy_axis(0, JOY_AXIS_RIGHT_X), Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
		)
		return player.position + (stick.normalized() if stick.length() > .2 else player.facing) * 76
	var root := get_tree().root
	var local := root.get_mouse_position() / root.get_visible_rect().size * get_viewport_rect().size
	return camera.get_screen_center_position() + local - get_viewport_rect().size / 2.0


func objective_position() -> Vector2:
	var stage := int(Session.state.quest_stage)
	if stage == 0:
		return Vector2(npc_cell_at(0) * 32) + Vector2(16, 28)
	if stage in [1, 2]:
		return Vector2(MossWorld.SPAWN * 32) + Vector2(16, 28)
	if stage in [3, 4]:
		return Vector2(Session.world_model.landmarks[0] * 32) + Vector2(16, 28)
	if stage == 5:
		for region in range(1, 4):
			if not Session.state.wardens[region]:
				return Vector2(Session.world_model.landmarks[region] * 32) + Vector2(16, 28)
	if stage == 6:
		return Vector2(Session.world_model.landmarks[4] * 32) + Vector2(16, 28)
	return player.position
