# JAKOB
extends CardBase
func attack(card):
	card["health"] -= data["damage"]
	print("%s attacked %s".format(self.name, card.name))
	return card

func battlecry():
	print(data["name"]+ "'s custom Battlecry")
	game_manager.create_card_instance(game_manager.get_card_data("7f2f4188-773d-4ac4-b8f4-075c6df850d1"), false, "LOCAL_HAND")
	game_manager.create_card_instance(game_manager.get_card_data("7f2f4188-773d-4ac4-b8f4-075c6df850d1"), false, "LOCAL_HAND")	
