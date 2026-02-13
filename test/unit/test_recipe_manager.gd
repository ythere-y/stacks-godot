extends SceneTree
const RecipeManagerClass = preload("res://core/recipe_manager.gd")

func _init():
	var rm = RecipeManagerClass.new()
	# 模拟手动加载数据
	rm.recipes = {
		"test_recipe": {
			"inputs": {"villager": 1, "berry_bush": 1},
			"outputs": ["berry"]
		}
	}
	
	print("--- Running RecipeManager Tests ---")
	
	# 测试 1: 正确匹配
	var stack1 = {"villager": 1, "berry_bush": 1, "stone": 5}
	var res1 = rm.find_matching_recipe(stack1)
	assert(not res1.is_empty(), "Test 1 Failed: Should match recipe")
	print("Test 1 Passed: Correct matching")
	
	# 测试 2: 材料不足
	var stack2 = {"villager": 1}
	var res2 = rm.find_matching_recipe(stack2)
	assert(res2.is_empty(), "Test 2 Failed: Should NOT match (missing berry_bush)")
	print("Test 2 Passed: Missing ingredients handled")
	
	# 测试 3: 数量不足
	rm.recipes["test_multi"] = {"inputs": {"wood": 3}, "outputs": ["charcoal"]}
	var stack3 = {"wood": 2}
	var res3 = rm.find_matching_recipe(stack3)
	assert(res3.is_empty(), "Test 3 Failed: Should NOT match (not enough wood)")
	print("Test 3 Passed: Insufficient quantity handled")
	
	print("--- All Tests Passed ---")
	quit()
