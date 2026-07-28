extends Area2D

var has_grown: bool = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	
	
	
	if Input.is_action_pressed("Left_Click"):
		if has_grown:
			return
		has_grown = true 
		print("Plant!!")
		$Dirt.play("Growth")
		await get_tree().create_timer(0.3).timeout
		$Dirt.pause()
		
		
