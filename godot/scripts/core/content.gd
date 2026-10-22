extends Node

const VERSION := "1.0.0"
var items: Dictionary
var recipes: Dictionary
var mobs: Dictionary
var structures: Dictionary
var difficulties: Dictionary
var regions: Array
var npcs: Array
var perks: Array
var releases: Array
var points_of_interest: Array
var icon_cache: Dictionary = {}
var requests: Array
var production: Array
var fish_species: Array
var crops: Dictionary
var trade_stock: Dictionary = {
	"seed": {"count": 5, "price": 2, "goodwill": 0},
	"water": {"count": 5, "price": 1, "goodwill": 0},
	"bandage": {"count": 4, "price": 3, "goodwill": 0},
	"hide": {"count": 3, "price": 3, "goodwill": 0},
	"salve": {"count": 3, "price": 5, "goodwill": 10},
	"tonic": {"count": 2, "price": 7, "goodwill": 20},
	"cloth": {"count": 4, "price": 5, "goodwill": 10},
	"venom_sac": {"count": 3, "price": 5, "goodwill": 20}
}


func _ready() -> void:
	trade_stock["grain_seed"] = {"count": 4, "price": 3, "goodwill": 0}
	trade_stock["sunroot_seed"] = {"count": 3, "price": 4, "goodwill": 10}
	for id in ["mint", "sunblossom", "sage", "orchid"]:
		trade_stock[id] = {"count": 3, "price": 4, "goodwill": 10}
	items = read_data("items")
	recipes = read_data("recipes")
	mobs = read_data("mobs")
	structures = read_data("structures")
	difficulties = read_data("difficulties")
	regions = read_data("regions")
	npcs = read_data("npcs")
	perks = read_data("perks")
	releases = read_data("releases")
	points_of_interest = read_data("points_of_interest")
	requests = read_data("requests")
	production = read_data("production")
	fish_species = read_data("fish_species")
	crops = read_data("crops")


func read_data(name_: String) -> Variant:
	var file := FileAccess.open("res://data/%s.json" % name_, FileAccess.READ)
	assert(file != null, "Required content file is missing: " + name_)
	var result: Variant = JSON.parse_string(file.get_as_text())
	assert(result != null, "Required content file is invalid: " + name_)
	return result


func item_name(id: String) -> String:
	return L.t("item.%s.name" % id)


func item_description(id: String) -> String:
	return L.t("item.%s.desc" % id)


func icon(id: String) -> Texture2D:
	if icon_cache.has(id):
		return icon_cache[id]
	var path := "res://art/icons/%s.png" % id
	if not ResourceLoader.exists(path):
		return null
	var texture: Texture2D = load(path)
	icon_cache[id] = texture
	return texture
