extends BaseMenu

@export var back_button: Button


func _ready() -> void:
	super()
	back_button.pressed.connect(MenuManager.close_menu)
