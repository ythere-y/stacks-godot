class_name RecipeManager
extends Node

static var recipes: Dictionary = {}

func _ready():
	load_recipes()

static func load_recipes():
	var file_path = "res://data/recipes.json"
	if FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		var json_text = file.get_as_text()
		var data = JSON.parse_string(json_text)
		if data is Dictionary:
			recipes = data
			print("RecipeManager: Loaded ", recipes.size(), " recipes.")
	else:
		push_error("RecipeManager: recipes.json not found!")

## 检查当前堆栈内容是否匹配任何配方
static func find_matching_recipe(stack_ids: Dictionary) -> Dictionary:
	for recipe_id in recipes:
		var recipe = recipes[recipe_id]
		var inputs = recipe.get("inputs", {})
		
		if _can_craft(stack_ids, inputs):
			# 返回包含 ID 的配方副本
			var result = recipe.duplicate()
			result["id"] = recipe_id
			return result
	return {}

static func _can_craft(stack_ids: Dictionary, required_inputs: Dictionary) -> bool:
	if required_inputs.is_empty(): return false
	for id in required_inputs:
		if stack_ids.get(id, 0) < required_inputs[id]["num"]:
			return false
	return true
