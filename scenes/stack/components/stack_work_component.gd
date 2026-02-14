class_name StackWorkComponent
extends Node

signal work_finished(outputs: Array, pos: Vector2)

var stack # 移除 : CardStack 以避免循环引用
var current_recipe: Dictionary = {}
var work_timer: float = 0.0
var is_working: bool = false
var progress_bar_owner: Card = null # 负责显示进度条的卡牌

func _init(parent_stack = null):
	if parent_stack:
		stack = parent_stack

func _ready():
	if not stack:
		stack = get_parent() as CardStack

	# 监听 Stack 变化，每次变动都重置并重新检查配方
	if stack:
		stack.stack_changed.connect(_on_stack_changed)

func _process(delta: float):
	if not is_working or current_recipe.is_empty():
		return
	
	work_timer += delta
	var duration = current_recipe.get("time", 5.0)
	
	# 更新进度条
	if is_instance_valid(progress_bar_owner):
		var percent = (work_timer / duration) * 100.0
		progress_bar_owner.update_progress(percent)
	
	if work_timer >= duration:
		_complete_work()
func _check_recipe_valid(recipe: Dictionary) -> bool:
	if stack.cards.is_empty():
		return false
	# 1. 收集所有卡片ID
	var card_ids_map: Dictionary = {}
	for card in stack.cards:
		if not card.data: continue
		if card.current_durability <= 0: continue # 跳过已损坏
		var id = card.data.id
		if card_ids_map.has(id):
			card_ids_map[id] += 1
		else:
			card_ids_map[id] = 1
	# 2. 检查配方要求
	var inputs = recipe.get("inputs", {})
	for id in inputs:
		if card_ids_map.get(id, 0) < inputs[id].get("num", 1):
			return false

	return true
func _on_stack_changed():
	# 如果有正在进行的工作，检测当前stack是否满足配方要求，如果不满足则打断工作
	if current_recipe.is_empty():
		_check_recipe() # 没有正在进行的工作，直接检查是否能开始新工作
	else:
		if not _check_recipe_valid(current_recipe):
			_stop_work() # 任何变动都打断当前工作
			_check_recipe()
		else:
			pass
func _check_recipe():
	if stack.cards.is_empty():
		return
	
	# 1. 收集所有卡片ID
	var card_ids_map: Dictionary = {}
	for card in stack.cards:
		if not card.data: continue
		if card.current_durability <= 0: continue # 跳过已损坏的卡牌
		var id = card.data.id
		if card_ids_map.has(id):
			card_ids_map[id] += 1
		else:
			card_ids_map[id] = 1
	
	# 2. 查询配方管理器
	var recipe = RecipeManager.find_matching_recipe(card_ids_map)
	
	if not recipe.is_empty():
		_start_work(recipe)

func _start_work(recipe: Dictionary):
	current_recipe = recipe
	is_working = true
	work_timer = 0.0
	
	# 通常进度条显示在第一张卡上
	if not stack.cards.is_empty():
		progress_bar_owner = stack.cards[0]
		progress_bar_owner.show_progress(true)
	
	Log.info("Stack started work on recipe: ", recipe.get("id"))

func _stop_work():
	is_working = false
	current_recipe = {}
	work_timer = 0.0
	if is_instance_valid(progress_bar_owner):
		progress_bar_owner.show_progress(false)
		progress_bar_owner.update_progress(0)
	progress_bar_owner = null

func _complete_work():
	Log.info("Work completed!")
	var outputs = current_recipe.get("outputs", []).duplicate()
	var inputs = current_recipe.get("inputs", {})
	
	# 1. 消耗材料 (从后往前删，避免索引问题)
	# 注意：这是简单的消耗逻辑，如果 inputs 需要特定卡片，需要更复杂的匹配
	var temp_cards = stack.cards.duplicate()
	var cards_to_hit: Array[Card] = []
	var to_consume: Array[Card] = []
	
	# 对于配方所需的每个输入 ID
	for input_id in inputs:
		var count_needed = inputs[input_id].get("num", 1)
		for i in range(temp_cards.size() - 1, -1, -1):
			var card = temp_cards[i]
			if count_needed <= 0: break
			if card.data and card.data.id == input_id and not card in to_consume:
				cards_to_hit.append(card) # 先记录需要被击打的卡牌
				temp_cards.remove_at(i) # 从临时列表中移除，避免重复匹配
				count_needed -= 1
		
	# 2. 对选中的卡牌执行扣血
	for c in cards_to_hit:
		if is_instance_valid(c):
			var consume_damage: int = inputs[c.data.id].get("consume", 1)
			c.take_damage(consume_damage)
	_stop_work()
	
	# 3. 通知 Board 生成产物
	# 产物生成位置通常在当前 Stack 旁边
	var spawn_pos = stack.global_position + Vector2(50, 0)
	SignalBus.card_spawn_requested.emit(outputs, spawn_pos)
	SignalBus.stack_work_finished.emit(outputs, spawn_pos)

	# 完成后，如果 Stack 中卡牌已空，自动销毁 Stack
	if stack.cards.is_empty():
		stack.queue_free()
	else:
		# 如果还有卡牌，重新检查是否能继续工作（例如有些配方可能允许部分材料继续生产）
		_check_recipe()
