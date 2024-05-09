# JAKOB
extends CardBase

var brokkoli = load("res://Cards/magic_brokkoli.tres") as Card

func battlecry():
	print(data["name"]+ "'s custom Battlecry")
	game_manager.create_card_instance(brokkoli.get_data_legacy(), false, "LOCAL_HAND")
	game_manager.create_card_instance(brokkoli.get_data_legacy(), false, "LOCAL_HAND")
