extends Node2D

@onready var card = $Card
# 路径已经修正是正确的
@onready var btn_start = $DebugUI/PanelContainer/VBoxContainer/BtnStart
@onready var btn_stop = $DebugUI/PanelContainer/VBoxContainer/BtnStop
@onready var status_label = $DebugUI/PanelContainer/VBoxContainer/StatusLabel

# --- 关键修改 1: 使用 extends 继承 RecipeData ---
# 这样 MockRecipe 就是 RecipeData 的子类，可以通过类型检查
class MockCardData extends Resource:
	var display_name: String = ""
	var background_color: Color = Color.WHITE
	var icon: Texture2D = null
	var id: String = ""
class MockRecipe extends RecipeData:
	# --- 关键修改 2: 使用 _init 初始化 ---
	# 不需要重新 var 定义变量，直接修改父类的属性
	func _init():
		id = "test_recipe"
		time = 3.0 # 测试用3秒
		output = ["gold_coin"]
		inputs = {} # 测试不需要输入，给个空的防止报错
	
	# 删除 mock_get 函数，因为继承 Resource 后自带 get() 方法

func _ready():
	# 初始化 UI 文本
	btn_start.text = "Force Start Working (3s)"
	btn_stop.text = "Force Stop"
	
	# 连接信号
	btn_start.pressed.connect(_on_start_pressed)
	btn_stop.pressed.connect(_on_stop_pressed)
	
	# 连接卡牌的产出信号
	if card.has_signal("production_complete"): # 加个判断防止改名报错
		card.production_complete.connect(_on_card_production_complete)
	
	# 给卡牌注入假数据
	mock_card_data()

func mock_card_data():
	# 使用 set_meta 临时注入数据，避免依赖真实的 CardData 资源
	# 确保这里和你的 card.gd 读取逻辑一致（如果 card.gd 用 data.get() 就可以）
	var fake_data = MockCardData.new()
	fake_data.display_name = "Test Villager"
	fake_data.background_color = Color.CYAN
	fake_data.icon = null
	fake_data.id = "villager"

	# 如果你的 card.gd 需要 data 属性，且 data 是 export 变量
	if "data" in card:
		card.data = fake_data
	
	# 强制更新一下视觉
	if card.has_method("_update_visuals"):
		card._update_visuals()

func _process(delta):
	# 实时监控
	var state_text = "State: "
	# 假设 Card.State 是 enum {IDLE, WORKING}
	match card.current_state:
		0: state_text += "IDLE"
		1: state_text += "WORKING"
		_: state_text += str(card.current_state)
	
	state_text += "\nTimer: %.2f / 3.0" % card.work_timer
	
	if card.progress_bar:
		state_text += "\nProgress Bar: %d%%" % card.progress_bar.value
		state_text += "\nBar Visible: %s" % str(card.progress_bar.visible)
	
	status_label.text = state_text

func _on_start_pressed():
	print("Test: Triggering start_working")
	# 因为 MockRecipe 继承了 RecipeData，这里传入就不会报错了
	var recipe = MockRecipe.new()
	if card.has_method("start_working"):
		card.start_working(recipe)
	else:
		printerr("Error: Card script missing start_working method")

func _on_stop_pressed():
	print("Test: Triggering stop_working")
	if card.has_method("stop_working"):
		card.stop_working()

func _on_card_production_complete(outputs, pos):
	print("Test Success! Produced: ", outputs, " at ", pos)
	
	# 视觉反馈
	var icon = Sprite2D.new()
	# 尝试加载图标，如果没有就用默认的 Godot 图标，或者画个方块
	if ResourceLoader.exists("res://icon.svg"):
		icon.texture = load("res://icon.svg")
	else:
		# 如果没有 icon.svg，就创建一个临时的 Placeholder
		var placeholder = PlaceholderTexture2D.new()
		placeholder.size = Vector2(32, 32)
		icon.texture = placeholder
		
	icon.scale = Vector2(0.5, 0.5)
	icon.global_position = pos
	icon.modulate = Color.YELLOW
	add_child(icon)
	
	var tween = create_tween()
	tween.tween_property(icon, "position", pos + Vector2(0, -60), 0.8)
	tween.tween_property(icon, "modulate:a", 0.0, 0.8) # 渐隐
	tween.tween_callback(icon.queue_free)
