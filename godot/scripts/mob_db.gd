extends Node
class_name MobDB

## Loads mob definitions from JSON and provides lookup helpers.

const MOBS_PATH := "res://data/mobs.json"

var mobs: Dictionary = {}

func _ready() -> void:
    mobs = _load_json(MOBS_PATH)

func _load_json(path: String) -> Dictionary:
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        push_error("Failed to open mob data: %s" % path)
        return {}
    var content := file.get_as_text()
    var parsed_value: Variant = JSON.parse_string(content)
    var parsed_dict: Dictionary = {}
    if parsed_value is Dictionary:
        parsed_dict = parsed_value
    else:
        push_error("Mob data is not a dictionary: %s" % path)
        return {}
    return parsed_dict

func get_mob(mob_id: String) -> Dictionary:
    return mobs.get(mob_id, {})

func get_display_name(mob_id: String) -> String:
    var mob := get_mob(mob_id)
    return mob.get("name", mob_id)

func has_mob(mob_id: String) -> bool:
    return mobs.has(mob_id)

func all_mobs() -> Array:
    return mobs.keys()
