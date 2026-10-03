extends Node2D

signal finished(completed: bool)

const PLANT_PER_HIVE := 2
const PLANT_PER_HIVE_SEASON := 1
const SOIL_PER_HIVE_SEASON := 1
const SPOT_LAYER_MASK := 4
const OUTLINE_COLOR := Color(1, 0.9, 0.2)
const SPOT_COLOR := Color(1, 1, 1, 0.5)

@export var hive_texture: Texture2D

var active := false
var hovered_spot: Node = null
var spots_node: Node
var placed_names: Array = []

var info_layer: CanvasLayer
var info_label: Label

func _ready() -> void:
	z_index = 10
	spots_node = find_child("HiveSpots", true, false)
	if spots_node == null:
		spots_node = get_parent().find_child("HiveSpots", true, false)
	if spots_node == null:
		var root := get_tree().get_root()
		for child in root.get_children():
			spots_node = child.find_child("HiveSpots", true, false)
			if spots_node != null:
				break
	if spots_node == null:
		push_error("Can't find a node called HiveSpots")
	_build_ui()
	queue_redraw()

func _build_ui() -> void:
	info_layer = CanvasLayer.new()
	info_layer.layer = 10
	info_layer.visible = false
	add_child(info_layer)

	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.offset_top = 600

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

func _update_info() -> void:
	var text := "PLACE BEEHIVES\n"
	text += "Click a marked spot to place a hive\n"
	text += "Press Enter when you're done  |  Right-click to go back\n"
	text += "Hives placed: %d" % placed_names.size()
	info_label.text = text
	info_label.modulate = Color.WHITE

func _flash(message: String) -> void:
	info_label.text = message
	info_label.modulate = Color(1, 0.4, 0.4)
	await get_tree().create_timer(0.9).timeout
	if active:
		_update_info()
		
func begin(_type: String = "") -> void:
	active = true
	placed_names.clear()
	hovered_spot = null
	info_layer.visible = true
	_update_info()
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		_cancel()
	elif event.is_action_pressed("ui_accept"):
		_confirm()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_try_place()
	elif event is InputEventMouseMotion:
		_update_hover()
		queue_redraw()

func _spot_root(node: Node) -> Node:
	while node != null and node.get_parent() != spots_node:
		node = node.get_parent()
	return node

func _update_hover() -> void:
	hovered_spot = null
	if spots_node == null:
		return
	var query := PhysicsPointQueryParameters2D.new()
	query.position = get_global_mouse_position()
	query.collide_with_areas = true
	query.collide_with_bodies = false
	query.collision_mask = SPOT_LAYER_MASK
	for hit in get_world_2d().direct_space_state.intersect_point(query, 8):
		var spot := _spot_root(hit.collider)
		if spot != null:
			hovered_spot = spot
			return

func _is_occupied(spot: Node) -> bool:
	return str(spot.name) in GameState.hives

func _all_filled() -> bool:
	for spot in spots_node.get_children():
		if not _is_occupied(spot):
			return false
	return true

func _try_place() -> void:
	_update_hover()
	if hovered_spot == null or _is_occupied(hovered_spot):
		return
	var spot_name := str(hovered_spot.name)
	GameState.hives.append(spot_name)
	placed_names.append(spot_name)
	hovered_spot = null
	_update_info()
	queue_redraw()
	if _all_filled():
		_confirm()

func _cancel() -> void:
	for spot_name in placed_names:
		GameState.hives.erase(spot_name)
	_finish(false)

func _confirm() -> void:
	if not active:
		return
	if placed_names.is_empty():
		_flash("Place at least one hive first!")
		return

	var count := placed_names.size()
	GameState.choose(
		{"plant_health": count * PLANT_PER_HIVE},
		{"plant_health": count * PLANT_PER_HIVE_SEASON, "soil_health": count * SOIL_PER_HIVE_SEASON}
	)
	active = false
	hovered_spot = null
	queue_redraw()
	await get_tree().create_timer(0.6).timeout
	_finish(true)

func _finish(completed: bool) -> void:
	active = false
	hovered_spot = null
	placed_names.clear()
	info_layer.visible = false
	queue_redraw()
	finished.emit(completed)

func _spot_rect(spot: Node) -> Rect2:
	for cs in spot.find_children("*", "CollisionShape2D", true, false):
		var size := Vector2.ZERO
		if cs.shape is RectangleShape2D:
			size = cs.shape.size * cs.global_scale
		elif cs.shape is CircleShape2D:
			size = Vector2.ONE * cs.shape.radius * 2.0 * cs.global_scale
		if size != Vector2.ZERO:
			return Rect2(to_local(cs.global_position) - size / 2.0, size)
	return Rect2()

func _draw_hive(r: Rect2, alpha: float) -> void:
	if hive_texture != null:
		draw_texture_rect(hive_texture, r, false, Color(1, 1, 1, alpha))
		return
	draw_rect(r, Color(0.95, 0.75, 0.15, alpha), true)
	var stripe := r.size.y / 5.0
	for i in [1, 3]:
		draw_rect(Rect2(r.position.x, r.position.y + stripe * i, r.size.x, stripe), Color(0.3, 0.2, 0.05, alpha), true)
	draw_rect(r, Color(0.3, 0.2, 0.05, alpha), false, 2.0)

func _draw() -> void:
	if spots_node == null:
		return
	for spot in spots_node.get_children():
		var r := _spot_rect(spot)
		if r.size == Vector2.ZERO:
			continue
		if _is_occupied(spot):
			_draw_hive(r, 1.0)
		elif active:
			if spot == hovered_spot:
				_draw_hive(r, 0.5)
				draw_rect(r, OUTLINE_COLOR, false, 3.0)
			else:
				draw_rect(r, SPOT_COLOR, false, 2.0)
