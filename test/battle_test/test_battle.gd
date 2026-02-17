extends Node2D

@onready var battle_zone = $BattleZone
@onready var anim_speed_slider: HSlider = $DebugCanvas/ControlPanel/HBox/AnimSpeedSlider
@onready var value_display: Label = $DebugCanvas/ControlPanel/HBox/ValueDisplay
@onready var btn_attack: Button = $DebugCanvas/ControlPanel/BtnAttack
@onready var btn_behit: Button = $DebugCanvas/ControlPanel/BtnBeHit
@onready var btn_continue: Button = $DebugCanvas/ControlPanel/BtnContinue
@onready var btn_death: Button = $DebugCanvas/ControlPanel/BtnDeath
@onready var btn_reset: Button = $DebugCanvas/ControlPanel/BtnReset

@export var stack_scene: PackedScene = preload("res://scenes/stack/stack.tscn") # 预加载堆叠场景以便实例化

var stack: CardStack = null

func spawn_stack(card_ids: Array, pos: Vector2) -> void:
	var new_stack = stack_scene.instantiate() as CardStack
	var data_list = []
	for id in card_ids:
		var data = CardLibrary.create_data(id)
		data_list.append(data)
	new_stack.setup(data_list)
	
	new_stack.global_position = pos
	battle_zone.add_child(new_stack)
	new_stack.battle_component.pause_battle() # 先暂停战斗，等所有堆叠都生成完毕后再统一开始战斗
	stack = new_stack
	Log.info("Spawned battle stack with cards: " + str(card_ids) + " at position: " + str(pos))

func spawn_card(card_id: String, pos: Vector2, data: BaseCardData = null):
	var new_stack = stack_scene.instantiate()
	if data == null:
		data = CardLibrary.create_data(card_id)
	if data and new_stack.has_method("setup"):
		var init_cards: Array[BaseCardData] = [data]
		new_stack.setup(init_cards)
	new_stack.global_position = pos
	self.add_child(new_stack)
	print("Spawned stack with card: ", card_id)

func _on_card_production_complete(output_ids: Array, pos: Vector2):
	for id in output_ids:
		var random_offset = Vector2(randf_range(-20, 20), randf_range(-20, 20))
		spawn_card(id, pos + random_offset)


func _spawn_battle_stack():
	var battle_list = ["villager", "villager", "villager", "wolf", "wolf", "wolf", "wolf", "wolf", ]
	# 获取画布中心
	var screen_size = get_viewport_rect().size
	var center_pos = screen_size / 2
	spawn_stack(battle_list, center_pos)
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_spawn_battle_stack()
	anim_speed_slider.value_changed.connect(func(val):
		value_display.text = "%.1f" % val + "x"
	)
	btn_attack.pressed.connect(_random_attack)
	btn_continue.pressed.connect(_continue_battle)
	btn_behit.pressed.connect(_be_hit)
	btn_death.pressed.connect(_death)
	btn_reset.pressed.connect(_reset)

	SignalBus.card_spawn_requested.connect(_on_card_production_complete)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _random_attack():
	var ally_card = stack.battle_component.alies.pick_random()
	var enemy_card = stack.battle_component.enemies.pick_random()

	ally_card.card.play_attack(enemy_card.card, ally_card.card.data.attack)
	pass
func _continue_battle():
	if stack == null:
		return
	if stack.battle_component.battle_paused:
		stack.battle_component.battle_paused = false
	else:
		stack.battle_component.battle_paused = true
func _be_hit():
	if stack == null:
		return
	var ally_card = stack.battle_component.alies.pick_random()
	ally_card.card.take_damage(0)
	var enemy_card = stack.battle_component.enemies.pick_random()
	enemy_card.card.take_damage(0)
func _death():
	if stack == null:
		return
	var ally_card = stack.battle_component.alies.pick_random()
	ally_card.card.take_damage(999)
	var enemy_card = stack.battle_component.enemies.pick_random()
	enemy_card.card.take_damage(999)
	pass
func _reset():
	if stack:
		stack.queue_free()
		stack = null
	_spawn_battle_stack()
