extends Node

var socket = WebSocketPeer.new()

var MASTER_CARD_RECORD : Dictionary = {
	"LOCAL_HAND": [],
	"LOCAL_DECK": [],
	"LOCAL_PLAYAREA": [],
	"REMOTE_PLAYAREA": [],
	"LOCAL_CHARACTER": [],
	"LOCAL_GRAVEYARD": [],
	"REMOTE_HAND": []
}

var MASTER_LOCATION_RECORD: Dictionary = {
	"LOCAL_HAND": null,
	"LOCAL_DECK": null,
	"LOCAL_PLAYAREA": null,
	"REMOTE_PLAYAREA": null,
	"LOCAL_GRAVEYARD": null,
	"REMOTE_HAND": null
}

var MAX_SIZES: Dictionary = {
	"LOCAL_HAND" = 9,
	"LOCAL_DECK" = 1024,
	"LOCAL_PLAYAREA" = 5,
	"REMOTE_PLAYAREA" = 5,
	"LOCAL_GRAVEYARD" = 1024,
	"REMOTE_HAND" = 9
}

var ROUND = 0
var MANA = 0
var MAX_MANA = 10

func _ready():
	init_ws()
	init_card_areas()
	GameState.on_enter_selectmode.connect(_dbg_display_select_mode)
	GameState.on_exit_selectmode.connect(_dbg_clear_select_mode)


func init_card_areas():
	MASTER_LOCATION_RECORD["LOCAL_HAND"] = get_node("VBoxContainer/LOCAL_HAND")
	MASTER_LOCATION_RECORD["LOCAL_DECK"] = get_node("ColorRect/BoxContainer/LOCAL_DECK")
	MASTER_LOCATION_RECORD["LOCAL_PLAYAREA"] = get_node("VBoxContainer/LOCAL_PLAYAREA")
	MASTER_LOCATION_RECORD["REMOTE_PLAYAREA"] = get_node("VBoxContainer/REMOTE_PLAYAREA")
	MASTER_LOCATION_RECORD["LOCAL_GRAVEYARD"] = get_node("ColorRect/BoxContainer/LOCAL_GRAVEYARD")
	MASTER_LOCATION_RECORD["REMOTE_HAND"] = get_node("ColorRect/BoxContainer/REMOTE_HAND")

func _process(_delta):
	poll_ws()

func init_ws():
	socket.connect_to_url(GameState.WS_SERVER_URL)

func connect_ws(url):
	GameState.WS_SERVER_URL = url
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
			if packet.get_string_from_utf8().contains("ROUNDOVER"):
				GameState.begin_turn()
				start_round()
				$VBoxContainer/DebugUI/RoundCounter.text = str(ROUND)
			if packet.get_string_from_utf8().contains("MATCH:"):
				GameState.MATCH_ID = packet.get_string_from_utf8().split(":")[1]
			else:
				deserialize_cards(packet)
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
			socket.send(message)
			return true
			
		current_attempt += 1
		await get_tree().create_timer(interval_time)

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

func create_card_instance(data: Dictionary, check_for_duplicates = false, location = "LOCAL_DECK", mid : String = ""):
	if MASTER_LOCATION_RECORD[location].get_child_count() > MAX_SIZES[location]:
		print(location, " full! Exiting")
		return
	var card_image = load("res://Cards/card.tscn").instantiate()
	card_image.set_meta("card_data", data)
	var script = load("res://Cards/scripts/" + data["uuid"] + ".gd")
	var img = load("res://Cards/images/"+ data["uuid"] + ".png")
	card_image.set_meta("mid", mid)
	if mid == "":
		card_image.set_meta("mid", Helpers.generate_uuid())
	if img == null:
		img = load("res://Cards/images/Image-1.jpg")
	card_image.get_child(1).texture = img
	card_image.script = script

	if card_image in MASTER_CARD_RECORD[location] and check_for_duplicates:
		return
	
	MASTER_LOCATION_RECORD[location].add_child(card_image)
	update_screen_area(location)
	card_image.setup(data, self)

	var ability_button : Button = card_image.get_child(2)
	ability_button.pressed.connect(card_image.dispatch_ability)
		
	var click_event = card_image.gui_input
	click_event.connect(card_image.on_click)

	if location == "LOCAL_DECK":
		card_image.z_index = -10
	
	if location == "LOCAL_PLAYAREA" and mid == "":
		card_image.battlecry()
	card_image.update_stats()
	print("Instantiated ", data["name"], " (Card Object) in ", location )
	
