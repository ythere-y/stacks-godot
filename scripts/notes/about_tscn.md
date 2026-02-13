完全可以。Godot 的 `.tscn` 文件本质上就是 **INI 格式的文本文件**。只要你遵循它的语法规则，完全可以用记事本或 VS Code 手写。

这对于批量修改属性、解决合并冲突或者像你现在这样——**精准控制节点层级**非常有帮助。

下面我将教你 `.tscn` 的核心语法，并直接给出**修复后的 `card.tscn**` 和 **全新的 `test_card_logic.tscn**` 的完整代码。

---

### `.tscn` 文件语法速成

一个 `.tscn` 文件由三个主要部分组成：

1. **头部 (Header)**: 定义文件格式和依赖数量。
2. **资源 (Resources)**:
* `[ext_resource]`: 外部引用（图片、脚本、其他场景）。
* `[sub_resource]`: 内部资源（直接画在编辑器里的形状、样式、动画）。


3. **节点 (Nodes)**: 定义场景树结构和属性。

#### 关键规则

* **引用方式**:
* `ExtResource("id")`: 引用外部资源（如 `icon.svg`）。
* `SubResource("id")`: 引用内部资源（如 `RectangleShape2D`）。


* **层级关系**: `parent="父节点名称"`。如果没有 `parent`，它就是根节点。

---

### 1. 修复后的 `card.tscn` (手动代码版)

这是根据你的需求修复后的代码。我已经把 **`ProgressBar` 移到了列表最下方**，确保它渲染在最上层。

**请直接新建/覆盖 `res://cards/card.tscn`，内容如下：**

```ini
[gd_scene load_steps=5 format=3 uid="uid://c8q4w5y6z7x8"]

# --- 1. 外部资源引用区 ---
# id="1_script" 是我们给脚本起的代号，下面引用时用 ExtResource("1_script")
[ext_resource type="Script" path="res://cards/card.gd" id="1_script"]
[ext_resource type="Texture2D" path="res://icon.svg" id="2_icon"]

# --- 2. 内部资源定义区 ---
# 定义碰撞形状
[sub_resource type="RectangleShape2D" id="RectangleShape2D_card"]
size = Vector2(140, 190)

# 定义背景样式 (圆角矩形)
[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_bg"]
bg_color = Color(1, 1, 1, 1)
corner_radius_top_left = 12
corner_radius_top_right = 12
corner_radius_bottom_right = 12
corner_radius_bottom_left = 12
shadow_color = Color(0, 0, 0, 0.2)
shadow_size = 4
shadow_offset = Vector2(4, 4)

# --- 3. 节点树定义区 ---

# 根节点
[node name="Card" type="Area2D"]
script = ExtResource("1_script")

# 碰撞形状
[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("RectangleShape2D_card")

# 背景面板 (注意: 它的顺序靠前，会被后面的节点覆盖)
[node name="Background" type="Panel" parent="."]
offset_left = -70.0
offset_top = -95.0
offset_right = 70.0
offset_bottom = 95.0
mouse_filter = 2
theme_override_styles/panel = SubResource("StyleBoxFlat_bg")

# 标题栏 (作为 Background 的子节点)
[node name="TitleBar" type="Panel" parent="Background"]
layout_mode = 0
offset_right = 140.0
offset_bottom = 30.0
mouse_filter = 2
theme_override_styles/panel = SubResource("StyleBoxFlat_bg")
self_modulate = Color(0, 0, 0, 0.1)

# 图标
[node name="Sprite2D" type="Sprite2D" parent="."]
position = Vector2(0, 15)
scale = Vector2(0.5, 0.5)
texture = ExtResource("2_icon")

# 文字标签
[node name="Label" type="Label" parent="."]
offset_left = -65.0
offset_top = -93.0
offset_right = 65.0
offset_bottom = -67.0
theme_override_colors/font_color = Color(0.2, 0.2, 0.2, 1)
theme_override_font_sizes/font_size = 14
text = "Card Name"
horizontal_alignment = 1
vertical_alignment = 1

# 高亮框
[node name="Highlight" type="Line2D" parent="."]
visible = false
points = PackedVector2Array(-70, -84, -70, 84)
width = 4.0
default_color = Color(1, 0.8, 0.2, 0.9)

# --- 关键修改: 进度条放在最后 ---
# 这样它在渲染队列的最后，会画在所有东西上面
[node name="ProgressBar" type="ProgressBar" parent="."]
visible = false
offset_left = -60.0
offset_top = 40.0
offset_right = 60.0
offset_bottom = 67.0
mouse_filter = 2
step = 0.1
show_percentage = false

```

---

### 2. 测试场景 `test_card_logic.tscn` (手动代码版)

