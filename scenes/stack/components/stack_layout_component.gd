class_name StackLayoutComponent
extends Node

const VERTICAL_OFFSET: float = Gamesettings.STACK_OFFSET
const BASE_Z_INDEX: int = Gamesettings.STACK_Z_INDEX

var stack # 移除 : CardStack 以避免循环引用

func _init(parent_stack = null): # 移除类型提示
	if parent_stack:
		stack = parent_stack

func _ready():
	if not stack:
		stack = get_parent() as CardStack

## 重新排列所有卡牌的位置并更新碰撞盒
func update_layout():
	if not stack or stack.cards.is_empty():
		return
	
	# 1. 物理对齐与顺序同步
	for i in range(stack.cards.size()):
		var card = stack.cards[i]
		# 确保卡牌是当前Stack的子节点（由于拖拽逻辑可能导致短暂的父子关系滞后，加个校验）
		if card.get_parent() != stack:
			continue
			
		var target_pos = Vector2(0, i * VERTICAL_OFFSET)
		card.position = target_pos
		
		# 同步 Z-Index，确保数组后面的卡片渲染在上面
		card.z_index = i + BASE_Z_INDEX
		
		# 同步场景树子节点顺序
		if card.get_index() != i + 1: # 0是CollisionShape/Components, 卡片从1开始? 或者直接 move_to_back
			stack.move_child(card, i + stack.get_children().size() - stack.cards.size())

	# 2. 动态调整 Stack 的碰撞盒大小
	if stack.collision_shape and stack.collision_shape.shape is RectangleShape2D:
		var first_card = stack.cards[0]
		if not is_instance_valid(first_card) or not first_card.layout: return
		
		var card_size = first_card.layout.size
		var total_height = card_size.y + (stack.cards.size() - 1) * VERTICAL_OFFSET
		
		# 确保资源唯一
		if stack.collision_shape.shape.resource_local_to_scene == false:
			stack.collision_shape.shape = stack.collision_shape.shape.duplicate()
			
		stack.collision_shape.shape.size = Vector2(card_size.x, total_height)
		# 碰撞盒中心点需要向下偏移
		stack.collision_shape.position = Vector2(0, (stack.cards.size() - 1) * VERTICAL_OFFSET / 2.0)


func set_drag_layout():
	if not stack: return
	
	stack.z_index = 1000 # 确保在最上层
	stack.collision_shape.set_deferred("disabled", true) # 禁用碰撞，避免干扰拖拽过程中的鼠标检测

func reset_layout():
	if not stack: return
	
	stack.z_index = BASE_Z_INDEX
	stack.collision_shape.set_deferred("disabled", false) # 恢复碰撞
