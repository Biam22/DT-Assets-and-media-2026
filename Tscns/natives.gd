extends Node2D

signal finished(completed: bool)

const HERBICIDE := "herbicide"
const NATIVES := "natives"

var active := false
var tool_type := ""
var cursor: Sprite2D
var spray_area: Area2D
var spraying := false
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

	spray_area = Area2D.new()
	spray_area.collision_layer = 1
	spray_area.global_position = Vector2(600, 400)
	add_child(spray_area)

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(500, 400)
	shape.shape = rect
	spray_area.add_child(shape)

	cursor = Sprite2D.new()
	cursor.texture = load("res://Sprites/UI/Nativebag.png")
	cursor.scale = Vector2(0.6, 0.6)
	cursor.visible = false
	add_child(cursor)

	var material := ParticleProcessMaterial.new()
	material.direction = Vector3(0, 0, 0)
	material.spread = 180
	material.gravity = Vector3(0, 100, 0)
	material.initial_velocity_min = 100
	material.initial_velocity_max = 200
	material.scale_min = 1.5
	material.scale_max = 4.5

	particles = GPUParticles2D.new()
	particles.position = Vector2(0, 0)
	particles.emitting = false
	particles.amount = 30
	particles.lifetime = 0.6
	particles.process_material = material
	cursor.add_child(particles)

func _update_info() -> void:
	var text := "PLANT MODE\n"
	text += "Hold click over the field to plant\n"
	text += "Release to finish\n"
	text += "Right-click to go back\n"
	info_label.text = text

func begin(_type: String = "") -> void:
	active = true
	tool_type = _type
	spraying = false
	hold_time = 0.0
	if not is_instance_valid(cursor):
		cursor = Sprite2D.new()
		cursor.scale = Vector2(0.6, 0.6)
		add_child(cursor)
		var material := ParticleProcessMaterial.new()
		material.direction = Vector3(0, 0, 0)
		material.spread = 180
		material.gravity = Vector3(0, 100, 0)
		material.initial_velocity_min = 100
		material.initial_velocity_max = 200
		material.scale_min = 0.15
		material.scale_max = 0.25
		material.color = Color(0.0, 1.0, 0.294, 1.0)
		
		particles = GPUParticles2D.new()
		particles.position = Vector2(0, 0)
		particles.emitting = false
		particles.amount = 30
		particles.lifetime = 0.6
		particles.process_material = material
		cursor.add_child(particles)
	if _type == HERBICIDE:
		cursor.texture = load("res://Sprites/UI/herbicides_spray.png")
	else:
		cursor.texture = load("res://Sprites/UI/Nativebag.png")
	cursor.visible = true
	cursor.rotation = 0
	info_layer.visible = true
	_update_info()

func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		_finish(false)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if is_instance_valid(cursor):
				spraying = true
				hold_time = 0.0
				particles.emitting = true
		else:
			if spraying and hold_time >= 0.5:
				_finish(true)
			else:
				_finish(false)
			spraying = false
			if is_instance_valid(particles):
				particles.emitting = false
	elif event is InputEventMouseMotion:
		if is_instance_valid(cursor):
			cursor.global_position = get_global_mouse_position()

func _process(delta: float) -> void:
	if not active or not spraying or not is_instance_valid(cursor):
		return
	hold_time += delta

func _finish(completed: bool) -> void:
	active = false
	spraying = false
	if is_instance_valid(particles):
		particles.emitting = false
	if is_instance_valid(cursor):
		cursor.visible = false
	info_layer.visible = false
	finished.emit(completed)
