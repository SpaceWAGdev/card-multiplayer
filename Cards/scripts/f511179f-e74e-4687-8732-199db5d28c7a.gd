# Boxtraining
extends CardBase

func battlecry():
    var friendlies = game_manager.MASTER_LOCATION_RECORD["LOCAL_PLAYAREA"].get_children()
    for card in friendlies: 
        card.data["damage"] = int(card.data["damage"]) + 1