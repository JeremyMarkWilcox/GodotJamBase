extends Node
## Fades between scenes and handles restart, return to title and quit.

signal transition_started
signal transition_finished

const FADE_TIME := 0.3
const TITLE_SCENE_PATH := "res://core/ui/title.tscn"

var is_transitioning := false

var _fade_rect: ColorRect


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # keeps working while the game is paused
	_build_fade_overlay()


func change_scene(path: String) -> void:
	if is_transitioning:
		return
	if not ResourceLoader.exists(path):
		push_error("SceneManager: scene not found: %s" % path)
		return

	is_transitioning = true
	transition_started.emit()
	await _fade_to(1.0)
	Audio.stop_all_sfx()

	get_tree().paused = false
	var error := get_tree().change_scene_to_file(path)
	if error != OK:
		push_error("SceneManager: failed to load %s" % path)
	await get_tree().process_frame  # the swap happens at the end of this frame

	await _fade_to(0.0)
	is_transitioning = false
	transition_finished.emit()


func restart() -> void:
	var current := get_tree().current_scene
	if current:
		change_scene(current.scene_file_path)


func return_to_title() -> void:
	change_scene(TITLE_SCENE_PATH)


func quit() -> void:
	if OS.has_feature("web"):
		return  # browsers can't close the tab
	get_tree().quit()


func _build_fade_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100  # draws above everything
	add_child(layer)

	_fade_rect = ColorRect.new()
	_fade_rect.color = Color(0, 0, 0, 0)
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_fade_rect)


func _fade_to(alpha: float) -> void:
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP  # block clicks mid-fade
	var tween := create_tween()
	tween.tween_property(_fade_rect, "color:a", alpha, FADE_TIME)
	await tween.finished
	if alpha == 0.0:
		_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			
