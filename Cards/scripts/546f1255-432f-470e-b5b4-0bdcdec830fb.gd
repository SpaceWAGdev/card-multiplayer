#WINDRICH
extends CardBase

func attack(card):
	card.data["health"] -= data["damage"]
