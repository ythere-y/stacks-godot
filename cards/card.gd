class_name Card
extends Area2D

# ------------------------------------------------------------------------------
# Constants & Signals
# ------------------------------------------------------------------------------
const SNAP_DISTANCE := 60.0
const STACK_OFFSET := 45.0 # Increased from 25.0 to 45.0 for better visibility

# Physics for "Snake/Trail" effect
const FOLLOW_SPEED := 15.0 # Higher = tighter, Lower = more loose/trail

signal drag_started(card)
signal drag_ended(card)

# ------------------------------------------------------------------------------
# Exports & Nodes
# ------------------------------------------------------------------------------
@export var data: Resource

@onready var sprite: Sprite2D = $Sprite2D
@onready var label: Label = $Label
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var background: Polygon2D = $Background
@onready var highlight: Line2D = $Highlight

# ------------------------------------------------------------------------------
# State Variables
# ------------------------------------------------------------------------------
# Robust Hover Logic: Maintain a list of ALL cards currently under the mouse.
static var _hover_candidates: Array[Card] = []
static var hovered_card: Card = null

var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var hover_target: Card = null

# Linked List Structure for Stacks
var card_below: Card = null
var card_above: Card = null

# Target position for snake movement (smooth following)
var _target_pos: Vector2 = Vector2.ZERO
var _detached_parent: Card = null # Logic to restore stack if drag is interrupted (e.g. by sorting)

# ------------------------------------------------------------------------------
# Lifecycle
# ------------------------------------------------------------------------------
func _ready():
	_update_visuals()
	_target_pos = global_position
	
	input_event.connect(_on_input_event)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func setup(new_data: Resource):
	data = new_data
	_update_visuals()

func _update_visuals():
	if data:
		if label: label.text = data.get("display_name")
		if sprite: sprite.texture = data.get("icon")
		if background: background.color = data.get("background_color")

func _process(delta):
	if is_dragging:
		_process_dragging(delta)
	else:
		# If we have a parent, we want to follow it with lag (snake effect)
		if card_below:
			_target_pos = card_below.global_position + Vector2(0, STACK_OFFSET)
			# Do the lerp
			if global_position.distance_squared_to(_target_pos) > 1.0:
				global_position = global_position.lerp(_target_pos, delta * FOLLOW_SPEED)
			else:
				global_position = _target_pos
			
			# Propagate z-index implicitly or via checks? 
			# Reflow logic usually handles Z, but let's ensure it here just is case
			if z_index != card_below.z_index + 1:
				z_index = card_below.z_index + 1

# ------------------------------------------------------------------------------
# Input Handling (Refined Robustness)
# ------------------------------------------------------------------------------
func _on_input_event(viewport, event, _shape_idx):
	if event is InputEventMouseButton:
		# Double Click: Auto Sort/Categorize Stack
		if event.button_index == MOUSE_BUTTON_LEFT and event.double_click:
			if Card.hovered_card == self:
				_sort_stack_logic()
				viewport.set_input_as_handled()
				return # Don't start drag on double click

		# Left Click: Drag
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if Card.hovered_card == self:
				start_drag()
				viewport.set_input_as_handled()
				
		# Right Click: Extract Single Card
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if Card.hovered_card == self:
				start_drag(true) # Pass true for "extract single"
				viewport.set_input_as_handled()

func _input(event):
	if is_dragging and event is InputEventMouseButton and not event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			end_drag()
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			end_drag()
			get_viewport().set_input_as_handled()

func _on_mouse_entered():
	if not Card._hover_candidates.has(self):
		Card._hover_candidates.append(self)
	_recalculate_global_hover()

func _on_mouse_exited():
	if Card._hover_candidates.has(self):
		Card._hover_candidates.erase(self)
	_recalculate_global_hover()

