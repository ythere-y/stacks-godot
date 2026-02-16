class_name GameSettings
extends Node

const TEST_MODE: bool = true

const STACK_OFFSET: float = 25.0
const FOLLOW_SPEED: int = 15
const HOVER_SCALE: float = 1.05


const CARD_COLLISION_LAYER: int = 1 << 0
const STACK_COLLISION_LAYER: int = 1 << 1


const STACK_Z_INDEX: int = 10


const BATTLE_STATS_TABLE = {
	"spd_lvl": {
		1: 3.5,
		2: 2.9,
		3: 2.3,
		4: 1.7,
		5: 1.1,
		6: 0.5,
	},
	"hit_chance": {
		1: 0.5,
		2: 0.59,
		3: 0.68,
		4: 0.77,
		5: 0.86,
		6: 0.95,
	},
	"atk_lvl": {
		1: 1,
		2: 2,
		3: 3,
		4: 4,
		5: 5,
		6: 6,
	},
	"def_lvl": {
		1: 1,
		2: 1,
		3: 2,
		4: 2,
		5: 3,
		6: 3,
	}

}
