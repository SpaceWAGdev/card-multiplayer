extends Node

var socket = WebSocketPeer.new()

var MASTER_CARD_RECORD : Dictionary = {
	"LOCAL_HAND": [],
	"LOCAL_DECK": [],
	"LOCAL_PLAYAREA": [],
	"REMOTE_PLAYAREA": [],
	"LOCAL_CHARACTER": [],
	"LOCAL_GRAVEYARD": []
}

var MASTER_LOCATION_RECORD: Dictionary = {
	"LOCAL_HAND": null,
	"LOCAL_DECK": null,
	"LOCAL_PLAYAREA": null,
	"REMOTE_PLAYAREA": null,
	"LOCAL_GRAVEYARD": null
}

var MAX_SIZES: Dictionary = {
	"LOCAL_HAND" = 9,
	"LOCAL_DECK" = 1024,
	"LOCAL_PLAYAREA" = 7,
	"REMOTE_PLAYAREA" = 7,
	"LOCAL_GRAVEYARD" = 1024
}

var ROUND = 0

func _ready():
	init_ws()
	init_card_areas()

func init_card_areas():
	MASTER_LOCATION_RECORD["LOCAL_HAND"] = get_node("VBoxContainer/LOCAL_HAND")
	MASTER_LOCATION_RECORD["LOCAL_DECK"] = get_node("ColorRect/BoxContainer/LOCAL_DECK")
	MASTER_LOCATION_RECORD["LOCAL_PLAYAREA"] = get_node("VBoxContainer/LOCAL_PLAYAREA")
	MASTER_LOCATION_RECORD["REMOTE_PLAYAREA"] = get_node("VBoxContainer/REMOTE_PLAYAREA")
	MASTER_LOCATION_RECORD["LOCAL_GRAVEYARD"] = get_node("ColorRect/BoxContainer/LOCAL_GRAVEYARD")

func _process(_delta):
	poll_ws()

func init_ws(url = "ws://localhost:8765"):
	socket.connect_to_url(url)
	
func poll_ws():
	socket.poll()
	var state = socket.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		while socket.get_available_packet_count():
			var packet = socket.get_packet()
			print("Packet: ", packet.get_string_from_utf8())
			return packet			
	elif state == WebSocketPeer.STATE_CLOSING:
		# Keep polling to achieve proper close.
		pass
	elif state == WebSocketPeer.STATE_CLOSED:
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
			# Send the message once the connection is open
			socket.send_text(message)
			return true
			
		current_attempt += 1
		await get_tree().create_timer(interval_time)

	return false

func serialize_card(card: Node):
	var data : Dictionary = card.get_meta("card_data")
	var uuid: String = data["uuid"]
	var mid : String = card.get_meta("mid")
	var to_serialize = {
		"data": data,
		"uuid": uuid,
		"mid": mid
	}
	return JSON.stringify(to_serialize)
	
func deserialize_card(json: String):
	pass

func create_card_instance(uuid: String, check_for_duplicates = false, location = "LOCAL_DECK", mid : String = ""):
	if MASTER_LOCATION_RECORD[location].get_child_count() > MAX_SIZES[location]:
		print(location, " full! Exiting")
		return
	var data = get_card_data(uuid)
	var card_image = load("res://Cards/card.tscn").instantiate()
	card_image.set_meta("card_data", data)
	var script = load("res://Cards/scripts/" + data["uuid"] + ".gd")
	var img = load("res://Cards/images/"+ data["uuid"] + ".png")
	if mid == "":
		mid = Helpers.generate_uuid()
	card_image.set_meta("mid", mid)
	if img == null:
		img = load("res://Cards/images/Image-1.jpg")
	card_image.texture = img
	card_image.script = script
	
	
	if card_image in MASTER_CARD_RECORD[location] and check_for_duplicates:
		return
	
	MASTER_LOCATION_RECORD[location].add_child(card_image)
	update_screen_area(location)
	card_image.setup(data, self)
		
	var click_event = card_image.gui_input
	click_event.connect(card_image.on_click)
	
	if location == "LOCAL_PLAYAREA":
		card_image.battlecry()
	
	print("Instantiated ", data["name"], " (Card Object) in ", location )
	
func update_screen_area(Area: String):
	for child in find_child(Area, true).get_children():
		if child not in MASTER_CARD_RECORD[Area]:
			MASTER_CARD_RECORD[Area].append(child)
			print("Added " + child.get_meta("card_data")["name"] + " to " + Area + " record") 
	for child in MASTER_CARD_RECORD[Area]:
		if child not in find_child(Area, true).get_children():
			MASTER_CARD_RECORD[Area].erase(child)
			print("Removed " + child.get_meta("card_data")["name"] + " from " +  Area)

func get_card_data(uuid: String):
	var card_list = JSON.parse_string((Helpers.load_text_file(("res://Cards/cards.json"))))
	if card_list.has(uuid):
		return card_list[uuid]
	else:
		return null

func load_deck(deck_name: String):
	var deck = JSON.parse_string(Helpers.load_text_file("res://Decks/" + deck_name + ".json"))
	create_card_instance(deck["leader"])
	for card in deck["cards"]:
		create_card_instance(card)
	for child in MASTER_LOCATION_RECORD["LOCAL_DECK"].get_children():
		if child.get_meta("card_data")["class"] == "leader":
			move_card(child, "LOCAL_CHARACTER")
		else:
			move_card(child, "LOCAL_HAND")
	update_screen_area("LOCAL_HAND")
	sync()

func move_card(card: Node, new_location: String):
	var old_parent = card.get_parent()
	var new_location_node = MASTER_LOCATION_RECORD[new_location]
	if old_parent == new_location_node:
		return
	old_parent.remove_child(card)
	new_location_node.add_child(card)
	update_screen_area(card.get_parent().name)
	update_screen_area(new_location_node.name)
	if new_location == "LOCAL_PLAYAREA":
		card.battlecry()
	if new_location == "LOCAL_GRAVEYARD":
		card.z_index = -10 
	print(new_location_node.name, new_location_node.get_children())

func _dbg_spawn_card():
	load_deck("deck"+$VBoxContainer/DebugUI/LineEdit.text)

func _dbg_sync():
	sync()


func finish_round():
	ROUND += 1
	$VBoxContainer/DebugUI/RoundCounter.text = str(ROUND)
	sync()

func start_round():
	ROUND += 1
	pass
	
func sync():
	print("Attempting to sync")
	var to_sync = []
	for card in MASTER_LOCATION_RECORD["LOCAL_PLAYAREA"].get_children():
		to_sync.append(serialize_card(card))
	print(JSON.stringify(to_sync))
	
func replace_areas(data: PackedByteArray):
	print(bytes_to_var_with_objects(data))
	
func reset_game():
	for key in MASTER_LOCATION_RECORD.keys(): 
		for child in MASTER_LOCATION_RECORD[key].get_children(): 
			MASTER_LOCATION_RECORD[key].remove_child(child)
		update_screen_area(key)
	
