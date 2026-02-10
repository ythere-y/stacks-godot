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
signal production_complete(outputs: Array, spawn_position: Vector2)

enum State {IDLE, WORKING}
var current_state: State = State.IDLE
var current_recipe: RecipeData = null
var work_timer: float = 0.0


# ------------------------------------------------------------------------------
# Exports & Nodes
# ------------------------------------------------------------------------------
@export var data: Resource

@onready var layout: VBoxContainer = $Layout
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var card_visuals: PanelContainer = $Layout/CardVisuals
@onready var label: Label = $Layout/CardVisuals/MarginContainer/Content/Label
@onready var card_image: TextureRect = $Layout/CardVisuals/MarginContainer/Content/ImagePanel/CardImage
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var highlight: Line2D = $Highlight
# ------------------------------------------------------------------------------
# State Variables
# ------------------------------------------------------------------------------
# Robust Hover Logic
static var _hover_candidates: Array[Card] = []
static var hovered_card: Card = null

var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var hover_target: Card = null
var velocity: Vector2 = Vector2.ZERO
var _last_mouse_pos: Vector2 = Vector2.ZERO

var card_below: Card = null # The card directly below me in the stack (null if I'm on the ground)
var card_above: Card = null # The card directly above me in the stack (null if I'm the top)

var _target_pos: Vector2 = Vector2.ZERO
var _detached_parent: Card = null # Logic to restore stack if drag is interrupted (e.g. by sorting)

# ------------------------------------------------------------------------------
# Lifecycle
# ------------------------------------------------------------------------------
func _ready():
	if progress_bar:
		progress_bar.visible = false
		progress_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if layout:
		layout.resized.connect(_on_ui_resized)
	_update_visuals()
	_target_pos = global_position
	input_event.connect(_on_input_event)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func setup(new_data: Resource):
	data = new_data
	_update_visuals()

func _on_ui_resized():
	# 让物理碰撞体的大小自动匹配 UI 布局的大小
	if collision_shape and collision_shape.shape is RectangleShape2D:
		collision_shape.shape.size = layout.size
	
	# 更新高亮线框的大小（如果需要动态跟随）
	if highlight:
		var s = layout.size / 2
		highlight.points = PackedVector2Array([
			Vector2(-s.x, -s.y), Vector2(s.x, -s.y),
			Vector2(s.x, s.y), Vector2(-s.x, s.y),
			Vector2(-s.x, -s.y)
		])
func _update_visuals():
	if not data: return
	if label:
		var name_val = data.get("display_name")
		label.text = str(name_val) if name_val != null else ""
	if card_image:
		card_image.texture = data.get("icon")
	if card_visuals:
		var style_box = card_visuals.get_theme_stylebox("panel").duplicate()
		if style_box is StyleBoxFlat:
			style_box.bg_color = data.get("background_color") if data.get("background_color") else Color.WHITE
			card_visuals.add_theme_stylebox_override("panel", style_box)
func _process(delta):
	# 生产逻辑
	if current_state == State.WORKING and current_recipe:
		work_timer += delta
		var total_time = current_recipe.get("time") if "time" in current_recipe else 1.0
		var progress = clamp(work_timer / total_time * 100, 0, 100)
		if progress_bar:
			progress_bar.visible = true
			progress_bar.value = progress
		if work_timer >= total_time:
			complete_production()
		
	if is_dragging:
		_process_dragging(delta)
	else:
		# Inertia / Slide Physics (When dropped on ground)
		if not card_below:
			if velocity.length_squared() > 1.0:
				global_position += velocity * delta
				velocity = velocity.lerp(Vector2.ZERO, delta * 5.0) # Friction
				
				# Keep within screen bounds ( Optional, simple bounce )
				var vp_rect = get_viewport_rect()
				var margin = 50.0
				if global_position.x < margin:
					global_position.x = margin
					velocity.x *= -0.5
				if global_position.x > vp_rect.size.x - margin:
					global_position.x = vp_rect.size.x - margin
					velocity.x *= -0.5
				if global_position.y < margin:
					global_position.y = margin
					velocity.y *= -0.5
				if global_position.y > vp_rect.size.y - margin:
					global_position.y = vp_rect.size.y - margin
					velocity.y *= -0.5
			else:
				velocity = Vector2.ZERO
		
		# Snake Follow Logic (When in stack)
		if card_below:
			velocity = Vector2.ZERO # Stop sliding if we get attached
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
# 物理与堆叠逻辑 (核心逻辑抽离，保持原有算法)
# ------------------------------------------------------------------------------
func _process_stack_physics(delta):
	if not card_below:
		if velocity.length_squared() > 1.0:
			global_position += velocity * delta
			velocity = velocity.lerp(Vector2.ZERO, delta * 5.0)
			_screen_bounce()
		else:
			velocity = Vector2.ZERO
	else:
		velocity = Vector2.ZERO
		_target_pos = card_below.global_position + Vector2(0, STACK_OFFSET)
		global_position = global_position.lerp(_target_pos, delta * FOLLOW_SPEED)
		if z_index != card_below.z_index + 1:
			z_index = card_below.z_index + 1

