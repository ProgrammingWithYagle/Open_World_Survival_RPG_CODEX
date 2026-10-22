extends CanvasLayer
class_name MossUI

signal begin_requested(name_: String, seed_: String, difficulty: String, death_mode: String)
signal load_requested(id: String)
signal title_requested
var root: Control
var world_view: MossWorldView
var page := "title"
var last_page := "title"
var chosen_tab := "inventory"
var selected_item := ""
var search_text := ""
var health_bar: ProgressBar
var stamina_bar: ProgressBar
var need_label: Label
var objective_label: Label
var place_label: Label
var hint_label: Label
var toast_label: Label
var toast_timer := 0.0
var hotbar: HBoxContainer
var notice_panel: PanelContainer
var notice_label: Label
var notice_key := ""
var notice_args: Dictionary = {}
var dialog_target: Dictionary = {}
var ink := Color("142b2b")
var parchment := Color("eddfbd")
var gold := Color("d6b16d")
var muted := Color("9fb2a1")


func _ready() -> void:
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	notice_panel = PanelContainer.new()
	notice_panel.z_index = 100
	notice_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	notice_panel.offset_left = -430
	notice_panel.offset_right = 430
	notice_panel.offset_top = -185
	notice_panel.offset_bottom = -125
	notice_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	notice_label = _label("", 17, parchment)
	notice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice_panel.add_child(notice_label)
	root.add_child(notice_panel)
	notice_panel.hide()
	L.language_changed.connect(_language_changed)
	Session.message.connect(show_message)
	Session.player_fell.connect(_on_player_fell)
	Session.victory.connect(show_victory)
	Session.changed.connect(_state_changed)
	_apply_theme()


func _apply_theme() -> void:
	var theme_ = Theme.new()
	theme_.default_font = L.font()
	theme_.default_font_size = 18
	for kind in ["Label", "Button", "CheckButton", "OptionButton", "LineEdit"]:
		theme_.set_color("font_color", kind, parchment)
		theme_.set_color("font_hover_color", kind, Color("fff0c6"))
	var normal := _style(Color("1c3433"), Color("577266"))
	var hover := _style(Color("314c42"), gold)
	for kind in ["Button", "OptionButton"]:
		theme_.set_stylebox("normal", kind, normal)
		theme_.set_stylebox("hover", kind, hover)
		theme_.set_stylebox("pressed", kind, _style(Color("405844"), gold))
		theme_.set_stylebox("focus", kind, _style(Color(0, 0, 0, 0), gold))
		theme_.set_stylebox("disabled", kind, _style(Color("192e2b"), Color("334b43")))
	theme_.set_stylebox("normal", "LineEdit", _style(Color("102323"), Color("577266")))
	theme_.set_stylebox("focus", "LineEdit", hover)
	theme_.set_stylebox(
		"panel", "PanelContainer", _style(Color(.055, .12, .12, .96), Color("6f8067"))
	)
	theme_.set_constant("separation", "VBoxContainer", 12)
	theme_.set_constant("separation", "HBoxContainer", 12)
	theme_.set_stylebox("background", "ProgressBar", _style(Color("102121"), Color("4c6559")))
	theme_.set_stylebox("fill", "ProgressBar", _style(Color("88a978"), Color("88a978")))
	root.theme = theme_


func _style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 9
	style.content_margin_bottom = 9
	return style


func _clear() -> void:
	for child in root.get_children():
		if child != notice_panel:
			root.remove_child(child)
			child.queue_free()
	health_bar = null
	stamina_bar = null
	need_label = null
	objective_label = null
	place_label = null
	hint_label = null
	toast_label = null
	hotbar = null


func _label(text_: String, size_: int = 18, color_: Color = Color("eddfbd")) -> Label:
	var label := Label.new()
	label.text = text_
	label.add_theme_font_size_override("font_size", size_)
	if size_ >= 29:
		label.add_theme_font_override("font", L.title_font())
	label.add_theme_color_override("font_color", color_)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _button(text_: String, callback: Callable, height := 43) -> Button:
	var button := Button.new()
	button.text = text_
	button.custom_minimum_size = Vector2(0, height)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var on_play_and_invoke := func():
		Sound.effect("ui")
		callback.call()
	button.pressed.connect(on_play_and_invoke)
	return button


func _icon(id: String, size_ := 40) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = Content.icon(id)
	icon.custom_minimum_size = Vector2(size_, size_)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return icon


func _items_text(items: Dictionary) -> String:
	var parts := PackedStringArray()
	for id in items:
		parts.append(Content.item_name(str(id)) + " ×" + str(int(items[id])))
	return " · ".join(parts)


func _box(parent: Node, margin := 20) -> VBoxContainer:
	var panel := PanelContainer.new()
	parent.add_child(panel)
	var margins := MarginContainer.new()
	margins.add_theme_constant_override("margin_left", margin)
	margins.add_theme_constant_override("margin_right", margin)
	margins.add_theme_constant_override("margin_top", margin)
	margins.add_theme_constant_override("margin_bottom", margin)
	panel.add_child(margins)
	var box := VBoxContainer.new()
	margins.add_child(box)
	return box


func _overlay() -> void:
	var shade := ColorRect.new()
	shade.color = Color(.025, .06, .065, .7)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(shade)


func _window(title_: String) -> VBoxContainer:
	_clear()
	_overlay()
	var center := MarginContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.add_theme_constant_override("margin_left", 130)
	center.add_theme_constant_override("margin_right", 130)
	center.add_theme_constant_override("margin_top", 45)
	center.add_theme_constant_override("margin_bottom", 45)
	root.add_child(center)
	var box := _box(center, 22)
	box.add_child(_label(title_, 29, gold))
	call_deferred("_focus_first")
	return box


func _focus_first(node: Node = null) -> bool:
	if node == null:
		node = root
	if node is Button and node.is_visible_in_tree() and not node.disabled:
		node.grab_focus()
		return true
	for child in node.get_children():
		if _focus_first(child):
			return true
	return false


