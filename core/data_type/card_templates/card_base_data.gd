class_name BaseCardData
extends BaseEntityData

enum CardType {
	STRUCTURE,
	VILLAGER,
	RESOURCE,
	IDEA,
	FOOD,
	MOB,
	LOCATION,
	BUILDING,
	EQUIPMENT,
	OTHER,
	CURRENCY
}
enum CardStyle {
	DEFAULT,
	VILLAGER,
	WOOD,
	STONE,
	METAL,
	MAGIC,
	FOOD,
	MONSTER,
	LOCATION,
	BUILDING,
	EQUIPMENT,
	RESOURCE_STRUCTURE,
	DARK,
	YELLOW,
	RED,
	BROWN,
	CURRENCY,

}
@export var type: CardType = CardType.OTHER
@export var can_sell: bool = true
@export var sell_value: int = 1
@export var style: CardStyle = CardStyle.DEFAULT
@export var can_stack: bool = true

func from_dict(dict: Dictionary) -> BaseCardData:
	id = dict.get("id", "")
	match dict.get("type", ""):
		"structure": type = CardType.STRUCTURE
		"villager": type = CardType.VILLAGER
		"resource": type = CardType.RESOURCE
		"idea": type = CardType.IDEA
		"food": type = CardType.FOOD
		"mob": type = CardType.MOB
		"location": type = CardType.LOCATION
		"building": type = CardType.BUILDING
		"equipment": type = CardType.EQUIPMENT
		"currency": type = CardType.CURRENCY
		_: type = CardType.OTHER
	can_sell = dict.get("can_sell", true)
	sell_value = dict.get("sell_value", 1)
	match dict.get("style", "default"):
		"villager": style = CardStyle.VILLAGER
		"wood": style = CardStyle.WOOD
		"stone": style = CardStyle.STONE
		"metal": style = CardStyle.METAL
		"magic": style = CardStyle.MAGIC
		"food": style = CardStyle.FOOD
		"monster": style = CardStyle.MONSTER
		"location": style = CardStyle.LOCATION
		"building": style = CardStyle.BUILDING
		"equipment": style = CardStyle.EQUIPMENT
		"resource_structure": style = CardStyle.RESOURCE_STRUCTURE
		"dark": style = CardStyle.DARK
		"yellow": style = CardStyle.YELLOW
		"red": style = CardStyle.RED
		"brown": style = CardStyle.BROWN
		"currency": style = CardStyle.CURRENCY
		"default": style = CardStyle.DEFAULT
	can_stack = dict.get("can_stack", true)
	return self
