extends Node
class_name Crafting

## Loads crafting recipes and crafts items using the Inventory.

const RECIPES_PATH := "res://data/recipes.json"

var recipes: Dictionary = {}

func _ready() -> void:
    recipes = _load_json(RECIPES_PATH)

func _load_json(path: String) -> Dictionary:
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        push_error("Failed to open recipes: %s" % path)
        return {}
    var content := file.get_as_text()
    var parsed: Variant = JSON.parse_string(content)
    if typeof(parsed) != TYPE_DICTIONARY:
        push_error("Recipe data is not a dictionary: %s" % path)
        return {}
    return parsed as Dictionary

func can_craft(inventory: Inventory, recipe_id: String) -> bool:
    if not recipes.has(recipe_id):
        return false
    var recipe: Dictionary = recipes[recipe_id]
    for ingredient in recipe.get("ingredients", []):
        if not inventory.has_item(ingredient["id"], ingredient["count"]):
            return false
    return true

func craft(inventory: Inventory, recipe_id: String) -> bool:
    if not can_craft(inventory, recipe_id):
        return false
    var recipe: Dictionary = recipes[recipe_id]
    for ingredient in recipe.get("ingredients", []):
        inventory.remove_item(ingredient["id"], ingredient["count"])
    inventory.add_item(recipe["result"]["id"], recipe["result"]["count"])
    return true

func get_recipe_ids() -> Array:
    return recipes.keys()

func get_recipe(recipe_id: String) -> Dictionary:
    return recipes.get(recipe_id, {})

func get_craftable_recipe_ids(inventory: Inventory) -> Array:
    var craftable: Array = []
    for recipe_id in recipes.keys():
        if can_craft(inventory, recipe_id):
            craftable.append(recipe_id)
    craftable.sort()
    return craftable
