extends Node

enum {
	STATE_STARTING,
	STATE_LOCALTURN,
	STATE_REMOTETURN,
	STATE_OVER,
	STATE_PAUSED,
	STATE_ERR
}

enum {
	MODE_DISABLED,
	MODE_PLAY,
	MODE_SELECT
}

var WS_SERVER_URL = "ws://localhost:8080"

var IS_BEGINNER = false

var GAME_STATE = STATE_STARTING
var GAME_MODE = MODE_DISABLED

func set_game_state(state):
	GAME_STATE = state

func end_turn():
	GAME_STATE = STATE_REMOTETURN

func begin_turn():
	GAME_STATE = STATE_LOCALTURN

var SELECT_CALLBACK = null

func get_card_selection(callback: Callable):
	GAME_MODE = MODE_SELECT
	print("SELECT MODE STARTED")
	SELECT_CALLBACK = callback
	Input.set_default_cursor_shape(Input.CURSOR_CROSS)
	
func cancel_card_selection():
	print("SELECT MODE CANCELLED")
	GAME_MODE = MODE_PLAY
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)