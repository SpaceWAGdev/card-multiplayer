# JAKOB
extends CardBase
func attack(card):
	card["health"] -= data["damage"]
	return card

func battlecry():
	print(data["name"]+ "'s custom Battlecry")
	game_manager.create_card_instance("7f2f4188-773d-4ac4-b8f4-075c6df850d1", "LOCAL_HAND")
	game_manager.create_card_instance("7f2f4188-773d-4ac4-b8f4-075c6df850d1", "LOCAL_HAND")
