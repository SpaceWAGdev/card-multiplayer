extends Node

static func load_text_file(path):
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		printerr("Error opening card list")
	var text = file.get_as_text()
	file.close()
	return text
