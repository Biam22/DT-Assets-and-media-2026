extends Node2D



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	HarvestCounter.reset_counter()
	HarvestCounterMain.reset_counter()
	await get_tree().create_timer(120).timeout
	$Score.visible = true 
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
