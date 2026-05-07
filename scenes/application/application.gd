extends Node
## Example application implementation.
## 
## The application scene should be responsible for high-level functions like
## switching between modes (main menu, credits, game, etc). It should not store
## game state.

# Avoid preload where possible for scenes you are switching to, it forces
# loading to happen immediately rather than during a transition.
const _MENU_SCENE: String = "uid://c82jdhh45n2n8"
const _LEVEL_1_PATH: String = "uid://dqjbk0gkloecc"

@onready var _node_swapper: NodeSwapper = %NodeSwapper

# Switch to the initial mode (typically a preloader/splash screen).
func _ready() -> void:
	_swap_to_menu()


## Switches to the main menu.
func _swap_to_menu() -> void:
	if _node_swapper.is_transitioning():
		await _node_swapper.transitioned
	
	var initialize_menu: Callable = func(menu: Menu) -> void:
		menu.process_mode = Node.PROCESS_MODE_ALWAYS
		
		# Connect any signals we may want to monitor.
		# 
		# If a signal can be fired during scene swapping, connect to it deferred
		# so we don't try to swap scenes while already swapping.
		menu.play_pressed.connect(_switch_to_game.bind(_LEVEL_1_PATH), CONNECT_DEFERRED | CONNECT_ONE_SHOT)
	
	
	_node_swapper.transition_to_scene(_MENU_SCENE, initialize_menu)


## Switches to the game.
## 
## The [param level_path] specifies which level to load.
func _switch_to_game(level_path: String) -> void:
	if _node_swapper.is_transitioning():
		await _node_swapper.transitioned
	
	var make_game: Callable = func() -> Node:
		var game: Game = Game.new()
		game.process_mode = Node.PROCESS_MODE_PAUSABLE
		
		# Connect any signals we may want to monitor.
		# 
		# If a signal can be fired during scene swapping, connect to it deferred
		# so we don't try to swap scenes while already swapping.
		game.game_over.connect(_swap_to_menu, CONNECT_DEFERRED | CONNECT_ONE_SHOT)
		
		return game
	
	
	var start_game: Callable = func(game: Game) -> void:
		# start is a coroutine which loads the level so wait for the game to
		# start before letting the transition end
		await game.start(level_path)
	
	
	_node_swapper.transition_to(make_game, start_game)
