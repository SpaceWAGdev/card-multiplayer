extends Resource
class_name Card

enum Type {
    entity,
    spell
}

@export var name : String
@export var character_class : String
@export var type: Type
@export var health: int
@export var damage: int
@export var mana: int
@export var ability_mana_cost: int
@export var uuid : String
@export var behaviour_script : GDScript
@export var tooltip: String
@export var image: Texture2D

func get_data_legacy():
    return {
        "name" : name,
        "class" : character_class,
        "type" : type,
        "health" : health,
        "damage" : damage,
        "mana" : mana,
        "mana_cost" : ability_mana_cost,
        "uuid" : uuid,
        "script": behaviour_script,
        "tooltip" : tooltip,
        "image" : image
    }