class_name GameBoard
extends Node2D

const CardDataRes = preload("uid://coxctgrbhcok5")

#region Configuration
@export_group("Scene References")
@export var card_scene: PackedScene = preload("res://scenes/card/card.tscn") # 预加载卡牌场景以便实例化
@export var stack_scene: PackedScene = preload("res://scenes/stack/stack.tscn") # 预加载堆叠场景以便实例化

@export_group("Camera Control")
@export var camera_speed: float = 800.0
@export var zoom_speed: float = 0.2
@export var min_zoom: Vector2 = Vector2(0.5, 0.5)
@export var max_zoom: Vector2 = Vector2(3.0, 3.0)

var _current_focus: Node = null
var is_dragging: bool = false
var _target_zoom: Vector2 = Vector2(1, 1)

# Container for all cards in play
@onready var stacks_container = $StacksContainer

# --- Camera Nodes (Auto-assigned from Scene) ---
@onready var camera_target: Node2D = $CameraTarget
@onready var phantom_camera: PhantomCamera2D = $PhantomCamera2D
#endregion

#region Lifecycle
func _ready():
	# 确保 CardLibrary 已经加载了 CSV
	CardLibrary.load_library()
	
	_connect_signals()
	if not card_scene:
		print("Card scene not assigned, attempting to load...")
		card_scene = load("res://scenes/card/card.tscn") # 旧路径，确保向后兼容
	if not stack_scene:
		print("Stack scene not assigned, attempting to load...")
		stack_scene = load("res://scenes/stack/stack.tscn") # 旧路径，确保向后兼容
	if card_scene:
		_spawn_all_types_and_random()
	else:
		push_error("Card scene is NOT assigned in GameBoard!")
	
	# 初始化 _target_zoom
	if phantom_camera:
		_target_zoom = phantom_camera.zoom

	# 初始化相机位置到中心 (可选)
	if camera_target:
		camera_target.position = get_viewport_rect().size / 2

func _process(delta: float):
	_handle_camera_movement(delta)

func _physics_process(_delta: float):
	if is_dragging: return
	
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = get_global_mouse_position()
	query.collide_with_areas = true
	query.collide_with_bodies = false
	query.collision_mask = Gamesettings.CARD_COLLISION_LAYER
	
	var results = space_state.intersect_point(query, 32)
	var candidates: Array[Card] = []
	
	for res in results:
		var c = res.collider
		if c is Card:
			candidates.append(c)
	Log.info("Cards under mouse: ", candidates.size())
	_update_hover_focus_list(candidates)

func _unhandled_input(event: InputEvent):
	_handle_camera_zoom(event)
#endregion

#region Camera Logic
func _handle_camera_movement(delta: float):
	if not camera_target: return
	
	# 获取 WASD 输入向量 (需确保 项目设置->输入映射 中配置了 ui_left/right/up/down 或自定义的一套)
	# 也可以直接使用 physical keycode
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if direction != Vector2.ZERO:
		camera_target.position += direction * camera_speed * delta

func _handle_camera_zoom(event: InputEvent):
	if not phantom_camera or not camera_target: return
	
	if event is InputEventMouseButton and event.pressed:
		var old_zoom = _target_zoom
		var new_zoom = old_zoom
		
		# 2. 决定新的目标缩放值
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			new_zoom += Vector2(zoom_speed, zoom_speed)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			new_zoom -= Vector2(zoom_speed, zoom_speed)
		else:
			return
			
		new_zoom = new_zoom.clamp(min_zoom, max_zoom)
		_target_zoom = new_zoom
		
		# 只有目标缩放发生变化时才执行位移计算
		if new_zoom != old_zoom:
			var mouse_pos = get_global_mouse_position()
			var camera_pos = phantom_camera.global_position
			
			var zoom_ratio = old_zoom.x / new_zoom.x
			var new_camera_pos = mouse_pos + (camera_pos - mouse_pos) * zoom_ratio
			
			var diff = new_camera_pos - camera_pos
			camera_target.global_position += diff
			phantom_camera.global_position += diff
			phantom_camera.set_zoom(new_zoom)
#endregion

#region Signal Handling
func _connect_signals():
	# 连接生产完成信号
	SignalBus.card_spawn_requested.connect(_on_card_production_complete)

	# 卡牌拖拽信号
	SignalBus.card_drag_started.connect(_on_card_drag_started)
	SignalBus.card_drag_ended.connect(_on_drag_ended)
	SignalBus.card_sort_requested.connect(_on_card_sort_requested)

