class_name EquipmentCardData
extends BaseCardData

@export var health_bonus: int = 0
@export var attack_bonus: int = 0
@export var defense_bonus: int = 0
@export var attack_speed_bonus: float = 0.0
@export var hit_chance_bonus: float = 0.0
@export var skills: Array= []


func from_dict(dict: Dictionary) -> EquipmentCardData:
	super.from_dict(dict) # 先解析通用属性
	health_bonus = dict.get("hp_bonus", 0)
	attack_bonus = dict.get("atk_lvl", 0)
	defense_bonus = dict.get("def_lvl", 0)
	attack_speed_bonus = dict.get("spd_lvl", 0)
	hit_chance_bonus = dict.get("hit_chance_lvl", 0)
	skills = dict.get("skills", [])
	return self
