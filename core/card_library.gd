class_name CardLibrary
extends RefCounted

# 存储解析后的数据
static var _definitions: Dictionary = {}
const CSV_PATH = "res://data/card_definitions.csv"

# 初始化函数：在游戏开始时调用一次
static func load_library():
	var file = FileAccess.open(CSV_PATH, FileAccess.READ)
	if not file:
		push_error("无法打开卡片定义文件: " + CSV_PATH)
		return

	# 跳过表头
	file.get_csv_line()
	
	while file.get_position() < file.get_length():
		var line = file.get_csv_line()
		if line.size() < 5: continue # 确保行数据完整
		
		var id = line[0]
		_definitions[id] = {
			"name_key": line[1],
			"type": line[2],
			"max_durability": int(line[3]),
			"color": Color.html(line[4]), # 将十六进制字符串转为 Color 对象
			"icon": line[5]
		}
	file.close()
static func get_all_card_ids() -> Array:
	if _definitions.is_empty():
		load_library()
	return _definitions.keys()
static func create_data(id: String) -> CardData:
	# 如果字典为空，尝试加载（或者在主流程中预先加载）
	if _definitions.is_empty():
		load_library()
		
	if not _definitions.has(id):
		push_error("Card ID not found in CSV: " + id)
		return null
		
	var def = _definitions[id]
	var data = load("res://core/data_type/card_data.gd").new()
	
	data.id = id
	data.display_name = def["name_key"]
	data.background_color = def["color"]
	data.icon = load(def["icon"])
	data.max_durability = def["max_durability"]
	return data
