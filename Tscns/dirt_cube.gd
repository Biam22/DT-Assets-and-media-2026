extends Area2D
@onready var growth_bar: TextureProgressBar = $UI_Bar/UI_growth

const TILL_TIME := 0.7
const SEEDS_NEEDED := 3

const GROW_TIME_ONE := 3.0
const GROW_TIME_TWO := 4.0

const FIRST_STEP := 0
const TILL_STEP := 1
const SEED_STEP := 2
const GROW_STEP := 3
const FINAL_STEP := 4

var has_grown: bool = false
var Soil_ready: bool = false
var is_planted: bool = false
var is_harvested: bool = false

var till_progress: float = 0.0
var seeds_dropped: int = 0

var _pointer_inside: bool = false
var _was_held: bool = false


const WELCOME_DELAY := 2.0
var _welcome_elapsed: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	growth_bar.visible = false
	var water_ui := get_node_or_null("UI_water")
	if water_ui:
		water_ui.visible = false
	TutorialUI.last_step = FINAL_STEP
	if TutorialUI.current_index < 0:
		TutorialUI.show_step(FIRST_STEP)

func _sibling_plots() -> Array:
	var holder := get_parent()
	while holder != null and holder.name != "Plants":
		holder = holder.get_parent()
	if holder == null:
		return [self]
	var found: Array = []
	for child in holder.get_children():
		var area = child.get_node_or_null("Dirt cube")
		if area != null:
			found.append(area)
	if found.is_empty():
		return [self]
	return found

func _all_of(field: String) -> bool:
	for p in _sibling_plots():
		if not bool(p.get(field)):
			return false
	return true

func _rect() -> Rect2:
	var shape := $Collisiondirt.shape as RectangleShape2D
	if shape == null:
		return Rect2()
	var s: Vector2 = shape.size
	return Rect2(-s * 0.5, s)

func _pointer_over_me() -> bool:
	return _rect().has_point(to_local(get_global_mouse_position()))

func _check_milestones() -> void:
	match TutorialUI.current_index:
		TILL_STEP:
			if _all_of("Soil_ready"):
				TutorialUI.show_step(SEED_STEP)
		SEED_STEP:
			if _all_of("is_planted"):
				TutorialUI.show_step(GROW_STEP)
		GROW_STEP:
			if _all_of("is_harvested"):
				TutorialUI.show_step(FINAL_STEP)

func _spawn_dirt_particles() -> void:
	var particles := CPUParticles2D.new()
	particles.emitting = false
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = 10
	particles.lifetime = 0.45
	particles.lifetime_randomness = 0.3

	particles.position = Vector2(0, 3)
	particles.direction = Vector2(0, -0.3)
	particles.spread = 45.0
	particles.initial_velocity_min = 40.0
	particles.initial_velocity_max = 70.0
	particles.gravity = Vector2(0, 260.0)
	particles.damping_min = 0.0
	particles.damping_max = 0.0
	particles.angular_velocity_min = -180.0
	particles.angular_velocity_max = 180.0
	particles.scale_amount_min = 1.4
	particles.scale_amount_max = 2.2
	particles.randomness = 0.35

	var color_ramp := Gradient.new()
	color_ramp.add_point(0.0, Color(0.33, 0.23, 0.13, 1.0))
	color_ramp.add_point(0.7, Color(0.29, 0.2, 0.11, 1.0))
	color_ramp.add_point(1.0, Color(0.25, 0.17, 0.09, 0.0))
	particles.color = Color(1, 1, 1, 1)
	particles.color_ramp = color_ramp

	add_child(particles)
	particles.global_position = $Dirt.global_position
	particles.emitting = true

	await get_tree().create_timer(particles.lifetime + 0.1).timeout
	if is_instance_valid(particles):
		particles.queue_free()

func _spawn_seed_particles() -> void:
	var particles := CPUParticles2D.new()
	particles.emitting = false
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = 6
	particles.lifetime = 0.45
	particles.direction = Vector2(0, -1)
	particles.spread = 25.0
	particles.initial_velocity_min = 30.0
	particles.initial_velocity_max = 55.0
	particles.gravity = Vector2(0, 220.0)
	particles.scale_amount_min = 1.2
	particles.scale_amount_max = 1.8
	particles.randomness = 0.3

	var color_ramp := Gradient.new()
	color_ramp.add_point(0.0, Color(0.45, 0.55, 0.25, 1.0))
	color_ramp.add_point(1.0, Color(0.3, 0.38, 0.16, 0.0))
	particles.color = Color(1, 1, 1, 1)
	particles.color_ramp = color_ramp

	add_child(particles)
	particles.global_position = $Dirt.global_position
	particles.emitting = true

	await get_tree().create_timer(particles.lifetime + 0.1).timeout
	if is_instance_valid(particles):
		particles.queue_free()