func _scroll(parent: Node) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	parent.add_child(scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(box)
	return box


func show_title() -> void:
	page = "title"
	Session.paused = true
	toast_timer = 0
	_clear()
	var shade := ColorRect.new()
	shade.color = Color(.025, .07, .07, .78)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(shade)
	var margin := MarginContainer.new()
	margin.position = Vector2(70, 56)
	margin.size = Vector2(475, 620)
	root.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 15)
	margin.add_child(box)
	box.add_child(_label(L.t("ui.title"), 43, gold))
	box.add_child(_label(L.t("ui.subtitle"), 18, muted))
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 16)
	box.add_child(spacer)
	box.add_child(_button(L.t("ui.new"), show_new, 52))
	box.add_child(_button(L.t("ui.continue"), show_worlds, 48))
	box.add_child(_button(L.t("ui.settings"), _title_settings))
	box.add_child(_button(L.t("ui.changelog"), show_changelog))
	box.add_child(_button(L.t("ui.quit"), func(): get_parent().quit_game()))
	var language := _language_picker()
	box.add_child(language)
	box.add_child(_label(L.t("ui.version", {"version": Content.VERSION}), 14, muted))
	var caption := _label(L.t("ui.credits"), 13, muted)
	caption.position = Vector2(615, 645)
	caption.size = Vector2(590, 52)
	root.add_child(caption)
	Sound.theme("bracken")
	call_deferred("_focus_first")


func _language_picker() -> OptionButton:
	var picker := OptionButton.new()
	picker.add_theme_font_override("font", load("res://fonts/NotoSansCJKsc-Regular.otf"))
	picker.custom_minimum_size.y = 42
	for name_ in L.LANGUAGE_NAMES:
		picker.add_item(name_)
	picker.select(L.LANGUAGES.find(L.language))
	picker.item_selected.connect(func(index: int): L.set_language(L.LANGUAGES[index]))
	return picker


func show_new() -> void:
	page = "new"
	var box := _window(L.t("ui.new"))
	var scroll := _scroll(box)
	scroll.add_child(_label(L.t("ui.name"), 16, muted))
	var name_input := LineEdit.new()
	name_input.text = L.t("ui.title")
	name_input.max_length = 48
	scroll.add_child(name_input)
	scroll.add_child(_label(L.t("ui.seed"), 16, muted))
	var seed_input := LineEdit.new()
	seed_input.max_length = 64
	scroll.add_child(seed_input)
	scroll.add_child(_label(L.t("ui.difficulty"), 18, gold))
	var difficulty := OptionButton.new()
	var keys: Array = Content.difficulties.keys()
	for key in keys:
		difficulty.add_item(L.t("difficulty." + str(key)))
	difficulty.select(2)
	scroll.add_child(difficulty)
	var difficulty_desc := _label(L.t("difficulty.normal.desc"), 16, muted)
	scroll.add_child(difficulty_desc)
	difficulty.item_selected.connect(
		func(index: int): difficulty_desc.text = L.t("difficulty." + str(keys[index]) + ".desc")
	)
	scroll.add_child(_label(L.t("ui.death_mode"), 18, gold))
	var death := OptionButton.new()
	var modes: Array = ["easycore", "mediumcore", "hardcore"]
	for key in modes:
		death.add_item(L.t("death." + str(key)))
	scroll.add_child(death)
	var death_desc := _label(L.t("death.easycore.desc"), 16, muted)
	scroll.add_child(death_desc)
	death.item_selected.connect(
		func(index: int): death_desc.text = L.t("death." + str(modes[index]) + ".desc")
	)
	var actions := HBoxContainer.new()
	box.add_child(actions)
	actions.add_child(_button(L.t("ui.back"), show_title))
	var on_create_journey := func():
		begin_requested.emit(
			name_input.text,
			seed_input.text,
			str(keys[difficulty.selected]),
			str(modes[death.selected])
		)
	actions.add_child(_button(L.t("ui.create"), on_create_journey))


func show_worlds() -> void:
	page = "worlds"
	var box := _window(L.t("ui.worlds"))
	var scroll := _scroll(box)
	var worlds := Saves.list_worlds()
	if worlds.is_empty():
		scroll.add_child(_label(L.t("ui.empty_saves"), 19, muted))
	for saved in worlds:
		var entry := _box(scroll, 12)
		entry.add_child(_label(str(saved.name), 21, gold))
		if saved.has("error"):
			entry.add_child(_label(L.t(str(saved.error)), 17, muted))
			continue
		entry.add_child(
			_label(
				(
					L.t("ui.day", {"day": saved.day})
					+ " · "
					+ L.t("difficulty." + str(saved.settings.difficulty))
					+ " · "
					+ L.t("death." + str(saved.settings.death_mode))
				),
				15,
				muted
			)
		)
		if saved.retired:
			entry.add_child(_label(L.t("ui.read_only"), 16, muted))
			entry.add_child(_button(L.t("ui.atlas"), func(): load_requested.emit(str(saved.id))))
		else:
			entry.add_child(_button(L.t("ui.continue"), func(): load_requested.emit(str(saved.id))))
	box.add_child(_button(L.t("ui.back"), show_title))


func show_hud() -> void:
	page = "hud"
	_clear()
	Session.paused = false
	var status := PanelContainer.new()
	status.position = Vector2(22, 20)
	status.size = Vector2(270, 110)
	root.add_child(status)
	var box := VBoxContainer.new()
	status.add_child(box)
	place_label = _label("", 17, gold)
	box.add_child(place_label)
	health_bar = _meter(box, L.t("ui.health"), Color("bb6151"))
	stamina_bar = _meter(box, L.t("ui.stamina"), Color("c1ad63"))
	need_label = _label("", 13, muted)
	box.add_child(need_label)
	var objective := PanelContainer.new()
	objective.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	objective.offset_left = -370
	objective.offset_top = 20
	objective.offset_right = -22
	objective.offset_bottom = 120
	root.add_child(objective)
	var objective_box := VBoxContainer.new()
	objective.add_child(objective_box)
	objective_box.add_child(_label(L.t("ui.objective"), 14, gold))
	objective_label = _label("", 16)
	objective_box.add_child(objective_label)
	var nav := HBoxContainer.new()
	nav.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	nav.offset_left = -465
	nav.offset_right = -22
	nav.offset_top = -53
	nav.offset_bottom = -16
	root.add_child(nav)
	for tab in ["atlas", "inventory", "crafting", "building"]:
		nav.add_child(_button(L.t("ui." + tab), func(): show_panel(tab), 34))
	var hint_panel := PanelContainer.new()
	hint_panel.name = "HintPanel"
	hint_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	hint_panel.offset_left = -370
	hint_panel.offset_right = 370
	hint_panel.offset_top = -120
	hint_panel.offset_bottom = -79
	root.add_child(hint_panel)
	hint_label = _label("", 15, gold)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_panel.add_child(hint_label)
	toast_label = _label("", 17, parchment)
	toast_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	toast_label.offset_left = -350
	toast_label.offset_right = 350
	toast_label.offset_top = 142
	toast_label.offset_bottom = 204
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(toast_label)
	hotbar = HBoxContainer.new()
	hotbar.position = Vector2(22, 656)
	hotbar.add_theme_constant_override("separation", 5)
	root.add_child(hotbar)
	_refresh_hotbar()


