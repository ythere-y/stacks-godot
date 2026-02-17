extends CPUParticles2D

signal effect_finished

func _ready():
	# 确保在加入场景时就开始发射
	emitting = true
	
	# 动态创建一个计时器，等待粒子寿命结束后自动删除
	var total_time = lifetime + 0.5
	get_tree().create_timer(total_time).timeout.connect(_on_timer_timeout)

func _on_timer_timeout():
	effect_finished.emit()
	# 彻底清理节点，防止内存泄漏
	queue_free()
