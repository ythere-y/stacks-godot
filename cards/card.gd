class_name Card
extends Area2D

# ------------------------------------------------------------------------------
# Constants & Signals
# ------------------------------------------------------------------------------
const SNAP_DISTANCE := 60.0
const STACK_OFFSET := 25.0

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
# Static variable acts as a "Singleton" for hover state across ALL cards.
# Only ONE card can be the 'hovered_card' at a time (globally).
static var hovered_card: Card = null 

var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var hover_target: Card = null # Target we are hovering over to drop/stack

# Linked List Structure for Stacks
var card_below: Card = null
var card_above: Card = null

# ------------------------------------------------------------------------------
# Lifecycle
# ------------------------------------------------------------------------------
func _ready():
	_update_visuals()
	
	# Input Setup
	# We subscribe to input_event to handle clicks *before* unhandled_input
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

func _process(_delta):
	if is_dragging:
		_process_dragging()

# ------------------------------------------------------------------------------
# Input Handling (The Fix for Overlaps)
# ------------------------------------------------------------------------------
func _on_input_event(viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# Only allow drag if I am explicitly the hovered card
			# This prevents clicking "through" a card to one below it
			if Card.hovered_card == self:
				start_drag()
				viewport.set_input_as_handled()

func _input(event):
	# Global input check for mouse release (drop)
	if is_dragging and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		end_drag()
		get_viewport().set_input_as_handled()

func _on_mouse_entered():
	# When mouse enters ANY card, we recalculate who should own the hover state
	_update_global_hover_state()

func _on_mouse_exited():
	# If I was the hovered card and mouse leaves ME, clear the state
	if Card.hovered_card == self:
		Card.hovered_card = null
		_set_hover_scale(false)
		
		# Optional: If there's another overlapping card strictly "below" the mouse now,
		# Godot will likely trigger _on_mouse_entered for THAT card immediately after this frame,
		# or we might need to rely on the physics engine to resolve it.
		# For simplicity, we just clear. The next card's enter event will clame it.

func _update_global_hover_state():
	# 1. If nobody owns hover, I take it.
	if Card.hovered_card == null:
		_claim_hover()
		return

	# 2. If someone owns it, but it's not me...
	if Card.hovered_card != self:
		# check if I am strictly "above" the current owner visually
		if self.is_visually_above(Card.hovered_card):
			# I steal the focus
			Card.hovered_card._set_hover_scale(false) # Un-highlight them
			_claim_hover()

func _claim_hover():
	if not is_dragging:
		Card.hovered_card = self
		_set_hover_scale(true)

func is_visually_above(other: Card) -> bool:
	if self.z_index > other.z_index: return true
	if self.z_index < other.z_index: return false
	
	# If Z-index is identical, Godot draws based on Tree Order (lower index = drawn first/behind, higher = last/front)
	return self.get_index() > other.get_index()

func _set_hover_scale(active: bool):
	# Don't tween scale if we are the one being dragged (drag logic handles scale)
	if is_dragging: return
	
	var target_scale = Vector2(1.05, 1.05) if active else Vector2(1.0, 1.0)
	var tween = create_tween()
	tween.tween_property(self, "scale", target_scale, 0.1)

# ------------------------------------------------------------------------------
# Dragging Logic
# ------------------------------------------------------------------------------
func start_drag():
	is_dragging = true
	drag_offset = get_global_mouse_position() - global_position
	
	# Visuals: Pop stack to front
	_set_z_index_recursive(100) # Ensure we are way above everything
	move_to_front() # Ensure tree order (input priority) matches Z
	
	# Animate Scale Recursively (New Feature)
	_animate_stack_scale(true)
	
	emit_signal("drag_started", self)
	
	# Detach from parent stack if needed
	if card_below:
		var old_root = card_below.get_stack_root()
		card_below.card_above = null
		card_below = null
		_reflow_stack_logic(old_root)
	
	# Reflow my own stack immediately to ensure children follow tightly in tree
	_reflow_stack_logic(self)

func end_drag():
	is_dragging = false
	_animate_stack_scale(false)
	
	# Clear highlight on drop target
	if hover_target:
		hover_target._set_highlight(false)
		hover_target = null
	
	emit_signal("drag_ended", self)
	_try_stack_on_nearest()

func _process_dragging():
	global_position = get_global_mouse_position() - drag_offset
	# Sync children positions frame-by-frame
	_sync_stack_positions()
	# Check for drop targets
	_update_drop_target()

func _animate_stack_scale(dragging: bool):
	# "Lift" effect for the whole stack
	var s = Vector2(1.1, 1.1) if dragging else Vector2(1.0, 1.0)
	var current = self
	while current:
		var tween = create_tween()
		tween.tween_property(current, "scale", s, 0.1)
		current = current.card_above

# ------------------------------------------------------------------------------
# Stacking Logic (Refactored)
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
	var min_dist = INF
	
	for area in areas:
		if not (area is Card) or area == self: continue
		if _is_in_my_stack(area): continue # Don't stack on self children
		
		# Extra check: Are we accidentally trying to stack on a card that is visually ABOVE us (impossible/weird)?
		# Actually, standard overlapping logic finds anything. logic usually favors stacking "onto" something below.
		
		var dist = global_position.distance_to(area.global_position)
		if dist < SNAP_DISTANCE and dist < min_dist:
			min_dist = dist
			best_target = area
			
	return best_target

func _try_stack_on_nearest():
	var target = _find_valid_stack_target()
	if target:
		_perform_stack(target)
	else:
		# Dropped on emptiness.
		# Reset Z-Index to baseline (0) + offsets
		z_index = 0
		_reflow_stack_logic(self)

func _perform_stack(target_card: Card):
	# We always append to the VERY TOP of the target's stack
	var stack_top = target_card
	while stack_top.card_above:
		stack_top = stack_top.card_above
		
	# Check for loops (paranoia)
	if stack_top == self: return 
	
	stack_top.card_above = self
	self.card_below = stack_top
	
	# Reflow EVERYONE starting from the absolute root
	_reflow_stack_logic(stack_top.get_stack_root())

func _reflow_stack_logic(root: Card):
	var current = root.card_above
	var index = 1
	var nodes = [root]
	
	# Reset root Z logic
	if not root.is_dragging and not root.card_below:
		root.z_index = 0
	
	while current:
		nodes.append(current)
		# Position Snap
		current.global_position = root.global_position + Vector2(0, STACK_OFFSET * index)
		# Z-Index Snap
		current.z_index = root.z_index + index
		current = current.card_above
		index += 1
	
	# Critical: Reorder Godot Scene Tree
	# This ensures the visual rendering AND input event order (front = first) match our logic
	for node in nodes:
		node.move_to_front()

func _sync_stack_positions():
	# Only sync positions, expensive tree reordering is done on DragStart/End
	var current = self.card_above
	var index = 1
	while current:
		current.global_position = global_position + Vector2(0, STACK_OFFSET * index)
		current = current.card_above
		index += 1

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
