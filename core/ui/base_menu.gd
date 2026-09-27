class_name BaseMenu
extends Control
## Shared behavior for every menu: showing, hiding and focus.

@export var first_focus: Control
@export var pauses_game := false
@export var can_go_back := true
## Buttons in navigation order. Focus stays inside this list and wraps around.
@export var focus_chain: Array[Control] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	_link_focus_chain()


func open() -> void:
	show()
	if first_focus:
		first_focus.grab_focus()


func close() -> void:
	hide()


func _link_focus_chain() -> void:
	var count := focus_chain.size()
	for i in count:
		var current := focus_chain[i]
		var previous := focus_chain[(i - 1 + count) % count]
		var next := focus_chain[(i + 1) % count]
		current.focus_neighbor_top = current.get_path_to(previous)
		current.focus_neighbor_bottom = current.get_path_to(next)
		current.focus_neighbor_left = current.get_path_to(current)  # left/right stay put
		current.focus_neighbor_right = current.get_path_to(current)
		current.focus_previous = current.get_path_to(previous)  # Tab / Shift+Tab
		current.focus_next = current.get_path_to(next)
