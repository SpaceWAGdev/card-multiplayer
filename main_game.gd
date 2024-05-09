extends Node

var socket = WebSocketPeer.new()

# var MASTER_CARD_RECORD : Dictionary = {
# 	"LOCAL_HAND": [],
# 	"LOCAL_DECK": [],
# 	"LOCAL_PLAYAREA": [],
# 	"REMOTE_PLAYAREA": [],
# 	"LOCAL_CHARACTER": [],
# 	"LOCAL_GRAVEYARD": [],
# 	"REMOTE_HAND": []
# }

@export var MASTER_LOCATION_RECORD: Dictionary = {
	"LOCAL_HAND": null,
	"LOCAL_DECK": null,
	"LOCAL_PLAYAREA": null,
	"REMOTE_PLAYAREA": null,
	"LOCAL_GRAVEYARD": null,
	"REMOTE_HAND": null
}

@export var MAX_SIZES: Dictionary = {
	"LOCAL_HAND" = 9,
	"LOCAL_DECK" = 1024,
	"LOCAL_PLAYAREA" = 5,
	"REMOTE_PLAYAREA" = 5,
	"LOCAL_GRAVEYARD" = 1024,
	"REMOTE_HAND" = 9
}

@export var cards: Array[Card]

var UUID_CARD_TABLE : Dictionary

var ROUND = 0
var MANA = 0
var MAX_MANA = 10

func _ready():
	for card in cards:
		UUID_CARD_TABLE[card.uuid] = card
	init_ws()
	init_card_areas()
	GameState.on_enter_selectmode.connect(_dbg_display_select_mode)
	GameState.on_exit_selectmode.connect(_dbg_clear_select_mode)
	print(GameState.DECK_PATH.to_string())
	load_deck(GameState.DECK_PATH)

func init_card_areas():
	MASTER_LOCATION_RECORD["LOCAL_HAND"] = get_node(MASTER_LOCATION_RECORD["LOCAL_HAND"])
	MASTER_LOCATION_RECORD["LOCAL_DECK"] = get_node(MASTER_LOCATION_RECORD["LOCAL_DECK"])
	MASTER_LOCATION_RECORD["LOCAL_PLAYAREA"] = get_node(MASTER_LOCATION_RECORD["LOCAL_PLAYAREA"])
	MASTER_LOCATION_RECORD["REMOTE_PLAYAREA"] = get_node(MASTER_LOCATION_RECORD["REMOTE_PLAYAREA"])
	MASTER_LOCATION_RECORD["LOCAL_GRAVEYARD"] = get_node(MASTER_LOCATION_RECORD["LOCAL_GRAVEYARD"])
	MASTER_LOCATION_RECORD["REMOTE_HAND"] = get_node(MASTER_LOCATION_RECORD["REMOTE_HAND"])

func _process(_delta):
	poll_ws()
	if Input.is_key_pressed(KEY_ESCAPE) and GameState.GAME_MODE == GameState.MODE_SELECT:
		GameState.cancel_card_selection()

func init_ws():
	socket.connect_to_url(GameState.WS_SERVER_URL)
	print(GameState.SETUP_MESSAGE)
	wait_for_open_connection_and_send_message(GameState.SETUP_MESSAGE)

func connect_ws():
	socket.connect_to_url(GameState.WS_SERVER_URL)
	get_tree().reload_current_scene()
	
func disconnect_ws(code = 1000):
	socket.close(code, "Manual Disconnect")
	get_tree().change_scene_to_file("res://menu.tscn")

func poll_ws():
	socket.poll()
	var state = socket.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		while socket.get_available_packet_count():
			var packet = socket.get_packet()
			print("Packet: ", packet.get_string_from_utf8())
			var packet_data = JSON.parse_string(packet.get_string_from_utf8())

			match packet_data["type"]:
				"Control":
					match packet_data["control-message"]:
						"ROUNDOVER":
							GameState.begin_turn()
							start_round()
							$VBoxContainer/DebugUI/RoundCounter.text = str(ROUND)
						"CONFIRM_MATCH":
							GameState.MATCH_ID = packet_data["control-arguments"]["id"]
				"Sync":
					deserialize_cards(packet_data["sync-data"])
				"Message" :
					print(packet_data["message"])
			return packet
	elif state == WebSocketPeer.STATE_CLOSING:
		# Keep polling to achieve proper close.
		$"VBoxContainer/DebugUI/Connect WS".set("theme_override_colors/font_color", Color.RED)
		pass
	elif state == WebSocketPeer.STATE_CLOSED:
		$"VBoxContainer/DebugUI/Connect WS".set("theme_override_colors/font_color", Color.RED)
		var code = socket.get_close_code()
		var reason = socket.get_close_reason()
		print("WebSocket closed with code: %d, reason %s. Clean: %s" % [code, reason, code != -1])
		set_process(false) # Stop processing.

