extends CardBase

func attack(card):
	card.data["health"] -= data["damage"]

func handle_click(event: InputEvent):
	print("+1 Mana")
	game_manager.move_card(self, "LOCAL_GRAVEYARD")
