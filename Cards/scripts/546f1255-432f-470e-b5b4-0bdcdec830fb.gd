#WINDRICH
extends CardBase

func handleAbility(card: CardBase):
	game_manager.move_card(card, "REMOTE_HAND")

func leaderAbility():
	GameState.get_card_selection()
