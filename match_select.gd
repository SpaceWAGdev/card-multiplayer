extends Control

@export var decks: Array[Deck]

func _ready() -> void:
	update_deck_list_mapping()

func update_deck_list_mapping() -> void:
	var deck_select_btn: OptionButton = %DeckSelect as OptionButton
	deck_select_btn.clear()
	for deck in decks:
		deck_select_btn.add_item(deck.name)

func on_deck_selection_changed(i: int) -> void:
	GameState.DECK_PATH = decks[i]

func on_debug_state_changed(value: bool) -> void:
	GameState.DEBUG_MODE = value

func start_game() -> void:
	get_tree().change_scene_to_file("res://game.tscn")