func _meter(parent: Node, name_: String, color: Color) -> ProgressBar:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var label := _label(name_, 13)
	label.custom_minimum_size.x = 72
	row.add_child(label)
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(150, 13)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.show_percentage = false
	var fill := _style(color, color)
	fill.set_content_margin_all(0)
	bar.add_theme_stylebox_override("fill", fill)
	row.add_child(bar)
	return bar


func _refresh_hotbar() -> void:
	if hotbar == null:
		return
	for child in hotbar.get_children():
		hotbar.remove_child(child)
		child.queue_free()
	for id in [str(Session.state.equipped), "berry", "water", "bandage"]:
		if id.is_empty() or int(Session.state.inventory.get(id, 0)) <= 0:
			continue
		var button := _button(
			"×" + str(Session.state.inventory[id]), func(): Session.use_item(id), 44
		)
		button.icon = Content.icon(id)
		button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", 32)
		button.custom_minimum_size.x = 98
		button.add_theme_font_size_override("font_size", 14)
		button.tooltip_text = Content.item_name(id) + "\n" + Content.item_description(id)
		hotbar.add_child(button)


func show_panel(tab: String = "inventory") -> void:
	page = "panel"
	chosen_tab = tab
	Session.paused = true
	var box := _window(L.t("ui." + tab))
	var nav := GridContainer.new()
	nav.columns = 4
	box.add_child(nav)
	for key in [
		"inventory", "crafting", "building", "atlas", "journal", "perks", "activities", "bestiary"
	]:
		var button := _button(L.t("ui." + key), func(): show_panel(key), 36)
		button.add_theme_font_size_override("font_size", 15)
		nav.add_child(button)
	var body: VBoxContainer
	var search: LineEdit
	if tab in ["inventory", "crafting", "building"]:
		search = LineEdit.new()
		search.placeholder_text = L.t("ui.search")
		search.text = search_text
		box.add_child(search)
	body = _scroll(box)
	if search != null:
		var on_update_search := func(value: String):
			search_text = value
			for child in body.get_children():
				body.remove_child(child)
				child.queue_free()
			if tab == "inventory":
				_inventory(body)
			else:
				_recipes(body, tab == "building")
		search.text_changed.connect(on_update_search)
	if tab == "inventory":
		_inventory(body)
	elif tab in ["crafting", "building"]:
		_recipes(body, tab == "building")
	elif tab == "journal":
		_journal(body)
	elif tab == "perks":
		_skills(body)
	elif tab == "activities":
		_discoveries(body)
	elif tab == "bestiary":
		_bestiary(body)
	elif tab == "atlas":
		body.add_child(_label(L.t("ui.map_help"), 16, muted))
		var map := MossMap.new()
		map.custom_minimum_size = Vector2(880, 390)
		body.add_child(map)
	box.add_child(_button(L.t("ui.resume"), show_hud))


func _inventory(body: VBoxContainer) -> void:
	body.add_child(
		_label(
			L.t(
				"ui.pack_slots",
				{
					"used": Session.used_slots(Session.state.inventory),
					"total": Session.capacity(),
					"level": Session.state.level
				}
			),
			16,
			muted
		)
	)
	body.add_child(
		_label(
			L.t(
				"ui.loadout",
				{
					"weapon":
					(
						Content.item_name(str(Session.state.equipped))
						if not str(Session.state.equipped).is_empty()
						else "—"
					),
					"armor":
					(
						Content.item_name(str(Session.state.armor))
						if not str(Session.state.armor).is_empty()
						else "—"
					),
					"charm":
					(
						Content.item_name(str(Session.state.trinket))
						if not str(Session.state.trinket).is_empty()
						else "—"
					)
				}
			),
			14,
			muted
		)
	)
	var buffs := PackedStringArray()
	for key in Session.state.buffs:
		if Session.has_buff(str(key)):
			buffs.append(L.t("buff." + str(key)))
	if not buffs.is_empty():
		body.add_child(_label(L.t("ui.active_effects", {"effects": " · ".join(buffs)}), 15, gold))
	if Session.state.inventory.is_empty():
		body.add_child(_label(L.t("ui.empty_bag")))
		return
	for id in Session.state.inventory:
		var key := str(id)
		if (
			not search_text.is_empty()
			and not Content.item_name(key).to_lower().contains(search_text.to_lower())
		):
			continue
		var entry := _box(body, 8)
		var row := HBoxContainer.new()
		entry.add_child(row)
		row.add_child(_icon(key))
		row.add_child(
			_label(Content.item_name(key) + " ×" + str(int(Session.state.inventory[key])), 18, gold)
		)
		var kind: String = str(Content.items[key].kind)
		if kind == "building":
			var on_place_item := func():
				world_view.placing = key
				show_hud()
			row.add_child(_button(L.t("ui.place"), on_place_item, 32))
		elif kind in ["weapon", "tool", "armor", "consumable", "trinket"]:
			var on_use_item := func():
				Session.use_item(key)
				show_panel("inventory")
			row.add_child(
				_button(L.t("ui.use" if kind == "consumable" else "ui.equip"), on_use_item, 32)
			)
		entry.add_child(_label(Content.item_description(key), 15, muted))


