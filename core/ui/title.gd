extends Control

@export_file("*.tscn") var game_scene: String
@export var music: AudioStream
@export var play_button: Button
@export var settings_button: Button
@export var credits_button: Button
@export var quit_button: Button
@export var settings_menu: BaseMenu
@export var credits_menu: BaseMenu
@export var version_label: Label


func _ready() -> void:
	Audio.play_music(music)
	play_button.pressed.connect(_on_play_pressed)
	settings_button.pressed.connect(func() -> void: MenuManager.open_menu(settings_menu))
	credits_button.pressed.connect(func() -> void: MenuManager.open_menu(credits_menu))
	quit_button.pressed.connect(SceneManager.quit)
	quit_button.visible = not OS.has_feature("web")  # browsers can't close the tab
	MenuManager.menu_closed.connect(_on_menu_closed)
	play_button.grab_focus()
	var version: String = ProjectSettings.get_setting("application/config/version", "")
	version_label.text = "v" + version if version else ""


func _on_play_pressed() -> void:
	SceneManager.change_scene(game_scene)


func _on_menu_closed(_menu: BaseMenu) -> void:
	if not MenuManager.is_menu_open():
		play_button.grab_focus()
