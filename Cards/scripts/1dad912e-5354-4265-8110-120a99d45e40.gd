# Mate
extends CardBase

func battlecry():
	var cards = game_manager.MASTER_LOCATION_RECORD["LOCAL_PLAYAREA"].get_children()
	for card: CardBase in cards:
		card.data["health"] = int(card.data["health"]) + 1
