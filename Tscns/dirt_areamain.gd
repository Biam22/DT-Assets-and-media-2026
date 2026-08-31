extends Area2D
@onready var growth_bar: TextureProgressBar = $UI_Bar/UI_growth
@onready var water_bar: TextureProgressBar = $UI_water/TextureProgressBar
var has_grown: bool = false
var Soil_ready: bool = false
var is_growing: bool = false 
var is_planted: bool = false 
var is_watered: bool = false
var is_ready_to_harvest: bool = false
var water_amount: float = 0.0        
var water_needed: float = 3.0 

func _ready() -> void:
	growth_bar.visible = false 
	water_bar.visible = false
	
func _pop_tween() -> void:
	var tween = create_tween()
	tween.tween_property($DirtMain, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property($DirtMain, "scale", Vector2(1, 1), 0.1)
	await tween.finished
	
func _water_flash() -> void:
	var tween = create_tween()
	tween.tween_property($DirtMain, "modulate", Color(0.6, 0.8, 1.2), 0.1)
	tween.tween_property($DirtMain, "modulate", Color(1, 1, 1), 0.15)
	await tween.finished

func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if not Input.is_action_just_pressed("Left_Click"):
		return 
		
	if not Soil_ready:
		Soil_ready = true
		print("Prepping soil!!")
		$DirtMain.frame = 1
		_pop_tween()
		await get_tree().create_timer(0.1).timeout
		return
		
	elif Soil_ready and not is_planted and not is_ready_to_harvest:
		is_planted = true
		print("Planted!")
		$DirtMain.frame = 2                        
		_pop_tween()
		await get_tree().create_timer(0.4).timeout
		return
		
	elif is_planted and not is_growing and not is_ready_to_harvest:
		if not is_watered:
			water_amount += 1.0
			print("Watering... (%s/%s)" % [water_amount, water_needed])
			water_bar.visible = true
			await _fill_water_bar_step()
			_pop_tween()
			_water_flash()
			
			if water_amount >= water_needed:
				is_watered = true
				await get_tree().create_timer(0.1).timeout
				is_growing = true
				print("Plant is growing!")
				water_bar.visible = false 
				Growth_timer()
			return
		
	elif is_ready_to_harvest:
		_harvest()
		return
		
func _fill_water_bar_step() -> void:
	var target: float = water_amount / water_needed
	var tween = create_tween()
	tween.tween_method(_update_water_bar, water_bar.value / water_bar.max_value, target, 0.2)
	await tween.finished

func _update_water_bar(progress: float) -> void:
	water_bar.value = progress * water_bar.max_value
	
func Growth_timer() -> void:
	await Growth_bar(5.0)
	print("Growing stage1")
	$DirtMain.frame = 3
	await Growth_bar(8.0)
	print("Growing stage2")
	$DirtMain.frame = 4
	$Tickmain.visible = true 
	is_ready_to_harvest = true
	return
	
func _harvest() -> void:
	if not is_ready_to_harvest:
		return
	is_ready_to_harvest = false
	print("Harvested!")
	var tween_done = create_tween()
	tween_done.set_parallel(true)
	tween_done.tween_property($DirtMain, "scale", Vector2(1.3, 1.3), 0.15)
	tween_done.tween_property($DirtMain, "modulate:a", 0.0, 0.2)
	await tween_done.finished
	
	HarvestCounter.add_harvest()
	$DirtMain.frame = 0
	Soil_ready = false
	is_planted = false
	is_growing = false
	is_watered = false
	is_ready_to_harvest = false
	water_amount = 0.0
	
	$DirtMain.scale = Vector2(1, 1)
	$DirtMain.modulate = Color(1, 1, 1, 1)
	
	growth_bar.visible = false
	growth_bar.value = 0
	water_bar.visible = false
	water_bar.value = 0
	
	$Tickmain.visible = false
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
