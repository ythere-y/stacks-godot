class_name StackBattleComponent
extends Node


var is_battling: bool = false
var battle_paused: bool = false
var stack
var enemies: Array = []
var alies: Array = []


func _init(parent_stack = null):
	if parent_stack:
		stack = parent_stack

func _ready():
	if not stack:
		stack = get_parent() as CardStack
	stack.stack_changed.connect(_check_battle_condition)

func _process(delta: float):
	if not stack or not is_battling or battle_paused:
		return
	

	# 每个unit有不同的攻击频率时，可以在UnitCardData中添加attack_interval属性，并在此处根据单位类型调整battle_interval
	# 那么该如何实现呢？
	# ans: 可以在UnitCardData中添加一个attack_interval属性，表示该单位的攻击频率。然后在StackBattleComponent中维护一个字典，记录每个单位的攻击计时器。当battle_timer达到某个单位的attack_interval时，就执行该单位的攻击逻辑，并重置该单位的攻击计时器。这样就可以实现不同单位有不同攻击频率的战斗系统。

	for ally in alies:
		if is_instance_valid(ally['card']):
			ally['battle_timer'] += delta
			if ally['battle_timer'] >= ally['interval']:
				ally['battle_timer'] = 0.0
				if not enemies.is_empty():
					var target = enemies.pick_random()
					_attack(ally['card'], target['card'])
	for enemy in enemies:
		if is_instance_valid(enemy['card']):
			enemy['battle_timer'] += delta
			if enemy['battle_timer'] >= enemy['interval']:
				enemy['battle_timer'] = 0.0
				if not alies.is_empty():
					var target = alies.pick_random()
					_attack(enemy['card'], target['card'])

func _check_battle_condition():
	alies.clear()
	enemies.clear()
	var has_player = false
	var has_enemy = false

	for card in stack.cards:
		if not card.data: continue
		if card.data is UnitCardData:
			if card.data.team == UnitCardData.Team.PLAYER:
				has_player = true
				alies.append({
					"card": card,
					"battle_timer": 0.0,
					"interval": card.data.current_attack_speed,
				})
			elif card.data.team == UnitCardData.Team.ENEMY:
				has_enemy = true
				enemies.append({
					"card": card,
					"battle_timer": 0.0,
					"interval": card.data.current_attack_speed,
				})
	
	var should_battle = has_player and has_enemy
	
	if should_battle != is_battling:
		is_battling = should_battle
		if should_battle:
			# 战斗开始
			Log.info("Battle started in stack: " + stack.name)
			SignalBus.battle_started.emit(stack)
			# 暂停合成逻辑
			if stack.work_component:
				stack.work_component.is_working = false
		else:
			# 战斗结束
			Log.info("Battle ended in stack: " + stack.name)
		stack.layout_component.update_layout()

func _apply_attack_effects(attacker_card: Card, target_card: Card, damage):
	if not attacker_card.data or not target_card.data:
		return
	attacker_card.play_attack(target_card, damage)
		
	# attacker_card 飞过去，踹一脚
	# ques:这个打击动画在哪里实现比较好？
	# ai_ans: 打击动画可以在Card节点中实现一个play_attack_animation方法，当卡牌被攻击时调用该方法播放动画。StackBattleComponent在执行攻击逻辑时，可以调用目标卡牌的play_attack_animation方法来触发动画效果。这样可以将动画逻辑封装在Card节点中，保持StackBattleComponent的职责单一。
	# ques:调用的时候，需要传入那些参数？
	# ai_ans: play_attack_animation方法可以接受一些参数来定制动画效果，例如攻击类型（物理攻击、魔法攻击等）、伤害数值、是否暴击等。StackBattleComponent在调用该方法时，可以根据攻击的具体情况传入相应的参数，以便Card节点能够根据这些参数播放不同的动画效果。
func _attack(attacker: Card, target: Card):
	var base_damage = attacker.data.current_attack - target.data.current_defense
	# 50%的概率伤害+1
	var damage: int = base_damage + (1 if randf() < 0.5 else 0)
	_apply_attack_effects(attacker, target, damage)

	target.take_damage(damage)

func pause_battle():
	battle_paused = true
