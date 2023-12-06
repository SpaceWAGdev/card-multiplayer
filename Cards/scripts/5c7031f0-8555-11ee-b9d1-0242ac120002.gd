extends CardBase



func attack(card):
	card.data["health"] -= data["damage"]

func battlecry():
	print("Battlecry")
