class_name Card
extends Area2D

# Removed shadowing constant to prevent class name conflicts
# const CardData = preload("res://cards/card_data.gd")

const SNAP_DISTANCE := 60.0
const STACK_OFFSET := 25.0 # Increased slightly

signal drag_started(card)
signal drag_ended(card)

# Use Resource type hint to avoid "Class not found" errors if Godot cache is stale
@export var data: Resource

# Components need to be linked in the editor
@onready var sprite: Sprite2D = $Sprite2D
@onready var label: Label = $Label
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var background: Polygon2D = $Background
@onready var highlight: Line2D = $Highlight

var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var target_position: Vector2
var hover_target: Card = null

# Stacking logic
var card_below: Card = null
var card_above: Card = null

func _ready():
	_update_visuals()
	input_event.connect(_on_input_event)
	
	# Hover signals
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered():
	if not is_dragging:
		var tween = create_tween()
		tween.tween_property(self , "scale", Vector2(1.05, 1.05), 0.1)

func _on_mouse_exited():
	if not is_dragging:
		var tween = create_tween()
		tween.tween_property(self , "scale", Vector2(1.0, 1.0), 0.1)

func setup(new_data: Resource):
	data = new_data
	_update_visuals()

func _update_visuals():
	# Allow updates before _ready (if calling setup manually) via null checks
	# But accessing @onready vars safely
	if data:
		if label:
			label.text = data.get("display_name")
		if sprite:
			sprite.texture = data.get("icon")
		if background:
			background.color = data.get("background_color")

func _process(delta):
	if is_dragging:
		global_position = get_global_mouse_position() - drag_offset
		# If we are dragging a stack, we must update the children positions frame-by-frame
		# Pass false to skip extensive tree reordering every frame
		_reflow_stack_from_root(self , false)
		_update_hover_target()
	else:
		# Smooth snap or settle movement could go here
		pass

func _on_input_event(viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			start_drag()
			viewport.set_input_as_handled() # Stop event from propagating to cards below

func _input(event):
	if is_dragging and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		end_drag()
		# We don't necessarily need to consume the release, but good practice if we started it
		get_viewport().set_input_as_handled()

func start_drag():
	print("Start drag: ", self.name, " (", data.get("display_name") if data else "Unknown", ")")
	is_dragging = true
	drag_offset = get_global_mouse_position() - global_position
	# Move to top of visual stack
	# When dragging, we want the whole stack we are holding to appear above everything else
	# Also raise to front of tree to capture input priority
	move_to_front()
	_set_z_index_recursive(100)
	
	# Drag visual effect
	var tween = create_tween()
	tween.tween_property(self , "scale", Vector2(1.1, 1.1), 0.1)
	
	emit_signal("drag_started", self )
	
	# Break stack links if dragging from middle/bottom
	if card_below:
		print("Detaching from below: ", card_below.name)
		var below_root = card_below.get_stack_root()
		card_below.card_above = null
		card_below = null
		# Reflow the stack we left behind
		_reflow_stack_from_root(below_root)

	# Reorder the stack we are dragging to keep hierarchy correct in tree
	_reflow_stack_from_root(self )

func _set_z_index_recursive(base_z: int):
	z_index = base_z
	if card_above:
		card_above._set_z_index_recursive(base_z + 1)

func end_drag():
	print("End drag: ", self.name)
	is_dragging = false
	# z_index reset will be handled by reflow logic eventually, 
	# but for now we simply leave it high until stacked/reflowed
	
	# Reset scale
	var tween = create_tween()
	tween.tween_property(self , "scale", Vector2(1.0, 1.0), 0.1)
	
	emit_signal("drag_ended", self )
	if hover_target:
		hover_target._set_stack_highlight(false)
		hover_target = null
	_check_for_stack()

func _check_for_stack():
	# Simple logic to find overlapping cards
	var closest_card = _find_stack_target()
	if closest_card:
		print("Attempting to stack on: ", closest_card.name)
		stack_on(closest_card)
	else:
		print("No stack target found")

func stack_on(target: Card):
	if _is_in_stack_below(target):
		print("Cannot stack on own child card! Cycle prevented.")
		return
		
	# Find the top of the target's stack
	var current = target
	while current.card_above != null:
		current = current.card_above
		if current == self:
			print("Critical Loop Detected in stack_on! Aborting.")
			return
		
	print("Linking ", self.name, " on top of ", current.name)
	# Link them
	current.card_above = self
	self.card_below = current

	# Reflow the whole stack so offsets are consistent
	var root = current.get_stack_root()
	_reflow_stack_from_root(root)

func _is_in_stack_below(potential_child: Card) -> bool:
	var current = self.card_above
	while current != null:
		if current == potential_child:
			return true
		current = current.card_above
	return false

func _update_hover_target():
	var new_target = _find_stack_target()
	if new_target != hover_target:
		if hover_target:
			hover_target._set_stack_highlight(false)
		hover_target = new_target
		if hover_target:
			hover_target._set_stack_highlight(true)

func _find_stack_target() -> Card:
	var areas = get_overlapping_areas()
	var closest_card: Card = null
	var min_dist = INF
	for area in areas:
		if area is Card and area != self and not _is_in_stack_below(area):
			var dist = global_position.distance_to(area.global_position)
			if dist < SNAP_DISTANCE and dist < min_dist:
				min_dist = dist
				closest_card = area
	return closest_card

func _set_stack_highlight(active: bool):
	if highlight:
		highlight.visible = active

func get_stack_root() -> Card:
	var current = self
	while current.card_below != null:
		current = current.card_below
	return current

func _reflow_stack_from_root(root: Card, reorder_tree: bool = true):
	var current = root.card_above
	var index = 1
	var nodes_to_reorder = [root]
	
	# If we are dragging this stack, the root z_index is already 100
	if not root.is_dragging and root.card_below == null:
		root.z_index = 0
	
	while current != null:
		nodes_to_reorder.append(current)
		# Use lerp for smoother following if desired, but direct set is more reliable for stacking
		current.global_position = root.global_position + Vector2(0, STACK_OFFSET * index)
		current.z_index = root.z_index + index
		current = current.card_above
		index += 1
		
	if reorder_tree:
		for node in nodes_to_reorder:
			node.move_to_front()