func _on_card_production_complete(output_ids: Array, pos: Vector2):
	for id in output_ids:
		var random_offset = Vector2(randf_range(-20, 20), randf_range(-20, 20))
		spawn_card(id, pos + random_offset)

func _on_card_drag_started(target_card: Card, single: bool = false):
	is_dragging = true
	var stack_parent: CardStack = target_card.get_parent()

	# split_stack 内部已经把 new_stack 加到 stacks_container 了，并且设置好了 global_position
	# new_stack 包含了 target_card (及可能的其他卡片)
	var temp_stack: CardStack = stack_parent.start_drag_from_card(target_card, single)
	
	if not temp_stack:
		push_error("Failed to create drag stack")
		is_dragging = false
		return

	temp_stack.name = "TempDragStack"
	temp_stack.z_index = 1000 # 确保在最上层

	var mouse_pos = temp_stack.get_global_mouse_position()
	temp_stack.drag_offset = temp_stack.global_position - mouse_pos
	temp_stack.start_drag()

func _on_card_sort_requested(card: Card):
	if is_dragging: return
	var parent_stack = card.get_parent() as CardStack
	parent_stack.sort_from_card(card)

func _on_drag_ended(dragged_card: Node):
	is_dragging = false
	# 被拖拽的卡片此时应该位于 TempDragStack 中
	# 我们需要调用该 Stack 的 end_drag 方法来执行放置逻辑（如合并、归位等）
	if dragged_card is Card:
		var parent_stack = dragged_card.get_parent() as CardStack
		parent_stack.end_drag()
#endregion

#region Focus Logic
func _update_hover_focus_list(candidates: Array[Card]):
	var winner = _find_top_card(candidates)

	if _current_focus != winner:
		# 让旧的焦点取消高亮
		if is_instance_valid(_current_focus):
			if _current_focus.has_method("set_highlight"):
				_current_focus.set_highlight(false)
			# 更新状态标志
			if "is_top_hovered" in _current_focus:
				_current_focus.is_top_hovered = false
		
		# 让新的焦点开启高亮
		_current_focus = winner
		if is_instance_valid(_current_focus):
			if _current_focus.has_method("set_highlight"):
				_current_focus.set_highlight(true)
			# 更新状态标志
			if "is_top_hovered" in _current_focus:
				_current_focus.is_top_hovered = true

func _find_top_card(list: Array[Card]) -> Node:
	# 清理list中的无效实例
	list = list.filter(func(c): return is_instance_valid(c))
	if list.is_empty():
		return null

	var top_node: Card = list.reduce(func(best, current):
		if current.get_layout_score() > best.get_layout_score():
			return current
		return best
	)
	return top_node
#endregion

#region Spawning Logic
func _spawn_all_types_and_random():
	# 1. 获取库中所有的 ID
	var all_ids = CardLibrary.get_all_card_ids()
	if all_ids.is_empty():
		print("Warning: CardLibrary is empty!")
		return

	var screen_size = get_viewport_rect().size
	
	# 2. 保证每种卡片至少有一张
	for id in all_ids:
		var data = CardLibrary.create_data(id)
		var pos = _get_random_screen_pos(screen_size)
		spawn_card(id, pos, data)
	
	# 3. 再额外生成一些随机卡片（比如生成 10 张随机的）
	var extra_cards_count = 10
	for i in range(extra_cards_count):
		var id = all_ids.pick_random()
		var data = CardLibrary.create_data(id)
		var pos = _get_random_screen_pos(screen_size)
		spawn_card(id, pos, data)

func _get_random_screen_pos(screen_size: Vector2) -> Vector2:
	return Vector2(
		randf_range(100, screen_size.x - 100),
		randf_range(100, screen_size.y - 100)
	)

func spawn_card(card_id: String, pos: Vector2, data: Resource = null):
	var new_stack = stack_scene.instantiate()
	if data == null:
		data = CardLibrary.create_data(card_id)
	if data and new_stack.has_method("setup"):
		var init_cards: Array[CardData] = [data]
		new_stack.setup(init_cards)
	new_stack.global_position = pos
	stacks_container.add_child(new_stack)
	print("Spawned stack with card: ", card_id)
#endregion
