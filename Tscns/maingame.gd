extends Node2D



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var trees_node := find_child("Trees", true, false)
	if trees_node == null:
		push_error("Can't find a node called Trees under " + name)
		return
		
	for tree in trees_node.get_children():
		if str(tree.name) in GameState.cleared_trees:
			tree.queue_free()
		else:
			tree.add_to_group("trees")

	HarvestCounter.reset_counter()
	HarvestCounterMain.reset_counter()
	await get_tree().create_timer(20).timeout
	$Score.show_results()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
