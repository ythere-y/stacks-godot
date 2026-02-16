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

@onready var layout: MarginContainer = $Layout
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var card_visuals: PanelContainer = $Layout/CardVisuals
@onready var label: Label = $Layout/CardVisuals/MarginContainer/Content/Label
@onready var card_image: TextureRect = $Layout/CardVisuals/MarginContainer/Content/ImagePanel/CardImage
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var highlight: Line2D = $Highlight
@onready var flash_overlay = $Layout/FlashOverlay


#------------------------------------------------------------------------------
# 基础初始化属性
#------------------------------------------------------------------------------

@export var display_name: String = "Card"
@export var icon: Texture2D


# ------------------------------------------------------------------------------
# 状态变量
# -----------------------------------------------------------------------------
var signal_connected: bool = false # 标记是否已连接信号，避免重复连接
var is_dragging: bool = false
var is_top_hovered: bool = false # 只有被Board判定为最上层卡片时才允许拖拽
var drag_offset: Vector2 = Vector2.ZERO
var velocity: Vector2 = Vector2.ZERO
var hover_target: Card = null # 拖拽时潜在的吸附目标

# ------------------------------------------------------------------------------
# 发射信号
# ------------------------------------------------------------------------------
signal request_destruction(card_node: Card)
signal request_smoke_effect(card_node: Card, position: Vector2)
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


func play_attack(target: Node2D, damage: int):
	if target == null: return
	
	# 1. 准备工作
	var original_pos = position # 记录起始位置
	var target_pos = target.position # 目标位置
	# 计算冲撞点（不需要重叠，冲到目标边缘即可，这里取中点偏向目标的方向）
	var impact_pos = original_pos + (target_pos - original_pos) * 0.9
	# 计算后退蓄力的位置（向目标反方向微移）
	var back_pos = original_pos - (target_pos - original_pos).normalized() * 20.0

	# 创建 Tween
	var tween = create_tween()
	# 设置z_index确保动画在上层
	var original_z = z_index
	z_index = 800

	
	# --- 阶段 A: 蓄势待发 ---
	# 稍微后退 + 稍微缩小一点点，产生蓄力感
	tween.tween_property(self , "position", back_pos, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self , "scale", Vector2(0.95, 0.95), 0.15)
	
	# --- 阶段 B: 极速撞击 ---
	# 使用 TRANS_EXPO 或 TRANS_CIRC 来模拟爆发力
	tween.tween_property(self , "position", impact_pos, 0.1).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(self , "scale", Vector2(1.1, 1.1), 0.1) # 撞击时稍微变大增强冲击感
	
	# 在撞击发生的瞬间，调用伤害逻辑和对方的受击效果
	tween.tween_callback(func():
		if is_instance_valid(target):
			# 假设对方有这个函数
			if target.has_method("take_damage"):
				target.take_damage(damage)
	)
	
	# --- 阶段 C: 回弹原位 ---
	# 使用 TRANS_ELASTIC 或 TRANS_BACK 增加回弹的生动感
	tween.tween_property(self , "position", original_pos, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self , "scale", Vector2(1.0, 1.0), 0.3)
	tween.tween_callback(func():
		z_index = original_z # 恢复原始 z_index
)
func play_damage_effect():
	# --- 1. 准备工作 ---
	# 建议抖动内部的视觉容器 VisualParent，而不是根节点，以免干扰堆叠逻辑
	# 如果没有容器，可以直接操作 self，但要确保 original_position 的准确性
	var visual_node = self
	var original_pos = visual_node.position
	var original_rot = visual_node.rotation
	var original_z_index = z_index
	var tween = create_tween()
	z_index = 799
	
	# --- 2. 动画逻辑 (并行执行) ---
	
	# A. 颜色闪烁逻辑
	flash_overlay.color.a = 0.7
	tween.tween_property(flash_overlay, "color:a", 0.0, 0.10).set_trans(Tween.TRANS_SINE)
	
	# B. 抖动逻辑 (Parallel 会让它与上面的颜色动画同时进行)
	# 通过在极短时间内进行多次随机位移来实现
	var shake_intensity = 20.0 # 抖动强度
	var rot_intensity = 0.15
	var shake_count = 6 # 抖动次数
	var shake_duration = 0.05 # 每次抖动的时间
	
	for i in range(shake_count):
		var random_offset = Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
		var random_rot = randf_range(-rot_intensity, rot_intensity)
		shake_intensity *= 0.8 # 逐渐减小抖动强度
		rot_intensity *= 0.8
		if i == 0:
			tween.parallel().tween_property(visual_node, "position", original_pos + random_offset, shake_duration)
		else:
			tween.tween_property(visual_node, "position", visual_node.position + random_offset, shake_duration)
		tween.parallel().tween_property(visual_node, "rotation", original_rot + random_rot, shake_duration)
	
	# 最后确保归位
	tween.tween_property(visual_node, "position", original_pos, 0.05)
	tween.parallel().tween_property(visual_node, "rotation", original_rot, 0.05)
	tween.tween_callback(func():
		z_index = original_z_index # 恢复原始 z_index
	)

func signal_connect(stack):
	if signal_connected:
		return
	signal_connected = true
	request_destruction.connect(stack._on_card_request_destruction)
	request_smoke_effect.connect(stack._on_card_smoke_effect)

func die_me():
	# 1. 立即禁用碰撞和交互，防止玩家在死亡动画期间继续拖拽或触发逻辑
	$CollisionShape2D.set_deferred("disabled", true)
	
	# 确保 Layout 会忽略鼠标
	if has_node("Layout"):
		$Layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
	var tween = create_tween()
	var visuals = $Layout/CardVisuals # 我们只缩小视觉部分
	
	# 2. 死亡视觉动画：稍微放大一点点（蓄力），然后瞬间缩小到0并变透明
	tween.tween_property(visuals, "scale", Vector2(1.1, 1.1), 0.05)
	
	tween.parallel().tween_property(visuals, "scale", Vector2(0.0, 0.0), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(visuals, "modulate:a", 0.0, 0.2)
	
	# 3. 动画进行到一半（卡牌缩没的瞬间），发出产生烟雾和掉落的信号
	# 注意：这里的 global_position 是为了让外部知道在哪里生成
	tween.tween_callback(func():
		request_smoke_effect.emit(self , global_position)
		
		# 假设你的卡牌数据里有 drops 数组
		if data and data.has_method("get_drops"):
			var drop_id = data.get_drops()
			if drop_id != "":
				SignalBus.card_spawn_requested.emit(drop_id, global_position)
	).set_delay(0.15) # 稍微延迟一点产生掉落物，手感更好

	# 4. 动画彻底结束后，才发出销毁请求。此时 Stack 才会重新排版
	tween.tween_callback(func():
		request_destruction.emit(self )
	)
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
			var death_info: String = String("Card'") + name + "' has died."
			Log.info(death_info)
			die_me()

	
#endregion
