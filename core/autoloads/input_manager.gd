extends Node
## Tracks keyboard/mouse vs gamepad, and saves/loads remapped controls.

signal device_changed(device: Device)
signal bindings_changed

enum Device { KEYBOARD_MOUSE, GAMEPAD }

const CONFIG_PATH := "user://controls.cfg"
const STICK_DEADZONE := 0.5
const MOUSE_MOVE_THRESHOLD := 4.0
const JOY_NAMES: Dictionary[int, String] = {
	JOY_BUTTON_A: "A", JOY_BUTTON_B: "B", JOY_BUTTON_X: "X", JOY_BUTTON_Y: "Y",
	JOY_BUTTON_BACK: "Back", JOY_BUTTON_START: "Start",
	JOY_BUTTON_LEFT_SHOULDER: "LB", JOY_BUTTON_RIGHT_SHOULDER: "RB",
	JOY_BUTTON_LEFT_STICK: "L3", JOY_BUTTON_RIGHT_STICK: "R3",
	JOY_BUTTON_DPAD_UP: "D-Pad Up", JOY_BUTTON_DPAD_DOWN: "D-Pad Down",
	JOY_BUTTON_DPAD_LEFT: "D-Pad Left", JOY_BUTTON_DPAD_RIGHT: "D-Pad Right",
}

var current_device := Device.KEYBOARD_MOUSE

var _defaults: Dictionary[StringName, Array] = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_store_defaults()
	load_bindings()


func _input(event: InputEvent) -> void:
	var device := current_device
	if event is InputEventKey or event is InputEventMouseButton:
		device = Device.KEYBOARD_MOUSE
	elif event is InputEventMouseMotion and (event as InputEventMouseMotion).relative.length() > MOUSE_MOVE_THRESHOLD:
		device = Device.KEYBOARD_MOUSE
	elif event is InputEventJoypadButton:
		device = Device.GAMEPAD
	elif event is InputEventJoypadMotion and absf((event as InputEventJoypadMotion).axis_value) > STICK_DEADZONE:
		device = Device.GAMEPAD
	if device != current_device:
		current_device = device
		device_changed.emit(device)


# --- Bindings ---

func get_event(action: StringName, device: int) -> InputEvent:
	for event in InputMap.action_get_events(action):
		if _device_of(event) == device:
			return event
	return null


func rebind(action: StringName, device: int, new_event: InputEvent) -> void:
	var old_event := get_event(action, device)
	# If another action already uses this input, swap: it gets our old input.
	for other in _defaults:
		if other == action:
			continue
		for existing in InputMap.action_get_events(other):
			if existing.is_match(new_event):
				InputMap.action_erase_event(other, existing)
				if old_event:
					InputMap.action_add_event(other, old_event)
	if old_event:
		InputMap.action_erase_event(action, old_event)
	InputMap.action_add_event(action, new_event)
	save_bindings()
	bindings_changed.emit()


func reset_to_defaults() -> void:
	for action in _defaults:
		InputMap.action_erase_events(action)
		for event: InputEvent in _defaults[action]:
			InputMap.action_add_event(action, event)
	save_bindings()
	bindings_changed.emit()


func event_label(event: InputEvent) -> String:
	if event == null:
		return "—"
	if event is InputEventKey:
		var key := event as InputEventKey
		var code := key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode
		return OS.get_keycode_string(code)  # "P", "Escape", "Space"
	if event is InputEventJoypadButton:
		var index := (event as InputEventJoypadButton).button_index
		return JOY_NAMES.get(index, "Button %d" % index)
	return event.as_text()  # mouse buttons: "Left Mouse Button", etc.


# --- Save / load ---

func save_bindings() -> void:
	var config := ConfigFile.new()
	for action in _defaults:
		config.set_value("bindings", action, InputMap.action_get_events(action))
	if config.save(CONFIG_PATH) != OK:
		push_warning("InputManager: could not save %s" % CONFIG_PATH)


func load_bindings() -> void:
	var config := ConfigFile.new()
	if config.load(CONFIG_PATH) != OK:
		return  # first run: keep the defaults
	for action in _defaults:
		if not config.has_section_key("bindings", action):
			continue
		InputMap.action_erase_events(action)
		for event: InputEvent in config.get_value("bindings", action):
			InputMap.action_add_event(action, event)


func _store_defaults() -> void:
	# Every project action except Godot's built-in ui_* actions is remappable.
	for action in InputMap.get_actions():
		if String(action).begins_with("ui_"):
			continue
		_defaults[action] = InputMap.action_get_events(action).duplicate()


func _device_of(event: InputEvent) -> int:
	if event is InputEventKey or event is InputEventMouseButton:
		return Device.KEYBOARD_MOUSE
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		return Device.GAMEPAD
	return -1
