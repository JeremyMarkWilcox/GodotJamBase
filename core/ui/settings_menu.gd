extends BaseMenu

@export var master_slider: HSlider
@export var music_slider: HSlider
@export var sfx_slider: HSlider
@export var ui_slider: HSlider
@export var fullscreen_toggle: CheckButton
@export var shake_toggle: CheckButton
@export var flash_toggle: CheckButton
@export var back_button: Button
@export var controls_button: Button
@export var controls_menu: BaseMenu
@export var game_speed_slider: HSlider
@export var game_speed_value_label: Label
@export var ui_scale_down_button: Button
@export var ui_scale_up_button: Button
@export var ui_scale_value_label: Label

const UI_SCALE_STEPS: Array[float] = [0.75, 0.9, 1.0, 1.1, 1.25]




func _ready() -> void:
	super()
	controls_button.pressed.connect(func() -> void: MenuManager.open_menu(controls_menu))
	master_slider.value_changed.connect(func(value: float) -> void: Settings.set_volume("Master", value))
	music_slider.value_changed.connect(func(value: float) -> void: Settings.set_volume("Music", value))
	sfx_slider.value_changed.connect(func(value: float) -> void: Settings.set_volume("SFX", value))
	ui_slider.value_changed.connect(func(value: float) -> void: Settings.set_volume("UI", value))
	fullscreen_toggle.toggled.connect(Settings.set_fullscreen)
	shake_toggle.toggled.connect(Settings.set_screen_shake)
	flash_toggle.toggled.connect(Settings.set_flashing)
	back_button.pressed.connect(MenuManager.close_menu)
	game_speed_slider.value_changed.connect(_on_game_speed_changed)
	ui_scale_down_button.pressed.connect(_step_ui_scale.bind(-1))
	ui_scale_up_button.pressed.connect(_step_ui_scale.bind(1))
	
		# The − and + buttons share one row: left/right moves between them,
	# up/down leaves the row the same way from either button.
	ui_scale_down_button.focus_neighbor_right = ui_scale_down_button.get_path_to(ui_scale_up_button)
	ui_scale_up_button.focus_neighbor_left = ui_scale_up_button.get_path_to(ui_scale_down_button)
	ui_scale_up_button.focus_neighbor_right = ui_scale_up_button.get_path_to(ui_scale_up_button)
	ui_scale_up_button.focus_neighbor_top = ui_scale_down_button.focus_neighbor_top
	ui_scale_up_button.focus_neighbor_bottom = ui_scale_down_button.focus_neighbor_bottom


func open() -> void:
	_sync_from_settings()
	super()


func close() -> void:
	Settings.save_settings()
	super()
	
	
func _on_game_speed_changed(value: float) -> void:
	Settings.set_game_speed(value)
	_update_game_speed_label(value)
	
	
func _update_game_speed_label(value: float) -> void:
	game_speed_value_label.text = "%sx" % value


func _sync_from_settings() -> void:
	master_slider.set_value_no_signal(Settings.volumes["Master"])
	music_slider.set_value_no_signal(Settings.volumes["Music"])
	sfx_slider.set_value_no_signal(Settings.volumes["SFX"])
	ui_slider.set_value_no_signal(Settings.volumes["UI"])
	fullscreen_toggle.set_pressed_no_signal(Settings.fullscreen)
	shake_toggle.set_pressed_no_signal(Settings.screen_shake)
	flash_toggle.set_pressed_no_signal(Settings.flashing)
	game_speed_slider.set_value_no_signal(Settings.game_speed)
	_update_game_speed_label(Settings.game_speed)
	_update_ui_scale_display()
	
	
func _step_ui_scale(direction: int) -> void:
	var index := clampi(_ui_scale_index() + direction, 0, UI_SCALE_STEPS.size() - 1)
	Settings.set_ui_scale(UI_SCALE_STEPS[index])
	_update_ui_scale_display()


func _ui_scale_index() -> int:
	# The step closest to the current setting (handles old saved values too).
	var best := 0
	for i in UI_SCALE_STEPS.size():
		if absf(UI_SCALE_STEPS[i] - Settings.ui_scale) < absf(UI_SCALE_STEPS[best] - Settings.ui_scale):
			best = i
	return best


func _update_ui_scale_display() -> void:
	ui_scale_value_label.text = "%d%%" % roundi(Settings.ui_scale * 100)
	var index := _ui_scale_index()
	ui_scale_down_button.disabled = index == 0
	ui_scale_up_button.disabled = index == UI_SCALE_STEPS.size() - 1