func wait_for_open_connection_and_send_message(message):
	var max_number_of_attempts = 10
	var interval_time = 0.2  # seconds
	var current_attempt = 0
	while current_attempt < max_number_of_attempts:
		if socket.get_ready_state() == socket.STATE_OPEN:
			$"VBoxContainer/DebugUI/Connect WS".set("theme_override_colors/font_color", Color.GREEN_YELLOW)
			# Send the message once the connection is open
			socket.send_text(message)
			return true
			
		current_attempt += 1
		await get_tree().create_timer(interval_time).timeout

	return false

func serialize_card(card: Node):
	var data : Dictionary = card.get_meta("card_data")
	var uuid: String = data["uuid"]
	var mid : String = card.get_meta("mid")
	return {
		"data": data,
		"uuid": uuid,
		"mid": mid
	}
	
func deserialize_cards(bytes: PackedByteArray):
	var obj = bytes_to_var_with_objects(bytes)
	if obj == null or len(obj) == 0:
		printerr("Deserialization Error")
		return
	clear_area("REMOTE_PLAYAREA")
	clear_area("LOCAL_PLAYAREA")	
	for card in obj["LOCAL_PLAYAREA"]:
		create_card_instance(card["data"], false, "REMOTE_PLAYAREA", card["mid"])
	for card in obj["REMOTE_PLAYAREA"]:
		create_card_instance(card["data"], false, "LOCAL_PLAYAREA", card["mid"])
	for card in obj["REMOTE_HAND"]:
		create_card_instance(card["data"], false, "LOCAL_HAND", card["mid"])
	if not GameState.IS_BEGINNER:
		ROUND = obj["ROUND"]

func decorate_card(card_image, location, data):
	for child in card_image.find_child("Top Row").get_children():
		child.visible = false

	var mana_label = card_image.find_child("Mana", true)

	if location.contains("REMOTE"):
		card_image.find_child("Ability", true).visible = false
		mana_label.visible = false
	elif location == "LOCAL_HAND":
		mana_label.visible = true
	elif location == "LOCAL_PLAYAREA":
		var to_enable = [
		card_image.find_child("Health", true),
		card_image.find_child("Damage", true),
		card_image.find_child("VSeparator", true)
		]

		for e in to_enable:
			e.visible = true
		
	mana_label.text = str(data["mana"])

func create_card_instance(data: Dictionary, check_for_duplicates = false, location = "LOCAL_DECK", mid : String = ""):
	if MASTER_LOCATION_RECORD[location].get_child_count() > MAX_SIZES[location]:
		print(location, " full! Exiting")
		return
	var card_image = load("res://Cards/card.tscn").instantiate()
	card_image.set_meta("card_data", data)
	# var script = load("res://Cards/scripts/" + data["uuid"] + ".gd")
	var script = data["script"]
	# var img = load("res://Cards/images/"+ data["uuid"] + ".png")
	var img = data["image"]
	card_image.set_meta("mid", mid)
	if mid == "":
		card_image.set_meta("mid", Helpers.generate_uuid())
	if img == null:
		img = load("res://Cards/images/Image-1.jpg")
	card_image.find_child("Image").texture = img
	card_image.script = script

	if card_image in MASTER_LOCATION_RECORD[location].get_children() and check_for_duplicates:
		return
	
	MASTER_LOCATION_RECORD[location].add_child(card_image)
	# update_screen_area(location)
	card_image.setup(data, self)

	var ability_button : Button = card_image.find_child("Ability", true)
	ability_button.pressed.connect(card_image.dispatch_ability)
	
	var click_event = card_image.gui_input
	click_event.connect(card_image.on_click)

	if location == "LOCAL_PLAYAREA" and mid == "":
		card_image.battlecry()

	decorate_card(card_image, location, data)

	card_image.update_stats()
	print("Instantiated ", data["name"], " (Card Object) in ", location )
	
# func update_screen_area(area: String):
# 	for child in find_child(area, true).get_children():
# 		if child == null:
# 			printerr("CHILD NULL")
# 		if child not in MASTER_CARD_RECORD[area]:
# 			MASTER_CARD_RECORD[area].append(child)
# 			# print("Added " + child.get_meta("card_data")["name"] + " to " + area + " record") 
# 	for child in MASTER_CARD_RECORD[area]:
# 		if child not in find_child(area, true).get_children():
# 			# print("Removed " + child.get_meta("card_data")["name"] + " from " +  area)
# 			MASTER_CARD_RECORD[area].erase(child)

