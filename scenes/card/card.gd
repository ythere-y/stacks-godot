class_name Card
extends Area2D


#region Configs
# ------------------------------------------------------------------------------
# Constants & Signals
# ------------------------------------------------------------------------------
const HOVER_SCALE := Gamesettings.HOVER_SCALE


# ------------------------------------------------------------------------------
# 节点引用与导出
# ------------------------------------------------------------------------------
@export var data: BaseCardData = null

@onready var layout: VBoxContainer = $Layout
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var card_visuals: PanelContainer = $Layout/CardVisuals
@onready var label: Label = $Layout/CardVisuals/MarginContainer/Content/Label
@onready var card_image: TextureRect = $Layout/CardVisuals/MarginContainer/Content/ImagePanel/CardImage
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var highlight: Line2D = $Highlight

#------------------------------------------------------------------------------
# 基础初始化属性
#------------------------------------------------------------------------------

@export var display_name: String = "Card"
@export var icon: Texture2D


# ------------------------------------------------------------------------------
# 状态变量
# -----------------------------------------------------------------------------

var is_dragging: bool = false
var is_top_hovered: bool = false # 只有被Board判定为最上层卡片时才允许拖拽
var drag_offset: Vector2 = Vector2.ZERO
var velocity: Vector2 = Vector2.ZERO
var hover_target: Card = null # 拖拽时潜在的吸附目标

# ------------------------------------------------------------------------------
# 发射信号
# ------------------------------------------------------------------------------
signal request_destruction(card_node: Card)

#endregion

#region Lifecycle
# ------------------------------------------------------------------------------
# 生命周期
# ------------------------------------------------------------------------------
func setup(new_data: BaseCardData):
	data = new_data
	display_name = tr("card_" + data.id)
	var icon_path = "res://assets/textures/card_images/" + data.id + ".png"
	if FileAccess.file_exists(icon_path):
		icon = load(icon_path)
	else:
		icon = load("res://icon.svg")

func _ready():
	_on_ui_resized()
	
	input_event.connect(_on_input_event)
	layout.resized.connect(_on_ui_resized)
	_update_visuals()
	collision_layer = 1 << 0 # 确保卡牌在正确的碰撞层级
	name = display_name
	# Log.info("Card '{0}' is ready with durability {1}.".format([name, str(current_durability)]))


#endregion


#region UI Update
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
func _update_visuals():
	if not data: return
	label.text = display_name
	card_image.texture = icon
	name = display_name
	# TODO: update box style

#endregion
#region Interaction
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


#endregion

#region API
func get_layout_score() -> Array[int]:
	var stack_score: Array[int] = get_parent().get_layout_score()
	var self_score: Array[int] = [ self.z_index, self.get_index()]
	return stack_score + self_score

func set_highlight(active: bool):
	if highlight: highlight.visible = active
func play_damage_effect():
	# 这里可以添加一些受伤动画或效果
	pass
func die_me():
	# 发出销毁请求信号，交由 Board 或 Stack 处理实际销毁逻辑
	request_destruction.emit(self )

func take_damage(amount: int):
	# 需要区分是unit还是structure
	play_damage_effect()
	if data:
		var die_flag = false
		if data.type == BaseCardData.CardType.STRUCTURE:
			die_flag = data.take_damage(amount)
			var damage_info: String = String("Card'") + name + "'takes [" + str(amount) + "] damage. Remaining durability: [" + str(data.current_durability) + "]"
			Log.info(damage_info)
		if data.type == BaseCardData.CardType.RESOURCE:
			die_flag = data.take_damage(amount)
			var damage_info: String = String("Card'") + name + "'takes [" + str(amount) + "] damage. and died"
			Log.info(damage_info)
		elif data.type == BaseCardData.CardType.VILLAGER or data.type == BaseCardData.CardType.MOB:
			die_flag = data.take_damage(amount)
			var damage_info: String = String("Card'") + name + "'takes [" + str(amount) + "] damage. Remaining health: [" + str(data.current_health) + "]"
			Log.info(damage_info)
		if die_flag:
			die_me()
			
	
#endregion
