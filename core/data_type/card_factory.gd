# card_factory.gd
class_name CardFactory

# 建立 类型 -> 类文件 的映射
const TYPE_MAP = {
	BaseCardData.CardType.STRUCTURE: "res://core/data_type/card_templates/card_structure_data.gd",
	BaseCardData.CardType.FOOD: "res://core/data_type/card_templates/card_food_data.gd",
	BaseCardData.CardType.EQUIPMENT: "res://core/data_type/card_templates/card_equipment_data.gd",
	BaseCardData.CardType.RESOURCE: "res://core/data_type/card_templates/card_resource_data.gd",
	BaseCardData.CardType.VILLAGER: "res://core/data_type/card_templates/card_villager_data.gd",
	BaseCardData.CardType.MOB: "res://core/data_type/card_templates/card_unit_data.gd",
}

static func create_card(dict: Dictionary) -> BaseCardData:
	var type = dict.get("type", -1)
	
	# 1. 找到对应的类定义
	var path = TYPE_MAP.get(type, "") # 找不到就退回基类
	var card_instance: BaseCardData
	if path != "" and FileAccess.file_exists(path):
		card_instance = load(path).new()
	else:
		push_error("Card type not found or file missing for type: " + str(type))
		return null
	# 2. 实例化对象并解析
	return card_instance.from_dict(dict)
