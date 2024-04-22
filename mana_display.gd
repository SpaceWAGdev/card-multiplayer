extends HBoxContainer

func update_mana(mana: int) -> void:
	while len(get_children()) > mana:
		remove_child(get_children()[0])
	while len(get_children()) < mana:
		add_child(preload("res://mana_circle.tscn").instantiate())
