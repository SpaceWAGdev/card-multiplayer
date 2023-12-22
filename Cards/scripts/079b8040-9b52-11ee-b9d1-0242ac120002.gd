extends CardBase

func attack(card):
	card.data["health"] -= data["damage"]

func battlecry():
	print(data["name"],"´s Battlecry triggered")
