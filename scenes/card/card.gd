class_name Card
extends Area2D

# ------------------------------------------------------------------------------
# Constants & Signals
# ------------------------------------------------------------------------------
const HOVER_SCALE := Gamesettings.HOVER_SCALE


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
# -----------------------------------------------------------------------------

var is_dragging: bool = false
var is_top_hovered: bool = false # 只有被Board判定为最上层卡片时才允许拖拽
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
	# mouse_entered.connect(_on_mouse_entered)
	# mouse_exited.connect(_on_mouse_exited)
	layout.resized.connect(_on_ui_resized)
	_update_visuals()
	collision_layer = 1 << 0 # 确保卡牌在正确的碰撞层级
	name = data.display_name if data else "Card"
func setup(new_data: Resource):
	data = new_data

func get_layout_score() -> Array[int]:
	var stack_score: Array[int] = get_parent().get_layout_score()
	var self_score: Array[int] = [ self.z_index, self.get_index()]
	return stack_score + self_score

# ------------------------------------------------------------------------------
# 表现层接口 (供组件调用)
# ------------------------------------------------------------------------------
func _update_visuals():
	if not data: return
	if label: label.text = tr(data.display_name)
	if card_image: card_image.texture = data.icon
	name = data.display_name if data.display_name else "Card"
	
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
		# 统一检查：只有最上层高亮卡片才能响应任何点击交互
		if event.pressed and not is_top_hovered:
			return

		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.double_click and event.pressed:
				SignalBus.card_sort_requested.emit(self )
			elif event.pressed:
				is_dragging = true # Set dragging state
				SignalBus.card_drag_started.emit(self , false) # 明确传入 false
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			is_dragging = true # Set dragging state
			SignalBus.card_drag_started.emit(self , true)

func _input(event):
	if is_dragging and event is InputEventMouseButton and not event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT:
			is_dragging = false # Reset dragging state
			SignalBus.card_drag_ended.emit(self )


# ------------------------------------------------------------------------------
# 悬停逻辑 (静态处理)
# ------------------------------------------------------------------------------
func _on_mouse_entered():
	# Deprecated: Hover logic is now handled by polling in Board._physics_process
	pass

func _on_mouse_exited():
	# Deprecated
	pass

func set_highlight(active: bool):
	if highlight: highlight.visible = active


func is_visually_above(other: Card) -> bool:
	if self.z_index != other.z_index: return self.z_index > other.z_index
	return self.get_index() > other.get_index()

# ------------------------------------------------------------------------------
# 信号转发
# ------------------------------------------------------------------------------
func _on_production_finished(outputs: Array, pos: Vector2):
	SignalBus.card_spawn_requested.emit(outputs, pos + Vector2(0, -50))