func _recipes(body: VBoxContainer, buildings: bool) -> void:
	var available := Session.available_items()
	for id in Content.recipes:
		var key := str(id)
		var recipe: Dictionary = Content.recipes[key]
		var result_id := str(recipe.result.id)
		var name_ := (
			L.t(str(recipe.name_key)) if recipe.has("name_key") else Content.item_name(result_id)
		)
		if (Content.items[result_id].kind == "building") != buildings:
			continue
		if not search_text.is_empty() and not name_.to_lower().contains(search_text.to_lower()):
			continue
		var entry := _box(body, 8)
		var row := HBoxContainer.new()
		entry.add_child(row)
		row.add_child(_icon(result_id))
		row.add_child(_label(name_, 18, gold))
		var on_craft_or_place := func():
			if buildings:
				world_view.placing = key
				show_hud()
			else:
				Session.craft(key)
				show_panel("crafting")
		var button := _button(
			L.t(
				(
					"ui.place"
					if buildings
					else "ui.queue" if recipe.has("production_seconds") else "ui.craft"
				)
			),
			on_craft_or_place,
			32
		)
		button.disabled = int(recipe.tier) > Session.unlocked_tier()
		row.add_child(button)
		entry.add_child(_label(Content.item_description(result_id), 15, muted))
		var parts := PackedStringArray()
		for ingredient in recipe.ingredients:
			parts.append(
				(
					"%s %d/%d"
					% [
						Content.item_name(str(ingredient.id)),
						int(available.get(ingredient.id, 0)),
						int(ingredient.count)
					]
				)
			)
		entry.add_child(_label(" · ".join(parts), 14, Color("b7c391")))
		if int(recipe.tier) > Session.unlocked_tier():
			entry.add_child(_label(L.t("ui.locked"), 14, muted))
		elif not str(recipe.station).is_empty():
			entry.add_child(
				_label(
					L.t("ui.requires", {"name": Content.item_name(str(recipe.station))}), 14, muted
				)
			)


func _journal(body: VBoxContainer) -> void:
	body.add_child(_label(L.t(Session.quest_key()), 20, gold))
	for id in Session.state.npc_met:
		body.add_child(_label(L.t("npc." + str(id)), 20, gold))
		body.add_child(_label(L.t("npc." + str(id) + ".dialogue"), 17, muted))
	body.add_child(_label(L.t("ui.controls"), 16, muted))
	if not Session.state.expedition_run.is_empty():
		var on_withdraw_expedition := func():
			get_parent().end_expedition(false)
			show_hud()
		body.add_child(_button(L.t("ui.withdraw_expedition"), on_withdraw_expedition))


func _discoveries(body: VBoxContainer) -> void:
	Activities.ensure_state()
	body.add_child(
		_label(
			L.t(
				"ui.discoveries",
				{"count": Session.state.sites.size(), "total": Content.points_of_interest.size()}
			),
			20,
			gold
		)
	)
	body.add_child(
		_label(
			L.t(
				"ui.fishing_record",
				{
					"count": Session.state.fishing_records.get("count", 0),
					"weight": Session.state.fishing_records.get("best", 0)
				}
			),
			17,
			muted
		)
	)
	for site in Content.points_of_interest:
		if not Session.state.sites.has(str(site.id)):
			continue
		var entry := _box(body, 9)
		entry.add_child(_label(L.t(str(site.name_key)), 19, gold))
		entry.add_child(_label(L.t(str(site.description_key)), 16, muted))
		if site.kind == "expedition":
			entry.add_child(
				_label(
					L.t(
						"ui.wave",
						{
							"wave": 1,
							"depth": int(Session.state.expeditions.get(str(site.id), 0)) + 1
						}
					),
					14,
					muted
				)
			)


func _bestiary(body: VBoxContainer) -> void:
	Activities.ensure_state()
	for id in Content.mobs:
		var entry := _box(body, 8)
		var observed: Dictionary = Session.state.bestiary.get(str(id), {})
		entry.add_child(
			_label(
				L.t(str(Content.mobs[id].name_key)) if not observed.is_empty() else "???", 20, gold
			)
		)
		if observed.is_empty():
			entry.add_child(_label(L.t("ui.unknown_creature"), 16, muted))
			continue
		var portrait := TextureRect.new()
		portrait.texture = load("res://art/sprites/mob_%s.png" % id)
		var atlas := AtlasTexture.new()
		atlas.atlas = portrait.texture
		var size_ := 96 if Content.mobs[id].boss else 48
		atlas.region = Rect2(0, 0, size_, size_)
		portrait.texture = atlas
		portrait.custom_minimum_size = Vector2(64, 64)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		entry.add_child(portrait)
		entry.add_child(
			_label(
				L.t("ui.seen", {"count": observed.observed.size(), "kills": observed.kills}),
				16,
				muted
			)
		)
		var definition: Dictionary = Content.mobs[id]
		var pattern := str(definition.pattern).trim_prefix("boss_")
		entry.add_child(_label(L.t("behavior." + pattern), 16, muted))
		entry.add_child(
			_label(
				L.t(
					"ui.creature_stats", {"health": definition.health, "damage": definition.damage}
				),
				15,
				muted
			)
		)
		var drops: Dictionary = {}
		for drop in definition.drops:
			drops[str(drop.id)] = int(drop.count)
		entry.add_child(_label(L.t("ui.creature_drops", {"items": _items_text(drops)}), 15, gold))


func _skills(body: VBoxContainer) -> void:
	body.add_child(_label(L.t("ui.points", {"count": Session.state.skill_points}), 18, gold))
	for id in Content.perks:
		var entry := _box(body, 8)
		entry.add_child(_label(L.t("perk." + str(id)), 19, gold))
		entry.add_child(_label(L.t("perk." + str(id) + ".desc"), 16, muted))
		var on_learn_skill := func():
			Session.learn_perk(str(id))
			show_panel("perks")
		var button := _button(
			L.t("ui.known" if Session.has_perk(str(id)) else "ui.learn"), on_learn_skill, 34
		)
		button.disabled = Session.has_perk(str(id)) or int(Session.state.skill_points) <= 0
		entry.add_child(button)


