class_name CardBase
extends TextureRect
@export var	data: Dictionary

func setup(_data: Dictionary):
	data = _data

func battlecry():
	print(data["name"], "has no battlecry")
	
func on_click(event: InputEvent):
	if event.is_pressed():
		print("Click on " + self.data["name"])
		get_tree().root.get_node("PanelContainer").move_card(self, get_tree().root.get_node("PanelContainer/VBoxContainer/LocalPlayArea"))
	else:
		pass