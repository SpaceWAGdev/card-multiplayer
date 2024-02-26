extends Node

func connect_to_server(url: String = "") -> void: 
	if url == "":
		%URLField.select_all()
		url = %URLField.get_selected_text()
		%URLField.deselect()
	if url == "":
		return
	GameState.WS_SERVER_URL = url
	get_tree().change_scene_to_file("res://game.tscn")
