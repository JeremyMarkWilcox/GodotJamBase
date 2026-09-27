extends BaseMenu

@export var master_slider: HSlider
@export var music_slider: HSlider
@export var sfx_slider: HSlider
@export var ui_slider: HSlider
@export var fullscreen_toggle: CheckButton
@export var ui_scale_slider: HSlider
@export var shake_toggle: CheckButton
@export var flash_toggle: CheckButton
@export var back_button: Button


func _ready() -> void:
	super()
	master_slider.value_changed.connect(func(value: float) -> void: Settings.set_volume("Master", value))
	music_slider.value_changed.connect(func(value: float) -> void: Settings.set_volume("Music", value))
	sfx_slider.value_changed.connect(func(value: float) -> void: Settings.set_volume("SFX", value))
	ui_slider.value_changed.connect(func(value: float) -> void: Settings.set_volume("UI", value))
	fullscreen_toggle.toggled.connect(Settings.set_fullscreen)
	ui_scale_slider.value_changed.connect(Settings.set_ui_scale)
	shake_toggle.toggled.connect(Settings.set_screen_shake)
	flash_toggle.toggled.connect(Settings.set_flashing)
	back_button.pressed.connect(MenuManager.close_menu)


func open() -> void:
	_sync_from_settings()
	super()


func close() -> void:
	Settings.save_settings()
	super()


func _sync_from_settings() -> void:
	master_slider.set_value_no_signal(Settings.volumes["Master"])
	music_slider.set_value_no_signal(Settings.volumes["Music"])
	sfx_slider.set_value_no_signal(Settings.volumes["SFX"])
	ui_slider.set_value_no_signal(Settings.volumes["UI"])
	fullscreen_toggle.set_pressed_no_signal(Settings.fullscreen)
	ui_scale_slider.set_value_no_signal(Settings.ui_scale)
	shake_toggle.set_pressed_no_signal(Settings.screen_shake)
	flash_toggle.set_pressed_no_signal(Settings.flashing)
