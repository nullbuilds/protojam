class_name Menu
extends CanvasLayer
## Example main menu implementation.
## 
## The main menu should solely be responsible for the state of the menu itself
## and otherwise just signal any requested mode changes.

## Emitted when play is pressed.
signal play_pressed()

@onready var _play_button: Button = %PlayButton

func _ready() -> void:
	_play_button.pressed.connect(play_pressed.emit)
	
	# Focus the first control in the menu so we don't have to manually assign it
	NodeUtils.focus_first_available(self)
