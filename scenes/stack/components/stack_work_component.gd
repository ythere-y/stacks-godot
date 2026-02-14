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
	if not is_working or current_recipe.is_empty() or stack.is_dragging:
		return
	
	work_timer += delta
	var duration = current_recipe.get("time", 5.0)
	
	# 更新进度条
	if is_instance_valid(progress_bar_owner):
		var percent = (work_timer / duration) * 100.0
		progress_bar_owner.update_progress(percent)
	
	if work_timer >= duration:
		_complete_work()

func _on_stack_changed():
	_stop_work() # 任何变动都打断当前工作
	_check_recipe()

func _check_recipe():
	if stack.cards.is_empty(): return
	
	# 1. 收集所有卡片ID
	var location_ids: Dictionary = {}
	for card in stack.cards:
		if not card.data: continue
		var id = card.data.id
		if location_ids.has(id):
			location_ids[id] += 1
		else:
			location_ids[id] = 1
	
	# 2. 查询配方管理器
	var recipe = RecipeManager.find_matching_recipe(location_ids)
	
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
	
	print("Stack started work on recipe: ", recipe.get("id"))

func _stop_work():
	is_working = false
	current_recipe = {}
	work_timer = 0.0
	if is_instance_valid(progress_bar_owner):
		progress_bar_owner.show_progress(false)
		progress_bar_owner.update_progress(0)
	progress_bar_owner = null

func _complete_work():
	print("Work completed!")
	var outputs = current_recipe.get("outputs", []).duplicate()
	var inputs = current_recipe.get("inputs", {})
	var pos = stack.global_position
	
	# 1. 消耗材料 (从后往前删，避免索引问题)
	# 注意：这是简单的消耗逻辑，如果 inputs 需要特定卡片，需要更复杂的匹配
	var temp_cards = stack.cards.duplicate()
	var to_consume: Array[Card] = []
	
	# 对于配方所需的每个输入 ID
	for input_id in inputs:
		var count_needed = inputs[input_id]
		# 在当前堆叠里找对应数量的卡片
		for card in temp_cards:
			if count_needed <= 0: break
			if card.data and card.data.id == input_id and not card in to_consume:
				to_consume.append(card)
				count_needed -= 1
	
	# 2. 从 Stack 移除并销毁
	if not to_consume.is_empty():
		stack.remove_cards(to_consume) # 先从逻辑移除
		for c in to_consume:
			c.queue_free() # 再物理销毁
	
	_stop_work()
	
	# 3. 通知 Board 生成产物
	# 产物生成位置通常在当前 Stack 旁边
	SignalBus.card_spawn_requested.emit(outputs, pos + Vector2(50, 0))
