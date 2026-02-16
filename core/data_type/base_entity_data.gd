class_name BaseEntityData
extends Resource

@export var id: String = ""


# 统一的入口函数
func init_from_dict(dict: Dictionary) -> void:
	id = dict.get("id", "")
	_parse_specific_data(dict) # 调用虚函数

# 留给子类实现的虚函数
func _parse_specific_data(_dict: Dictionary) -> void:
	pass
