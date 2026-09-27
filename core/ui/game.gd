extends Control

@export var back_button: Button


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	back_button.grab_focus()


func _on_back_pressed() -> void:
	SceneManager.return_to_title()
