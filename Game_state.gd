extends Node

var money := 0
var level := 1
var soil_health := 100
var yield_bonus := 0
var pollinators := 100
var trees_cleared := 0
var cleared_trees: Array = []
var per_level_effects := []   
var hives: Array = []

func choose(effects: Dictionary, per_level: Dictionary) -> void:
	for key in effects:                       
		set(key, get(key) + effects[key])
	if not per_level.is_empty():       
		per_level_effects.append(per_level)

func start_level() -> void:
	level += 1
	for effect in per_level_effects:
		for key in effect:
			set(key, get(key) + effect[key])