func _pop_tween() -> void:
	var tween: Tween = create_tween()
	tween.tween_property($Dirt , "scale", Vector2(1.15, 1.15), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property($Dirt , "scale", Vector2(1, 1), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tween.finished


func _process(delta: float) -> void:
	_check_milestones()

	if TutorialUI.current_index == FIRST_STEP:
		_welcome_elapsed += delta
		if _welcome_elapsed >= WELCOME_DELAY:
			TutorialUI.show_step(TILL_STEP)

	if is_planted:
		_pointer_inside = false
		_was_held = false
		return

	var held := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if held and not _was_held:
		_pointer_inside = false
	_was_held = held

	var over := _pointer_over_me()
	var entered := over and not _pointer_inside
	_pointer_inside = over

	if not held or not over:
		return

	if _all_of("Soil_ready"):
		if entered:
			_seed_step()
	else:
		_till_step(delta, entered)

func _till_step(delta: float, entered: bool) -> void:
	if Soil_ready:
		return

	if entered:
		_spawn_dirt_particles()

	till_progress += delta
	growth_bar.visible = true
	growth_bar.value = clampf(till_progress / TILL_TIME, 0.0, 1.0) * growth_bar.max_value

	if till_progress >= TILL_TIME:
		_complete_till()

func _complete_till() -> void:
	till_progress = TILL_TIME
	Soil_ready = true
	$Dirt.frame = 1
	_pop_tween()
	growth_bar.visible = false

func _seed_step() -> void:
	if not Soil_ready or is_planted:
		return

	seeds_dropped += 1
	_spawn_seed_particles()

	growth_bar.visible = true
	growth_bar.value = float(seeds_dropped) / float(SEEDS_NEEDED) * growth_bar.max_value

	if seeds_dropped >= SEEDS_NEEDED:
		is_planted = true
		$Dirt.frame = 2
		_pop_tween()
		growth_bar.visible = false
		_grow_and_harvest()

func _grow_and_harvest() -> void:
	await get_tree().create_timer(0.2).timeout
	await Growth_bar(GROW_TIME_ONE)
	print("Growing stage1")
	$Dirt.frame = 3
	await Growth_bar(GROW_TIME_TWO)
	print("Growing stage2")
	$Dirt.frame = 4
	has_grown = true

	$UI_Tick.visible = true
	$UI_Tick.modulate.a = 1.0
	$UI_Tick.position = Vector2(0, -50)
	$UI_Tick.scale = Vector2(0.9, 0.9)
	var tick_t: Tween = create_tween()
	tick_t.set_parallel(true)
	tick_t.tween_property($UI_Tick, "position", Vector2(0, -58), 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tick_t.tween_property($UI_Tick, "scale", Vector2(0.95, 0.95), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tick_t.tween_property($UI_Tick, "modulate:a", 0.0, 0.35).set_delay(0.15)
	tick_t.finished.connect(func():
		if is_instance_valid($UI_Tick):
			$UI_Tick.visible = false
	)

	await get_tree().create_timer(0.7).timeout
	await _harvest()

func _harvest() -> void:
	if is_harvested:
		return
	is_harvested = true
	print("Harvested!")
	var tween_done: Tween = create_tween()
	tween_done.set_parallel(true)
	tween_done.tween_property($Dirt, "scale", Vector2(1.2, 1.2), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween_done.tween_property($Dirt, "modulate:a", 0.0, 0.15)
	await tween_done.finished

	_fly_crops_to_counter(1)
	await get_tree().create_timer(0.38).timeout
	HarvestCounter.add_harvest()

func _fly_crops_to_counter(amount: int) -> void:
	var scene: Node = get_tree().current_scene
	if scene == null:
		return

	var counter: Control = scene.find_child("Counting", true, false)
	if counter == null:
		return

	var start_pos: Vector2 = $Dirt.global_position
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

func Growth_bar(duration: float) -> void:
	growth_bar.value = 0
	growth_bar.visible = true

	var tween = create_tween()
	tween.tween_method(_update_bar, 0.0, 1.0, duration)
	await tween.finished

	growth_bar.visible = false


func _update_bar(progress: float) -> void:
	growth_bar.value = progress * growth_bar.max_value
