extends Node	
const uuid_util = preload("res://addons/uuid/uuid.gd")

func load_text_file(path):
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		printerr("Error opening card list")
	var text = file.get_as_text()
	file.close()
	return text

static func generate_uuid():
	return uuid_util.v4()
