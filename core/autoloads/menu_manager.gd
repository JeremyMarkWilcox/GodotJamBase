extends Node
## Keeps a stack of open menus, handles Back, and pauses the game while a pausing menu is open.

signal menu_opened(menu: BaseMenu)
signal menu_closed(menu: BaseMenu)

const NAV_ACTIONS: Array[StringName] = [&"ui_up", &"ui_down", &"ui_left", &"ui_right", &"ui_focus_next", &"ui_focus_prev"]
const MOUSE_MOVE_THRESHOLD := 4.0

var _stack: Array[BaseMenu] = []

var _mouse_mode := false
var _remembered_focus: Control


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	SceneManager.transition_started.connect(close_all)
	get_viewport().gui_focus_changed.connect(_on_focus_changed)
	
	
func _on_focus_changed(control: Control) -> void:
	var menu := top_menu()
	if menu == null:
		return  # no menu open: focus can go anywhere
	if menu.is_ancestor_of(control):
		menu.last_focus = control  # remember where the player is
	else:
		menu.restore_focus.call_deferred()  # focus escaped: pull it back


func _unhandled_input(event: InputEvent) -> void:
	var menu := top_menu()
	if menu == null:
		return  # no menu open: Esc/B does nothing here
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		if menu.can_go_back:
			Audio.play_back()
			close_menu()
		get_viewport().set_input_as_handled()


func open_menu(menu: BaseMenu) -> void:
	if menu in _stack:
		return
	if not _stack.is_empty():
		top_menu().close()  # hide the one underneath
	_stack.push_back(menu)
	menu.open()
	_update_pause()
	menu_opened.emit(menu)


func close_menu() -> void:
	if _stack.is_empty():
		return
	var menu: BaseMenu = _stack.pop_back()
	menu.close()
	menu.last_focus = null  # a fresh open starts at first_focus
	if not _stack.is_empty():
		top_menu().open()  # show the previous one and restore its focus
	_update_pause()
	menu_closed.emit(menu)


func close_all() -> void:
	for menu in _stack:
		menu.close()
		menu.last_focus = null
	_stack.clear()
	_update_pause()


func top_menu() -> BaseMenu:
	# Drop any menus that were freed without being closed (e.g. scene changes).
	while not _stack.is_empty() and not is_instance_valid(_stack.back()):
		_stack.pop_back()
	if _stack.is_empty():
		return null
	return _stack.back()


func is_menu_open() -> bool:
	return not _stack.is_empty()


func _update_pause() -> void:
	var should_pause := false
	for menu in _stack:
		if menu.pauses_game:
			should_pause = true
	get_tree().paused = should_pause


func _input(event: InputEvent) -> void:
	# Mouse used: hide the focus outline (only after a click is finished).
	var is_click_release := event is InputEventMouseButton and not event.is_pressed()
	var is_move := event is InputEventMouseMotion \
			and (event as InputEventMouseMotion).button_mask == 0 \
			and (event as InputEventMouseMotion).relative.length() > MOUSE_MOVE_THRESHOLD
	if is_click_release or is_move:
		_mouse_mode = true
		_release_focus.call_deferred()
		return
	# Keyboard/controller navigation: bring focus back where it was.
	if _mouse_mode:
		for action in NAV_ACTIONS:
			if event.is_action_pressed(action):
				_mouse_mode = false
				if get_viewport().gui_get_focus_owner() == null:
					_restore_any_focus()
					get_viewport().set_input_as_handled()  # first press just shows focus
				return


func _release_focus() -> void:
	var focused := get_viewport().gui_get_focus_owner()
	if focused:
		_remembered_focus = focused
		get_viewport().gui_release_focus()


func _restore_any_focus() -> void:
	var menu := top_menu()
	if menu:
		menu.restore_focus()
	elif is_instance_valid(_remembered_focus) and _remembered_focus.is_visible_in_tree():
		_remembered_focus.grab_focus()  # e.g. the title buttons, with no menu open
