class_name MoveData
extends Resource

enum MoveType {STILL, JUMP, TELEPORT, DASH, FLY}

@export var move_type: MoveData.MoveType = MoveData.MoveType.STILL
@export var properties: Dictionary = {}

func _init(init_move_type: MoveData.MoveType = MoveData.MoveType.STILL):
	self.move_type = init_move_type
	match init_move_type:
		MoveData.MoveType.STILL:
			self.properties = {}
		MoveData.MoveType.JUMP:
			self.properties = {
				"height": 5, # example property for jump
			}
		MoveData.MoveType.TELEPORT:
			self.properties = {
				"range": 5, # example property for teleport
			}
		MoveData.MoveType.DASH:
			self.properties = {
				"speed": 10, # example property for dash
			}
		MoveData.MoveType.FLY:
			self.properties = {
				"height": 10, # example property for fly
			}
