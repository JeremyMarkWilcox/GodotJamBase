extends Control

@export var music: AudioStream
@export var back_button: Button
@export var pause_menu: BaseMenu
@export var win_screen: BaseMenu
@export var game_over_screen: BaseMenu

@export_group("Testing")
@export var win_test_button: Button
@export var lose_test_button: Button


func _ready() -> void:
	Audio.play_music(music)
	back_button.pressed.connect(_on_back_pressed)
	back_button.grab_focus()
	win_test_button.pressed.connect(func() -> void: MenuManager.open_menu(win_screen))
	lose_test_button.pressed.connect(func() -> void: MenuManager.open_menu(game_over_screen))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not MenuManager.is_menu_open():
		MenuManager.open_menu(pause_menu)
		get_viewport().set_input_as_handled()


func _on_back_pressed() -> void:
	SceneManager.return_to_title()
