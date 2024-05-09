extends Resource
class_name Deck

@export var name: String
@export var leader: Card
@export var cards: Array[Card]

func _to_string() -> String:
	var c = cards.filter(func(card): return card.name + "\n")
	return name + "\n" + "\n".join(c)
