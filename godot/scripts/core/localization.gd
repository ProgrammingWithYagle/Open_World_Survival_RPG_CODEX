extends Node

signal language_changed
const LANGUAGES := ["en", "zh_CN", "zh_TW", "es", "ja"]
const LANGUAGE_NAMES := ["English", "简体中文", "繁體中文", "Español", "日本語"]
var language := "en"
var catalog: Dictionary = {}
var fallback: Dictionary = {}
var preferences := {
	"language": "en", "music": 0.55, "effects": 0.75, "reduce_motion": false, "fullscreen": false
}


func _ready() -> void:
	fallback = _read("res://locale/en.json")
	var config := ConfigFile.new()
	if config.load("user://preferences.cfg") == OK:
		for key in preferences:
			preferences[key] = config.get_value("preferences", key, preferences[key])
	set_language(str(preferences.language), false)


func _read(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var value: Variant = JSON.parse_string(file.get_as_text())
	return value if value is Dictionary else {}


func set_language(value: String, persist := true) -> void:
	language = value if value in LANGUAGES else "en"
	catalog = _read("res://locale/%s.json" % language)
	preferences.language = language
	TranslationServer.set_locale(language)
	if persist:
		save_preferences()
	language_changed.emit()


func t(key: String, args: Dictionary = {}) -> String:
	var result: String = str(catalog.get(key, fallback.get(key, key)))
	for name in args:
		var value: Variant = args[name]
		var formatted := (
			str(int(value))
			if value is float and float(value) == floorf(float(value))
			else str(value)
		)
		result = result.replace("{" + str(name) + "}", formatted)
	return result


func save_preferences() -> void:
	var config := ConfigFile.new()
	for key in preferences:
		config.set_value("preferences", key, preferences[key])
	config.save("user://preferences.cfg")


func font() -> Font:
	if (
		language in ["en", "es"]
		and ResourceLoader.exists("res://fonts/AtkinsonHyperlegible-Regular.ttf")
	):
		return load("res://fonts/AtkinsonHyperlegible-Regular.ttf")
	var region := "jp" if language == "ja" else "tc" if language == "zh_TW" else "sc"
	var path := "res://fonts/NotoSansCJK%s-Regular.otf" % region
	if ResourceLoader.exists(path):
		return load(path)
	return ThemeDB.fallback_font


func title_font() -> Font:
	if language in ["en", "es"] and ResourceLoader.exists("res://fonts/Lora-Regular.ttf"):
		return load("res://fonts/Lora-Regular.ttf")
	return font()
