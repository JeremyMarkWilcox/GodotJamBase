extends Node
## UI sounds for every button, a small SFX pool, and music with crossfade.

const SFX_VOICES := 8
const NAV_ACTIONS: Array[String] = ["ui_up", "ui_down", "ui_left", "ui_right", "ui_focus_next", "ui_focus_prev"]

@export_group("UI Sounds")
@export var hover_sound: AudioStream
@export var click_sound: AudioStream
@export var back_sound: AudioStream

@export_group("Music")
@export var default_crossfade := 1.0

var _ui_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _active_music: AudioStreamPlayer
var _music_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # UI sounds must work while paused
	_ui_player = _make_player("UI")
	for i in SFX_VOICES:
		_sfx_players.append(_make_player("SFX"))
	_music_a = _make_player("Music")
	_music_b = _make_player("Music")
	_active_music = _music_a
	get_tree().node_added.connect(_on_node_added)
	_hook_existing.call_deferred(get_tree().root)


# --- UI ---

func play_ui(stream: AudioStream) -> void:
	if stream == null:
		return  # empty slot = silent
	_ui_player.stream = stream
	_ui_player.play()


func play_back() -> void:
	play_ui(back_sound)


# --- SFX ---

func play_sfx(stream: AudioStream, pitch_variation := 0.0) -> void:
	if stream == null:
		return
	for player in _sfx_players:
		if not player.playing:
			player.stream = stream
			player.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
			player.play()
			return
	# every voice is busy: skip this sound rather than cut one off


# --- Music ---

func play_music(stream: AudioStream, fade_time := default_crossfade) -> void:
	if stream == null:
		stop_music(fade_time)
		return
	if _active_music.playing and _active_music.stream == stream:
		return  # already playing this track
	var old_player := _active_music
	var new_player := _music_b if old_player == _music_a else _music_a
	new_player.stream = stream
	_set_linear_volume(0.0, new_player)
	new_player.play()
	_active_music = new_player
	_crossfade(old_player, new_player, fade_time)


func stop_music(fade_time := default_crossfade) -> void:
	if not _active_music.playing:
		return
	_crossfade(_active_music, null, fade_time)


func _crossfade(from: AudioStreamPlayer, to: AudioStreamPlayer, fade_time: float) -> void:
	if _music_tween:
		_music_tween.kill()
	_music_tween = create_tween().set_parallel()
	if from and from.playing:
		_music_tween.tween_method(_set_linear_volume.bind(from), db_to_linear(from.volume_db), 0.0, fade_time)
	if to:
		_music_tween.tween_method(_set_linear_volume.bind(to), db_to_linear(to.volume_db), 1.0, fade_time)
	await _music_tween.finished
	if from and from != to:
		from.stop()


func _set_linear_volume(value: float, player: AudioStreamPlayer) -> void:
	player.volume_db = linear_to_db(maxf(value, 0.0001))


# --- Automatic button hookup ---

func _hook_existing(node: Node) -> void:
	_on_node_added(node)
	for child in node.get_children():
		_hook_existing(child)

func _on_node_added(node: Node) -> void:
	if not node is BaseButton or node.has_meta("_audio_hooked"):
		return
	node.set_meta("_audio_hooked", true)  # avoid double-connecting if a node is re-added
	var button := node as BaseButton
	button.mouse_entered.connect(_on_button_hovered.bind(button))
	button.focus_entered.connect(_on_button_focused)
	button.pressed.connect(_on_button_pressed)


func _on_button_hovered(button: BaseButton) -> void:
	if not button.disabled:
		play_ui(hover_sound)


func _on_button_focused() -> void:
	# Only when the player moved focus, not when a menu grabs focus on open.
	for action in NAV_ACTIONS:
		if Input.is_action_just_pressed(action):
			play_ui(hover_sound)
			return


func _on_button_pressed() -> void:
	play_ui(click_sound)


func _make_player(bus: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.bus = bus
	add_child(player)
	return player
