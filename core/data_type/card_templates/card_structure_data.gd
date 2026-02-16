class_name StructureCardData
extends BaseCardData


@export var durability: int = 1
@export var current_durability: int = 1
@export var skills: Array = [] # Example: [{name: "Heal", effect: "restore 5 HP", cooldown: 2.0}]
@export var loot_table: Array = [] # Example: [{id: "gold_coin", chance: 0.5}, {id: "iron_sword", chance: 0.1}]

func take_damage(amount: int):
	current_durability -= amount
	if current_durability <= 0:
		current_durability = 0
		return true # Indicates the structure has been destroyed
	return false
func from_dict(dict: Dictionary) -> StructureCardData:
	super.from_dict(dict) # 先解析通用属性
	durability = dict.get("durability", 1)
	current_durability = durability
	skills = dict.get("skills", [])
	loot_table = dict.get("loot_table", [])

	return self
