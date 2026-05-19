extends Node
## An auto-load for global audio management.
## 
## [b]Note:[/b] Music tracks will not be unloaded once played. This manager
## requires all tracks to be loops.

const _MUSIC_RESTART_FIX_TRANSITION_TIME: float = 1.0

var _music_stream: AudioStreamInteractive = AudioStreamInteractive.new()
var _music_player: AudioStreamPlayer = AudioStreamPlayer.new()
var _music_stream_indices: Dictionary[String, int] = {}
var _music_bus: String = "Music"
var _music_fade_beats: float = 1.0

func _ready() -> void:
	_music_player.stream = _music_stream
	_music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	_update_music_stream()
	add_child(_music_player, false, Node.INTERNAL_MODE_FRONT)


## Sets the name of the bus to play music on.
## 
## Users are advised to also call [method sync_bus_volume] for the bus.
func set_music_bus(bus_name: String) -> Error:
	if AudioServer.get_bus_index(bus_name) >= 0:
		_music_bus = bus_name
		_update_music_stream()
		return Error.OK
	
	return Error.ERR_DOES_NOT_EXIST


## Sets the number of beats for music transitions.
## 
## This must be greater than [code]0.0[/code].
func set_music_fade_beats(fade_beats: float) -> void:
	if fade_beats > 0.0:
		_music_fade_beats = fade_beats
		_update_music_stream()


## Automatically sync the bus volume to the given setting.
## 
## Any bus can be sync'd.
func sync_bus_volume(bus_setting: AudioBusVolumeRangeSetting) -> Error:
	if bus_setting.get_bus_index() < 0:
		push_error("Failed to synchronize bus \"%s\"; no such bus" % bus_setting.bus_name)
		return Error.ERR_DOES_NOT_EXIST
	
	var error: Error = bus_setting.apply(1.0)
	if Error.OK != error:
		return error
	
	bus_setting.value_changed.connect(_on_bus_volume_changed.unbind(1), \
			Object.CONNECT_APPEND_SOURCE_OBJECT)
	
	return Error.OK


## Transitions to and plays a music loop.
func play_music_loop(audio_stream_path: String) -> void:
	var track_index: int = -1
	var new_track_added: bool = false
	if _music_stream_indices.has(audio_stream_path):
		track_index = _music_stream_indices.get(audio_stream_path)
	else:
		track_index = await _load_music_loop(audio_stream_path)
		_music_stream_indices.set(audio_stream_path, track_index)
		# Hack to fix audio stream interactives not allowing new clips to be
		# added while playing https://github.com/godotengine/godot/issues/99384
		new_track_added = true
	
	if track_index >= 0:
		_play_music_track(track_index, new_track_added)
		print("Audio manager playing loop \"%s\"" % audio_stream_path)
	else:
		push_error("Unable to play music stream \"%s\"" % audio_stream_path)


## Loads the music track from the given path and returns its clip index.
## 
## Also verifies the track is configured to loop.
## [br][br]
## Users should not call this function.
func _load_music_loop(audio_stream_path: String) -> int:
	var resource_handle: AsyncResourceHandle = BackgroundResourceLoader.load_async(audio_stream_path, "AudioStream")
	var success: bool = await resource_handle.ready
	if success:
		var clip_index: int = _music_stream.clip_count
		_music_stream.clip_count += 1
		
		var track: AudioStream = resource_handle.get_resource()
		
		if not track.get(&"loop"):
			push_warning("Music stream \"%s\" is not configured to loop" % audio_stream_path)
		
		_music_stream.set_clip_stream(clip_index, track)
		_music_stream.set_clip_name(clip_index, audio_stream_path)
		return clip_index
	
	push_error("Failed to load music stream \"%s\"" % audio_stream_path)
	return -1


## Starts playing a loaded music track.
## 
## Users should not call this function.
func _play_music_track(track_index: int, restart_playback: bool) -> void:
	if not _music_player.playing or restart_playback:
		# This tween hides an audio discrepancy caused when restarting the
		# player. Restarting is necessary to add new tracks but also forces
		# playback to start at clip 0 regardless of what clip was previously
		# playing which can be jarring. This hides the transition out of clip 0
		# into the new clip by tweening the volume from 0.0.
		var tween: Tween = _music_player.create_tween()
		tween.tween_property(_music_player, "volume_linear", 1.0, \
				_MUSIC_RESTART_FIX_TRANSITION_TIME).from(0.0)
		_music_player.play()
	
	var playback: AudioStreamPlaybackInteractive = _get_music_stream_playback()
	if playback.get_current_clip_index() != track_index:
		playback.switch_to_clip(track_index)


## Gets the internal music stream playback.
## 
## Users should not call this function.
func _get_music_stream_playback() -> AudioStreamPlaybackInteractive:
	return _music_player.get_stream_playback()


## Updates the underlying music stream parameters.
## 
## Users should not call this function.
func _update_music_stream() -> void:
	var clip_id: int = AudioStreamInteractive.CLIP_ANY
	
	if _music_stream.has_transition(clip_id, clip_id):
		_music_stream.erase_transition(clip_id, clip_id)
	
	_music_stream.add_transition(clip_id, clip_id, \
				AudioStreamInteractive.TRANSITION_FROM_TIME_NEXT_BEAT, \
				AudioStreamInteractive.TRANSITION_TO_TIME_START, \
				AudioStreamInteractive.FADE_AUTOMATIC, \
				_music_fade_beats)
	
	# TODO check if bus exists!
	if AudioServer.get_bus_index(_music_bus) >= 0:
		_music_player.bus = _music_bus
	else:
		push_warning("Unable to play music on bus \"%s\"; no such bus; using default" % _music_bus)


func _on_bus_volume_changed(setting: AudioBusVolumeRangeSetting) -> void:
	setting.apply()
