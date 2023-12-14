extends CardBase

func attack(card):
	card.data["health"] -= data["damage"]

func handle_click(event: InputEvent):
	print("+1 Mana")
