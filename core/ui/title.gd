extends Control

@export_file("*.tscn") var game_scene: String
@export var play_button: Button


func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	play_button.grab_focus()


func _on_play_pressed() -> void:
	SceneManager.change_scene(game_scene)
