class_name ResourceCardData
extends BaseCardData

@export var max_durability: int = 1


func take_damage(_amount: int):
	return true
func from_dict(dict: Dictionary) -> ResourceCardData:
	super.from_dict(dict) # 先解析通用属性
	max_durability = dict.get("max_durability", 1)
	return self
