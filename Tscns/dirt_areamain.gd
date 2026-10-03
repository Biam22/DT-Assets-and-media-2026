extends Area2D

signal planted
signal harvested

const GROW_TIME_ONE := 3.0
const GROW_TIME_TWO := 4.0

@onready var growth_bar: TextureProgressBar = $UI_Bar/UI_growth

var soil_ready: bool = false
var is_planted: bool = false
var till_progress: float = 0.0
var seeds_dropped: int = 0
var planting = null

func _ready() -> void:
	add_to_group("plots")
	growth_bar.visible = false
	var water_ui := get_node_or_null("UI_water")
	if water_ui:
		water_ui.visible = false

	var scene: Node = get_tree().current_scene
	if scene:
		planting = scene.get_node_or_null("MiniGames/Planting")

func _mark_planted() -> void:
	if is_planted:
		return
	is_planted = true
	planted.emit()

func _spawn_dirt_particles() -> void:
	var particles: CPUParticles2D = CPUParticles2D.new()
	particles.emitting = false
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = 12
	particles.lifetime = 0.55
	particles.lifetime_randomness = 0.35
	particles.position = Vector2(0, 4)

	particles.direction = Vector2(0, -0.3)
	particles.spread = 55.0
	particles.initial_velocity_min = 55.0
	particles.initial_velocity_max = 95.0
	particles.gravity = Vector2(0, 320.0)
	particles.damping_min = 0.0
	particles.damping_max = 0.0
	particles.angular_velocity_min = -220.0
	particles.angular_velocity_max = 220.0
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 3.4
	particles.randomness = 0.4

	var color_ramp: Gradient = Gradient.new()
	color_ramp.add_point(0.0, Color(0.33, 0.23, 0.13, 1.0))
	color_ramp.add_point(0.7, Color(0.29, 0.2, 0.11, 1.0))
	color_ramp.add_point(1.0, Color(0.25, 0.17, 0.09, 0.0))
	particles.color = Color(1, 1, 1, 1)
	particles.color_ramp = color_ramp

	add_child(particles)
	particles.global_position = $DirtMain.global_position
	particles.emitting = true

	await get_tree().create_timer(particles.lifetime + 0.1).timeout
	if is_instance_valid(particles):
		particles.queue_free()

func _pop_tween() -> void:
	var tween: Tween = create_tween()
	tween.tween_property($DirtMain, "scale", Vector2(1.15, 1.15), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property($DirtMain, "scale", Vector2(1, 1), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tween.finished

func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if GameState.farm_locked:
		return
	if not Input.is_action_just_pressed("Left_Click"):
		return
	if planting == null:
		return
	if is_planted or planting.is_active():
		return
	planting.begin(self)

func _fly_crops_to_counter(amount: int) -> void:
	var scene: Node = get_tree().current_scene
	if scene == null:
		return

	var counter: Control = scene.find_child("Counting", true, false)
	if counter == null:
		return

	var start_pos: Vector2 = $DirtMain.global_position
	var target_pos: Vector2 = counter.global_position + (counter.size * 0.5)

	var crop_texture: Texture2D = load("res://Sprites/UI/Planticon.png")
	if crop_texture == null:
		return

	var spawn_count: int = amount
	if spawn_count < 1:
		spawn_count = 1
	if spawn_count > 8:
		spawn_count = 8

	for i in spawn_count:
		var crop: Sprite2D = Sprite2D.new()
		crop.texture = crop_texture
		crop.scale = Vector2(0.55, 0.55)
		crop.z_index = 5
		crop.global_position = start_pos + Vector2(randf_range(-10.0, 10.0), randf_range(-10.0, 10.0))
		get_tree().current_scene.add_child(crop)

		var t: Tween = create_tween()
		t.set_parallel(true)
		var delay: float = randf_range(0.0, 0.02)
		t.tween_property(crop, "global_position", target_pos, 0.4).set_delay(delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		t.tween_property(crop, "scale", Vector2(0.22, 0.22), 0.4).set_delay(delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		t.tween_property(crop, "modulate:a", 0.0, 0.35).set_delay(delay + 0.05)
		t.finished.connect(func():
			if is_instance_valid(crop):
				crop.queue_free()
		)

func grow_and_harvest(crops: int) -> void:
	await get_tree().create_timer(randf_range(0.0, 0.5)).timeout
	await _fill_growth_bar(GROW_TIME_ONE)
	$DirtMain.frame = 3
	await _fill_growth_bar(GROW_TIME_TWO)
	$DirtMain.frame = 4
	$Tickmain.visible = true
	$Tickmain.modulate.a = 1.0
	$Tickmain.position = $Tickmain.position
	$Tickmain.scale = Vector2(0.9, 0.9)
	var tick_t: Tween = create_tween()
	tick_t.set_parallel(true)
	tick_t.tween_property($Tickmain, "position", $Tickmain.position + Vector2(0, -15), 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tick_t.tween_property($Tickmain, "scale", Vector2(1.1, 1.1), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tick_t.tween_property($Tickmain, "modulate:a", 0.0, 0.35).set_delay(0.15)
	tick_t.finished.connect(func():
		if is_instance_valid($Tickmain):
			$Tickmain.visible = false
	)
	await get_tree().create_timer(0.7).timeout

	var tween_pop: Tween = create_tween()
	tween_pop.set_parallel(true)
	tween_pop.tween_property($DirtMain, "scale", Vector2(1.2, 1.2), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween_pop.tween_property($DirtMain, "modulate:a", 0.0, 0.15)
	await tween_pop.finished

	_fly_crops_to_counter(crops)
	await get_tree().create_timer(0.38).timeout
	HarvestCounter.add_harvest(crops)

	$DirtMain.frame = 0
	$DirtMain.scale = Vector2(1, 1)
	$DirtMain.modulate = Color(1, 1, 1, 1)
	soil_ready = false
	is_planted = false
	till_progress = 0.0
	seeds_dropped = 0
	harvested.emit()

func _fill_growth_bar(duration: float) -> void:
	growth_bar.value = 0
	growth_bar.visible = true
	var tween: Tween = create_tween()
	tween.tween_method(_update_bar, 0.0, 1.0, duration)
	await tween.finished
	growth_bar.visible = false

func _update_bar(progress: float) -> void:
	growth_bar.value = progress * growth_bar.max_value
