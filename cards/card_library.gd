class_name CardLibrary
extends RefCounted

const DEFINITIONS = {
	"villager": {
		"name": "Villager", 
		"color": Color(0.92, 0.92, 0.92),
		"icon": "res://icon.svg", # Placeholder
		"type": "unit"
	},
	"berry_bush": {
		"name": "Berry Bush", 
		"color": Color(0.55, 0.85, 0.55),
		"icon": "res://icon.svg",
		"type": "resource_source"
	},
	"stone": {
		"name": "Stone", 
		"color": Color(0.7, 0.7, 0.75),
		"icon": "res://icon.svg",
		"type": "resource"
	},
	"wood": {
		"name": "Wood", 
		"color": Color(0.82, 0.68, 0.48),
		"icon": "res://icon.svg",
		"type": "resource"
	},
	"gold": {
		"name": "Gold", 
		"color": Color(0.95, 0.82, 0.35),
		"icon": "res://icon.svg",
		"type": "currency"
	},
	"slime": {
		"name": "Slime", 
		"color": Color(0.55, 0.7, 0.9),
		"icon": "res://icon.svg",
		"type": "enemy"
	},
	"militia": {
		"name": "Militia", 
		"color": Color(0.85, 0.3, 0.3),
		"icon": "res://icon.svg",
		"type": "unit"
	},
	"sword": {
		"name": "Sword", 
		"color": Color(0.75, 0.75, 0.8),
		"icon": "res://icon.svg",
		"type": "equipment"
	},
	"house": {
		"name": "House", 
		"color": Color(0.7, 0.5, 0.3),
		"icon": "res://icon.svg",
		"type": "building"
	},
	"garden": {
		"name": "Garden", 
		"color": Color(0.4, 0.8, 0.4),
		"icon": "res://icon.svg",
		"type": "building"
	}
}

static func create_data(id: String) -> Resource:
	if not DEFINITIONS.has(id):
		push_error("Card ID not found: " + id)
		return null
		
	var def = DEFINITIONS[id]
	var data = load("res://cards/card_data.gd").new()
	data.id = id
	data.display_name = def["name"]
	data.background_color = def["color"]
	# Load icon if specific path exists, otherwise default
	if def.has("icon"):
		# In a real project you might preload these or load securely
		data.icon = load(def["icon"]) 
	return data
