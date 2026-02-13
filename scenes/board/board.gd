class_name GameBoard
extends Node2D

const CardDataRes = preload("uid://coxctgrbhcok5")

@export var card_scene: PackedScene

var _hover_candidates: Array[Card] = []
var _current_focus: Node = null

# Container for all cards in play
@onready var cards_container = $CardsContainer

func _ready():
	# 确保 CardLibrary 已经加载了 CSV
	CardLibrary.load_library()
	
	_connect_signals()
	if not card_scene:
		print("Card scene not assigned, attempting to load...")
		card_scene = load("res://scenes/card/card.tscn") # 旧路径，确保向后兼容
		
	if card_scene:
		_spawn_all_types_and_random()
	else:
		push_error("Card scene is NOT assigned in GameBoard!")
# -- 信号连接中心 --
func _connect_signals():
	# 连接生产完成信号
	SignalBus.card_spawn_requested.connect(_on_card_production_complete)

	# 悬停管理信号
	SignalBus.card_hovered.connect(_on_card_hovered)
	SignalBus.card_unhovered.connect(_on_card_unhovered)

# -- 悬停焦点仲裁逻辑 --

func _on_card_hovered(card: Card):
	if not _hover_candidates.has(card):
		_hover_candidates.append(card)
	_update_hover_focus()
func _on_card_unhovered(card: Card):
	if _hover_candidates.has(card):
		_hover_candidates.erase(card)
	_update_hover_focus()
func _update_hover_focus():
	var winner = _find_top_card(_hover_candidates)

	if _current_focus != winner:
		# 让旧的焦点取消高亮
		if is_instance_valid(_current_focus) and _current_focus.has_method("set_highlight"):
			_current_focus.set_highlight(false)
		
		# 让新的焦点开启高亮
		_current_focus = winner
		if is_instance_valid(_current_focus) and _current_focus.has_method("set_highlight"):
			_current_focus.set_highlight(true)
func _find_top_card(list: Array) -> Node:
	var top_node: Node = null
	for c in list:
		if not is_instance_valid(c): continue
		
		if top_node == null:
			top_node = c
			continue
		
		# 判定标准 1: Z-Index 更大的在上面
		if c.z_index > top_node.z_index:
			top_node = c
		# 判定标准 2: Z-Index 相同时，在场景树中更靠后的节点渲染在更上面
		elif c.z_index == top_node.z_index:
			if c.get_index() > top_node.get_index():
				top_node = c
	return top_node
## 核心逻辑修改：保证全种类 + 随机生成
func _spawn_all_types_and_random():
	# 1. 获取库中所有的 ID
	var all_ids = CardLibrary.get_all_card_ids()
	if all_ids.is_empty():
		print("Warning: CardLibrary is empty!")
		return

	var screen_size = get_viewport_rect().size
	
	# 2. 保证每种卡片至少有一张
	for id in all_ids:
		var data = CardLibrary.create_data(id)
		var pos = _get_random_screen_pos(screen_size)
		spawn_card(id, pos, data)
	
	# 3. 再额外生成一些随机卡片（比如生成 10 张随机的）
	var extra_cards_count = 10
	for i in range(extra_cards_count):
		var id = all_ids.pick_random()
		var data = CardLibrary.create_data(id)
		var pos = _get_random_screen_pos(screen_size)
		spawn_card(id, pos, data)

## 辅助函数：获取随机位置
func _get_random_screen_pos(screen_size: Vector2) -> Vector2:
	return Vector2(
		randf_range(100, screen_size.x - 100),
		randf_range(100, screen_size.y - 100)
	)

func spawn_card(card_id: String, pos: Vector2, data: Resource = null):
	var new_card = card_scene.instantiate()
	
	# 如果没传 data，则现场从库里建一个（兼容生产系统）
	if data == null:
		data = CardLibrary.create_data(card_id)
	
	if data and new_card.has_method("setup"):
		new_card.setup(data)
		
	new_card.global_position = pos
	cards_container.add_child(new_card)
	print("Spawned card: ", card_id)

func _on_card_production_complete(output_ids: Array, pos: Vector2):
	for id in output_ids:
		var random_offset = Vector2(randf_range(-20, 20), randf_range(-20, 20))
		spawn_card(id, pos + random_offset)