func update_screen_area(area: String):
	for child in find_child(area, true).get_children():
		if child == null:
			printerr("CHILD NULL")
		if child not in MASTER_CARD_RECORD[area]:
			MASTER_CARD_RECORD[area].append(child)
			# print("Added " + child.get_meta("card_data")["name"] + " to " + area + " record") 
	for child in MASTER_CARD_RECORD[area]:
		if child not in find_child(area, true).get_children():
			# print("Removed " + child.get_meta("card_data")["name"] + " from " +  area)
			MASTER_CARD_RECORD[area].erase(child)

func get_card_data(uuid: String):
	var card_list = JSON.parse_string((Helpers.load_text_file(("res://Cards/cards.json"))))
	if card_list.has(uuid):
		return card_list[uuid]
	else:
		return null

func load_deck(deck_name: String):
	var deck = JSON.parse_string(Helpers.load_text_file("res://Decks/" + deck_name + ".json"))
	create_card_instance(get_card_data(deck["leader"]), false, "LOCAL_HAND")
	for card in deck["cards"]:
		print(card)
		create_card_instance(get_card_data(card))
	sync()

func draw_card():
	var cards = MASTER_LOCATION_RECORD["LOCAL_DECK"].get_children()
	if cards.is_empty():
		return		
	move_card(cards.pick_random(), "LOCAL_HAND")

func move_card(card: Node, new_location: String):
	var old_parent = card.get_parent()
	var new_location_node = MASTER_LOCATION_RECORD[new_location]
	if old_parent == new_location_node:
		return
	old_parent.remove_child(card)
	new_location_node.add_child(card)
	update_screen_area(card.get_parent().name)
	update_screen_area(new_location_node.name)
	if new_location == "LOCAL_PLAYAREA" and old_parent.name == "LOCAL_HAND":
		card.battlecry()
	if new_location in ["LOCAL_GRAVEYARD", "LOCAL_DECK"]:
		card.z_index = -10
	else:
		card.z_index = 0
	if new_location.begins_with("LOCAL"):
		card.friendly = true
	print(new_location_node.name, new_location_node.get_children())

func _dbg_spawn_card():
	load_deck("deck"+$VBoxContainer/DebugUI/LineEdit.text)

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
	wait_for_open_connection_and_send_message("ROUNDOVER\n".to_utf8_buffer())
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
	wait_for_open_connection_and_send_message(bytes)             
	
func replace_areas(data: PackedByteArray): 
	print(bytes_to_var_with_objects(data))
	
func reset_game():
	for key in MASTER_LOCATION_RECORD.keys(): 
		for child in MASTER_LOCATION_RECORD[key].get_children(): 
			MASTER_LOCATION_RECORD[key].remove_child(child)
		update_screen_area(key)
	
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
	$VBoxContainer/DebugUI/ManaDisplay.text = str(MANA)

func overwrite_mana(value: int):
	MANA = value
	if MANA > MAX_MANA:
		MANA = MAX_MANA
	$VBoxContainer/DebugUI/ManaDisplay.text = str(MANA)

func _dbg_display_select_mode():
	$VBoxContainer/DebugUI.set("theme_override_colors/background_color", Color.GREEN_YELLOW)

func _dbg_clear_select_mode():
	$VBoxContainer/DebugUI.set("theme_override_colors/background_color", Color.TRANSPARENT)