func show_pause() -> void:
	page = "pause"
	Session.paused = true
	var box := _window(L.t("ui.title"))
	box.add_child(
		_label(
			(
				L.t("ui.day", {"day": int(float(Session.state.time) / 1440.0) + 1})
				+ " · "
				+ L.t("difficulty." + str(Session.state.settings.difficulty))
				+ " · "
				+ L.t("death." + str(Session.state.settings.death_mode))
			),
			16,
			muted
		)
	)
	box.add_child(_button(L.t("ui.resume"), show_hud))
	if not Session.state.get("expedition_run", {}).is_empty():
		var on_withdraw_trial := func():
			get_parent().end_expedition(false)
			show_hud()
		box.add_child(_button(L.t("ui.withdraw_expedition"), on_withdraw_trial))
	var on_save_and_resume := func():
		Session.save()
		show_hud()
	box.add_child(_button(L.t("ui.save"), on_save_and_resume))
	box.add_child(_button(L.t("ui.settings"), _pause_settings))
	box.add_child(_button(L.t("ui.changelog"), show_changelog))
	var on_save_and_return := func():
		if Session.save():
			title_requested.emit()
	box.add_child(_button(L.t("ui.save_quit"), on_save_and_return))
	box.add_child(_label(L.t("ui.controls"), 15, muted))


func show_settings() -> void:
	page = "settings"
	var window := _window(L.t("ui.settings"))
	var box := _scroll(window)
	box.add_child(_label(L.t("ui.language"), 17, gold))
	box.add_child(_language_picker())
	for key in ["music", "effects"]:
		box.add_child(_label(L.t("ui." + key), 17, gold))
		var slider := HSlider.new()
		slider.min_value = 0
		slider.max_value = 1
		slider.step = .01
		slider.value = float(L.preferences[key])
		box.add_child(slider)
		var on_adjust_volume := func(value: float):
			L.preferences[key] = value
			Sound.apply_preferences()
			L.save_preferences()
		slider.value_changed.connect(on_adjust_volume)
	for key in ["fullscreen", "reduce_motion"]:
		var toggle := CheckButton.new()
		toggle.text = L.t("ui." + key)
		toggle.button_pressed = bool(L.preferences[key])
		box.add_child(toggle)
		var on_toggle_preference := func(value: bool):
			L.preferences[key] = value
			L.save_preferences()
			if key == "fullscreen":
				DisplayServer.window_set_mode(
					(
						DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
						if value
						else DisplayServer.WINDOW_MODE_WINDOWED
					)
				)
		toggle.toggled.connect(on_toggle_preference)
	if Session.active and not Session.state.retired:
		box.add_child(_label(L.t("ui.difficulty_change"), 17, gold))
		var picker := OptionButton.new()
		var choices := Content.difficulties.keys()
		for key in choices:
			picker.add_item(L.t("difficulty." + str(key)))
		picker.select(choices.find(str(Session.state.settings.difficulty)))
		var on_change_difficulty := func(index: int):
			Session.state.settings.difficulty = choices[index]
			Session.changed.emit()
		picker.item_selected.connect(on_change_difficulty)
		box.add_child(picker)
		box.add_child(_label(L.t("ui.death_fixed"), 14, muted))
	var on_return_from_settings := func():
		if last_page == "pause":
			show_pause()
		else:
			show_title()
	window.add_child(_button(L.t("ui.back"), on_return_from_settings))


func _title_settings() -> void:
	last_page = "title"
	show_settings()


func _pause_settings() -> void:
	last_page = "pause"
	show_settings()


func show_changelog() -> void:
	page = "changelog"
	var box := _window(L.t("ui.changelog"))
	var scroll := _scroll(box)
	for release in Content.releases:
		scroll.add_child(_label(str(release.version) + " · " + str(release.date), 24, gold))
		scroll.add_child(_label(L.t(str(release.text_key)), 18, muted))
		for entry in release.get("entries", []):
			scroll.add_child(_label("• " + L.t(str(entry)), 17, muted))
	var on_return_from_changelog := func():
		if Session.active:
			show_pause()
		else:
			show_title()
	box.add_child(_button(L.t("ui.back"), on_return_from_changelog))


func _state_changed() -> void:
	if page == "hud":
		_refresh_hotbar()


func _language_changed() -> void:
	_apply_theme()
	if not notice_key.is_empty():
		notice_label.text = L.t(notice_key, notice_args)
	match page:
		"title":
			show_title()
		"new":
			show_new()
		"worlds":
			show_worlds()
		"settings":
			show_settings()
		"pause":
			show_pause()
		"panel":
			show_panel(chosen_tab)
		"changelog":
			show_changelog()
		"dialogue":
			show_interaction(dialog_target)
		_:
			show_hud()


func show_message(key: String, args: Dictionary = {}) -> void:
	notice_key = key
	notice_args = args.duplicate()
	notice_label.text = L.t(key, args)
	toast_timer = 5.0
	notice_panel.show()


func _process(delta: float) -> void:
	toast_timer -= delta
	if notice_panel != null:
		notice_panel.visible = toast_timer > 0
	if page != "hud" or Session.state.is_empty():
		return
	health_bar.value = float(Session.state.player.health)
	stamina_bar.max_value = Session.max_stamina()
	stamina_bar.value = float(Session.state.player.stamina)
	var region := Session.world_model.region_at(Vector2i(Session.player_position() / 32.0))
	place_label.text = (
		L.t("region." + str(Content.regions[region].id))
		+ " · "
		+ L.t("ui.day", {"day": int(float(Session.state.time) / 1440.0) + 1})
	)
	need_label.text = (
		"%s %d  ·  %s %d"
		% [
			L.t("ui.food"),
			int(Session.state.player.food),
			L.t("ui.water"),
			int(Session.state.player.water)
		]
	)
	need_label.text += (
		"\n"
		+ L.t("ui.weather_" + Activities.weather())
		+ " · "
		+ L.t("ui.warmth")
		+ " "
		+ str(int(Session.state.player.exposure))
	)
	objective_label.text = L.t(Session.quest_key())
	if int(Session.state.quest_stage) == 1:
		objective_label.text += (
			"\n"
			+ Content.item_name("wood")
			+ " %d/8 · " % int(Session.state.gathered.get("wood", 0))
			+ Content.item_name("stone")
			+ " %d/6" % int(Session.state.gathered.get("stone", 0))
		)
	if not Session.state.expedition_run.is_empty():
		objective_label.text = L.t(
			"ui.wave",
			{
				"wave": Session.state.expedition_run.wave,
				"depth": int(Session.state.expedition_run.depth) + 1
			}
		)
	if world_view != null:
		var offset: Vector2 = world_view.objective_position() - Session.player_position()
		if (
			offset.length() > 64
			and Session.state.expedition_run.is_empty()
			and int(Session.state.quest_stage) > 2
		):
			var arrow := (
				"→"
				if absf(offset.x) > absf(offset.y) and offset.x > 0
				else "←" if absf(offset.x) > absf(offset.y) else "↓" if offset.y > 0 else "↑"
			)
			objective_label.text += "\n" + arrow + " " + str(roundi(offset.length() / 32)) + " m"
		if not world_view.placing.is_empty():
			hint_label.text = L.t("ui.build_hint")
		elif not world_view.target.is_empty():
			hint_label.text = "[E / A] " + _target_name(world_view.target)
		else:
			hint_label.text = ""
		if root.has_node("HintPanel"):
			root.get_node("HintPanel").visible = not hint_label.text.is_empty()


