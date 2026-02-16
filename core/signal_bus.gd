extends Node

# 当任何卡片完成生产时触发
signal card_spawn_requested(card_ids: Array, position: Vector2)

# 当任何卡片被销毁时触发
signal card_destroy_requested(card_ids: Array)

# 当任何Stack生产完成时触发
signal stack_work_finished(outputs: Array, position: Vector2)

# 也可以添加其他全局事件
# signal card_drag_started(card: Card, single: bool) # 参数必须对应，否则会报错
signal card_drag_started(card: Card, single: bool)
signal card_drag_ended(card: Card)
signal card_sort_requested(card: Card)


signal battle_started(stack: CardStack)
