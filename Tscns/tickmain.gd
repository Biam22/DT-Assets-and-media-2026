extends Sprite2D


# Called when the node enters the scene tree for the first time.extends Sprite2D

func _ready() -> void:
	visible = false
	visibility_changed.connect(_on_visibility_changed)

func _on_visibility_changed() -> void:
	if visible:
		modulate.a = 1.0
		fade_out()

func fade_out():
	var tween_fadeout = create_tween()
	tween_fadeout.tween_property(self, "modulate:a", 0.0, 1.0)
	await tween_fadeout.finished
	visible = false
	
