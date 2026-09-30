extends Control

@export var music: AudioStream
@export var pause_menu: BaseMenu
@export var win_screen: BaseMenu
@export var game_over_screen: BaseMenu


func _ready() -> void:
	Audio.play_music(music)
	Debug.win_requested.connect(_on_debug_win)
	Debug.lose_requested.connect(_on_debug_lose)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not MenuManager.is_menu_open():
		MenuManager.open_menu(pause_menu)
		get_viewport().set_input_as_handled()
	

func _on_debug_win() -> void:
	if not MenuManager.is_menu_open():
		MenuManager.open_menu(win_screen)


func _on_debug_lose() -> void:
	if not MenuManager.is_menu_open():
		MenuManager.open_menu(game_over_screen)
