extends Control

@export_file("*.tscn") var game_scene: String
@export var play_button: Button
@export var settings_button: Button
@export var settings_menu: BaseMenu


func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	play_button.grab_focus()
	settings_button.pressed.connect(func() -> void: MenuManager.open_menu(settings_menu))
	MenuManager.menu_closed.connect(_on_menu_closed)



func _on_play_pressed() -> void:
	SceneManager.change_scene(game_scene)
	
	
func _on_menu_closed(_menu: BaseMenu) -> void:
	if not MenuManager.is_menu_open():
		play_button.grab_focus()
