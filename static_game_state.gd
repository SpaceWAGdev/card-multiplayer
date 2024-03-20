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

var SELECT_MASK_ALL = ["LOCAL_HAND", "LOCAL_PLAYAREA", "REMOTE_HAND", "REMOTE_PLAYAREA"]
var SELECT_MASK_ENEMIES = ["REMOTE_PLAYAREA"]
var SELECT_MASK_FRIENDLY = ["LOCAL_PLAYAREA"]

var SELECT_MASK = []

func get_card_selection(callback: Callable, mask = SELECT_MASK_ENEMIES):
	SELECT_MASK = mask
	GAME_MODE = MODE_SELECT
	print("SELECT MODE STARTED")
	SELECT_CALLBACK = callback
	Input.set_default_cursor_shape(Input.CURSOR_CROSS)
	
func cancel_card_selection():
	SELECT_MASK = []
	print("SELECT MODE CANCELLED")
	GAME_MODE = MODE_PLAY
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)