static func _recalculate_global_hover():
	# Find the best candidate from the list
	var winner: Card = null
	
	if _hover_candidates.size() > 0:
		winner = _hover_candidates[0]
		for c in _hover_candidates:
			# Priority: Higher Z-Index > Higher Tree Index
			if c.is_visually_above(winner):
				winner = c
	
	# Update state
	if hovered_card != winner:
		# Deactivate old
		if hovered_card and is_instance_valid(hovered_card):
			hovered_card._set_hover_scale(false)
		
		# Activate new
		hovered_card = winner
		if hovered_card:
			hovered_card._set_hover_scale(true)

func is_visually_above(other: Card) -> bool:
	if self.z_index > other.z_index: return true
	if self.z_index < other.z_index: return false
	return self.get_index() > other.get_index()

func _set_hover_scale(active: bool):
	if is_dragging: return
	
	var target_scale = Vector2(1.05, 1.05) if active else Vector2(1.0, 1.0)
	var tween = create_tween()
	tween.tween_property(self, "scale", target_scale, 0.1)

# ------------------------------------------------------------------------------
# Dragging Logic
# ------------------------------------------------------------------------------
func start_drag(extract_single: bool = false):
	is_dragging = true
	drag_offset = get_global_mouse_position() - global_position
	
	_set_z_index_recursive(100)
	move_to_front()
	
	if not extract_single:
		_animate_stack_scale(true)
	else:
		_set_hover_scale(true)
	
	emit_signal("drag_started", self)
	
	if card_below:
		var parent = card_below
		_detached_parent = parent # Remember who we detached from
		var old_root = parent.get_stack_root()
		
		# Right Click Logic: Bridge elements
		if extract_single:
			if card_above:
				parent.card_above = card_above
				card_above.card_below = parent
				# Force immediate visual snap of the gap for better feedback
				card_above._target_pos = parent.global_position + Vector2(0, STACK_OFFSET)
				_reflow_stack_logic(old_root, false)
			else:
				parent.card_above = null
			
			card_below = null
			card_above = null
		else:
			# Normal Logic
			parent.card_above = null
			card_below = null
			_reflow_stack_logic(old_root, false)
			
	else:
		_detached_parent = null
		# Root Logic
		if extract_single and card_above:
			var new_root = card_above
			new_root.card_below = null
			new_root.z_index = 0
			_reflow_stack_logic(new_root, false)
			card_above = null
	
	_reflow_stack_logic(self)
	_reorder_tree_recursive(self)

func _sort_stack_logic():
	# 0. Handle Active Drag Interaction
	var restore_parent: Card = null
	
	if is_dragging:
		# Cancel the drag immediately
		is_dragging = false
		_animate_stack_scale(false)
		
		# If we just detached from someone, try to re-attach
		if _detached_parent and is_instance_valid(_detached_parent) and _detached_parent.card_above == null:
			restore_parent = _detached_parent
		
		# Reset internal detached tracker
		_detached_parent = null
	else:
		restore_parent = self.card_below
	
	# 1. Collect all cards in this substack
	var stack_list: Array[Card] = []
	var current = self
	
	# Capture valid base position for root stacks
	var old_base_pos = global_position
	
	while current:
		stack_list.append(current)
		current = current.card_above
		
	if stack_list.size() < 2: return # Nothing to sort
	
	# 2. Sort by ID (or Display Name)
	stack_list.sort_custom(func(a, b): return a.data.id < b.data.id)
	
	# 3. Re-link them
	var root = stack_list[0]
	root.card_below = restore_parent # Connect to the restored parent
	
	if root.card_below:
		root.card_below.card_above = root
		
	for i in range(stack_list.size()):
		var c = stack_list[i]
		if i > 0:
			c.card_below = stack_list[i - 1]
			stack_list[i - 1].card_above = c
			
		if i == stack_list.size() - 1:
			c.card_above = null
			
	# 4. Reflow
	# If I have a parent (restored or original), reflow from absolute root
	if root.card_below:
		_reflow_stack_logic(root.get_stack_root(), true) # True for hard snap
	else:
		# If I am the new root (on ground), snap to the old position
		root.global_position = old_base_pos
		root._target_pos = old_base_pos
		_reflow_stack_logic(root, true)

