#Lia
extends CardBase

func battlecry():
	print(data["name"],"'s Battlecry triggered")
	var enemies = game_manager.MASTER_LOCATION_RECORD["REMOTE_PLAYAREA"].get_children()
	for enemy in enemies:
		if enemy.get_meta("card_data")["class"].contains("Naturwissenschaftler"):
			enemy.data["health"] = int(enemy.data["health"]) - 1
