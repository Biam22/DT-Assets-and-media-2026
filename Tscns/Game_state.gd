extends Node

signal money_changed(new_amount: int)

const BASE_CROPS := 8000
const MAX_HEALTH := 150
const TOTAL_SEASONS := 3

var level := 1
var soil_health := 100
var plant_health := 100
var total_crops := 0
var farm_locked := false
var playthrough := 1
var previous_score := 0

var money := 0:
	set(value):
		money = value
		money_changed.emit(money)

var per_level_effects: Array = []
var season_history: Array = []
var last_harvest: Dictionary = {}
var cleared_trees: Array = []
var hives: Array = []

func choose(effects: Dictionary, per_level: Dictionary) -> void:
	for key in effects:
		set(key, get(key) + effects[key])
	if not per_level.is_empty():
		per_level_effects.append(per_level)
	_clamp_health()

func start_level() -> void:
	level += 1
	for effect in per_level_effects:
		for key in effect:
			set(key, get(key) + effect[key])
	_clamp_health()

func _clamp_health() -> void:
	soil_health = clampi(soil_health, 10, MAX_HEALTH)
	plant_health = clampi(plant_health, 0, MAX_HEALTH)

func yield_value() -> int:
	return soil_health + plant_health

func expected_crops() -> int:
	return int(round(BASE_CROPS * yield_value() / 200.0))

func snapshot() -> Dictionary:
	return {
		"soil_health": soil_health,
		"plant_health": plant_health,
		"yield": yield_value(),
		"crops": expected_crops(),
	}

func harvest_season() -> Dictionary:
	var result := {
		"season": level,
		"soil_health": soil_health,
		"plant_health": plant_health,
		"yield": yield_value(),
		"potential": BASE_CROPS,
		"crops": expected_crops(),
	}
	total_crops += int(result["crops"])
	season_history.append(result)
	last_harvest = result
	return result

func reset_run() -> void:
	level = 1
	soil_health = 100
	plant_health = 100
	total_crops = 0
	farm_locked = false
	money = 0
	per_level_effects.clear()
	season_history.clear()
	last_harvest = {}
	cleared_trees.clear()
	hives.clear()
