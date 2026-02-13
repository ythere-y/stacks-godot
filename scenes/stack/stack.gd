class_name CardStack
extends Area2D

# --- 信号 ---
signal stack_changed # 当堆叠内卡牌增减时触发

# --- 导出与变量 ---
@export var stack_data: StackData = StackData.new()
const vertical_offset: float = Gamesettings.STACK_OFFSET
const card_scene: PackedScene = preload("res://scenes/card/card.tscn") # 预加载卡牌场景以便实例化
const stack_scene: PackedScene = preload("res://scenes/stack/stack.tscn") # 预加载堆叠场景以便实例化
const base_z_index = Gamesettings.STACK_Z_INDEX
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var is_dragging: bool = false
var cards: Array[Card] = []
var velocity: Vector2 = Vector2.ZERO
var drag_offset: Vector2 = Vector2.ZERO
var current_drop_target: CardStack = null # 记录当前拖拽时悬停的目标Stack
var leader_card: Card = null # 记录当前拖拽的领头卡牌（即最初被抓取的那张）
var overlap_candidates: Array[CardStack] = [] # 记录当前与领头卡牌重叠的所有Stack候选列表
func _ready():
	# 确保 Stack 本身能检测碰撞，用于 Stack 之间的合并
	area_entered.connect(_on_area_entered)
	# 如果 stack_data 中已有数据，初始化加载（可选）
	_refresh_cards_from_data()
	# 设置碰撞层级和掩码，确保与 Card 的 Area2D 交互
	collision_shape.set_deferred("disabled", false) # 确保碰撞体启用
	collision_layer = Gamesettings.STACK_COLLISION_LAYER
	collision_mask = Gamesettings.STACK_COLLISION_LAYER | Gamesettings.CARD_COLLISION_LAYER
	# 移除这里的 leader_card 初始化，改为统一在 _refresh_cards_from_data 或 setup 中处理，或者在需要使用时动态获取
	# leader_card = cards[0] if not cards.is_empty() else null
	update_stack_layout()
func _physics_process(delta: float) -> void:
	if is_dragging:
		_update_drag_targets()
	else:
		_process_separation(delta)

func _process_separation(delta: float):
	var separation_speed: float = 100.0 # 分离速度，可调整
	var neighbors = get_overlapping_areas()
	var push_vector = Vector2.ZERO
	var count = 0
	
	for area in neighbors:
		# 仅与其他 Stack 互斥
		# area.is_dragging 的检查是为了防止：当你拖动一个 Stack 试图合并时，地上的 Stack 却因为碰撞检测逃跑了
		if area is CardStack and area != self and not area.is_dragging:
			var direction = global_position - area.global_position
			var dist = direction.length()
			
			# 如果刚好重合，给一个随机方向散开
			if dist < 1.0:
				direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
			else:
				direction = direction.normalized()
			
			push_vector += direction
			count += 1
	
	if count > 0:
		# 这里的 lerp 并非必要，但若是想要惯性可以用 velocity 方式，这里直接位移模拟"挤开"
		global_position += push_vector.normalized() * separation_speed * delta


func _process(delta: float) -> void:
	# 这里可以添加一些堆叠的动态效果，比如轻微的浮动或者根据卡牌数量调整外观
	if is_dragging:
		_process_dragging(delta)
		pass
	if not cards.is_empty() and cards[0] and cards[0].data:
		self.name = cards[0].data.display_name + "_Stack"
	else:
		self.name = "EmptyStack"

# --- 核心公有方法 ---
func setup(data: CardData):
	# 清理旧数据（防止多次调用 setup 导致数据混杂）
	for c in cards:
		c.queue_free()
	cards.clear()
	
	var new_card: Card = card_scene.instantiate()
	# 添加到场景树要在 setup 之前，或者手动传递 stack 引用（如果卡片依赖父节点获取配置）
	add_child(new_card)
	if new_card.has_method("setup"):
		new_card.setup(data)
	
	Log.log_message.emit(Log.LogLevel.DEBUG, "Added card {0}".format([data.display_name]))
	cards.append(new_card)
	#update_stack_layout() # 确保布局和碰撞体更新

## 加入一组卡
func add_cards(card_list: Array[Card]):
	if card_list.is_empty(): return
	
	for card in card_list:
		if not is_instance_valid(card): continue
		
		# 避免重复添加到数组 (如果某些逻辑错误导致重复调用)
		if card not in cards:
			cards.append(card)
			
		if card.get_parent() == self:
			continue # 已经是子节点了，无需 reparent
			
		if card.get_parent():
			card.reparent(self )
		else:
			add_child(card)
	
	update_stack_layout()
	stack_changed.emit()

func remove_cards(card_list: Array[Card]):
	for card in card_list:
		cards.erase(card)
	update_stack_layout()
	stack_changed.emit()
	
	# [修复] 如果移除卡牌后堆叠为空，立即销毁自身
	if cards.is_empty():
		queue_free()

