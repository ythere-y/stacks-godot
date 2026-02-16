class_name StackMovementComponent
extends Node

const SEPARATION_SPEED: float = 100.0
var stack # 移除 : CardStack 以避免循环引用

func _init(parent_stack = null):
	if parent_stack:
		stack = parent_stack

func _ready():
	if not stack:
		stack = get_parent() as CardStack

func process_physics(delta: float):
	if not stack or stack.interaction_component.is_dragging: return
	
	var neighbors = stack.get_overlapping_areas()
	var push_vector = Vector2.ZERO
	var count = 0
	
	for area in neighbors:
		# 仅与其他 Stack 互斥
		if area is CardStack and area != stack and not area.interaction_component.is_dragging:
			var direction = stack.global_position - area.global_position
			var dist = direction.length()
			
			# 如果刚好重合，给一个随机方向散开
			if dist < 1.0:
				direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
			else:
				direction = direction.normalized()
			
			push_vector += direction
			count += 1
	
	if count > 0:
		stack.global_position += push_vector.normalized() * SEPARATION_SPEED * delta
