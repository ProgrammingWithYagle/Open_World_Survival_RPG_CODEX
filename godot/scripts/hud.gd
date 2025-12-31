extends CanvasLayer

## HUD that shows survival needs, inventory icons, and craftable recipes.

const ICON_SIZE := 22
const ITEM_COLORS := {
	"wood": Color(0.45, 0.32, 0.18),
	"stone": Color(0.55, 0.55, 0.6),
	"berry": Color(0.7, 0.18, 0.4),
	"fiber": Color(0.25, 0.6, 0.3),
	"stick": Color(0.5, 0.4, 0.25),
	"water": Color(0.2, 0.5, 0.9),
	"cooked_berry": Color(0.8, 0.35, 0.3),
	"bandage": Color(0.85, 0.82, 0.78),
	"stone_knife": Color(0.7, 0.7, 0.75),
	"campfire": Color(0.9, 0.55, 0.25)
}

var health_bar: ProgressBar
var hunger_bar: ProgressBar
var thirst_bar: ProgressBar
var stamina_bar: ProgressBar
var temp_bar: ProgressBar

var health_value: Label
var hunger_value: Label
var thirst_value: Label
var stamina_value: Label
var temp_value: Label

var inventory_list: VBoxContainer
var crafting_list: VBoxContainer
var hint_label: Label

var inventory: Inventory
var needs: Needs
var item_db: ItemDB
var crafting: Crafting

var icon_cache: Dictionary = {}

func _ready() -> void:
	health_bar = $Panel/Root/NeedsList/HealthRow/HealthBar
	hunger_bar = $Panel/Root/NeedsList/HungerRow/HungerBar
	thirst_bar = $Panel/Root/NeedsList/ThirstRow/ThirstBar
	stamina_bar = $Panel/Root/NeedsList/StaminaRow/StaminaBar
	temp_bar = $Panel/Root/NeedsList/TempRow/TempBar

	health_value = $Panel/Root/NeedsList/HealthRow/HealthValue
	hunger_value = $Panel/Root/NeedsList/HungerRow/HungerValue
	thirst_value = $Panel/Root/NeedsList/ThirstRow/ThirstValue
	stamina_value = $Panel/Root/NeedsList/StaminaRow/StaminaValue
	temp_value = $Panel/Root/NeedsList/TempRow/TempValue

	inventory_list = $Panel/Root/InventoryList
	crafting_list = $Panel/Root/CraftingList
	hint_label = $Panel/Root/HintLabel

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
	if needs == null:
		return
	health_bar.value = needs.health
	hunger_bar.value = needs.hunger
	thirst_bar.value = needs.thirst
	stamina_bar.value = needs.stamina
	temp_bar.value = _temperature_to_percent(needs.temperature)

	health_value.text = str(int(needs.health))
	hunger_value.text = str(int(needs.hunger))
	thirst_value.text = str(int(needs.thirst))
	stamina_value.text = str(int(needs.stamina))
	temp_value.text = "%d°C" % int(needs.temperature)

func _refresh_inventory() -> void:
	if inventory == null or item_db == null:
		return
	_clear_container(inventory_list)
	var counts := inventory.get_counts()
	var item_ids := counts.keys()
	item_ids.sort()
	if item_ids.is_empty():
		inventory_list.add_child(_make_empty_label("Inventory empty"))
		return
	for item_id in item_ids:
		var row := _make_list_row(item_id, counts[item_id])
		inventory_list.add_child(row)

func _refresh_crafting() -> void:
	if crafting == null or inventory == null or item_db == null:
		return
	_clear_container(crafting_list)
	var recipe_ids := crafting.get_craftable_recipe_ids(inventory)
	if recipe_ids.is_empty():
		crafting_list.add_child(_make_empty_label("Nothing craftable yet"))
		return
	for recipe_id in recipe_ids:
		var recipe := crafting.get_recipe(recipe_id)
		var result: Dictionary = recipe.get("result", {})
		var result_id: String = result.get("id", recipe_id)
		var row := _make_list_row(result_id, int(result.get("count", 1)))
		crafting_list.add_child(row)

func _make_list_row(item_id: String, count: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.theme_override_constants.separation = 8

	var icon := TextureRect.new()
	icon.texture = _get_icon(item_id)
	icon.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	row.add_child(icon)

	var label := Label.new()
	var name := item_db.get_display_name(item_id) if item_db != null else item_id
	label.text = "%s x%d" % [name, count]
	row.add_child(label)

	return row

func _make_empty_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.modulate = Color(0.8, 0.8, 0.85)
	return label

func _clear_container(container: VBoxContainer) -> void:
	for child in container.get_children():
		child.queue_free()

func _temperature_to_percent(value: float) -> float:
	return clampf((value + 10.0) / 55.0 * 100.0, 0.0, 100.0)

func _get_icon(item_id: String) -> Texture2D:
	if icon_cache.has(item_id):
		return icon_cache[item_id]
	var color: Color = ITEM_COLORS.get(item_id, Color(0.4, 0.5, 0.45)) as Color
	var texture := _make_icon_texture(color)
	icon_cache[item_id] = texture
	return texture

func _make_icon_texture(color: Color) -> Texture2D:
	var image := Image.create(ICON_SIZE, ICON_SIZE, false, Image.FORMAT_RGBA8)
	var shadow := color.darkened(0.25)
	var highlight := color.lightened(0.2)
	image.fill(color)
	for x in range(ICON_SIZE):
		image.set_pixel(x, 0, shadow)
		image.set_pixel(x, ICON_SIZE - 1, shadow)
	for y in range(ICON_SIZE):
		image.set_pixel(0, y, shadow)
		image.set_pixel(ICON_SIZE - 1, y, shadow)
	for i in range(ICON_SIZE / 2):
		var px := 2 + i
		var py := 2
		if px < ICON_SIZE - 2:
			image.set_pixel(px, py, highlight)
	return ImageTexture.create_from_image(image)
