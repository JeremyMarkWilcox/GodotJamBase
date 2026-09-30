extends BaseMenu

const SCROLL_STEP := 60

@export var back_button: Button
@export var scroll: ScrollContainer


func _ready() -> void:
	super()
	back_button.pressed.connect(MenuManager.close_menu)


func _input(event: InputEvent) -> void:
	if not visible:
		return
	# Up/down (keys, D-pad, stick) scroll the credits; holding repeats.
	if event.is_action_pressed("ui_down", true):
		scroll.scroll_vertical += SCROLL_STEP
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_up", true):
		scroll.scroll_vertical -= SCROLL_STEP
		get_viewport().set_input_as_handled()
