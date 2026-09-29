extends Control
## First screen. On web, waits for a click or key so the browser allows audio.

@export_file("*.tscn") var next_scene: String
@export var prompt_label: Label
## Show the prompt on desktop too, for testing in the editor.
@export var always_show := false

var _started := false


func _ready() -> void:
	if not OS.has_feature("web") and not always_show:
		_start.call_deferred()  # desktop: skip straight to the title
		return
	_pulse_prompt()


func _input(event: InputEvent) -> void:
	if _started or not event.is_pressed():
		return
	if event is InputEventMouseButton or event is InputEventKey \
			or event is InputEventJoypadButton or event is InputEventScreenTouch:
		get_viewport().set_input_as_handled()
		_start()


func _start() -> void:
	_started = true
	SceneManager.change_scene(next_scene)


func _pulse_prompt() -> void:
	var tween := create_tween().set_loops()
	tween.tween_property(prompt_label, "modulate:a", 0.3, 0.8)
	tween.tween_property(prompt_label, "modulate:a", 1.0, 0.8)
