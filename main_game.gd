extends Node

var socket = WebSocketPeer.new()

var MASTER_CARD_RECORD : Dictionary = {
	"LOCAL_HAND": [],
	"LOCAL_DECK": [],
	"LOCAL_PLAYAREA": [],
	"REMOTE_PLAYAREA": []
}

var MAX_HAND_SIZE = 9
var MAX_DECK_SIZE = 1024
var MAX_PLAYAREA_SIZE = 5

var ROUND = 0

func _ready():
	init_ws()

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

func create_card_instance(data: Dictionary, check_for_duplicates = false):
	var card_image = load("res://Cards/card.tscn").instantiate()
	card_image.set_meta("card_data", data)
	var script = load("res://Cards/scripts/" + data["uuid"] + ".gd")
	var img = load("res://Cards/images/"+ data["uuid"] + ".png")
	card_image.texture = img
	card_image.script = script
	print(card_image.texture)
	
	if card_image in MASTER_CARD_RECORD["LOCAL_DECK"] and check_for_duplicates:
		return
	
	get_node("%LOCAL_DECK").add_child(card_image)
	update_screen_area("LOCAL_DECK")
	card_image.setup(data)
		
	var click_event = card_image.gui_input
	click_event.connect(card_image.on_click)
	
	card_image.battlecry()
	
	print(card_image.get_meta("card_data"))
	print("Children of Card:", card_image.get_children())
	print("New Master Card Record:", MASTER_CARD_RECORD)
	
func update_screen_area(Area: String):
	for child in find_child(Area, true).get_children():
		if child not in MASTER_CARD_RECORD[Area]:
			MASTER_CARD_RECORD[Area].append(child)
			print("Added " + child.name + " to " + Area + " record") 
	for child in MASTER_CARD_RECORD[Area]:
		if child not in find_child(Area, true).get_children():
			MASTER_CARD_RECORD[Area].remove(child)
			print("Removed " + child + " from " +  Area)

func get_card_data(uuid: String):
	var card_list = JSON.parse_string((Helpers.load_text_file(("res://Cards/cards.json"))))
	if card_list.has(uuid):
		return card_list[uuid]
	else:
		return null
		
func load_deck(deck_name: String):
	var deck = JSON.parse_string(Helpers.load_text_file("res://Decks/" + deck_name + ".json"))
	create_card_instance(get_card_data(deck["leader"]))
	for card in deck["cards"]:
		create_card_instance(get_card_data(card))
	for child in $VBoxContainer/LOCAL_DECK.get_children():
		if child.get_meta("card_data")["class"] == "leader":
			move_card(child, get_node("%LOCAL_CHARACTER"))
		else:
			move_card(child, get_node("%LOCAL_PLAYAREA"))
	update_screen_area("LOCAL_PLAYAREA")

func move_card(card: Node, new_location: Node):
	var old_parent = card.get_parent()
	if old_parent == new_location:
		return
	old_parent.remove_child(card)
	new_location.add_child(card)
	update_screen_area(card.get_parent().name)
	update_screen_area(new_location.name)
	print(new_location.name, new_location.get_children())

func _dbg_spawn_card():
	load_deck("default_deck")
	return
	if randi_range(0, 1) == 0:
		create_card_instance(get_card_data("3964a6c8-325f-46e2-8dda-595cec5c7d4f"))
	else:
		create_card_instance(get_card_data("8d056e3e-8555-11ee-b9d1-0242ac120002"))

func finish_round():
	ROUND += 1

func start_round():
	pass
	