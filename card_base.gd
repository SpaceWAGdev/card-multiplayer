class_name CardBase
extends TextureRect
@export var	data: Dictionary
var game_manager: Node

func setup(_data: Dictionary, _game_manager):
	data = _data
	game_manager = _game_manager

func battlecry():
	print(data["name"], " has no battlecry")
	
func on_click(event: InputEvent):
	if self.get_parent().name == "LOCAL_GRAVEYARD":
		return
	if event.is_pressed():
		if event.alt_pressed and self.get_parent().name == "LOCAL_HAND" and not data["class"] == "Leader":
			game_manager.move_card(self, "LOCAL_GRAVEYARD") 
		else:
			handle_click(event)	
		print("Click on " + self.data["name"])
	else:
		pass

func handle_click(event: InputEvent):
	if data["class"] == "Leader":
		return
	get_tree().root.get_node("PanelContainer").move_card(self, "LOCAL_PLAYAREA")
