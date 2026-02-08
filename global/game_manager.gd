extends Node

# Singleton for managing global game state (Days, Gold, Etc)

signal day_ended
signal gold_changed(new_amount)

var current_day: int = 1
var gold: int = 0

func add_gold(amount: int):
	gold += amount
	emit_signal("gold_changed", gold)

func end_day():
	current_day += 1
	emit_signal("day_ended")
	print("Day ", current_day, " started.")