## 获取该堆叠的所有数据，供 RecipeManager 检查
func get_card_data_list() -> Array[Card]:
	var list: Array[Card] = []
	for card in cards:
		list.append(card)
	return list

# --- 内部逻辑 ---

## 重新排列所有卡牌的位置并更新碰撞盒
func update_stack_layout():
	if cards.is_empty():
		return
	
	# [修复] 1. 清理无效实例 (Sanitize)
	# 使用 filter 移除已经释放的卡片引用，防止访问空指针
	var valid_cards: Array[Card] = []
	var need_cleanup = false
	for c in cards:
		if is_instance_valid(c) and c.is_inside_tree() and not c.is_queued_for_deletion():
			valid_cards.append(c)
		else:
			need_cleanup = true
	
	if need_cleanup:
		cards = valid_cards
		if cards.is_empty():
			# [修复] 如果清理后没有卡片了，销毁堆叠
			queue_free()
			return

	# 2. 物理对齐与顺序同步
	for i in range(cards.size()):
		var card = cards[i]
		var target_pos = Vector2(0, i * vertical_offset)
		card.position = target_pos
		
		# [修复] 同步 Z-Index，确保数组后面的卡片渲染在上面
		card.z_index = i + base_z_index
		
		# [修复] 同步场景树子节点顺序 (可选，但推荐)
		# 确保 Godot 内部的事件处理顺序与我们的数组顺序一致
		if card.get_index() != i + 1:
			move_child(card, i + 1)
	
	# 3. 动态调整 Stack 的碰撞盒大小
	# 假设卡牌高度来自第一个卡牌的 layout 大小
	if collision_shape.shape is RectangleShape2D:
		var card_size = cards[0].layout.size
		var total_height = card_size.y + (cards.size() - 1) * vertical_offset
		# 为了使碰撞体唯一，需要duplicate()
		if collision_shape.shape.resource_local_to_scene == false:
			collision_shape.shape = collision_shape.shape.duplicate()
			
		collision_shape.shape.size = Vector2(card_size.x, total_height)
		# 碰撞盒中心点需要向下偏移
		collision_shape.position = Vector2(0, (cards.size() - 1) * vertical_offset / 2.0)

func split_stack(card_list: Array[Card]) -> CardStack:
	# 从当前堆叠中分离出 card 以及它上方的所有卡牌，形成一个新的堆叠
	if card_list.is_empty():
		return null

	var new_stack: CardStack = stack_scene.instantiate()
	new_stack._ready() # 这行其实可以去掉，instantiate 后 add_child会自动调用，手动调可能重复
	new_stack.name = "SplitStack"
	
	# [关键修复] 计算新 Stack 的合理初始位置
	# 我们希望新 Stack 的原点 (0,0) 对应第一张卡片的当前视觉位置
	# 这样当卡片被 reparent 进去并重置为 (0,0) 时，视觉上不会跳变
	if not card_list.is_empty():
		new_stack.global_position = card_list[0].global_position

	var stay_cards: Array[Card] = []
	var move_cards: Array[Card] = []
	for card in cards:
		if card in card_list:
			move_cards.append(card)
		else:
			stay_cards.append(card)
	cards = stay_cards
	
	# 将新 stack 加到当前 stack 的同级（即 Board/StacksContainer）
	if get_parent():
		get_parent().add_child(new_stack)
	
	new_stack.add_cards(move_cards)
	
	self.update_stack_layout()
	
	stack_changed.emit()
	
	# [修复] 如果分裂后原堆叠为空，销毁原堆叠
	# 注意：new_stack 已经被返回并在外部使用，原堆叠的使命结束
	if cards.is_empty():
		queue_free()
		
	return new_stack

## 处理 Stack 与 Stack 之间的碰撞交互
func _on_area_entered(other_area: Area2D):
	if other_area is Card:
		pass
	elif other_area is CardStack:
		# If this stack is dragged, we ignore collision here as drop logic handles merge
		# If this stack is stationary, we might highlight it as a drop target
		pass

func _handle_stack_merge(other_stack: CardStack):
	self.add_cards(other_stack.cards)
	if get_parent():
		get_parent().move_child(self , get_parent().get_child_count())

func _refresh_cards_from_data():
	# 根据初始化数据生成 Card 节点的逻辑
	pass

## 处理stack拖拽逻辑
func start_drag_from_card(target_card: Card, single: bool = false):
	# 这里的逻辑是：如果 single 是 true，那么只拖动 target_card；否则拖动 target_card 以及它上面的所有卡牌
	var index = cards.find(target_card)
	if index == -1:
		return # 卡牌不在这个堆叠中
	
	var cards_to_drag: Array[Card] = []
	if single:
		cards_to_drag.append(target_card)
	else:
		cards_to_drag = cards.slice(index, cards.size())
	return self.split_stack(cards_to_drag)
