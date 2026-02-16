class_name StackInteractionComponent
extends Node

var stack
var current_drop_target = null
var is_dragging: bool = false

func _init(parent_stack = null):
	if parent_stack:
		stack = parent_stack

func _ready():
	if not stack:
		stack = get_parent() as CardStack

func update_drag_targets():
	if not stack: return
	
	var space_state = stack.get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = stack.get_global_mouse_position()
	query.collide_with_areas = true
	query.collide_with_bodies = false
	query.collision_mask = Gamesettings.STACK_COLLISION_LAYER
	
	var results = space_state.intersect_point(query, 32)
	var candidates: Array[CardStack] = []
	
	for res in results:
		var s = res.collider
		# 排除自己
		if s is CardStack and s != stack:
			candidates.append(s)
	
	_update_drop_candidate(candidates)
	
func _valid_stack_for_drag(target_stack: CardStack) -> bool:
	if not is_instance_valid(target_stack):
		return false
	
	if target_stack == stack:
		return false
	
	if target_stack.battle_component.is_battling:
		if not self.stack.cards[0].data is UnitCardData:
			return false
	return true
func _update_drop_candidate(candidates: Array[CardStack]):
	candidates = candidates.filter(_valid_stack_for_drag)
	
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
		if is_instance_valid(current_drop_target):
			current_drop_target.set_highlight(false)
		if is_instance_valid(new_target):
			new_target.set_highlight(true)
		current_drop_target = new_target

func clear_targets():
	if is_instance_valid(current_drop_target):
		current_drop_target.set_highlight(false)
	current_drop_target = null

func check_highlight(active: bool):
	if not stack: return
	for card in stack.cards:
		if card.has_method("set_highlight"):
			card.set_highlight(active)