func _target_name(target: Dictionary) -> String:
	if target.has("drop"):
		return L.t("ui.collect")
	if target.has("grave"):
		return L.t("ui.recover")
	var data: Dictionary = target.data
	if data.has("site"):
		return L.t(str(Activities.site_definition(str(data.site)).name_key))
	if data.has("npc"):
		return L.t("ui.talk", {"name": L.t("npc." + str(data.npc))})
	if data.has("waystone"):
		return L.t("ui.attune" if Session.state.restored[int(data.waystone)] else "ui.restore")
	if data.has("structure"):
		var name_ := Content.item_name(str(data.id))
		var kind := str(Content.structures[str(data.id)].kind)
		if kind == "chest":
			return L.t("ui.open", {"name": name_})
		if kind == "gate":
			return L.t("ui.open_gate")
		return L.t("ui.rest" if kind in ["bed", "hearth", "shelter"] else "ui.use") + " · " + name_
	return L.t("ui.harvest", {"name": Content.item_name(str(data.id))})


func show_death() -> void:
	page = "death"
	Session.paused = true
	var box := _window(L.t("ui.dead"))
	box.add_child(
		_label(
			L.t(
				(
					"ui.retired"
					if Session.state.retired
					else "death." + str(Session.state.settings.death_mode) + ".desc"
				)
			),
			20,
			muted
		)
	)
	if Session.state.settings.death_mode == "mediumcore":
		box.add_child(_label(L.t("ui.grave"), 18, muted))
	if not Session.state.retired:
		var on_respawn_player := func():
			if Session.respawn():
				get_parent()._build_world()
				show_hud()
		box.add_child(_button(L.t("ui.respawn"), on_respawn_player))
	else:
		box.add_child(_button(L.t("ui.atlas"), show_retired_atlas))
	box.add_child(_button(L.t("ui.back"), func(): title_requested.emit()))


func _on_player_fell() -> void:
	await get_tree().create_timer(.95).timeout
	if not Session.state.is_empty() and Session.state.player.dead:
		show_death()


func show_retired_atlas() -> void:
	page = "retired"
	Session.paused = true
	var box := _window(L.t("ui.atlas"))
	box.add_child(_label(L.t("ui.read_only"), 18, muted))
	var map := MossMap.new()
	map.custom_minimum_size = Vector2(880, 390)
	box.add_child(map)
	box.add_child(_button(L.t("ui.back"), func(): title_requested.emit()))


func show_victory() -> void:
	page = "victory"
	Session.paused = true
	var box := _window(L.t("ui.victory"))
	box.add_child(_label(L.t("ui.ending"), 21, muted))
	box.add_child(_label(L.t("ui.credits"), 16, gold))
	box.add_child(_button(L.t("ui.keep_playing"), show_hud))
	Sound.effect("victory")


func show_interaction(target_: Dictionary) -> void:
	dialog_target = target_
	page = "dialogue"
	Session.paused = true
	var data: Dictionary = target_.data
	if data.has("npc"):
		var id := str(data.npc)
		if not id in Session.state.npc_met:
			Session.state.npc_met.append(id)
			Session.gain_xp(20)
		var box := _window(L.t("npc." + id))
		box.add_child(_label(L.t("npc." + id + ".dialogue"), 21, parchment))
		var request := Activities.request_for(id)
		box.add_child(
			_label(L.t("ui.request_cost", {"materials": _items_text(request.cost)}), 17, muted)
		)
		box.add_child(
			_label(
				L.t(
					"ui.request_reward",
					{
						"rewards": _items_text(request.reward),
						"xp": int(request.xp),
						"rep": int(request.goodwill)
					}
				),
				16,
				muted
			)
		)
		box.add_child(
			_label(L.t("ui.goodwill", {"count": Session.state.goodwill.get(id, 0)}), 16, gold)
		)
		var delivered := (
			int(Session.state.contracts.get(id, -1)) == int(float(Session.state.time) / 1440.0)
		)
		if delivered:
			box.add_child(_label(L.t("ui.request_today"), 16, muted))
		else:
			var on_deliver_request := func():
				Activities.deliver(id)
				show_interaction(target_)
			box.add_child(_button(L.t("ui.deliver"), on_deliver_request))
		box.add_child(_button(L.t("ui.trade"), func(): _trade(id)))
		box.add_child(_button(L.t("ui.close"), show_hud))
	elif data.has("waystone"):
		_waystone(int(data.waystone))
	elif data.has("structure"):
		_structure(str(target_.key))
	elif data.has("site"):
		_site(str(data.site))


