class_name RebindButton
extends Button
## Press it, then press a key or controller button to rebind one action for one device.

@export var action: StringName
@export_enum("Keyboard/Mouse", "Controller") var device: int = 0

var _listening := false

const LISTEN_TIMEOUT := 5.0

var _listen_id := 0


func _ready() -> void:
	pressed.connect(_start_listening)
	InputManager.bindings_changed.connect(_refresh)
	_refresh()


func _input(event: InputEvent) -> void:
	if not _listening or not event.is_pressed() or event.is_echo():
		return
	# Left-click or controller Back cancels without changing anything.
	var is_cancel := (event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT) \
			or (event is InputEventJoypadButton and (event as InputEventJoypadButton).button_index == JOY_BUTTON_BACK)
	if is_cancel:
		_stop_listening()
	elif _matches_device(event):
		_stop_listening()
		InputManager.rebind(action, device, _clean(event))
	else:
		return  # wrong device: keep listening
	get_viewport().set_input_as_handled()


func _start_listening() -> void:
	_listening = true
	_listen_id += 1
	var my_id := _listen_id
	text = "Press a key..." if device == 0 else "Press a button..."
	# Give up after a few seconds so the button never gets stuck listening.
	await get_tree().create_timer(LISTEN_TIMEOUT, true, false, true).timeout
	if _listening and my_id == _listen_id:
		_stop_listening()


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
