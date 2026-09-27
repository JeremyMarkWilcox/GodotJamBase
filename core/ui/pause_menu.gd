extends BaseMenu

@export var resume_button: Button
@export var restart_button: Button
@export var quit_button: Button


func _ready() -> void:
	super()  # runs BaseMenu's _ready too
	resume_button.pressed.connect(MenuManager.close_menu)
	restart_button.pressed.connect(SceneManager.restart)
	quit_button.pressed.connect(SceneManager.return_to_title)
