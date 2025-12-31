extends CanvasLayer

## Simple HUD that shows survival needs and inventory contents.

var needs_label: Label
var inventory_label: Label
var crafting_label: Label

var inventory: Inventory
var needs: Needs
var item_db: ItemDB
var crafting: Crafting

func _ready() -> void:
    needs_label = $Panel/NeedsLabel
    inventory_label = $Panel/InventoryLabel
    crafting_label = $Panel/CraftingLabel

func bind_systems(new_inventory: Inventory, new_needs: Needs, new_item_db: ItemDB, new_crafting: Crafting) -> void:
    inventory = new_inventory
    needs = new_needs
    item_db = new_item_db
    crafting = new_crafting
    inventory.inventory_changed.connect(_refresh_inventory)
    needs.needs_changed.connect(_refresh_needs)
    inventory.inventory_changed.connect(_refresh_crafting)
    _refresh_inventory()
    _refresh_needs()
    _refresh_crafting()

func _refresh_needs() -> void:
    if needs_label == null or needs == null:
        return
    needs_label.text = needs.get_readout()

func _refresh_inventory() -> void:
    if inventory_label == null or inventory == null or item_db == null:
        return
    var lines := ["Inventory:"]
    var counts := inventory.get_counts()
    for item_id in counts.keys():
        var name := item_db.get_display_name(item_id)
        lines.append("%s x%d" % [name, counts[item_id]])
    inventory_label.text = "\n".join(lines)

func _refresh_crafting() -> void:
    if crafting_label == null or crafting == null or inventory == null or item_db == null:
        return
    var lines := ["Craftable:"]
    var recipe_ids := crafting.get_craftable_recipe_ids(inventory)
    if recipe_ids.is_empty():
        lines.append("Nothing yet")
    else:
        for recipe_id in recipe_ids:
            var recipe := crafting.get_recipe(recipe_id)
            var result_id := recipe.get("result", {}).get("id", recipe_id)
            lines.append(item_db.get_display_name(result_id))
    crafting_label.text = "\n".join(lines)
