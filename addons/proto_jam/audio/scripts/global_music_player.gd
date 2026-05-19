@tool
class_name GlobalMusicPlayer
extends Node
## Plays a music loop automatically on [method _ready] using the [AudioManager].
## 
## This is preferable for background music as it will automatically fade to a
## new song during scene transitions while a standard [AudioPlayer] will stop
## abruptly when it gets freed.

## The path to the music to play.
## 
## Changing this path will cause the music to automatically transition.
@export_file("*.ogg", "*.wav", "*.mp3") var music_path: String = "":
	set(value):
		music_path = value
		
		if not Engine.is_editor_hint():
			if not is_node_ready():
				await ready
			
			_play_loop()
		else:
			update_configuration_warnings()


var _audio_manager: Memoizer = Memoizer.new(_get_audio_manager)

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	
	if music_path.is_empty():
		warnings.push_back("A music_path is required for GlobalMusicPlayer to work. Assign a path.")
	
	return warnings


func _play_loop() -> void:
	if not music_path.is_empty():
		var audio_manager: Node = await _audio_manager.get_value()
		if is_instance_valid(audio_manager):
			audio_manager.call("play_music_loop", music_path)
		else:
			push_error("Failed to get play music loop; AudioManager autoload is not present; did you forget to enable the ProtoJam plugin?")
	else:
		push_error("Music player \"%s\" failed to play; no music_path is empty." % get_path())


## Fetches the audio manager autoload without referencing its type.
## 
## Users should not call this. Use [AudioManager] instead.
func _get_audio_manager() -> Node:
	if has_node("/root/AudioManager"):
		return get_node("/root/AudioManager")
	
	return null
