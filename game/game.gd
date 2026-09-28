extends Control

@export var back_button: Button
@export var pause_menu: BaseMenu
@export var music: AudioStream


func _ready() -> void:
	Audio.play_music(music)
	back_button.pressed.connect(_on_back_pressed)
	back_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not MenuManager.is_menu_open():
		MenuManager.open_menu(pause_menu)
		get_viewport().set_input_as_handled()


func _on_back_pressed() -> void:
	SceneManager.return_to_title()
