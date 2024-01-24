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
	if event.is_pressed():
		if self.get_parent().name in ["REMOTE_PLAYAREA"] and GameState.GAME_MODE == GameState.MODE_SELECT:
			GameState.SELECT_CALLBACK.call(self)
		if data["class"] == "Leader":
			return
		if event.alt_pressed and self.get_parent().name == "LOCAL_HAND":
			game_manager.move_card(self, "LOCAL_GRAVEYARD") 
		if self.get_parent().name == "LOCAL_PLAYAREA" and GameState.GAME_STATE == GameState.STATE_LOCALTURN:
			GameState.get_card_selection(attack)
		elif self.get_parent().name == "LOCAL_DECK":
			play(event)	
		print("Click on " + self.data["name"])
	else:
		pass

func attack(card: CardBase):
	print('Attacking %s from %s'.format(card.name, name))
	card.data["health"] = card.data["health"] - data["damage"]
	
func play(_event: InputEvent):
	get_tree().root.get_node("PanelContainer").move_card(self, "LOCAL_PLAYAREA")
