extends CardBase

func setup(_data: Dictionary):
	data = _data

func attack(card):
	card["health"] -= data["damage"]
	return card

func battlecry():
	print(data["name"]+ "'s custom Battlecry")
