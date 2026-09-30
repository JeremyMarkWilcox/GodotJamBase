class_name BaseMenu
extends Control
## Shared behavior for every menu: showing, hiding and focus.

@export var first_focus: Control
var last_focus: Control
@export var pauses_game := false
@export var can_go_back := true
## Buttons in navigation order. Focus stays inside this list and wraps around.
@export var focus_chain: Array[Control] = []
## How many columns the focus chain forms. 1 = a simple list (up/down only).
@export var focus_columns := 1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	_link_focus_chain()


func open() -> void:
	show()
	restore_focus()
	
func restore_focus() -> void:
	# Return to the last focused control (e.g. back from Settings lands on the
	# Settings button), or first_focus if there isn't one.
	if last_focus and is_instance_valid(last_focus) and last_focus.is_visible_in_tree():
		last_focus.grab_focus()
	elif first_focus:
		first_focus.grab_focus()


func close() -> void:
	hide()


func _link_focus_chain() -> void:
	# Ignore empty slots (e.g. a node was deleted but its chain entry wasn't).
	var chain: Array[Control] = []
	for control in focus_chain:
		if control:
			chain.append(control)
	var count := chain.size()
	var cols := maxi(focus_columns, 1)
	for i in count:
		var current := chain[i]
		var column := i % cols
		var up := chain[posmod(i - cols, count)]
		var down := chain[posmod(i + cols, count)]
		var left := chain[i - 1] if column > 0 else chain[mini(i + cols - 1, count - 1)]
		var right := chain[i + 1] if column < cols - 1 and i + 1 < count else chain[i - column]
		current.focus_neighbor_top = current.get_path_to(up)
		current.focus_neighbor_bottom = current.get_path_to(down)
		current.focus_neighbor_left = current.get_path_to(left)
		current.focus_neighbor_right = current.get_path_to(right)
		current.focus_previous = current.get_path_to(chain[posmod(i - 1, count)])
		current.focus_next = current.get_path_to(chain[posmod(i + 1, count)])
