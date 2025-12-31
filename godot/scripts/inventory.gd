extends Node
class_name Inventory

## Tracks item counts and exposes add/remove helpers with signals for UI updates.

signal inventory_changed

var slots: Dictionary = {}

func add_item(item_id: String, amount: int) -> void:
    if amount <= 0:
        return
    slots[item_id] = slots.get(item_id, 0) + amount
    emit_signal("inventory_changed")

func remove_item(item_id: String, amount: int) -> bool:
    if amount <= 0:
        return false
    var current := slots.get(item_id, 0)
    if current < amount:
        return false
    var new_amount := current - amount
    if new_amount == 0:
        slots.erase(item_id)
    else:
        slots[item_id] = new_amount
    emit_signal("inventory_changed")
    return true

func has_item(item_id: String, amount: int) -> bool:
    return slots.get(item_id, 0) >= amount

func get_counts() -> Dictionary:
    return slots.duplicate()
