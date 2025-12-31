extends Control

## Main menu controller with settings persistence.

const SETTINGS_PATH := "user://settings.cfg"
const AUDIO_BUS_MASTER := 0

@onready var main_panel := $MainPanel
@onready var settings_panel := $SettingsPanel
@onready var volume_slider := $SettingsPanel/SettingsContainer/VolumeRow/VolumeSlider
@onready var fullscreen_toggle := $SettingsPanel/SettingsContainer/FullscreenRow/FullscreenToggle

var config := ConfigFile.new()

func _ready() -> void:
    _load_settings()
    _apply_settings()
    _show_main()

func _on_start_pressed() -> void:
    get_tree().change_scene_to_file("res://scenes/Main.tscn")

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
