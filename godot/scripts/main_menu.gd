extends Control

## Main menu controller with settings persistence.

const SETTINGS_PATH := "user://settings.cfg"
const AUDIO_BUS_MASTER := 0

@onready var main_panel := $MainPanel
@onready var settings_panel := $SettingsPanel
@onready var volume_slider := $SettingsPanel/SettingsContainer/VolumeRow/VolumeSlider
@onready var fullscreen_toggle := $SettingsPanel/SettingsContainer/FullscreenRow/FullscreenToggle
@onready var difficulty_option := $MainPanel/MenuContainer/WorldSettingsPanel/WorldSettingsContainer/DifficultyRow/DifficultyOption
@onready var needs_toggle := $MainPanel/MenuContainer/WorldSettingsPanel/WorldSettingsContainer/NeedsToggle
@onready var mobs_toggle := $MainPanel/MenuContainer/WorldSettingsPanel/WorldSettingsContainer/MobsToggle
@onready var respawn_toggle := $MainPanel/MenuContainer/WorldSettingsPanel/WorldSettingsContainer/RespawnToggle
@onready var starter_kit_toggle := $MainPanel/MenuContainer/WorldSettingsPanel/WorldSettingsContainer/StarterKitToggle

var config := ConfigFile.new()

func _ready() -> void:
	_load_settings()
	_apply_settings()
	_setup_world_settings()
	_show_main()

func _on_start_pressed() -> void:
	var settings := _build_world_settings()
	_start_game(settings)

func _on_settings_pressed() -> void:
    _show_settings()

func _on_quit_pressed() -> void:
    get_tree().quit()

func _on_back_pressed() -> void:
    _save_settings()
    _show_main()

func _on_volume_changed(value: float) -> void:
    _apply_volume(value)

func _on_fullscreen_toggled(pressed: bool) -> void:
	_apply_fullscreen(pressed)

func _show_main() -> void:
    main_panel.visible = true
    settings_panel.visible = false

func _show_settings() -> void:
    main_panel.visible = false
    settings_panel.visible = true

func _load_settings() -> void:
    if config.load(SETTINGS_PATH) != OK:
        return
    volume_slider.value = float(config.get_value("audio", "master_volume", 0.8))
    fullscreen_toggle.button_pressed = bool(config.get_value("display", "fullscreen", false))

func _save_settings() -> void:
    config.set_value("audio", "master_volume", volume_slider.value)
    config.set_value("display", "fullscreen", fullscreen_toggle.button_pressed)
    config.save(SETTINGS_PATH)

func _apply_settings() -> void:
    _apply_volume(volume_slider.value)
    _apply_fullscreen(fullscreen_toggle.button_pressed)

func _apply_volume(value: float) -> void:
    var volume_db := linear_to_db(clampf(value, 0.0, 1.0))
    AudioServer.set_bus_volume_db(AUDIO_BUS_MASTER, volume_db)

func _apply_fullscreen(is_fullscreen: bool) -> void:
	if is_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _setup_world_settings() -> void:
	difficulty_option.clear()
	difficulty_option.add_item("Peaceful", WorldSettings.Difficulty.PEACEFUL)
	difficulty_option.add_item("Easy", WorldSettings.Difficulty.EASY)
	difficulty_option.add_item("Normal", WorldSettings.Difficulty.NORMAL)
	difficulty_option.add_item("Hardcore", WorldSettings.Difficulty.HARDCORE)
	difficulty_option.select(WorldSettings.Difficulty.NORMAL)
	difficulty_option.item_selected.connect(_on_difficulty_selected)
	_apply_recommended_world_flags(WorldSettings.Difficulty.NORMAL)

func _on_difficulty_selected(index: int) -> void:
	_apply_recommended_world_flags(index)

func _apply_recommended_world_flags(difficulty: int) -> void:
	var settings := WorldSettings.new()
	settings.difficulty = difficulty
	settings.apply_recommended_flags()
	needs_toggle.button_pressed = settings.enable_needs
	mobs_toggle.button_pressed = settings.enable_hostile_mobs
	respawn_toggle.button_pressed = settings.allow_respawn
	starter_kit_toggle.button_pressed = settings.grant_starter_kit

func _build_world_settings() -> WorldSettings:
	var settings := WorldSettings.new()
	settings.difficulty = difficulty_option.get_selected_id()
	settings.enable_needs = needs_toggle.button_pressed
	settings.enable_hostile_mobs = mobs_toggle.button_pressed
	settings.allow_respawn = respawn_toggle.button_pressed
	settings.grant_starter_kit = starter_kit_toggle.button_pressed
	return settings

func _start_game(settings: WorldSettings) -> void:
	var packed_scene := load("res://scenes/Main.tscn") as PackedScene
	if packed_scene == null:
		return
	var instance := packed_scene.instantiate()
	if instance != null:
		instance.world_settings = settings
	get_tree().root.add_child(instance)
	get_tree().current_scene = instance
	queue_free()
