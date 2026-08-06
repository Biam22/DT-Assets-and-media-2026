extends Area2D
@onready var growth_bar: TextureProgressBar = $UI_Bar/UI_growth

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
		
	
func Growth_timer() -> void:
	await Growth_bar(5.0)
	print("Growing stage1")
	$Dirt.frame = 3
	await  Growth_bar(8.0)
	print("Growing stage2")
	$Dirt.frame = 4
	return
	
func Growth_bar(duration: float) -> void: 
	growth_bar.value = 0 
	growth_bar.visible = true 
	
	var tween = create_tween()
	tween.tween_method(_update_bar, 0.0, 1.0, duration)
	await tween.finished
	
	growth_bar.visible = false 
	
func _update_bar(progress: float) -> void:
	growth_bar.value = progress * growth_bar.max_value

	
	
	
	
		
		
		
