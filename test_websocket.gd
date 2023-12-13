extends Node

var socket = WebSocketPeer.new()

var MASTER_CARD_RECORD : Dictionary = {
	"LOCAL_HAND": [],
	"LOCAL_DECK": [],
	"LOCAL_PLAYAREA": [],
	"REMOTE_HAND": [],
	"REMOTE_DECK": [],
	"REMOTE_PLAYAREA": []
}

var MAX_HAND_SIZE = 9
var MAX_DECK_SIZE = 1024
var MAX_PLAYAREA_SIZE = 5

func load_text_file(path):
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		printerr("Error opening card list")
	var text = file.get_as_text()
	file.close()
	return text

func get_card_data(uuid: String):
	var card_list = JSON.parse_string((load_text_file(("res://Cards/cards.json"))))
	if card_list.has(uuid):
		return card_list[uuid]
	else:
		return null

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
	
	MASTER_CARD_RECORD["LOCAL_DECK"].append(card_image)
	update_screen_area(MASTER_CARD_RECORD["LOCAL_DECK"], $VBoxContainer/LocalDeck)
	card_image.setup(data)
	if len(MASTER_CARD_RECORD["LOCAL_DECK"]) > 2:
		card_image.set_meta("card_data", MASTER_CARD_RECORD["LOCAL_DECK"][0].attack(data))
	print(card_image.get_meta("card_data"))
	print("Children of Card:", card_image.get_children())
	print("New Master Card Record:", MASTER_CARD_RECORD)
	
func _ready():
	socket.connect_to_url("wss://ws.postman-echo.com/raw")
	# create_card_instance(get_card_data("8d056e3e-8555-11ee-b9d1-0242ac120002"))
	# create_card_instance(get_card_data("5c7031f0-8555-11ee-b9d1-0242ac120002"))
	# update_screen_area(MASTER_CARD_RECORD["LOCAL_DECK"], $Local/LocalDeck)

func update_screen_area(cards: Array, card_location: Node):
	for card in cards:
		if card not in card_location.get_children():
			card_location.add_child(card)
			print("Added Card " + card.get_meta("card_data")["name"])
	
func dbg_send_msg():
	if (socket.get_ready_state() == WebSocketPeer.STATE_OPEN):
		socket.send_text("hello, cardgame")

func _process(_delta):
	socket.poll()
	var state = socket.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		while socket.get_available_packet_count():
			%debug_message.text = socket.get_packet().get_string_from_utf8()
			print("Packet: ", socket.get_packet().get_string_from_utf8())
	elif state == WebSocketPeer.STATE_CLOSING:
		# Keep polling to achieve proper close.
		pass
	elif state == WebSocketPeer.STATE_CLOSED:
		var code = socket.get_close_code()
		var reason = socket.get_close_reason()
		print("WebSocket closed with code: %d, reason %s. Clean: %s" % [code, reason, code != -1])
		set_process(false) # Stop processing.

func _on_button_pressed():
	dbg_send_msg()

func dbg_spawn_card():
	create_card_instance(get_card_data("3964a6c8-325f-46e2-8dda-595cec5c7d4f"))
