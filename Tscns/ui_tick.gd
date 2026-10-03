extends Sprite2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false
	modulate.a = 0.0
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func fade_out(): #this makes the tick fade out
	var tween_fadeout: Tween = create_tween()
	tween_fadeout.set_parallel(true)
	tween_fadeout.tween_property(self, "modulate:a", 0.0, 0.5)
	tween_fadeout.tween_property(self, "position", Vector2(0, -40), 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween_fadeout.tween_property(self, "scale", Vector2(1.1, 1.1), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	
