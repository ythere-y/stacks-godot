extends Node

# 当任何卡片完成生产时触发
signal card_spawn_requested(card_ids: Array, position: Vector2)

# 也可以添加其他全局事件
signal card_drag_started(card: Node)
signal card_drag_ended(card: Node)


# res://core/signal_bus.gd
signal card_hovered(card: Node)
signal card_unhovered(card: Node)