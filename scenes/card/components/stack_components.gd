class_name StackComponent
extends Node

# 引用父级卡牌
@onready var card = get_parent()
var card_above = null
var card_below = null

## 获取整堆卡的 ID 统计（供 RecipeManager 使用）
func get_stack_ids() -> Dictionary:
	var ids = {}
	var current = get_stack_root()
	while current:
		var id = current.data.id
		ids[id] = ids.get(id, 0) + 1
		current = current.stack_comp.card_above
	return ids

func get_stack_root():
	var c = card
	while c.stack_comp.card_below:
		c = c.stack_comp.card_below
	return c

## 检查堆栈是否匹配配方
func check_recipe():
	var root = get_stack_root()
	# 只有堆栈底部的卡牌负责触发配方检测
	if root != card:
		root.stack_comp.check_recipe()
		return
		
	var stack_content = get_stack_ids()
	var matched_recipe = RecipeMgr.find_matching_recipe(stack_content)
	
	if not matched_recipe.is_empty():
		card.work_comp.start_working(matched_recipe)
	else:
		card.work_comp.stop_working()
