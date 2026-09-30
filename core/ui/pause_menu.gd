extends BaseMenu

@export var resume_button: Button
@export var restart_button: Button
@export var quit_button: Button
@export var settings_button: Button
@export var settings_menu: BaseMenu
@export var pause_on_focus_loss := true


func _ready() -> void:
	super()  # runs BaseMenu's _ready too
	resume_button.pressed.connect(MenuManager.close_menu)
	restart_button.pressed.connect(SceneManager.restart)
	quit_button.pressed.connect(SceneManager.return_to_title)
	settings_button.pressed.connect(func() -> void: MenuManager.open_menu(settings_menu))

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and pause_on_focus_loss \
			and not MenuManager.is_menu_open():
		MenuManager.open_menu(self)
