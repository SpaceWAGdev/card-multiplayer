extends Control

@export var decks: Array

func _ready() -> void:
	update_deck_list_mapping()

func update_deck_list_mapping() -> void:
	var deck_list = Helpers.list_directory("res://Decks")
	deck_list = deck_list.filter(func(file: String):
		return file.get_file()
		)
	decks = [null] + deck_list
	var deck_select_btn: OptionButton = %DeckSelect as OptionButton
	deck_select_btn.clear()
	for i in range(1, len(decks)):
		deck_select_btn.add_item(JSON.parse_string(Helpers.load_text_file("res://Decks/".path_join(decks[i])))["name"], i)
	print(decks)

func on_deck_selection_changed(i: int) -> void:
	GameState.DECK_PATH = decks[i]

func on_debug_state_changed(value: bool) -> void:
	GameState.DEBUG_MODE = value

func start_game() -> void:
	get_tree().change_scene_to_file("res://game.tscn")
