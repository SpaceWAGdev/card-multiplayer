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

var GAME_STATE = STATE_LOCALTURN
var GAME_MODE = MODE_DISABLED

var SELECT_CALLBACK = null

func set_game_state(state):
	GAME_STATE = state

func get_card_selection(callback: Callable):
	GAME_MODE = MODE_SELECT
	print("SELECT MODE STARTED")
	SELECT_CALLBACK = callback
	
func cancel_card_selection():
	print("SELECT MODE CANCELLED")
	GAME_MODE = MODE_PLAY

func end_turn():
	GAME_STATE = STATE_REMOTETURN

func begin_turn():
	GAME_STATE = STATE_LOCALTURN
