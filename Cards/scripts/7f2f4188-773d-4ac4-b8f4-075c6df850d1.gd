#MAGISCHES BROKKOLI
extends CardBase

func play(event: InputEvent):
	print("+1 Mana")
	game_manager.move_card(self, "LOCAL_GRAVEYARD")
