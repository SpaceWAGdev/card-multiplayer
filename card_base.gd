class_name CardBase
extends TextureRect
@export var	data: Dictionary
var game_manager: Node

func setup(_data: Dictionary, _game_manager):
	data = _data
	game_manager = _game_manager
	var health = get_child(0) as Label
	health.text = str(data["health"])

func battlecry():
	print(data["name"], " has no battlecry")
	
func on_click(event: InputEvent):
	if self.get_parent().name in ["LOCAL_GRAVEYARD"]:
		return
	elif event.is_pressed():
		if self.get_parent().name in ["REMOTE_PLAYAREA"] and GameState.GAME_MODE == GameState.MODE_SELECT:
			GameState.SELECT_CALLBACK.call(self)
			GameState.cancel_card_selection()
		elif data["class"] == "Leader":
			return
		elif event.alt_pressed and self.get_parent().name == "LOCAL_HAND":
			game_manager.move_card(self, "LOCAL_GRAVEYARD") 
		elif self.get_parent().name == "LOCAL_PLAYAREA" and GameState.GAME_STATE == GameState.STATE_LOCALTURN:
			GameState.get_card_selection(attack)
		elif self.get_parent().name == "LOCAL_HAND":
			play(event)
		print("Click on " + self.data["name"])
	else:
		pass

func attack(card: CardBase):
	print('Attacking ' + card.data["name"] + ' from ' +  data["name"])
	card.data["health"] = card.data["health"] - data["damage"]
	card.update_stats()
	if card.data["health"] <= 0:
		game_manager.move_card(card, "LOCAL_GRAVEYARD")
	
func play(_event: InputEvent):
	get_tree().root.get_node("PanelContainer").move_card(self, "LOCAL_PLAYAREA")

func update_stats():
	var health_label : Label = get_children()[0]
	health_label.text = str(data["health"])