func end_drag():
	is_dragging = false
	_detached_parent = null # Clear history on successful drop
	_animate_stack_scale(false)
	
	if hover_target:
		hover_target._set_highlight(false)
		hover_target = null
	
	emit_signal("drag_ended", self)
	_try_stack_on_nearest()

func _process_dragging(delta):
	# Leader moves instantly
	global_position = get_global_mouse_position() - drag_offset
	
	# Children follow via _process() logic (they have card_below = me), 
	# but we need to ensure their logic runs. Since _process runs on everyone, 
	# the children will automatically verify 'card_below' and lerp towards me.
	# We just need to check for Drop Targets here.
	_update_drop_target()

func _animate_stack_scale(dragging: bool):
	var s = Vector2(1.1, 1.1) if dragging else Vector2(1.0, 1.0)
	var current = self
	while current:
		var tween = create_tween()
		tween.tween_property(current, "scale", s, 0.1)
		current = current.card_above

# ------------------------------------------------------------------------------
# Stacking Logic
# ------------------------------------------------------------------------------
func _update_drop_target():
	var new_target = _find_valid_stack_target()
	if new_target != hover_target:
		if hover_target: hover_target._set_highlight(false)
		hover_target = new_target
		if hover_target: hover_target._set_highlight(true)

func _find_valid_stack_target() -> Card:
	var areas = get_overlapping_areas()
	var best_target: Card = null
	# Increase search text radius slightly to make snapping feel magnetic
	var min_dist = SNAP_DISTANCE + 20.0
	
	for area in areas:
		if not (area is Card) or area == self: continue
		if _is_in_my_stack(area): continue
		
		var dist = global_position.distance_to(area.global_position)
		if dist < min_dist:
			min_dist = dist
			best_target = area
			
	return best_target

func _try_stack_on_nearest():
	var target = _find_valid_stack_target()
	if target:
		_perform_stack(target)
	else:
		z_index = 0
		# Changed hard_snap_pos to false to preserve trail effect when dropping on ground
		_reflow_stack_logic(self, false)

func _perform_stack(target_card: Card):
	var stack_top = target_card
	while stack_top.card_above:
		stack_top = stack_top.card_above
		
	if stack_top == self: return 
	
	stack_top.card_above = self
	self.card_below = stack_top
	
	# Changed hard_snap_pos to false to preserve trail effect when stacking
	_reflow_stack_logic(stack_top.get_stack_root(), false)

func _reflow_stack_logic(root: Card, hard_snap_pos: bool = false):
	var current = root.card_above
	var index = 1
	var nodes = [root]
	
	if not root.is_dragging and not root.card_below:
		root.z_index = 0
	
	while current:
		nodes.append(current)
		
		# Update Logic
		current.z_index = root.z_index + index
		
		# If hard snap is requested (e.g. on drop), force position
		if hard_snap_pos:
			current.global_position = root.global_position + Vector2(0, STACK_OFFSET * index)
			current._target_pos = current.global_position # Reset lerp target
			
		current = current.card_above
		index += 1
	
	for node in nodes:
		node.move_to_front()

func _reorder_tree_recursive(node: Card):
	node.move_to_front()
	if node.card_above:
		_reorder_tree_recursive(node.card_above)

# ------------------------------------------------------------------------------
# Helpers
# ------------------------------------------------------------------------------
func get_stack_root() -> Card:
	var c = self
	while c.card_below: c = c.card_below
	return c

func _is_in_my_stack(other: Card) -> bool:
	var c = self
	while c:
		if c == other: return true
		c = c.card_above
	return false

func _set_highlight(active: bool):
	if highlight: highlight.visible = active
	
func _set_z_index_recursive(base_z: int):
	z_index = base_z
	if card_above:
		card_above._set_z_index_recursive(base_z + 1)
