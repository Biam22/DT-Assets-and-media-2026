extends Area2D
@onready var growth_bar: TextureProgressBar = $UI_Bar/UI_growth


var has_grown: bool = false
var Soil_ready: bool = false
var is_growing: bool = false 
var is_ready_to_harvest: bool = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	growth_bar.visible = false 

func _pop_tween() -> void:
	var tween = create_tween()
	tween.tween_property($DirtMain , "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property($DirtMain , "scale", Vector2(1, 1), 0.1)
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
		has_grown = true
		return
		
	elif has_grown and not is_growing and not is_ready_to_harvest:
		is_growing = true
		print("Plant!")
		$DirtMain.frame = 2
		_pop_tween()
		await get_tree().create_timer(0.1).timeout
		Growth_timer()
		
	
	elif is_ready_to_harvest:
		_harvest()
		return
		
	
func Growth_timer() -> void:
	await Growth_bar(10.0)
	print("Growing stage1")
	$DirtMain.frame = 3
	await Growth_bar(20.0)
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
	has_grown = false
	Soil_ready = false
	is_growing = false 
	is_ready_to_harvest = false
	
	$DirtMain.scale = Vector2(1, 1)
	$DirtMain.modulate.a = 1.0
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
	
	
	
		
		
		
