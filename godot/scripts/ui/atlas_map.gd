extends Control
class_name MossMap
var map_center := Vector2(512, 512)
var zoom := 1.0
var dragging := false


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	queue_redraw()
	clip_contents = true


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom = clampf(zoom * 1.2, .45, 3)
			queue_redraw()
			accept_event()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom = clampf(zoom / 1.2, .45, 3)
			queue_redraw()
			accept_event()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			dragging = event.pressed
			accept_event()
	elif event is InputEventMouseMotion and dragging:
		map_center -= event.relative / (minf(size.x / 680.0, size.y / 610.0) * zoom)
		map_center = map_center.clamp(Vector2.ZERO, Vector2(1024, 1024))
		queue_redraw()
		accept_event()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("172d2c"))
	var center := map_center
	var scale_ := minf(size.x / 680.0, size.y / 610.0) * zoom
	var colors: Array = [
		Color("607956"), Color("637a6c"), Color("8e7354"), Color("4f6967"), Color("688887")
	]
	var start := Vector2i((center - size / (2 * scale_)) / 8) * 8
	var end := Vector2i(center + size / (2 * scale_)) + Vector2i(8, 8)
	for y in range(maxi(0, start.y), mini(1024, end.y), 8):
		for x in range(maxi(0, start.x), mini(1024, end.x), 8):
			var cell := Vector2i(x, y)
			var chunk := Vector2i(x / 32, y / 32)
			if not Session.state.discovered.has(Session.cell_key(chunk)):
				continue
			var point := (Vector2(cell) - center) * scale_ + size / 2
			var region := Session.world_model.region_at(cell)
			var water: bool = Session.world_model.tile_at(cell).kind == "water"
			draw_rect(
				Rect2(point, Vector2.ONE * 8.1 * scale_),
				Color("385b68") if water else colors[region]
			)
	for i in range(Session.world_model.landmarks.size()):
		var cell: Vector2i = Session.world_model.landmarks[i]
		var point := (Vector2(cell) - center) * scale_ + size / 2
		var camp := (Vector2(MossWorld.SPAWN) - center) * scale_ + size / 2
		if Session.state.restored[i]:
			draw_line(camp, point, Color(.88, .76, .48, .7), 2)
		draw_circle(point, 5, Color("e5c27c") if Session.state.restored[i] else Color("8a9b88"))
		var label := L.t("region." + str(Content.regions[i].id))
		draw_string(
			L.font(),
			point + Vector2(10, -8),
			label,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			14,
			Color("eddfbd")
		)
	var player := (Session.player_position() / 32.0 - center) * scale_ + size / 2
	draw_circle(player, 4, Color("fff4d3"))
	for site in Content.points_of_interest:
		if not Session.state.get("sites", {}).has(str(site.id)):
			continue
		var point := (
			(Vector2(Session.world_model.poi_cell(str(site.id))) - center) * scale_ + size / 2
		)
		draw_rect(Rect2(point - Vector2(2, 2), Vector2(4, 4)), Color("c6af7a"))
	for structure in Session.state.structures.values():
		if Content.structures[str(structure.id)].kind != "hearth":
			continue
		var point := (
			(Vector2(float(structure.cell[0]), float(structure.cell[1])) - center) * scale_
			+ size / 2
		)
		draw_circle(point, 3, Color("efb86a"))
	for grave in Session.state.graves:
		var point := (
			(Vector2(float(grave.position[0]), float(grave.position[1])) / 32.0 - center) * scale_
			+ size / 2
		)
		draw_line(point - Vector2(5, 0), point + Vector2(5, 0), Color("d98c74"), 2)
		draw_line(point - Vector2(0, 5), point + Vector2(0, 5), Color("d98c74"), 2)