func start_drag():
	is_dragging = true
	# 每次开始拖拽时重新获取 leader_card，因为卡片列表可能变化
	if cards.is_empty():
		push_error("Try to drag empty stack")
		return

	leader_card = cards[0]
	# Polling logic replaces signal connections
	# leader_card.collision_mask = Gamesettings.STACK_COLLISION_LAYER 
	# if not leader_card.area_entered.is_connected(_on_lead_card_hit_stack):
	# 	leader_card.area_entered.connect(_on_lead_card_hit_stack)
	# if not leader_card.area_exited.is_connected(_on_lead_card_exit_stack):
	# 	leader_card.area_exited.connect(_on_lead_card_exit_stack)

func _update_drag_targets():
	# 使用物理查询代替信号来实时检测最佳堆叠目标
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	# 使用鼠标位置或领头卡片中心作为探测点
	query.position = get_global_mouse_position()
	query.collide_with_areas = true
	query.collide_with_bodies = false
	# 只检测 Stack 层
	query.collision_mask = Gamesettings.STACK_COLLISION_LAYER
	
	var results = space_state.intersect_point(query, 32)
	var candidates: Array[CardStack] = []
	
	for res in results:
		var s = res.collider
		# 排除自己
		if s is CardStack and s != self:
			candidates.append(s)
	
	_update_drop_candidate(candidates)

func _update_drop_candidate(candidates: Array[CardStack]):
	candidates = candidates.filter(func(s): return is_instance_valid(s))
	
	var new_target: CardStack = null
	if candidates.is_empty():
		new_target = null
	else:
		new_target = candidates.reduce(func(best, current):
			if best.get_layout_score() < current.get_layout_score():
				return current
			return best
		)
	
	if new_target != current_drop_target:
		# Log.info("Get new target from {0} to {1}".format([current_drop_target.name if current_drop_target else "null", new_target.name if new_target else "null"]))
		if is_instance_valid(current_drop_target):
			current_drop_target.set_highlight(false)
		if is_instance_valid(new_target):
			new_target.set_highlight(true)
		current_drop_target = new_target

# Deprecated signal handlers
func _on_lead_card_exit_stack(other_area: Area2D):
	pass
func _on_lead_card_hit_stack(other_area: Area2D):
	pass
## 处理dragging
func _process_dragging(delta: float):
	var mouse_pos = get_global_mouse_position()
	var target_pos = mouse_pos
	if drag_offset != Vector2.ZERO:
		target_pos += drag_offset

	global_position = global_position.lerp(target_pos, 25 * delta)

func get_layout_score() -> Array[int]:
	var stack_z = self.z_index
	var stack_idx = get_index()
	return [stack_z, stack_idx]

func set_highlight(active: bool):
	# Stack的高亮即高亮其拥有的所有卡片(或仅顶部卡片，视需求而定)
	for card in cards:
		if card.has_method("set_highlight"):
			card.set_highlight(active)

func end_drag():
	# 结束拖动，重置状态
	is_dragging = false
	velocity = Vector2.ZERO
	drag_offset = Vector2.ZERO
	# leader_card.collision_mask = Gamesettings.CARD_COLLISION_LAYER # 不再需要修改掩码
	# Signals are no longer connected
	# if leader_card.area_entered.is_connected(_on_lead_card_hit_stack):
	# 	leader_card.area_entered.disconnect(_on_lead_card_hit_stack)
	# if leader_card.area_exited.is_connected(_on_lead_card_exit_stack):
	# 	leader_card.area_exited.disconnect(_on_lead_card_exit_stack)

	# 可以直接使用 update_drop_target 中找到的 current_drop_target
	var target_stack: CardStack = current_drop_target
	
	if target_stack and is_instance_valid(target_stack):
		target_stack.set_highlight(false)
		target_stack._handle_stack_merge(self )
		current_drop_target = null
		queue_free()
	else:
		# 空地放置	
		self.name = cards[0].data.display_name + "_Stack" if not cards.is_empty() else "EmptyStack"
		self.z_index = 0 + base_z_index
		pass
	
	SignalBus.card_drag_ended.emit(self )

func sort_from_card(target_card: Card):
	if is_dragging: return # 拖拽中禁止排序
	
	var index = cards.find(target_card)
	if index == -1: return

	# 获取需要排序的卡牌片段
	var sort_slice = cards.slice(index, cards.size())
	if sort_slice.is_empty(): return
	
	# 自定义排序逻辑：优先按 Type 排序，其次按 ID 排序
	sort_slice.sort_custom(func(a, b):
		if not a.data or not b.data:
			return false
			
		# 如果都有 data，先按类型排序
		if a.data.type != b.data.type:
			return a.data.type < b.data.type
			
		# 类型相同则按 ID 排序
		return a.data.id < b.data.id
	)
	
	# 将排好序的片段放回原数组
	for i in range(sort_slice.size()):
		cards[index + i] = sort_slice[i]
	
	# 更新视觉布局
	update_stack_layout()
	stack_changed.emit()
