extends CardBase

func attack(card):
	card.data["health"] -= data["damage"]

func battlecry():
	print(data["name"],"´s Battlecry triggered")
	var enemies = game_manager.MASTER_LOCATION_RECORD["REMOTE_PLAYAREA"].get_children()
	for enemy in enemies:
		if enemy.get_meta("card_data")["class"]=="Naturwissenschaftler":
			enemy.data["health"] = enemy.data["health"] - 1
