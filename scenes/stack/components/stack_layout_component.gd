class_name StackLayoutComponent
extends Node

const VERTICAL_OFFSET: float = Gamesettings.STACK_OFFSET
const BASE_Z_INDEX: int = Gamesettings.STACK_Z_INDEX

var stack # 移除 : CardStack 以避免循环引用
var layout_tween: Tween = null

func _new_tween():
	if layout_tween and layout_tween.is_running():
		layout_tween.kill()
	layout_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	return layout_tween
func _init(parent_stack = null): # 移除类型提示
	if parent_stack:
		stack = parent_stack

func _ready():
	if not stack:
		stack = get_parent() as CardStack

## 重新排列所有卡牌的位置并更新碰撞盒
func update_layout():
	if not stack or stack.cards.is_empty():
		_hide_battle_bg()
		return
	
	if stack.battle_component.is_battling:
		_update_battle_layout()
	else:
		_hide_battle_bg()
		_update_normal_layout()

func _update_normal_layout():
	# 1. 物理对齐与顺序同步
	for i in range(stack.cards.size()):
		var card = stack.cards[i]
		if card.get_parent() != stack:
			continue
			
		var target_pos = Vector2(0, i * VERTICAL_OFFSET)
		card.position = target_pos
		card.z_index = i + BASE_Z_INDEX
		
		# 同步场景树子节点顺序
		if card.get_index() != i + 1:
			stack.move_child(card, i + stack.get_children().size() - stack.cards.size())

	# 2. 动态调整 Stack 的碰撞盒大小
	if stack.collision_shape and stack.collision_shape.shape is RectangleShape2D:
		var first_card = stack.cards[0]
		if not is_instance_valid(first_card) or not first_card.layout: return
		
		var card_size = first_card.layout.size
		var total_height = card_size.y + (stack.cards.size() - 1) * VERTICAL_OFFSET
		
		if stack.collision_shape.shape.resource_local_to_scene == false:
			stack.collision_shape.shape = stack.collision_shape.shape.duplicate()
			
		stack.collision_shape.shape.size = Vector2(card_size.x, total_height)
		stack.collision_shape.position = Vector2(0, (stack.cards.size() - 1) * VERTICAL_OFFSET / 2.0)
func _update_battle_layout():
	if stack.cards.is_empty(): return
	var allies = []
	var enemies = []
	for card in stack.cards:
		if card.data is UnitCardData:
			if card.data.team == UnitCardData.Team.ENEMY:
				enemies.append(card)
			elif card.data.team == UnitCardData.Team.PLAYER:
				allies.append(card)
			elif card.data.team == UnitCardData.Team.NEUTRAL:
				#TODO: 中立单位的处理逻辑，当前暂时视为玩家阵营
				enemies.append(card)
	var card_size = stack.cards[0].layout.size
	var h_gap = 20.0
	var v_gap = 50.0
	
	# 计算敌方(上方)布局
	var tween = _new_tween()

	var enemy_total_w = enemies.size() * card_size.x + (enemies.size() - 1) * h_gap
	var enemy_start_x = - enemy_total_w / 2.0 + card_size.x / 2.0
	for i in range(enemies.size()):
		var target_pos = Vector2(enemy_start_x + i * (card_size.x + h_gap), -card_size.y / 2.0 - v_gap / 2.0)
		tween.tween_property(enemies[i], "position", target_pos, 0.4)
		enemies[i].z_index = BASE_Z_INDEX + i

	
	# 计算我方(下方)布局
	var ally_total_w = allies.size() * card_size.x + (allies.size() - 1) * h_gap
	var ally_start_x = - ally_total_w / 2.0 + card_size.x / 2.0
	for i in range(allies.size()):
		var target_pos = Vector2(ally_start_x + i * (card_size.x + h_gap), card_size.y / 2.0 + v_gap / 2.0)
		tween.tween_property(allies[i], "position", target_pos, 0.4)
		allies[i].z_index = BASE_Z_INDEX + i
		
	# 更新战斗背景框与碰撞盒
	var box_w = max(enemy_total_w, ally_total_w) + 40.0
	var box_h = card_size.y * 2 + v_gap + 40.0
	_show_battle_bg(Vector2(box_w, box_h), tween)
	
	if stack.collision_shape and stack.collision_shape.shape is RectangleShape2D:
		tween.tween_property(stack.collision_shape.shape, "size", Vector2(box_w, box_h), 0.4)
		tween.tween_property(stack.collision_shape, "position", Vector2(0, 0), 0.4)
var battle_bg: Panel = null
func _show_battle_bg(size: Vector2, tween: Tween):
	if not battle_bg:
		battle_bg = Panel.new()
		# 简单的战斗框样式
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.2, 0, 0, 0.4) # 暗红色透明背景
		style.border_width_left = 4
		style.border_width_top = 4
		style.border_width_right = 4
		style.border_width_bottom = 4
		style.border_color = Color(0.8, 0.2, 0.2, 0.8)
		battle_bg.add_theme_stylebox_override("panel", style)
		stack.add_child(battle_bg)
		stack.move_child(battle_bg, 0) # 放在最底层
		
	battle_bg.visible = true
	tween.tween_property(battle_bg, "size", size, 0.4)
	tween.tween_property(battle_bg, "position", -size / 2.0, 0.4)

func _hide_battle_bg():
	if battle_bg:
		battle_bg.visible = false


func set_drag_layout():
	if not stack: return
	
	stack.z_index = 1000 # 确保在最上层
	stack.collision_shape.set_deferred("disabled", true) # 禁用碰撞，避免干扰拖拽过程中的鼠标检测

func reset_layout():
	if not stack: return
	
	stack.z_index = BASE_Z_INDEX
	stack.collision_shape.set_deferred("disabled", false) # 恢复碰撞
