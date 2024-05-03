extends Node

func connect_to_server(url: String = "") -> void: 
	if url == "":
		%URLField.select_all()
		url = %URLField.get_selected_text()
		%URLField.deselect()
	if url == "":
		return
	GameState.WS_SERVER_URL = url
	# switch_scene()

func join_match_with_key():
	connect_to_server("")
	%MatchID.select_all()
	var id = %MatchID.get_selected_text()
	%MatchID.deselect()

	GameState.SETUP_MESSAGE = JSON.stringify({
		"type" : "Control",
		"control-operation" : "JOIN_MATCH",
		"control-arguments" : {
			"id": id },
		"user": GameState.PLAYER_ID,
		"match": GameState.MATCH_ID
	})

func create_match_with_key():
	connect_to_server("")

func request_matchmaking():
	connect_to_server("")

func switch_scene():
	get_tree().change_scene_to_file("res://game.tscn")