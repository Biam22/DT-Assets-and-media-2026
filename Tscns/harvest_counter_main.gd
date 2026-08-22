extends Sprite2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false 
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if visible:
		fade_out()


func fade_out(): #this makes the tick fade out
	var tween_fadeout = create_tween()
	tween_fadeout.tween_property(self, "modulate:a", 0.0, 1.0)
	Vector2(0,-100)# just gets it off the screen
	
	
