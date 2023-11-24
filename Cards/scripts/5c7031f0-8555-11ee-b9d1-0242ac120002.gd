extends CardBase

func setup(data: Dictionary):
	health = data["health"]
	card_name = data["name"]

func attack(card):
	card.health -= 5
	return health
