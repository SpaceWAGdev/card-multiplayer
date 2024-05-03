# Till
extends CardBase

func battlecry():
	print(data["name"]+ "'s custom Battlecry")
	game_manager.create_card_instance(game_manager.get_card_data("f511179f-e74e-4687-8732-199db5d28c7a"), false, "LOCAL_HAND")
	game_manager.create_card_instance(game_manager.get_card_data("f511179f-e74e-4687-8732-199db5d28c7a"), false, "LOCAL_HAND")	
