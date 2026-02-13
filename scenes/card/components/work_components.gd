class_name WorkComponent
extends Node

# 信号：当生产完成时通知外界（通常是 Board）
signal production_finished(outputs: Array, pos: Vector2)

@onready var card = get_parent()

var current_recipe: Dictionary = {}
var timer: float = 0.0
var is_working: bool = false

func _process(delta: float) -> void:
	if not is_working or current_recipe.is_empty():
		return
	
	timer += delta
	var total_time = current_recipe.get("time", 1.0)
	
	# 计算百分比并更新 UI
	var progress = (timer / total_time) * 100.0
	card.update_progress(progress)
	
	if timer >= total_time:
		_complete_work()

## 开始生产逻辑
func start_working(recipe: Dictionary) -> void:
	if is_working and current_recipe.get("id") == recipe.get("id"):
		return # 已经在做同样的任务了，不重置
		
	current_recipe = recipe
	timer = 0.0
	is_working = true
	card.show_progress(true)
	print("WorkComponent: Started ", recipe.get("id"))

## 停止生产（比如卡堆散开了）
func stop_working() -> void:
	if not is_working: return
	is_working = false
	current_recipe = {}
	timer = 0.0
	card.show_progress(false)
	print("WorkComponent: Stopped working.")

func _complete_work() -> void:
	var outputs = current_recipe.get("outputs", [])
	# 发出信号：带上产出列表和当前位置
	production_finished.emit(outputs, card.global_position)
	
	# Stacklands 逻辑：产出后通常会重置计时重新开始（如果是持续生产）
	# 或者停止。这里我们默认停止，由 StackComponent 重新触发检测。
	stop_working()
