extends Node2D
class_name WorldGenerator

## Builds a procedural tile map with biomes and exposes biome lookup helpers.

const BIOMES: PackedStringArray = ["water", "grassland", "forest", "desert", "tundra"]

@export var map_size := Vector2i(64, 64)
@export var tile_size := 32
@export var noise_scale := 0.08
@export var moisture_scale := 0.1
@export var water_threshold := -0.25
@export var cold_threshold := 0.2
@export var desert_threshold := -0.15
@export var forest_threshold := 0.25
@export var auto_generate := false

var tilemap: TileMap
var biome_cells: Dictionary = {}
var last_seed := 0

var rng := RandomNumberGenerator.new()
var noise := FastNoiseLite.new()
var moisture_noise := FastNoiseLite.new()

func _ready() -> void:
    if auto_generate:
        generate()

func generate(seed: int = -1) -> void:
    if seed == -1:
        seed = randi()
    last_seed = seed
    rng.seed = seed
    noise.seed = seed
    noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
    noise.frequency = noise_scale
    moisture_noise.seed = seed + 1337
    moisture_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
    moisture_noise.frequency = moisture_scale

    if tilemap == null:
        tilemap = TileMap.new()
        tilemap.name = "TileMap"
        add_child(tilemap)
    _build_tileset()
    _paint_tiles()

func get_biome_cells(biome: String) -> Array:
    return biome_cells.get(biome, [])

func get_random_cell_in_biome(biome: String) -> Vector2i:
    var cells: Array = biome_cells.get(biome, [])
    if cells.is_empty():
        return Vector2i.ZERO
    return cells[rng.randi_range(0, cells.size() - 1)]

func get_world_position_for_cell(cell: Vector2i) -> Vector2:
    var local := tilemap.map_to_local(cell) + Vector2(tile_size * 0.5, tile_size * 0.5)
    return tilemap.to_global(local)

func get_biome_at_world_position(world_position: Vector2) -> String:
    var local := tilemap.to_local(world_position)
    var cell := tilemap.local_to_map(local)
    if cell.x < 0 or cell.y < 0 or cell.x >= map_size.x or cell.y >= map_size.y:
        return "grassland"
    for biome in BIOMES:
        if biome_cells.get(biome, []).has(cell):
            return biome
    return "grassland"

func _build_tileset() -> void:
    var atlas_image := Image.create(tile_size * BIOMES.size(), tile_size, false, Image.FORMAT_RGBA8)
    for i in range(BIOMES.size()):
        var biome := BIOMES[i]
        var base_color := _biome_color(biome)
        var detail_color := base_color.lightened(0.18)
        var tile_image := _make_tile_image(base_color, detail_color, biome)
        atlas_image.blit_rect(tile_image, Rect2i(Vector2i.ZERO, tile_image.get_size()), Vector2i(i * tile_size, 0))
    var texture := ImageTexture.create_from_image(atlas_image)
    var tile_set := TileSet.new()
    tile_set.tile_size = Vector2i(tile_size, tile_size)
    var atlas := TileSetAtlasSource.new()
    atlas.texture = texture
    atlas.texture_region_size = Vector2i(tile_size, tile_size)
    tile_set.add_source(atlas)
    for i in range(BIOMES.size()):
        atlas.create_tile(Vector2i(i, 0))
    tilemap.tile_set = tile_set
    tilemap.clear()
    tilemap.position = -Vector2(map_size.x, map_size.y) * tile_size * 0.5

func _paint_tiles() -> void:
    biome_cells.clear()
    for biome in BIOMES:
        biome_cells[biome] = []
    for x in range(map_size.x):
        for y in range(map_size.y):
            var height_value := noise.get_noise_2d(float(x), float(y))
            var moisture_value := moisture_noise.get_noise_2d(float(x), float(y))
            var biome := _choose_biome(height_value, moisture_value)
            var atlas_coord := Vector2i(BIOMES.find(biome), 0)
            tilemap.set_cell(0, Vector2i(x, y), 0, atlas_coord)
            biome_cells[biome].append(Vector2i(x, y))

func _choose_biome(height_value: float, moisture_value: float) -> String:
    if height_value < water_threshold:
        return "water"
    if height_value > 0.6 and moisture_value < desert_threshold:
        return "desert"
    if moisture_value > forest_threshold:
        return "forest"
    if height_value < cold_threshold and moisture_value < 0.0:
        return "tundra"
    return "grassland"

func _make_tile_image(base_color: Color, detail_color: Color, biome: String) -> Image:
    var image := Image.create(tile_size, tile_size, false, Image.FORMAT_RGBA8)
    image.fill(base_color)
    var speckle_count := int(tile_size * 1.5)
    for i in range(speckle_count):
        var px := rng.randi_range(1, tile_size - 2)
        var py := rng.randi_range(1, tile_size - 2)
        image.set_pixel(px, py, detail_color)
    if biome == "water":
        for x in range(2, tile_size - 2, 6):
            image.set_pixel(x, tile_size / 2, detail_color)
            image.set_pixel(x + 2, tile_size / 2 + 2, detail_color)
    if biome == "desert":
        for x in range(0, tile_size, 4):
            image.set_pixel(x, 2, detail_color)
    return image

func _biome_color(biome: String) -> Color:
    match biome:
        "water":
            return Color(0.18, 0.38, 0.72)
        "grassland":
            return Color(0.2, 0.55, 0.28)
        "forest":
            return Color(0.14, 0.42, 0.22)
        "desert":
            return Color(0.78, 0.7, 0.4)
        "tundra":
            return Color(0.7, 0.78, 0.85)
        _:
            return Color(0.25, 0.5, 0.3)
