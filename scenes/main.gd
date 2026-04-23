class_name Main
extends Node
## Example main implementation.

const _MASTER_VOLUME_SETTING: AudioBusVolumeRangeSetting = preload("uid://bcxbqwt2pbfrx")

## Perform initial setup like loading settings.
func _ready() -> void:
	var settings_error: Error = SettingsManager.load_settings()
	if Error.OK != settings_error:
		# Failing to load settings isn't a critical error as the defaults will
		# still exist but it should be logged for debugging.
		push_error("Failed to load settings; error code %d" % settings_error)
	
	var loader_error: Error = BackgroundResourceLoader.start()
	# There's no reasonable way to recover from this, fail fast!
	if Error.OK != loader_error:
		push_error("Failed to start background resource loader; error code %d" % loader_error)
		NodeUtils.quit_gracefully(-1)
	
	_MASTER_VOLUME_SETTING.apply()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_CLOSE_REQUEST:
			BackgroundResourceLoader.stop()
			SettingsManager.save_settings()
