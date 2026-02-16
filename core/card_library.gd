class_name CardLibrary
extends RefCounted

# 存储解析后的数据
# 使用拦截器：当你访问 definitions 时，它会自动检查是否加载
static var definitions: Dictionary:
	get:
		if _definitions.is_empty():
			load_library()
		return _definitions
static var _definitions: Dictionary = {}
static var _units: Dictionary = {}
const CSV_PATH = "res://data/card_definitions.csv"
const JSON_PATH = "res://data/card_define.json"

# 建立 类型 -> 类文件 的映射
const TYPE_MAP = {
	"structure": "res://core/data_type/card_templates/card_structure_data.gd",
	"food": "res://core/data_type/card_templates/card_food_data.gd",
	"equipment": "res://core/data_type/card_templates/card_equipment_data.gd",
	"resource": "res://core/data_type/card_templates/card_resource_data.gd",
	"villager": "res://core/data_type/card_templates/card_unit_data.gd",
	"mob": "res://core/data_type/card_templates/card_unit_data.gd",
	"currency": "res://core/data_type/card_templates/card_base_data.gd",
}


# 初始化函数：在游戏开始时调用一次
static func load_library():
	var file = FileAccess.open(JSON_PATH, FileAccess.READ)
	if not file:
		push_error("无法打开卡片定义文件: " + JSON_PATH)
		return

	var json_string: String = file.get_as_text()
	file.close()
	var json = JSON.new()
	var error = json.parse(json_string)
	if error != OK:
		push_error("解析卡片定义文件失败: " + json.get_error_message())
	else:
		_definitions = json.data


static func get_all_card_ids() -> Array:
	return definitions.keys()

static func get_card_definition(id: String) -> Dictionary:
	if definitions.is_empty():
		load_library()
	
	var result: Dictionary = {}
	if definitions.has(id):
		result["definition"] = definitions[id]
	if _units.has(id):
		result["unit"] = _units[id]
	return result
	

static func create_data(id: String) -> BaseCardData:
	if not definitions.has(id):
		push_error("Card ID not found in JSON: " + id)
		return null
	var dict: Dictionary = definitions[id]
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
	var init_card = card_instance.from_dict(dict)
	return init_card