这个文件展示了如何手动编写**场景实例化**和**UI布局**。

**请新建文件 `res://test_card_logic.tscn`，内容如下：**

```ini
[gd_scene load_steps=3 format=3 uid="uid://b1v2x3y4z5a6"]

# 引用刚才写的测试脚本
[ext_resource type="Script" path="res://test_card_logic.gd" id="1_logic"]
# 引用刚才写的 Card 场景 (作为 PackedScene)
[ext_resource type="PackedScene" path="res://cards/card.tscn" id="2_card"]

# 根节点
[node name="TestCardLogic" type="Node2D"]
script = ExtResource("1_logic")

# 背景颜色 (让屏幕不那么黑)
[node name="BG" type="ColorRect" parent="."]
offset_right = 1152.0
offset_bottom = 648.0
mouse_filter = 2
color = Color(0.211765, 0.239216, 0.290196, 1)

# --- 实例化 Card 场景 ---
# instance=ExtResource("2_card") 表示这里要把 card.tscn 里的东西搬过来
[node name="Card" parent="." instance=ExtResource("2_card")]
position = Vector2(576, 324)

# --- 调试 UI 层 ---
[node name="DebugUI" type="CanvasLayer" parent="."]

[node name="PanelContainer" type="PanelContainer" parent="DebugUI"]
offset_left = 20.0
offset_top = 20.0
offset_right = 260.0
offset_bottom = 200.0

[node name="VBoxContainer" type="VBoxContainer" parent="DebugUI/PanelContainer"]
layout_mode = 2

[node name="StatusLabel" type="Label" parent="DebugUI/PanelContainer/VBoxContainer"]
layout_mode = 2
text = "State: IDLE
Timer: 0.0s"

[node name="HSeparator" type="HSeparator" parent="DebugUI/PanelContainer/VBoxContainer"]
layout_mode = 2

[node name="BtnStart" type="Button" parent="DebugUI/PanelContainer/VBoxContainer"]
layout_mode = 2
text = "Force Start (3s)"

[node name="BtnStop" type="Button" parent="DebugUI/PanelContainer/VBoxContainer"]
layout_mode = 2
text = "Force Stop"

```

---

### 3. 配套的测试脚本 `test_card_logic.gd`

这个你需要创建为 `.gd` 文件（不是 tscn）。为了完整性，我再次贴出适配上面 `.tscn` 的脚本：

```gdscript
extends Node2D

@onready var card = $Card
@onready var btn_start = $DebugUI/PanelContainer/VBoxContainer/BtnStart
@onready var btn_stop = $DebugUI/PanelContainer/VBoxContainer/BtnStop
@onready var status_label = $DebugUI/PanelContainer/VBoxContainer/StatusLabel

class MockRecipe:
	var time: float = 3.0
	var outputs: Array = ["gold"]
	func get(prop): 
		if prop == "time": return time
		if prop == "outputs": return outputs
		return null

func _ready():
	btn_start.pressed.connect(_on_start)
	btn_stop.pressed.connect(_on_stop)
	
	# 连接生产完成信号
	if card.has_signal("production_complete"):
		card.production_complete.connect(_on_produced)

func _process(delta):
	var txt = "State: %s" % ("WORKING" if card.current_state == 1 else "IDLE")
	txt += "\nTimer: %.2f" % card.work_timer
	txt += "\nProgress: %d%%" % card.progress_bar.value
	status_label.text = txt

func _on_start():
	print("开始测试...")
	var r = MockRecipe.new()
	if card.has_method("start_working"):
		card.start_working(r)

func _on_stop():
	print("停止测试...")
	if card.has_method("stop_working"):
		card.stop_working()

func _on_produced(out_items, pos):
	print("生产成功: ", out_items)
	# 生成一个视觉反馈
	var icon = Sprite2D.new()
	icon.texture = load("res://icon.svg")
	icon.position = pos
	icon.scale = Vector2(0.3, 0.3)
	icon.modulate = Color.YELLOW
	add_child(icon)
	
	var t = create_tween()
	t.tween_property(icon, "position:y", pos.y - 50, 0.5)
	t.tween_callback(icon.queue_free)

```

### 如何生效

1. 在你的项目文件夹中新建/保存上述文件。
2. 切换回 Godot 编辑器。
3. Godot 会自动检测文件变化并重新导入。
4. 如果你手动写 `uid="..."` 觉得麻烦，可以**不写 uid 参数**（例如只写 `[gd_scene load_steps=5 format=3]`）。保存后切回 Godot，Godot 编辑器会自动为你生成并补全一个 `uid`。

现在你可以直接运行 `test_card_logic.tscn` (F6) 来看效果了！