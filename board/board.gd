class_name GameBoard
extends Node2D

const CardDataRes = preload("res://cards/card_data.gd")

@export var card_scene: PackedScene

# Container for all cards in play
@onready var cards_container = $CardsContainer

func _ready():
	print("GameBoard _ready executing...")
	if not card_scene:
		print("Card scene not assigned, attempting to load...")
		card_scene = load("res://cards/card.tscn")
		
	if card_scene:
		print("Card scene is valid. Spawning test cards.")
		_spawn_test_cards()
	else:
		print("CRITICAL ERROR: Could not load card scene!")
		push_error("Card scene is NOT assigned in GameBoard!")

func _spawn_test_cards():
	var test_cards = [
		{"id": "villager", "name": "Villager", "color": Color(0.92, 0.92, 0.92)},
		{"id": "berry_bush", "name": "Berry Bush", "color": Color(0.55, 0.85, 0.55)},
		{"id": "stone", "name": "Stone", "color": Color(0.7, 0.7, 0.75)},
		{"id": "wood", "name": "Wood", "color": Color(0.82, 0.68, 0.48)},
		{"id": "gold", "name": "Gold", "color": Color(0.95, 0.82, 0.35)},
		{"id": "slime", "name": "Slime", "color": Color(0.55, 0.7, 0.9)}
	]

	var start_pos = Vector2(260, 260)
	var spacing = Vector2(160, 0)
	var index = 0
	for entry in test_cards:
		var data = CardDataRes.new()
		data.id = entry["id"]
		data.display_name = entry["name"]
		data.background_color = entry["color"]
		spawn_card(entry["id"], start_pos + spacing * index, data)
		index += 1

func spawn_card(card_id: String, pos: Vector2, data: Resource = null):
	var new_card = card_scene.instantiate()
	# In a real game, you'd look up the CardData resource by ID from a global dictionary
	
	if data and new_card.has_method("setup"):
		new_card.setup(data)
		
	new_card.global_position = pos
	cards_container.add_child(new_card)
	print("Spawned card: ", card_id)

# You can add logic here to handle global inputs, camera movement, or turn processing
