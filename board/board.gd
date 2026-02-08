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
	var test_ids = [
		"villager", "berry_bush", "stone", "wood", "gold", 
		"slime", "militia", "sword", "house", "garden"
	]

	var screen_size = get_viewport_rect().size
	
	for i in range(12): 
		var id = test_ids.pick_random()
		# Use the new Library to create data
		var data = CardLibrary.create_data(id)
		
		# Random position
		var rand_x = randf_range(100, screen_size.x - 100)
		var rand_y = randf_range(100, screen_size.y - 100)
		
		spawn_card(id, Vector2(rand_x, rand_y), data)

func spawn_card(card_id: String, pos: Vector2, data: Resource = null):
	var new_card = card_scene.instantiate()
	# In a real game, you'd look up the CardData resource by ID from a global dictionary
	
	if data and new_card.has_method("setup"):
		new_card.setup(data)
		
	new_card.global_position = pos
	cards_container.add_child(new_card)
	print("Spawned card: ", card_id)

# You can add logic here to handle global inputs, camera movement, or turn processing
