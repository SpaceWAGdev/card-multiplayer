extends Node	
const uuid_util = preload("res://addons/uuid/uuid.gd")

func load_text_file(path: String):
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		printerr("Error opening card list")
	var text = file.get_as_text()
	file.close()
	return text

func list_directory(path: String):
	var dir = DirAccess.open(path)
	return dir.get_files() as Array

static func generate_uuid():
	return uuid_util.v4()