func _trade(npc: String) -> void:
	var box := _window(L.t("ui.trade"))
	box.add_child(_label(L.t("ui.trade_hint"), 17, muted))
	var body := _scroll(box)
	for id in Content.trade_stock:
		var stock: Dictionary = Content.trade_stock[id]
		var row := HBoxContainer.new()
		body.add_child(row)
		row.add_child(_icon(str(id)))
		row.add_child(_label(Content.item_name(str(id)) + " ×" + str(stock.count), 18, gold))
		var on_purchase_stock := func():
			Activities.trade(npc, str(id), int(stock.count), int(stock.price), int(stock.goodwill))
			_trade(npc)
		var button := _button(L.t("ui.price", {"count": stock.price}), on_purchase_stock)
		button.disabled = int(Session.state.goodwill.get(npc, 0)) < int(stock.goodwill)
		row.add_child(button)
	box.add_child(_button(L.t("ui.back"), func(): show_interaction(dialog_target)))


func _site(id: String) -> void:
	Activities.discover_site(id)
	var definition := Activities.site_definition(id)
	var saved: Dictionary = Session.state.sites[id]
	var box := _window(L.t(str(definition.name_key)))
	box.add_child(_label(L.t(str(definition.description_key)), 20, parchment))
	var kind := str(definition.kind)
	if kind == "puzzle" and not saved.searched:
		var sequence := PackedStringArray()
		var currents: Array = ["bloom", "ember", "gale"]
		for value in Activities.puzzle_solution(id):
			sequence.append(L.t("ui." + str(currents[int(value)])))
		box.add_child(_label(L.t("ui.puzzle_hint", {"sequence": " → ".join(sequence)}), 18, muted))
		var row := HBoxContainer.new()
		box.add_child(row)
		for i in range(3):
			var on_rotate_seal := func():
				saved.seals[i] = (int(saved.seals[i]) + 1) % 3
				_site(id)
			row.add_child(_button(L.t("ui." + str(currents[int(saved.seals[i])])), on_rotate_seal))
	if kind == "expedition":
		box.add_child(_label(L.t("ui.expedition_desc"), 17, muted))
	if saved.searched and kind in ["cache", "survey", "puzzle"]:
		box.add_child(_label(L.t("ui.searched"), 18, muted))
	else:
		var key: String = {
			"cache": "search_site",
			"survey": "survey_site",
			"puzzle": "puzzle_solve",
			"spring": "collect",
			"grove": "grove_offer",
			"expedition":
			"peaceful_survey" if Session.state.settings.difficulty == "peaceful" else "expedition"
		}[kind]
		var on_explore_site := func():
			if kind == "expedition":
				show_hud()
				Activities.site_action(id)
			else:
				Activities.site_action(id)
				_site(id)
		box.add_child(_button(L.t("ui." + key), on_explore_site))
	box.add_child(_button(L.t("ui.close"), show_hud))


func _waystone(region: int) -> void:
	var window := _window(L.t("region." + str(Content.regions[region].id)))
	var box := _scroll(window)
	if not Session.state.restored[region]:
		box.add_child(_label(L.t("ui.restore_cost"), 20, muted))
		var on_restore_waystone := func():
			Session.restore(region)
			_waystone(region)
		box.add_child(_button(L.t("ui.restore"), on_restore_waystone))
	else:
		box.add_child(_label(L.t("ui.attune"), 20, gold))
		for current in ["bloom", "ember", "gale"]:
			box.add_child(_label(L.t("ui." + current + "_desc"), 16, muted))
			var on_choose_current := func():
				Session.attune(region, current)
				show_hud()
			box.add_child(_button(L.t("ui." + current), on_choose_current))
		if not Session.state.wardens[region]:
			box.add_child(_label(L.t("ui.warden_warning"), 16, muted))
			var on_challenge_warden := func():
				show_hud()
				if Session.state.settings.difficulty == "peaceful":
					Session.peaceful_offering(region)
				else:
					world_view.challenge(region)
			box.add_child(
				_button(
					L.t(
						(
							"ui.peaceful_restore"
							if Session.state.settings.difficulty == "peaceful"
							else "ui.warden"
						)
					),
					on_challenge_warden
				)
			)
		elif Session.state.settings.difficulty != "peaceful":
			var on_rematch_warden := func():
				show_hud()
				world_view.challenge(region)
			box.add_child(_button(L.t("ui.rematch"), on_rematch_warden))
	window.add_child(_button(L.t("ui.close"), show_hud))


func _structure(key: String) -> void:
	var structure: Dictionary = Session.state.structures[key]
	var id := str(structure.id)
	var kind := str(Content.structures[id].kind)
	if kind in ["hearth", "bed", "shelter"]:
		Session.state.player.home = [
			Session.structure_position(structure).x + 32, Session.structure_position(structure).y
		]
		var box := _window(Content.item_name(id))
		box.add_child(_label(Content.item_description(id), 19, muted))
		var on_rest_until_morning := func():
			Session.state.time = ((floorf(float(Session.state.time) / 1440.0) + 1) * 1440.0 + 360)
			Session.state.player.health = 100.0
			Session.state.player.stamina = Session.max_stamina()
			show_hud()
			show_message("ui.rested")
		box.add_child(_button(L.t("ui.rest"), on_rest_until_morning))
		if kind == "hearth":
			box.add_child(_button(L.t("ui.travel"), func(): _travel()))
		box.add_child(_button(L.t("ui.close"), show_hud))
	elif kind == "chest":
		var box := _window(Content.item_name(id))
		var scroll := _scroll(box)
		for item_id in structure.contents:
			scroll.add_child(
				_label(
					Content.item_name(str(item_id)) + " ×" + str(int(structure.contents[item_id])),
					17,
					muted
				)
			)
		var on_deposit_materials := func():
			for item_id in Session.state.inventory.keys():
				if Content.items[item_id].kind == "material":
					structure.contents[item_id] = (
						int(structure.contents.get(item_id, 0))
						+ int(Session.state.inventory[item_id])
					)
					Session.state.inventory.erase(item_id)
			_structure(key)
		box.add_child(_button(L.t("ui.chest_hint"), on_deposit_materials))
		var on_withdraw_items := func():
			for item_id in structure.contents.keys():
				if Session.add_item(str(item_id), int(structure.contents[item_id]), false):
					structure.contents.erase(item_id)
			_structure(key)
		box.add_child(_button(L.t("ui.withdraw"), on_withdraw_items))
		box.add_child(_button(L.t("ui.close"), show_hud))
	elif kind == "well":
		Session.add_item("water", 3)
		show_hud()
	elif kind in ["garden", "apiary", "trap"]:
		var window := _window(Content.item_name(id))
		var box := _scroll(window)
		box.add_child(
			_label(
				L.t("ui.plant_hint") if kind == "garden" else Content.item_description(id),
				19,
				muted
			)
		)
		var remaining := Activities.ready_in(structure)
		if remaining < 0:
			box.add_child(_label(L.t("ui.plant_choice"), 18, gold))
			var available := Session.available_items()
			for seed_id in Content.crops:
				var on_plant_seed := func():
					Activities.plant(key, str(seed_id))
					_structure(key)
				var button := _button(
					Content.item_name(str(seed_id)) + " ×" + str(int(available.get(seed_id, 0))),
					on_plant_seed
				)
				button.icon = Content.icon(str(seed_id))
				button.expand_icon = true
				button.add_theme_constant_override("icon_max_width", 28)
				button.disabled = int(available.get(seed_id, 0)) < 1
				box.add_child(button)
		elif remaining == 0:
			var on_harvest_garden := func():
				Activities.harvest(key)
				_structure(key)
			box.add_child(
				_button(
					L.t("ui.harvest_crop" if kind == "garden" else "ui.collect"), on_harvest_garden
				)
			)
		else:
			box.add_child(_label(L.t("ui.growing", {"seconds": ceili(remaining)}), 20, gold))
		window.add_child(_button(L.t("ui.close"), show_hud))
	elif kind == "gate":
		structure.closed = not bool(structure.get("closed", true))
		if world_view.props.has(key):
			world_view.props[key].node.modulate.a = .45 if not structure.closed else 1.0
		show_hud()
	elif kind == "courier":
		_courier(key)
	elif kind == "station":
		_station(key)
	elif kind == "route":
		show_panel("atlas")
	elif id == "bookshelf" or id == "table":
		show_panel("journal")
	else:
		var box := _window(Content.item_name(id))
		box.add_child(_label(Content.item_description(id), 19, muted))
		box.add_child(_button(L.t("ui.close"), show_hud))


