extends Node2D

signal finished(completed: bool)

const TILL_TIME := 0.7
const SEEDS_NEEDED := 3

enum Phase { TILL, SEED }

var active := false
var phase: int = Phase.TILL
var plots: Array = []
var dragging := false
var hover = null

var info_layer: CanvasLayer
var info_label: Label
var bag_sprite: Sprite2D
var dirt_particles: CPUParticles2D
var seed_particles: CPUParticles2D

func _ready() -> void:
	z_index = 10
	_build_ui()
	_build_particles()

func is_active() -> bool:
	return active

func _build_ui() -> void:
	info_layer = CanvasLayer.new()
	info_layer.layer = 10
	info_layer.visible = false
	add_child(info_layer)

	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	panel.offset_bottom = -12

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.75)
	style.set_content_margin_all(16)
	style.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", style)

	info_label = Label.new()
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(info_label)
	info_layer.add_child(panel)

func _build_particles() -> void:
	dirt_particles = CPUParticles2D.new()
	dirt_particles.emitting = false
	dirt_particles.amount = 14
	dirt_particles.lifetime = 0.4
	dirt_particles.lifetime_randomness = 0.3
	dirt_particles.direction = Vector2(0, -0.4)
	dirt_particles.spread = 50.0
	dirt_particles.initial_velocity_min = 40.0
	dirt_particles.initial_velocity_max = 80.0
	dirt_particles.gravity = Vector2(0, 300.0)
	dirt_particles.scale_amount_min = 1.6
	dirt_particles.scale_amount_max = 2.6
	dirt_particles.randomness = 0.4
	var dirt_ramp := Gradient.new()
	dirt_ramp.add_point(0.0, Color(0.33, 0.23, 0.13, 1.0))
	dirt_ramp.add_point(1.0, Color(0.25, 0.17, 0.09, 0.0))
	dirt_particles.color_ramp = dirt_ramp
	add_child(dirt_particles)

	seed_particles = CPUParticles2D.new()
	seed_particles.emitting = false
	seed_particles.one_shot = true
	seed_particles.explosiveness = 1.0
	seed_particles.amount = 6
	seed_particles.lifetime = 0.45
	seed_particles.direction = Vector2(0, -1)
	seed_particles.spread = 25.0
	seed_particles.initial_velocity_min = 30.0
	seed_particles.initial_velocity_max = 55.0
	seed_particles.gravity = Vector2(0, 220.0)
	seed_particles.scale_amount_min = 1.2
	seed_particles.scale_amount_max = 1.8
	seed_particles.randomness = 0.3
	var seed_ramp := Gradient.new()
	seed_ramp.add_point(0.0, Color(0.45, 0.55, 0.25, 1.0))
	seed_ramp.add_point(1.0, Color(0.3, 0.38, 0.16, 0.0))
	seed_particles.color_ramp = seed_ramp
	add_child(seed_particles)

	bag_sprite = Sprite2D.new()
	bag_sprite.texture = load("res://Sprites/UI/Nativebag.png")
	bag_sprite.visible = false
	add_child(bag_sprite)

func _plot_at(pos: Vector2) -> Node:
	var params := PhysicsPointQueryParameters2D.new()
	params.position = pos
	params.collide_with_areas = true
	params.collide_with_bodies = false
	var hits: Array = get_world_2d().direct_space_state.intersect_point(params)
	for h in hits:
		var col = h.get("collider")
		if col and col.is_in_group("plots") and col.has_method("_mark_planted"):
			return col
	return null

func _bar_of(plot) -> TextureProgressBar:
	return plot.get_node_or_null("UI_Bar/UI_growth") as TextureProgressBar

func _dirt_of(plot) -> AnimatedSprite2D:
	return plot.get_node_or_null("DirtMain") as AnimatedSprite2D