func get_card_data(uuid: String):
	return UUID_CARD_TABLE[uuid].get_data_legacy()
	# var card_list = JSON.parse_string((Helpers.load_text_file(("res://Cards/cards.json"))))
	# if card_list.has(uuid):
	# 	return card_list[uuid]
	# else:
	# 	return null

func load_deck(deck: Deck):
	create_card_instance(deck.leader.get_data_legacy(), false, "LOCAL_HAND")
	for card in deck.cards:
		print(card)
		create_card_instance(card.get_data_legacy())


func draw_card():
	var card_list = MASTER_LOCATION_RECORD["LOCAL_DECK"].get_children()
	if card_list.is_empty():
		return		
	move_card(card_list.pick_random(), "LOCAL_HAND")

func move_card(card: Node, new_location: String):
	var old_parent = card.get_parent()
	var new_location_node = MASTER_LOCATION_RECORD[new_location]
	if old_parent == new_location_node:
		return
	old_parent.remove_child(card)
	new_location_node.add_child(card)
	# update_screen_area(card.get_parent().name)
	# update_screen_area(new_location_node.name)
	if new_location == "LOCAL_PLAYAREA" and old_parent.name == "LOCAL_HAND":
		card.battlecry()

	if new_location.begins_with("LOCAL"):
		card.friendly = true

	decorate_card(card, new_location, card.data)
	
	print(new_location_node.name, new_location_node.get_children())

func _dbg_begin():
	GameState.set_game_state(GameState.STATE_LOCALTURN)
	GameState.IS_BEGINNER = true
	start_round()

func _dbg_sync():
	sync()

func finish_round():
	if GameState.GAME_STATE != GameState.STATE_LOCALTURN:
		return
	ROUND += 1
	$VBoxContainer/DebugUI/RoundCounter.text = str(ROUND)
	GameState.GAME_STATE = GameState.STATE_REMOTETURN
	wait_for_open_connection_and_send_message(JSON.stringify({
		"type" : "Message",
		"match" : GameState.MATCH_ID,
		"message" : "ROUNDOVER"
	}))
	sync()

func start_round():
	GameState.begin_turn()
	overwrite_mana(ROUND)
	draw_card()
	for card in MASTER_LOCATION_RECORD["LOCAL_PLAYAREA"].get_children():
		card.on_round_start()
	
func sync():
	print("Attempting to sync")
	var to_sync = {
		"LOCAL_PLAYAREA" : [],
		"REMOTE_PLAYAREA" : [],
		"REMOTE_HAND" : [],
		"ROUND": ROUND
	}
	for card in MASTER_LOCATION_RECORD["LOCAL_PLAYAREA"].get_children():
		to_sync["LOCAL_PLAYAREA"].append(serialize_card(card))
	for card in MASTER_LOCATION_RECORD["REMOTE_PLAYAREA"].get_children():
		to_sync["REMOTE_PLAYAREA"].append(serialize_card(card))
	for card in MASTER_LOCATION_RECORD["REMOTE_HAND"].get_children():
		to_sync["REMOTE_HAND"].append(serialize_card(card))
	var bytes = var_to_bytes_with_objects(to_sync)

	var json = JSON.stringify({
		"type": "Sync",
		"sync-data" : bytes,
		"match": GameState.MATCH_ID
	})

	wait_for_open_connection_and_send_message(json)             
	
func replace_areas(data: PackedByteArray): 
	print(bytes_to_var_with_objects(data))
	
func reset_game():
	for key in MASTER_LOCATION_RECORD.keys(): 
		for child in MASTER_LOCATION_RECORD[key].get_children(): 
			MASTER_LOCATION_RECORD[key].remove_child(child)
		# update_screen_area(key)
	
func clear_area(area: String):
	for child in MASTER_LOCATION_RECORD[area].get_children():
		MASTER_LOCATION_RECORD[area].remove_child(child)
		child.queue_free()
		
func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		disconnect_ws(1001)

func update_mana(delta: int):
	MANA += delta
	if MANA > MAX_MANA:
		MANA = MAX_MANA
	$VBoxContainer/DebugUI/ManaDisplay.update_mana(MANA)

func overwrite_mana(value: int):
	MANA = value
	if MANA > MAX_MANA:
		MANA = MAX_MANA
	$VBoxContainer/DebugUI/ManaDisplay.update_mana(MANA)

func _dbg_display_select_mode():
	$VBoxContainer/DebugUI.set("theme_override_colors/background_color", Color.GREEN_YELLOW)

func _dbg_clear_select_mode():
	$VBoxContainer/DebugUI.set("theme_override_colors/background_color", Color.TRANSPARENT)
