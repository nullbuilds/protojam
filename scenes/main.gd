extends Node
## Example main implementation.
## 
## Your main scene should handle bootstrapping the ProtoJam services you need
## and cleaning them up when the game is exiting. Everything else should be
## handled elsewhere.

const _MASTER_VOLUME_SETTING: AudioBusVolumeRangeSetting = preload("uid://bcxbqwt2pbfrx")
const _MUSIC_VOLUME_SETTING: AudioBusVolumeRangeSetting = preload("uid://q75uxrblo753")
const _APPLICATION: PackedScene = preload("uid://df5fs5t16rhiw")

## Perform initial setup like loading settings.
func _ready() -> void:
	_start_background_loader()
	_load_settings()
	_setup_audio_manager()
	_start_application()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_CLOSE_REQUEST:
			# The game is closing - shutdown any services that require it, save
			# settings, etc. This should usually be done in reverse order of how
			# they were started.
			SettingsManager.save_settings()
			BackgroundResourceLoader.stop()


## Attempts to load the game's settings.
func _load_settings() -> void:
	var settings_error: Error = SettingsManager.load_settings()
	if Error.OK != settings_error:
		# Failing to load settings isn't a critical error as the defaults will
		# still exist but it should be logged for debugging.
		push_error("Failed to load settings; error code %d" % settings_error)


## Starts the background loading service or exits if it cannot start.
func _start_background_loader() -> void:
	var loader_error: Error = BackgroundResourceLoader.start()
	# Almost everything needs the resource loader and there's no reasonable way
	# to continue if it can't start - fail fast!
	if Error.OK != loader_error:
		push_error("Failed to start background resource loader; error code %d" % loader_error)
		NodeUtils.quit_gracefully(-1)


## Configures the audio manager.
func _setup_audio_manager() -> void:
	# Configure the audio manager to monitor and apply these settings
	AudioManager.sync_bus_volume(_MASTER_VOLUME_SETTING)
	AudioManager.sync_bus_volume(_MUSIC_VOLUME_SETTING)


## Starts the application.
func _start_application() -> void:
	add_child(_APPLICATION.instantiate())
