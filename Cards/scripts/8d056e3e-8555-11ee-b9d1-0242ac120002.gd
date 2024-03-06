#Sharif
extends CardBase
func leader_ability():
	var enemy_cards = game_manager.MASTER_LOCATION_RECORD["REMOTE_PLAYAREA"].get_children()
	for card in enemy_cards: 
		card.blocked_until_turn = game_manager.ROUND +1
		print("ßßßßßleader ability sharif")
