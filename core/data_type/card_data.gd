class_name CardData
extends BaseEntityData

enum CardType {RESOURCE, UNIT, BUILDING, FOOD, MOB, EQUIPMENT, OTHER}

@export_multiline var description: String
@export var type: CardType
@export var sell_value: int = 1
@export var background_color: Color = Color(0.9, 0.9, 0.9)
@export var max_health: int = 0
@export var can_stack: bool = true
@export var stack_limit: int = 99
@export var max_durability: int = 1