func _pop(node: Node2D) -> void:
	if node == null:
		return
	var base: Vector2 = node.scale
	var t := create_tween()
	t.tween_property(node, "scale", base * 1.15, 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(node, "scale", base, 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _tilled_count() -> int:
	var n := 0
	for p in plots:
		if bool(p.get("soil_ready")):
			n += 1
	return n

func _planted_count() -> int:
	var n := 0
	for p in plots:
		if bool(p.get("is_planted")):
			n += 1
	return n

func _update_info() -> void:
	if phase == Phase.TILL:
		info_label.text = "BREAK UP THE SOIL\n\nHold left click and drag across every plot\nRight-click to cancel\n\nTilled: %d / %d" % [_tilled_count(), plots.size()]
	else:
		info_label.text = "SCATTER THE SEEDS\n\nHold left click and drag across each plot 3 times\nRight-click to cancel\n\nPlanted: %d / %d" % [_planted_count(), plots.size()]

func begin(_target = null) -> void:
	plots = get_tree().get_nodes_in_group("plots")
	var mine: Array = []
	for p in plots:
		if p.has_method("_mark_planted"):
			mine.append(p)
	plots = mine

	active = true
	phase = Phase.TILL
	dragging = false
	hover = null
	info_layer.visible = true

	if _tilled_count() >= plots.size():
		_enter_seed_phase()
	else:
		bag_sprite.visible = false
	_update_info()

func _enter_seed_phase() -> void:
	if phase == Phase.SEED:
		return
	phase = Phase.SEED
	bag_sprite.visible = true
	bag_sprite.global_position = get_global_mouse_position()
	_update_info()

func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		_finish(false)
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			dragging = true
			hover = null
			_sync_hover()
		else:
			dragging = false
			hover = null
			dirt_particles.emitting = false

func _sync_hover() -> void:
	var plot = _plot_at(get_global_mouse_position())
	if plot == hover:
		return
	_on_hover_changed(plot)

func _on_hover_changed(plot) -> void:
	hover = plot
	if dragging and plot != null and phase == Phase.SEED:
		_seed_step(plot)

func _process(delta: float) -> void:
	if not active:
		return

	var pos := get_global_mouse_position()
	if bag_sprite.visible:
		bag_sprite.global_position = pos

	_sync_hover()

	if dragging and hover != null and phase == Phase.TILL:
		_till_step(hover, delta)
	else:
		dirt_particles.emitting = false

func _till_step(plot, delta: float) -> void:
	if bool(plot.get("soil_ready")):
		return

	var prog: float = float(plot.get("till_progress")) + delta
	plot.set("till_progress", prog)

	var bar := _bar_of(plot)
	if bar:
		bar.visible = true
		bar.value = clampf(prog / TILL_TIME, 0.0, 1.0) * bar.max_value

	var dirt := _dirt_of(plot)
	if dirt:
		dirt_particles.global_position = dirt.global_position
	dirt_particles.emitting = true

	if prog >= TILL_TIME:
		_complete_till(plot)

func _complete_till(plot) -> void:
	plot.set("till_progress", TILL_TIME)
	plot.set("soil_ready", true)
	var dirt := _dirt_of(plot)
	if dirt:
		dirt.frame = 1
		_pop(dirt)
	var bar := _bar_of(plot)
	if bar:
		bar.visible = false
	_update_info()
	if _tilled_count() >= plots.size():
		_enter_seed_phase()

func _seed_step(plot) -> void:
	if not bool(plot.get("soil_ready")) or bool(plot.get("is_planted")):
		return

	var seeds: int = int(plot.get("seeds_dropped")) + 1
	plot.set("seeds_dropped", seeds)

	var dirt := _dirt_of(plot)
	if dirt:
		seed_particles.global_position = dirt.global_position
	seed_particles.restart()
	seed_particles.emitting = true

	var bar := _bar_of(plot)
	if bar:
		bar.visible = true
		bar.value = float(seeds) / float(SEEDS_NEEDED) * bar.max_value

	if seeds >= SEEDS_NEEDED:
		_complete_seed(plot)
	else:
		_update_info()

func _complete_seed(plot) -> void:
	var dirt := _dirt_of(plot)
	if dirt:
		dirt.frame = 2
		_pop(dirt)
	plot._mark_planted()
	var bar := _bar_of(plot)
	if bar:
		bar.visible = false
	_update_info()
	if _planted_count() >= plots.size():
		_finish(true)

func _finish(completed: bool) -> void:
	active = false
	dragging = false
	hover = null
	dirt_particles.emitting = false
	seed_particles.emitting = false
	bag_sprite.visible = false
	for p in plots:
		var bar := _bar_of(p)
		if bar:
			bar.visible = false
	if info_layer:
		info_layer.visible = false
	finished.emit(completed)
