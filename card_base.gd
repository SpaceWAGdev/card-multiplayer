class_name CardBase
extends Control
@export var	data: Dictionary
@export var delta_y_position: int = 45
var game_manager: Node
var attacks = 0
var blocked_until_turn = 0
var friendly = true

func _hover_enter() -> void:
	if get_parent().name.contains("DECK") or get_parent().name.contains("GRAVEYARD"):
		return 
	var image = preload("res://card_image_overlay.tscn").instantiate()
	# TODO: Don't instantiate, just toggle visiblity
	image.get_child(0).texture = find_child("Image").texture
	image.scale = Vector2(0.5, 0.5)
	image.name = "hover_img"
	image.z_index = 20
	var width = image.get_child(0).texture.get_width()
	var height = image.get_child(0).texture.get_height()

	# image gets centered over the original card
	image.position = Vector2((image.position.x + width / 4 * image.scale.x ), (image.position.y + height / 6 * image.scale.y) - delta_y_position)

	self.add_child(image)

func _hover_exit() -> void:
	var image = get_child(3)
	print(image)
	if image != null:
		image.queue_free()

func setup(_data: Dictionary, _game_manager):
	data = _data
	game_manager = _game_manager
	var health = find_child("Health", true) as Label
	health.text = str(data["health"])
	if "max_attacks" not in data.keys():
		data["max_attacks"] = 1
	var atk = find_child("Damage", true) as Label
	atk.text = str(data["damage"])
	self.mouse_entered.connect(_hover_enter)
	self.mouse_exited.connect(_hover_exit)
	if "Leader" in data["class"]:
		find_child("Mana", true).visible = false

func battlecry():
	print(data["name"], " has no battlecry")

func deathrattle():
	print(data["name"], " has no deathrattle")
	
func dispatch_ability():
	if not int(data["manaCost"]) > game_manager.MANA:
		ability()

func ability():
	print(data["name"], " has no active ability")

func take_damage(amount: int):
	var current_armor = int(data["armor"])
	data["armor"] = int(data["armor"]) - amount
	data["health"] = int(data["health"]) - max(0, (amount - current_armor))
	update_stats()
	if data["health"] <= 0:
		self.deathrattle()
		game_manager.move_card(self, "LOCAL_GRAVEYARD")

func on_click(event: InputEvent):
	if GameState.GAME_STATE != GameState.STATE_LOCALTURN:
		return
	if self.get_parent().name in ["LOCAL_GRAVEYARD", "LOCAL_DECK"]:
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
	attacks += 1
	
func play(_event: InputEvent):
	game_manager.MANA = game_manager.MANA - int(data["mana"])
	get_tree().root.get_node("PanelContainer").move_card(self, "LOCAL_PLAYAREA")

func update_stats():
	var health_label : Label = find_child("Health", true)
	health_label.text = str(data["health"])

	var atk_label : Label = find_child("Damage", true)
	health_label.text = str(data["damage"])

	if "Leader" in data["class"]:
		find_child("Mana", true).visible = false

func on_round_start():
	attacks = 0
