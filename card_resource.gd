class_name CardBase
extends TextureRect
@export var	data: Dictionary

func setup(_data: Dictionary):
	data = _data

func battlecry():
	print(data["name"], ": Battlecry")
