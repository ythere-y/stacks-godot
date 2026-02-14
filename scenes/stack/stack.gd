class_name CardStack
extends Area2D

#region Configuration
signal stack_changed

const vertical_offset: float = Gamesettings.STACK_OFFSET
const card_scene: PackedScene = preload("res://scenes/card/card.tscn")
const stack_scene: PackedScene = preload("res://scenes/stack/stack.tscn")

@export var stack_data: StackData = StackData.new()
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

# 组件引用
var layout_component: StackLayoutComponent
var movement_component: StackMovementComponent
var interaction_component: StackInteractionComponent
var work_component: StackWorkComponent

# 状态
var is_dragging: bool = false
var cards: Array[Card] = []
var drag_offset: Vector2 = Vector2.ZERO
var init_cards: Array[CardData] = []
#endregion

#region Lifecycle
func setup(card_list: Array[CardData]):
	init_cards = card_list
	
func _ready():
	# 初始化组件
	layout_component = StackLayoutComponent.new(self )
	movement_component = StackMovementComponent.new(self )
	interaction_component = StackInteractionComponent.new(self )
	# 将 wrok_component 设为子节点，以便它能接收 _process 处理时间
	work_component = StackWorkComponent.new(self )
	
	add_child(layout_component)
	add_child(movement_component)
	add_child(interaction_component)
	add_child(work_component)
	
	area_entered.connect(_on_area_entered)
	_refresh_cards_from_data()
	
	collision_shape.set_deferred("disabled", false)
	collision_layer = Gamesettings.STACK_COLLISION_LAYER
	collision_mask = Gamesettings.STACK_COLLISION_LAYER | Gamesettings.CARD_COLLISION_LAYER
	name = cards[0].data.display_name + "_Stack" if not cards.is_empty() else "EmptyStack"
	layout_component.update_layout()

func _physics_process(delta: float) -> void:
	# 委托给组件
	if is_dragging:
		interaction_component.update_drag_targets()
		_process_dragging(delta)
	else:
		movement_component.process_physics(delta)

func _process_dragging(delta: float):
	var mouse_pos = get_global_mouse_position()
	var target_pos = mouse_pos
	if drag_offset != Vector2.ZERO:
		target_pos += drag_offset
	global_position = global_position.lerp(target_pos, 25 * delta)
#endregion

#region Card Management
func add_cards(card_list: Array[Card]):
	if card_list.is_empty(): return
	for card in card_list:
		if not is_instance_valid(card): continue
		if card not in cards:
			cards.append(card)
		if card.get_parent() != self:
			if card.get_parent():
				card.reparent(self )
			else:
				add_child(card)
	
	layout_component.update_layout()
	stack_changed.emit()

func remove_cards(card_list: Array[Card]):
	for card in card_list:
		cards.erase(card)
	
	layout_component.update_layout()
	stack_changed.emit()
	
	if cards.is_empty():
		queue_free()

func split_stack(card_list: Array[Card]) -> CardStack:
	if card_list.is_empty(): return null

	var new_stack: CardStack = stack_scene.instantiate()
	# 手动 Ready 确保组件加载? instantiate 会自动调 ready，通常不需要。
	new_stack.name = "SplitStack"
	
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
	
	if get_parent():
		get_parent().add_child(new_stack)
	
	new_stack.add_cards(move_cards)
	
	layout_component.update_layout()
	stack_changed.emit()
	
	if cards.is_empty():
		queue_free()
		
	return new_stack

func _handle_stack_merge(other_stack: CardStack):
	self.add_cards(other_stack.cards)
	if get_parent():
		get_parent().move_child(self , get_parent().get_child_count())

func start_drag_from_card(target_card: Card, single: bool = false):
	var index = cards.find(target_card)
	if index == -1: return
	
	var cards_to_drag: Array[Card] = []
	if single:
		cards_to_drag.append(target_card)
	else:
		cards_to_drag = cards.slice(index, cards.size())
	return self.split_stack(cards_to_drag)

func start_drag():
	is_dragging = true
	layout_component.set_drag_layout()

func end_drag():
	is_dragging = false
	layout_component.reset_layout()
	var target_stack: CardStack = null
	
	# [修复] 安全地检查引用有效性，防止"Trying to assign invalid previously freed instance"
	if is_instance_valid(interaction_component.current_drop_target):
		target_stack = interaction_component.current_drop_target
	
	if target_stack:
		interaction_component.clear_targets() # 清除高亮
		target_stack._handle_stack_merge(self )
		queue_free()
	else:
		# 放置在空地
		if interaction_component:
			interaction_component.clear_targets()
		if not cards.is_empty():
			self.name = cards[0].data.display_name + "_Stack"
			# 确保 Z-index 回归
			layout_component.update_layout()
	
	SignalBus.card_drag_ended.emit(self )
#endregion

#region Helpers
func _on_area_entered(other_area: Area2D):
	pass # 保留作为扩展点

func set_highlight(active: bool):
	interaction_component.check_highlight(active)

func get_layout_score() -> Array[int]:
	return [ self.z_index, get_index()]

func sort_from_card(target_card: Card):
	if is_dragging: return
	var index = cards.find(target_card)
	if index == -1: return
	var sort_slice = cards.slice(index, cards.size())
	
	sort_slice.sort_custom(func(a, b):
		if not a.data or not b.data: return false
		if a.data.type != b.data.type: return a.data.type < b.data.type
		return a.data.id < b.data.id
	)
	
	for i in range(sort_slice.size()):
		cards[index + i] = sort_slice[i]
	
	layout_component.update_layout()
	stack_changed.emit()

func _refresh_cards_from_data():
	for card_data in init_cards:
		var card: Card = card_scene.instantiate()
		card.setup(card_data)
		add_child(card)
		cards.append(card)

#endregion
