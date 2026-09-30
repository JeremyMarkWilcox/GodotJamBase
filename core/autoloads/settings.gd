extends Node
## Holds player settings, applies them, and saves them to disk.

signal changed

const CONFIG_PATH := "user://settings.cfg"

var volumes: Dictionary[String, float] = {"Master": 1.0, "Music": 0.8, "SFX": 0.8, "UI": 0.8}
var fullscreen := false
var ui_scale := 1.0
var screen_shake := true
var flashing := true

var _config := ConfigFile.new()

var game_speed := 1.0

func _ready() -> void:
	load_settings()
	_apply_all()


func set_volume(bus: String, value: float) -> void:
	volumes[bus] = clampf(value, 0.0, 1.0)
	_apply_volume(bus)
	changed.emit()


func set_fullscreen(value: bool) -> void:
	fullscreen = value
	_apply_fullscreen()
	changed.emit()


func set_ui_scale(value: float) -> void:
	ui_scale = value
	get_tree().root.content_scale_factor = ui_scale
	changed.emit()


func set_screen_shake(value: bool) -> void:
	screen_shake = value
	changed.emit()


func set_flashing(value: bool) -> void:
	flashing = value
	changed.emit()


func save_settings() -> void:
	for bus in volumes:
		_config.set_value("audio", bus, volumes[bus])
	_config.set_value("display", "fullscreen", fullscreen)
	_config.set_value("display", "ui_scale", ui_scale)
	_config.set_value("accessibility", "screen_shake", screen_shake)
	_config.set_value("accessibility", "flashing", flashing)
	_config.set_value("gameplay", "game_speed", game_speed)
	var error := _config.save(CONFIG_PATH)
	if error != OK:
		push_warning("Settings: could not save %s" % CONFIG_PATH)


func load_settings() -> void:
	if _config.load(CONFIG_PATH) != OK:
		return  # first run: keep the defaults
	for bus in volumes:
		volumes[bus] = _config.get_value("audio", bus, volumes[bus])
	fullscreen = _config.get_value("display", "fullscreen", fullscreen)
	ui_scale = _config.get_value("display", "ui_scale", ui_scale)
	screen_shake = _config.get_value("accessibility", "screen_shake", screen_shake)
	flashing = _config.get_value("accessibility", "flashing", flashing)
	game_speed = _config.get_value("gameplay", "game_speed", game_speed)


func _apply_all() -> void:
	for bus in volumes:
		_apply_volume(bus)
	if not OS.has_feature("web"):  # browsers only allow fullscreen after a click
		_apply_fullscreen()
	get_tree().root.content_scale_factor = ui_scale
	Engine.time_scale = game_speed


func _apply_volume(bus: String) -> void:
	var index := AudioServer.get_bus_index(bus)
	if index == -1:
		push_warning("Settings: no audio bus named %s" % bus)
		return
	AudioServer.set_bus_volume_db(index, linear_to_db(volumes[bus]))
	AudioServer.set_bus_mute(index, volumes[bus] <= 0.0)


func _apply_fullscreen() -> void:
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)
	
	
func set_game_speed(value: float) -> void:
	game_speed = value
	Engine.time_scale = game_speed
	changed.emit()
