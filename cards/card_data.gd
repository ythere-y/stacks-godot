class_name CardData
extends Resource

enum CardType {RESOURCE, UNIT, BUILDING, FOOD, MOB, EQUIPMENT, OTHER}

@export var id: String
@export var display_name: String
@export_multiline var description: String
@export var type: CardType
@export var sell_value: int = 1
@export var icon: Texture2D
@export var background_color: Color = Color(0.9, 0.9, 0.9)
@export var max_health: int = 0
@export var timer_duration: float = 0.0 # For cards that process things
@export var can_stack: bool = true
@export var stack_limit: int = 99
