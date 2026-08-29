extends Node

signal harvest_count_changed(new_count: int)
signal score_changed(new_score: int)

var count: int = 0
var score: int = 0

var price_per_plant: int = 10

func add_harvest(amount: int = 1) -> void:
	count += amount
	score += amount * price_per_plant
	harvest_count_changed.emit(count)
	score_changed.emit(score)

func reset_counter() -> void:
	count = 0
	score = 0
	harvest_count_changed.emit(count)
	score_changed.emit(score)
