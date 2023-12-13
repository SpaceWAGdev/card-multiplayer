extends Node

var socket = WebSocketPeer.new()

var MASTER_CARD_RECORD : Dictionary = {
	"LOCAL_HAND": [],
	"LOCAL_DECK": [],
	"LOCAL_PLAYAREA": [],
	"REMOTE_PLAYAREA": [],
	"LOCAL_CHARACTER": []
}

var MASTER_LOCATION_RECORD: Dictionary = {
	"LOCAL_HAND": null,
	"LOCAL_DECK": null,
	"LOCAL_PLAYAREA": null,
	"REMOTE_PLAYAREA": null
}

var MAX_HAND_SIZE = 9
var MAX_DECK_SIZE = 1024
var MAX_PLAYAREA_SIZE = 5

var ROUND = 0

func _ready():
	init_ws()
	init_card_areas()

func init_card_areas():
	MASTER_LOCATION_RECORD["LOCAL_HAND"] = get_node("VBoxContainer/LOCAL_HAND")
	MASTER_LOCATION_RECORD["LOCAL_DECK"] = get_node("VBoxContainer/LOCAL_DECK")
	MASTER_LOCATION_RECORD["LOCAL_PLAYAREA"] = get_node("VBoxContainer/LOCAL_PLAYAREA")
	MASTER_LOCATION_RECORD["REMOTE_PLAYAREA"] = get_node("VBoxContainer/REMOTE_PLAYAREA")

func _process(_delta):
	poll_ws()

func init_ws(url: String = "wss://ws.postman-echo.com/raw"):
	socket.connect_to_url(url)
	
func poll_ws():
	socket.poll()
	var state = socket.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		while socket.get_available_packet_count():
			var packet = socket.get_packet()
			print("Packet: ", packet)
			return packet			
	elif state == WebSocketPeer.STATE_CLOSING:
		# Keep polling to achieve proper close.
		pass
	elif state == WebSocketPeer.STATE_CLOSED:
		var code = socket.get_close_code()
		var reason = socket.get_close_reason()
		print("WebSocket closed with code: %d, reason %s. Clean: %s" % [code, reason, code != -1])
		set_process(false) # Stop processing.

func create_card_instance(uuid: String, check_for_duplicates = false, location : String  = "LOCAL_DECK"):
	var data = get_card_data(uuid)
	var card_image = load("res://Cards/card.tscn").instantiate()
	card_image.set_meta("card_data", data)
	var script = load("res://Cards/scripts/" + data["uuid"] + ".gd")
	var img = load("res://Cards/images/"+ data["uuid"] + ".png")
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
	
	print("### create_card_instance: " + card_image.get_meta("card_data")["name"])
	card_image.battlecry()
	
func update_screen_area(Area: String):
	for child in find_child(Area, true).get_children():
		if child not in MASTER_CARD_RECORD[Area]:
			MASTER_CARD_RECORD[Area].append(child)
			print("Added " + child.name + " to " + Area + " record") 
	for child in MASTER_CARD_RECORD[Area]:
		if child not in find_child(Area, true).get_children():
			MASTER_CARD_RECORD[Area].erase(child)
			print("Removed " + child.name + " from " +  Area)

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

func move_card(card: Node, new_location: String):
	var old_parent = card.get_parent()
	var new_location_node = MASTER_LOCATION_RECORD[new_location]
	if old_parent == new_location_node:
		return
	old_parent.remove_child(card)
	new_location_node.add_child(card)
	update_screen_area(card.get_parent().name)
	update_screen_area(new_location_node.name)
	print(new_location_node.name, new_location_node.get_children())

func _dbg_spawn_card():
	load_deck("default_deck")
	return
	if randi_range(0, 1) == 0:
		create_card_instance("3964a6c8-325f-46e2-8dda-595cec5c7d4f")
	else:
		create_card_instance("8d056e3e-8555-11ee-b9d1-0242ac120002")

func finish_round():
	ROUND += 1

func start_round():
	pass
	
func register_interaction(type: String ):
	pass
