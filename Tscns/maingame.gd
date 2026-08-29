extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	HarvestCounter.reset_counter()
	HarvestCounterMain.reset_counter()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
