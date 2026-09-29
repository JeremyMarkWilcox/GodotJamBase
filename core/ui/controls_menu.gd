extends BaseMenu

@export var reset_button: Button
@export var back_button: Button


func _ready() -> void:
	super()
	reset_button.pressed.connect(InputManager.reset_to_defaults)
	back_button.pressed.connect(MenuManager.close_menu)
