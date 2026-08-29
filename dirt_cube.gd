extends Area2D
@onready var growth_bar: TextureProgressBar = $UI_Bar/UI_growth
@onready var water_bar:TextureProgressBar = $UI_water/TextureProgressBar

var has_grown: bool = false
var Soil_ready: bool = false
var is_growing: bool = false 
var is_planted: bool = false 
var is_watered: bool = false
var is_ready_to_harvest: bool = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	growth_bar.visible = false 
	water_bar.visible = false
	TutorialUI.show_step(0) 

func _pop_tween() -> void:
	var tween = create_tween()
	tween.tween_property($Dirt , "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property($Dirt , "scale", Vector2(1, 1), 0.1)
	await tween.finished
	

func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	
	if not Input.is_action_just_pressed("Left_Click"):
		return 
		
	if not Soil_ready:
		Soil_ready = true
		print("Prepping soil!!")
		$Dirt.frame = 1
		_pop_tween()
		TutorialUI.show_step(2)
		await get_tree().create_timer(0.1).timeout
		return
		
	elif Soil_ready and not is_planted and not is_ready_to_harvest:
		is_planted = true
		print("Planted!")
		$Dirt.frame = 2                
		TutorialUI.show_step(3)        
		_pop_tween()
		await get_tree().create_timer(0.1).timeout
		return
		
	elif is_planted and not is_growing and not is_ready_to_harvest:
		if not is_watered:
			is_watered = true
			print("Watered!")
			$Dirt.frame = 2 
			await Water_bar(0.3)
			_pop_tween()
			await get_tree().create_timer(0.4).timeout
		
			is_growing = true
			print("Plant is growing!")
			TutorialUI.show_step(4)
			Growth_timer()
			return

	elif is_ready_to_harvest:
		_harvest()
		return
		
func Water_bar(duration: float) -> void:
	water_bar.value = 0
	water_bar.visible = true
	
	var tween = create_tween()
	tween.tween_method(_update_water_bar, 0.0, 1.0, duration)
	await tween.finished
	
	water_bar.visible = false


func _update_water_bar(progress: float) -> void:
	water_bar.value = progress * water_bar.max_value
	

	
func Growth_timer() -> void:
	await Growth_bar(5.0)
	print("Growing stage1")
	$Dirt.frame = 3
	await  Growth_bar(8.0)
	print("Growing stage2")
	$Dirt.frame = 4
	TutorialUI.show_step(5)
	$UI_Tick.visible = true 
	is_ready_to_harvest = true
	return
	
	
func _harvest() -> void:
	if not is_ready_to_harvest:
		return
	is_ready_to_harvest = false
	print("Harvested!")
	var tween_done = create_tween()
	tween_done.set_parallel(true)
	tween_done.tween_property($Dirt, "scale", Vector2(1.3, 1.3), 0.15)
	tween_done.tween_property($Dirt, "modulate:a", 0.0, 0.2)
	await tween_done.finished
	
	HarvestCounter.add_harvest()
	TutorialUI.show_step(6)
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
	
	
	
		
		
		
