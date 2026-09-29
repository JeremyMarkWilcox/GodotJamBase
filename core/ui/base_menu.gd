class_name BaseMenu
extends Control
## Shared behavior for every menu: showing, hiding and focus.

@export var first_focus: Control
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
	if first_focus:
		first_focus.grab_focus()


func close() -> void:
	hide()


func _link_focus_chain() -> void:
	var count := focus_chain.size()
	var cols := maxi(focus_columns, 1)
	for i in count:
		var current := focus_chain[i]
		var column := i % cols
		var up := focus_chain[posmod(i - cols, count)]
		var down := focus_chain[posmod(i + cols, count)]
		var left := focus_chain[i - 1] if column > 0 else focus_chain[mini(i + cols - 1, count - 1)]
		var right := focus_chain[i + 1] if column < cols - 1 and i + 1 < count else focus_chain[i - column]
		current.focus_neighbor_top = current.get_path_to(up)
		current.focus_neighbor_bottom = current.get_path_to(down)
		current.focus_neighbor_left = current.get_path_to(left)
		current.focus_neighbor_right = current.get_path_to(right)
		current.focus_previous = current.get_path_to(focus_chain[posmod(i - 1, count)])
		current.focus_next = current.get_path_to(focus_chain[posmod(i + 1, count)])
