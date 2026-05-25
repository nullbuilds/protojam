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
	_load_save_data()
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


## Attempts to load the game's save data.
func _load_save_data() -> void:
	var load_error: Error = SaveDataManager.load_global_data()
	if not load_error in [Error.OK, Error.ERR_FILE_NOT_FOUND]:
		push_error("Failed to load global save data; error code %d" % load_error)
	
	var slot: int = SaveDataManager.get_active_slot()
	load_error = SaveDataManager.load_slot_data(slot)
	if not load_error in [Error.OK, Error.ERR_FILE_NOT_FOUND]:
		push_error("Failed to load slot %d save data; error code %d" % [slot, load_error])


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
