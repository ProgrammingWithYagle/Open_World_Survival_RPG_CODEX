extends Node
class_name ItemDB

## Loads item definitions from JSON and provides lookup helpers.

const ITEMS_PATH := "res://data/items.json"

var items: Dictionary = {}

func _ready() -> void:
    items = _load_json(ITEMS_PATH)

func _load_json(path: String) -> Dictionary:
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        push_error("Failed to open item data: %s" % path)
        return {}
    var content := file.get_as_text()
    var parsed_value: Variant = JSON.parse_string(content)
    var parsed_dict: Dictionary = {}
    if parsed_value is Dictionary:
        parsed_dict = parsed_value
    else:
        push_error("Item data is not a dictionary: %s" % path)
        return {}
    return parsed_dict

func get_item(item_id: String) -> Dictionary:
    return items.get(item_id, {})

func get_display_name(item_id: String) -> String:
    var item := get_item(item_id)
    return item.get("name", item_id)

func get_effects(item_id: String) -> Dictionary:
    var item := get_item(item_id)
    return item.get("effects", {})

func has_item(item_id: String) -> bool:
    return items.has(item_id)

func all_items() -> Array:
    return items.keys()
