extends Node2D

signal finished(completed: bool)

const FERTILIZER := "fertilizer"
const COMPOST := "compost"

var active := false
var tool_type := ""
var bag_sprite: Sprite2D
var field_area: Area2D
var sprinkling := false
var particles: GPUParticles2D
var hold_time := 0.0

var info_layer: CanvasLayer
var info_label: Label

func _ready() -> void:
	z_index = 10
	_build_ui()

func _build_ui() -> void:
	info_layer = CanvasLayer.new()
	info_layer.layer = 10
	info_layer.visible = false
	add_child(info_layer)

	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.offset_top = 12

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

	field_area = Area2D.new()
	field_area.collision_layer = 1
	field_area.collision_mask = 0
	field_area.global_position = Vector2(600, 400)
	add_child(field_area)

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(400, 300)
	shape.shape = rect
	field_area.add_child(shape)

	bag_sprite = Sprite2D.new()
	bag_sprite.texture = load("res://Sprites/UI/Compost.png")
	bag_sprite.scale = Vector2(1.0, 1.0)
	bag_sprite.visible = false
	add_child(bag_sprite)
	var material := ParticleProcessMaterial.new()
	material.direction = Vector3(0, 1, 0)
	material.spread = 70
	material.gravity = Vector3(0, 200, 0)
	material.initial_velocity_min = 50
	material.initial_velocity_max = 100
	material.scale_min = 2
	material.scale_max = 5
		
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.306, 0.513, 0.21, 1.0))
	gradient.set_color(1, Color(0.306, 0.513, 0.21, 1.0))

	var color_ramp := GradientTexture2D.new()
	color_ramp.gradient = gradient
	material.color_ramp = color_ramp

	particles = GPUParticles2D.new()
	particles.position = Vector2(0, 20)
	particles.emitting = false
	particles.amount = 60
	particles.lifetime = 0.5
	particles.process_material = material
	bag_sprite.add_child(particles)
		

func _update_info() -> void:
	var text := "SPREAD MODE\n"
	text += "Hold click over the field to sprinkle\n"
	text += "Release to finish\n"
	text += "Right-click to go back\n"
	info_label.text = text

func begin(_type: String = "") -> void:
	active = true
	tool_type = _type
	sprinkling = false
	hold_time = 0.0
	if not is_instance_valid(bag_sprite):
		bag_sprite = Sprite2D.new()
		bag_sprite.scale = Vector2(1.0, 1.0)
		add_child(bag_sprite)
	
	if _type == FERTILIZER:
		bag_sprite.texture = load("res://Sprites/UI/heavy fertilizer.png")
	else:
		bag_sprite.texture = load("res://Sprites/UI/Compost.png")
	bag_sprite.visible = true
	bag_sprite.rotation = 0
	bag_sprite.modulate.a = 1.0
	info_layer.visible = true
	_update_info()

func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		_finish(false)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if is_instance_valid(bag_sprite):
				sprinkling = true
				hold_time = 0.0
				bag_sprite.rotation = 0.8
				particles.emitting = true
		else:
			if sprinkling and hold_time >= 0.5:
				_spread()
				_finish(true)
			else:
				_finish(false)
			sprinkling = false
			if is_instance_valid(bag_sprite):
				bag_sprite.rotation = 0
			if is_instance_valid(particles):
				particles.emitting = false
	elif event is InputEventMouseMotion:
		if is_instance_valid(bag_sprite):
			bag_sprite.global_position = get_global_mouse_position()

func _process(delta: float) -> void:
	if not active or not sprinkling or not is_instance_valid(bag_sprite):
		return
	hold_time += delta

func _spread() -> void:
	if not is_instance_valid(bag_sprite):
		return
	particles.emitting = false
	sprinkling = false
	var tween := create_tween()
	tween.tween_property(bag_sprite, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func():
		if is_instance_valid(bag_sprite):
			bag_sprite.visible = false
	)

func _finish(completed: bool) -> void:
	active = false
	sprinkling = false
	if is_instance_valid(particles):
		particles.emitting = false
	if is_instance_valid(bag_sprite):
		bag_sprite.rotation = 0
		bag_sprite.visible = false
	info_layer.visible = false
	finished.emit(completed)
