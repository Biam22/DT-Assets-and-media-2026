extends Node

signal harvest_count_changed(new_count: int)

var count: int = 0

func add_harvest(amount: int = 1) -> void:
	count += amount
	harvest_count_changed.emit(count)

func reset_counter() -> void:
	count = 0
	harvest_count_changed.emit(count)
