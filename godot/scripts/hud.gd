extends CanvasLayer

## Simple HUD that shows survival needs and inventory contents.

var needs_label: Label
var inventory_label: Label

var inventory: Inventory
var needs: Needs
var item_db: ItemDB

func _ready() -> void:
    needs_label = $Panel/NeedsLabel
    inventory_label = $Panel/InventoryLabel

func bind_systems(new_inventory: Inventory, new_needs: Needs, new_item_db: ItemDB) -> void:
    inventory = new_inventory
    needs = new_needs
    item_db = new_item_db
    inventory.inventory_changed.connect(_refresh_inventory)
    needs.needs_changed.connect(_refresh_needs)
    _refresh_inventory()
    _refresh_needs()

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
        var item := item_db.get_item(item_id)
        var name := item.get("name", item_id)
        lines.append("%s x%d" % [name, counts[item_id]])
    inventory_label.text = "\n".join(lines)
