extends Area2D


var has_grown: bool = false
var Soil_prep: bool = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	
	if not Input.is_action_pressed("Left_Click"):
		return 
		
	if not Soil_prep:
		Soil_prep = true
		print("Prepping soil!!")
		$Dirt.frame = 1
		await get_tree().create_timer(0.1).timeout
		has_grown = true
		return
		
	elif has_grown:
		print("Plant!")
		$Dirt.frame = 2
		Growth_timer()
	
func Growth_timer():
	await get_tree().create_timer(5).timeout
	$Dirt.frame = 3
	await get_tree().create_timer(8).timeout
	$Dirt.frame = 4
	return
	
	
		
		
		
