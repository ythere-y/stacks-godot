class_name UnitCardData
extends BaseCardData


enum Team {
	NEUTRAL,
	PLAYER,
	ENEMY
}
enum AttackType {
	MELEE,
	RANGED,
	MAGIC
}
enum AutoMoveType {
	NONE,
	WALK,
	JUMP,
	DASH
}
@export_category("Current States")

@export_group("current states", "current")
@export var current_health: int = 10
@export var current_attack: int = 0
@export var current_defense: int = 0
@export var current_attack_speed: float = 1.0
@export var current_hit_chance: float = 1.0

@export_category("Base Attributes")
@export_group("define states")
@export var attack_type: AttackType = AttackType.MELEE
@export var health: int = 10
@export var attack: int = 0
@export var defense: int = 0
@export var attack_speed: int = 1
@export var hit_chance: int = 1
@export var team: Team = Team.NEUTRAL
@export var skills: Array = [] # Example: [{name: "Slash", damage: 10, cooldown: 1.5}
@export var auto_move_type: AutoMoveType = AutoMoveType.NONE
@export var auto_move_params: Dictionary = {} # Example: {"walk": {"speed": 2.0}, "jump": {"height": 3.0}, "dash": {"distance": 5.0, "cooldown": 4.0}}
@export var loot_table: Array = [] # Example: [{id: "gold_coin", chance: 0.5}, {id: "iron_sword", chance: 0.1}]
func update_current_states():
	# 根据当前等级或其他因素更新当前状态值
	# TODO：后续需要加入装备、buff等因素对状态的影响
	var cur_def_lvl = defense
	current_defense = GameSettings.BATTLE_STATS_TABLE["def_lvl"][cur_def_lvl]
	var cur_atk_lvl = attack
	current_attack = GameSettings.BATTLE_STATS_TABLE["atk_lvl"][cur_atk_lvl]
	var cur_atk_spd_lvl = attack_speed
	current_attack_speed = GameSettings.BATTLE_STATS_TABLE["spd_lvl"][cur_atk_spd_lvl]
	var cur_hit_chance_lvl = hit_chance
	current_hit_chance = GameSettings.BATTLE_STATS_TABLE["hit_chance"][cur_hit_chance_lvl]
func take_damage(amount: int):
	current_health -= amount
	if current_health <= 0:
		current_health = 0
		return true # Indicates the unit has died
	return false
func from_dict(dict: Dictionary) -> UnitCardData:
	super.from_dict(dict) # 先解析通用属性
	match dict.get("attack_type", "melee"):
		"melee":
			attack_type = AttackType.MELEE
		"ranged":
			attack_type = AttackType.RANGED
		"magic":
			attack_type = AttackType.MAGIC
	
	health = dict.get("health", 10)
	attack = dict.get("atk_lvl", 1)
	defense = dict.get("def_lvl", 1)
	attack_speed = dict.get("spd_lvl", 1)
	hit_chance = dict.get("hit_chance_lvl", 1)
	current_health = health
	update_current_states()
	match dict.get("team", "neutral"):
		"neutral":
			team = Team.NEUTRAL
		"player":
			team = Team.PLAYER
		"enemy":
			team = Team.ENEMY
	
	skills = dict.get("skills", [])
	auto_move_params = dict.get("auto_move_type", {})
	match auto_move_params.get("move_type", "none"):
		"none":
			auto_move_type = AutoMoveType.NONE
		"walk":
			auto_move_type = AutoMoveType.WALK
		"jump":
			auto_move_type = AutoMoveType.JUMP
		"dash":
			auto_move_type = AutoMoveType.DASH

	loot_table = dict.get("loot_table", [])
	return self
