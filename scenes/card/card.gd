class_name Card
extends Area2D

# ------------------------------------------------------------------------------
# Constants & Signals
# ------------------------------------------------------------------------------
const HOVER_SCALE := Gamesettings.HOVER_SCALE

signal drag_started(card: Card)
signal drag_ended(card: Card)

# ------------------------------------------------------------------------------
# 节点引用与导出
# ------------------------------------------------------------------------------
@export var data: Resource

@onready var stack_comp = $StackComponent
@onready var work_comp = $WorkComponent

@onready var layout: VBoxContainer = $Layout
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var card_visuals: PanelContainer = $Layout/CardVisuals
@onready var label: Label = $Layout/CardVisuals/MarginContainer/Content/Label
@onready var card_image: TextureRect = $Layout/CardVisuals/MarginContainer/Content/ImagePanel/CardImage
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var highlight: Line2D = $Highlight

# ------------------------------------------------------------------------------
# 状态变量
# ------------------------------------------------------------------------------
static var _hover_candidates: Array[Card] = []
static var hovered_card: Card = null

var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var velocity: Vector2 = Vector2.ZERO
var hover_target: Card = null # 拖拽时潜在的吸附目标

# ------------------------------------------------------------------------------
# 生命周期
# ------------------------------------------------------------------------------
func _ready():
	# _update_visuals()
	_on_ui_resized()
	
	# 连接组件信号
	work_comp.production_finished.connect(_on_production_finished)
	
	# 基础交互信号
	input_event.connect(_on_input_event)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	layout.resized.connect(_on_ui_resized)

func setup(new_data: Resource):
	data = new_data
	if not is_node_ready():
		await ready
	_update_visuals()

func _process(delta):
	if is_dragging:
		_process_dragging(delta)
	else:
		# 物理与跟随逻辑已委托给 StackComponent 或在此处保持极简
		#stack_comp.process_physics(delta)
		pass

# ------------------------------------------------------------------------------
# 表现层接口 (供组件调用)
# ------------------------------------------------------------------------------
func _update_visuals():
	if not data: return
	if label: label.text = tr(data.display_name)
	if card_image: card_image.texture = data.icon
	
	var style_box = card_visuals.get_theme_stylebox("panel").duplicate()
	if style_box is StyleBoxFlat:
		style_box.bg_color = data.get("background_color") if data.get("background_color") else Color.WHITE
		card_visuals.add_theme_stylebox_override("panel", style_box)

func show_progress(val: bool):
	if progress_bar:
		progress_bar.visible = val

func update_progress(percent: float):
	if progress_bar:
		progress_bar.value = percent

func _set_highlight(active: bool):
	if highlight: highlight.visible = active

func _on_ui_resized():
	if collision_shape and collision_shape.shape is RectangleShape2D:
		collision_shape.shape.size = layout.size
	if highlight:
		var s = layout.size / 2
		highlight.points = PackedVector2Array([
			Vector2(-s.x, -s.y), Vector2(s.x, -s.y),
			Vector2(s.x, s.y), Vector2(-s.x, s.y),
			Vector2(-s.x, -s.y)
		])

# ------------------------------------------------------------------------------
# 输入与拖拽 (表现与基础交互)
# ------------------------------------------------------------------------------
func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.double_click and Card.hovered_card == self:
				stack_comp.sort_stack()
			elif event.pressed and Card.hovered_card == self:
				start_drag(false)
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if Card.hovered_card == self:
				start_drag(true)

func _input(event):
	if is_dragging and event is InputEventMouseButton and not event.pressed:
		end_drag()

func start_drag(extract_single: bool):
	is_dragging = true
	drag_offset = get_global_mouse_position() - global_position
	stack_comp.on_start_drag(extract_single)
	drag_started.emit(self )

func end_drag():
	is_dragging = false
	stack_comp.on_end_drag()
	drag_ended.emit(self )

func _process_dragging(delta):
	var mouse_pos = get_global_mouse_position()
	var target_pos = mouse_pos - drag_offset
	velocity = (target_pos - global_position) / delta
	global_position = target_pos
	stack_comp.update_drop_target()

# ------------------------------------------------------------------------------
# 悬停逻辑 (静态处理)
# ------------------------------------------------------------------------------
func _on_mouse_entered():
	print("Mouse entered card: ", data.display_name)
	SignalBus.card_hovered.emit(self )

func _on_mouse_exited():
	print("Mouse exited card: ", data.display_name)
	SignalBus.card_unhovered.emit(self )

func set_highlight(active: bool):
	if highlight: highlight.visible = active

static func _recalculate_global_hover():
	var winner: Card = null
	for c in _hover_candidates:
		if winner == null or c.is_visually_above(winner):
			winner = c
	
	if hovered_card != winner:
		if hovered_card and is_instance_valid(hovered_card):
			hovered_card._set_highlight(false)
		hovered_card = winner
		if hovered_card:
			hovered_card._set_highlight(true)


func is_visually_above(other: Card) -> bool:
	if self.z_index != other.z_index: return self.z_index > other.z_index
	return self.get_index() > other.get_index()

func _set_hover_scale(active: bool):
	if is_dragging: return
	var target_scale = Vector2(HOVER_SCALE, HOVER_SCALE) if active else Vector2(1.0, 1.0)
	var tween = create_tween()
	tween.tween_property(self , "scale", target_scale, 0.1)

# ------------------------------------------------------------------------------
# 信号转发
# ------------------------------------------------------------------------------
func _on_production_finished(outputs: Array, pos: Vector2):
	SignalBus.card_spawn_requested.emit(outputs, pos + Vector2(0, -50))
