class_name RebindButton
extends Button
## Press it, then press a key or controller button to rebind one action for one device.

@export var action: StringName
@export_enum("Keyboard/Mouse", "Controller") var device: int = 0

var _listening := false


func _ready() -> void:
	pressed.connect(_start_listening)
	InputManager.bindings_changed.connect(_refresh)
	_refresh()


func _input(event: InputEvent) -> void:
	if not _listening or not event.is_pressed() or event.is_echo():
		return
	# Escape (or Back on a controller) cancels without changing anything.
	var is_cancel := (event is InputEventKey and (event as InputEventKey).physical_keycode == KEY_ESCAPE) \
			or (event is InputEventJoypadButton and (event as InputEventJoypadButton).button_index == JOY_BUTTON_BACK)
	if is_cancel:
		_stop_listening()
	elif _matches_device(event):
		_stop_listening()
		InputManager.rebind(action, device, _clean(event))
	else:
		return  # wrong device: keep listening
	get_viewport().set_input_as_handled()  # nothing else sees this press


func _start_listening() -> void:
	_listening = true
	text = "Press a key..." if device == 0 else "Press a button..."


func _stop_listening() -> void:
	_listening = false
	_refresh()


func _refresh() -> void:
	text = InputManager.event_label(InputManager.get_event(action, device))


func _matches_device(event: InputEvent) -> bool:
	if device == 0:
		return event is InputEventKey or event is InputEventMouseButton
	return event is InputEventJoypadButton


func _clean(event: InputEvent) -> InputEvent:
	# Keys use the physical position so remaps work on any keyboard layout.
	if event is InputEventKey:
		var key := InputEventKey.new()
		key.physical_keycode = (event as InputEventKey).physical_keycode
		return key
	# Controller and mouse events work on any connected device.
	var copy := event.duplicate() as InputEvent
	copy.device = -1
	return copy
