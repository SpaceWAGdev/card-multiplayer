extends Node

signal on_enter_selectmode()
signal on_exit_selectmode()

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

var SETUP_MESSAGE = ""

var MATCH_ID = null

@export var DECK_PATH = load("res://Decks/deck1.tres")

var DEBUG_MODE = false

var IS_BEGINNER = false

var GAME_STATE = STATE_STARTING
var GAME_MODE = MODE_DISABLED

var PLAYER_ID = Helpers.generate_uuid()

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

var _default_cursor = preload("res://default_cursor.png")
var _selection_cursor = preload("res://select_cursor.png")

func get_card_selection(callback: Callable, mask = SELECT_MASK_ENEMIES):
	SELECT_MASK = mask
	GAME_MODE = MODE_SELECT
	print("SELECT MODE STARTED")
	SELECT_CALLBACK = callback
	on_enter_selectmode.emit()
	Input.set_custom_mouse_cursor(_selection_cursor)
	
func cancel_card_selection():
	SELECT_MASK = []
	print("SELECT MODE CANCELLED")
	GAME_MODE = MODE_PLAY
	on_exit_selectmode.emit()
	Input.set_custom_mouse_cursor(_default_cursor)
