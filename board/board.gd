class_name GameBoard
extends Node2D

const CardDataRes = preload("res://cards/card_data.gd")

@export var card_scene: PackedScene

# Container for all cards in play
@onready var cards_container = $CardsContainer

func _ready():
	# 确保 CardLibrary 已经加载了 CSV
	CardLibrary.load_library()
	
	print("GameBoard _ready executing...")
	if not card_scene:
		print("Card scene not assigned, attempting to load...")
		card_scene = load("res://cards/card.tscn")
		
	if card_scene:
		print("Card scene is valid. Spawning cards.")
		_spawn_all_types_and_random()
	else:
		print("CRITICAL ERROR: Could not load card scene!")
		push_error("Card scene is NOT assigned in GameBoard!")

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
