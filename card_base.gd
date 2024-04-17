class_name CardBase
extends Control
@export var	data: Dictionary
var game_manager: Node
var attacks = 0
var blocked_until_turn = 0
var friendly = true

func setup(_data: Dictionary, _game_manager):
	data = _data
	game_manager = _game_manager
	var health = get_child(0).get_child(0) as Label
	health.text = str(data["health"])
	if "max_attacks" not in data.keys():
		data["max_attacks"] = 1
	var atk = get_child(0).get_child(2) as Label
	atk.text = str(data["damage"])

func battlecry():
	print(data["name"], " has no battlecry")

func deathrattle():
	print(data["name"], " has no deathrattle")
	
func dispatch_ability():
	ability()

func ability():
	print(data["name"], " has no active ability")

func on_click(event: InputEvent):
	if GameState.GAME_STATE != GameState.STATE_LOCALTURN:
		return
	if self.get_parent().name in ["LOCAL_GRAVEYARD"]:
		return
	elif event.is_pressed():
		if self.get_parent().name in GameState.SELECT_MASK and GameState.GAME_MODE == GameState.MODE_SELECT:
			GameState.SELECT_CALLBACK.call(self)
			GameState.cancel_card_selection()
		elif blocked_until_turn != 0 and blocked_until_turn >= game_manager.ROUND:
			return
		elif blocked_until_turn == game_manager.ROUND and blocked_until_turn != 0:
			blocked_until_turn = 0
		elif data["class"].contains("Leader") and int(data["manaCost"]) <= game_manager.MANA:
			dispatch_ability()
		elif event.alt_pressed and self.get_parent().name == "LOCAL_HAND":
			game_manager.move_card(self, "LOCAL_GRAVEYARD") 
		elif self.get_parent().name == "LOCAL_PLAYAREA" and GameState.GAME_STATE == GameState.STATE_LOCALTURN:
			GameState.get_card_selection(attack)
		elif self.get_parent().name == "LOCAL_HAND" and int(data["mana"]) <= game_manager.MANA:
			play(event)
		print(game_manager.MANA)
		print("Click on " + self.data["name"])
	else:
		pass

func attack(card: CardBase):
	if attacks >= data["max_attacks"]:
		return
	print('Attacking ' + card.data["name"] + ' from ' +  data["name"])
	card.data["health"] = int(card.data["health"]) - int(data["damage"])
	card.update_stats()
	if card.data["health"] <= 0:
		self.deathrattle()
		game_manager.move_card(card, "LOCAL_GRAVEYARD")
	attacks += 1
	
func play(_event: InputEvent):
	game_manager.MANA = game_manager.MANA - int(data["mana"])
	get_tree().root.get_node("PanelContainer").move_card(self, "LOCAL_PLAYAREA")

func update_stats():
	var health_label : Label = get_child(0).get_child(0)
	health_label.text = str(data["health"])

func on_round_start():
	attacks = 0