func _station(key: String) -> void:
	var id := str(Session.state.structures[key].id)
	var box := _window(Content.item_name(id))
	box.add_child(_label(L.t("ui.production_hint"), 16, muted))
	var body := _scroll(box)
	var production: Dictionary = Session.state.production.get(key, {"queue": [], "ready": {}})
	if not production.ready.is_empty():
		body.add_child(_label(_items_text(production.ready), 18, gold))
		var on_collect_output := func():
			Activities.collect_production(key)
			_station(key)
		body.add_child(_button(L.t("ui.collect"), on_collect_output))
	body.add_child(_label(L.t("ui.queued", {"count": production.queue.size()}), 16, muted))
	for batch in production.queue:
		body.add_child(
			_label(
				(
					Content.item_name(str(batch.result))
					+ " · "
					+ L.t(
						"ui.growing",
						{"seconds": ceili(maxf(0, float(batch.finish) - float(Session.state.time)))}
					)
				),
				15,
				muted
			)
		)
	for definition in Content.production:
		if str(definition.station) != id:
			continue
		var recipe: Dictionary = Content.recipes[str(definition.id)]
		var row := HBoxContainer.new()
		body.add_child(row)
		row.add_child(_icon(str(definition.id)))
		var ingredients: Dictionary = {}
		for ingredient in recipe.ingredients:
			ingredients[str(ingredient.id)] = int(ingredient.count)
		row.add_child(
			_label(
				(
					Content.item_name(str(definition.id))
					+ " ×"
					+ str(recipe.result.count)
					+ "\n"
					+ _items_text(ingredients)
				),
				16,
				gold
			)
		)
		var on_queue_batch := func():
			Activities.queue_recipe(str(definition.id), key)
			_station(key)
		var button := _button(L.t("ui.queue"), on_queue_batch)
		button.disabled = int(recipe.tier) > Session.unlocked_tier()
		row.add_child(button)
	box.add_child(_button(L.t("ui.crafting"), func(): show_panel("crafting")))
	box.add_child(_button(L.t("ui.close"), show_hud))


func _courier(key: String) -> void:
	var box := _window(L.t("ui.courier"))
	box.add_child(_label(L.t("ui.courier_hint"), 19, muted))
	var body := _scroll(box)
	for other in Session.state.structures:
		if str(other) == key or Session.state.structures[other].id != "courier_board":
			continue
		var structure: Dictionary = Session.state.structures[other]
		var region := Session.world_model.region_at(
			Vector2i(int(structure.cell[0]), int(structure.cell[1]))
		)
		var label := (
			L.t("region." + str(Content.regions[region].id))
			+ " · "
			+ str(structure.cell[0])
			+ ", "
			+ str(structure.cell[1])
		)
		body.add_child(_label(label, 18, gold))
		var on_send_shipment := func():
			Activities.send_shipment(key, str(other))
			_courier(key)
		body.add_child(_button(L.t("ui.send_shipment"), on_send_shipment))
	box.add_child(_button(L.t("ui.close"), show_hud))


func _travel() -> void:
	var box := _window(L.t("ui.travel"))
	var body := _scroll(box)
	for structure in Session.state.structures.values():
		if Content.structures[str(structure.id)].kind != "hearth":
			continue
		var position_ := Session.structure_position(structure)
		if position_.distance_to(Session.player_position()) < 100:
			continue
		var region := Session.world_model.region_at(Vector2i(position_ / 32.0))
		var label := (
			L.t("region." + str(Content.regions[region].id))
			+ " · "
			+ str(structure.cell[0])
			+ ", "
			+ str(structure.cell[1])
		)
		var on_travel_to_hearth := func():
			if world_view.has_hostiles(240):
				show_message("ui.travel_blocked")
				return
			Activities.travel_requested.emit(position_ + Vector2(32, 0))
			show_hud()
		var button := _button(label, on_travel_to_hearth)
		var origin := Session.world_model.region_at(Vector2i(Session.player_position() / 32.0))
		button.disabled = (
			not bool(Session.state.restored[region]) or not bool(Session.state.restored[origin])
		)
		body.add_child(button)
	box.add_child(_button(L.t("ui.close"), show_hud))