func _screen_bounce():
	var vp_rect = get_viewport_rect()
	var margin = 50.0
	if global_position.x < margin or global_position.x > vp_rect.size.x - margin:
		velocity.x *= -0.5
		global_position.x = clamp(global_position.x, margin, vp_rect.size.x - margin)
	if global_position.y < margin or global_position.y > vp_rect.size.y - margin:
		velocity.y *= -0.5
		global_position.y = clamp(global_position.y, margin, vp_rect.size.y - margin)
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
	if not Card._hover_candidates.has(self ):
		Card._hover_candidates.append(self )
	_recalculate_global_hover()

func _on_mouse_exited():
	if Card._hover_candidates.has(self ):
		Card._hover_candidates.erase(self )
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
	tween.tween_property(self , "scale", target_scale, 0.1)

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
	
	emit_signal("drag_started", self )
	
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
	
	_reflow_stack_logic(self )
	_reorder_tree_recursive(self )

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
	
	emit_signal("drag_ended", self )
	_try_stack_on_nearest()
	check_for_recipes()

func _process_dragging(delta):
	var mouse_pos = get_global_mouse_position()
	
	# Calculate velocity for inertia release
	var current_velocity = (mouse_pos - drag_offset - global_position) / delta
	# Smooth out the velocity calculation
	velocity = velocity.lerp(current_velocity, 0.2)
	
	# Leader moves instantly
	global_position = mouse_pos - drag_offset
	
	# Children follow via _process() logic (they have card_below = me), 
	# but we need to ensure their logic runs. Since _process runs on everyone, 
	# the children will automatically verify 'card_below' and lerp towards me.
	# We just need to check for Drop Targets here.
	_update_drop_target()

func _animate_stack_scale(dragging: bool):
	var s = Vector2(1.05, 1.05) if dragging else Vector2(1.0, 1.0)
	var current = self
	while current:
		var tween = create_tween()
		# 缩放整个 Layout 容器
		tween.tween_property(current.layout, "scale", s, 0.1)
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
		_reflow_stack_logic(self , false)

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
func complete_production():
	var spawn_pos = global_position + Vector2(0, -STACK_OFFSET * 1.5) # Spawn above the stack
	emit_signal("production_complete", current_recipe.output, spawn_pos)
	stop_working()


func get_stack_ids() -> Dictionary:
	var ids = {}
	var root = get_stack_root()
	var current = root
	while current:
		if current.data and current.data.id:
			var id = current.data.id
			if id in ids:
				ids[id] += 1
			else:
				ids[id] = 1
		current = current.card_above # Move up the stack
	return ids
func check_for_recipes():
# 这是一个简化版，实际项目中建议用 RecipeManager
	var stack_content = get_stack_ids()
	print("Checking Recipe with stack: ", stack_content)
	
	# 仅做测试用的硬编码逻辑
	if "villager" in stack_content and "berry_bush" in stack_content:
		# 模拟一个 Recipe 资源
		var mock_recipe = RefCounted.new() # 使用 RefCounted 模拟简单对象
		mock_recipe.set_meta("id", "make_berry")
		mock_recipe.set_meta("time", 3.0)
		mock_recipe.set_meta("outputs", ["berry"])
		current_recipe = mock_recipe
		# 为了兼容 GDScript 的动态特性，我们给这个对象加个脚本或者直接读 meta
		# 这里为了方便测试脚本调用，我们直接传个字典也可以，取决于你 RecipeData 怎么写的
		# 假设 start_working 接受任何带 .time 的对象
		start_working(mock_recipe)
		return

	stop_working()
func stop_working():
	current_state = State.IDLE
	current_recipe = null
	work_timer = 0.0
	if progress_bar:
		progress_bar.visible = false

func start_working(recipe: RecipeData):
	print(self , " Starting work on: ", recipe.get("id") if recipe.has_meta("id") else "unknown")
	current_state = State.WORKING
	current_recipe = recipe
	work_timer = 0.0
func is_recip_match(stack_content: Dictionary, recipe_inputs: Dictionary) -> bool:
	for key in recipe_inputs.keys():
		if not stack_content.has(key) or stack_content[key] < recipe_inputs[key]:
			return false
	return true
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
