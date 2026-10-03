extends Node2D

signal season_harvested

var plots: Array = []
var planted_count := 0
var harvested_count := 0

func _ready() -> void:
	GameState.farm_locked = SeasonFX.busy

	var trees_node := find_child("Trees", true, false)
	if trees_node == null:
		push_error("Can't find a node called Trees under " + name)
	else:
		for tree in trees_node.get_children():
			if str(tree.name) in GameState.cleared_trees:
				tree.queue_free()
			else:
				tree.add_to_group("trees")

	HarvestCounter.reset_counter()
	HarvestCounterMain.reset_counter()

	plots = get_tree().get_nodes_in_group("plots")
	for plot in plots:
		plot.planted.connect(_on_plot_planted)
		plot.harvested.connect(_on_plot_harvested)

func _on_plot_planted() -> void:
	print("plot planted")
	planted_count += 1
	if planted_count >= plots.size():
		_run_season()

func _run_season() -> void:
	print("season running")
	GameState.farm_locked = true
	await get_tree().create_timer(0.8).timeout
	await $Score.run_choice()
	await _grow_and_harvest()
	await get_tree().create_timer(0.8).timeout
	$Score.show_results()

func _grow_and_harvest() -> void:
	var result: Dictionary = GameState.harvest_season()
	var count := plots.size()
	var total := int(result["crops"])
	var share := floori(float(total) / count)
	harvested_count = 0
	for i in count:
		var crops := share
		if i == count - 1:
			crops = total - share * (count - 1)
		plots[i].grow_and_harvest(crops)
	await season_harvested
	var money_earned := int(result["crops"]) * 10
	GameState.money += money_earned

func _on_plot_harvested() -> void:
	harvested_count += 1
	if harvested_count >= plots.size():
		season_harvested.emit()
