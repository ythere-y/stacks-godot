class_name FoodCardData
extends BaseCardData

@export var feed_value: int = 1
@export var skills: Array = []


func from_dict(dict: Dictionary) -> FoodCardData:
	super.from_dict(dict) # 先解析通用属性
	feed_value = dict.get("feed_value", 1)
	skills = dict.get("skills", [])
	return self
