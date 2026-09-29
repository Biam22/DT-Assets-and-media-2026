extends Node2D

signal finished

const HIVE_COST := 5
const YIELD_PER_HIVE := 5
const POLLINATORS_PER_HIVE := 10
const SPOT_LAYER_MASK := 4
const OUTLINE_COLOR := Color(1, 0.9, 0.2)
const SPOT_COLOR := Color(1, 1, 1, 0.5)

@export var hive_texture: Texture2D

var active := false
var placed_this_round := 0
var hovered_spot: Node = null
var spots_node: Node

var info_layer: CanvasLayer
var info_panel: PanelContainer
var info_label: Label
var blurb_panel: PanelContainer
var blurb_value: Label

func _ready() -> void:
	spots_node = find_child("HiveSpots", true, false)
	if spots_node == null:
		spots_node = get_parent().find_child("HiveSpots", true, false)
	if spots_node == null:
		push_error("Can't find a node called HiveSpots")
	_build_ui()
	queue_redraw()

func _make_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.75)
	style.set_content_margin_all(16)
	style.set_corner_radius_all(6)
	return style

func _build_ui() -> void:
	info_layer = CanvasLayer.new()
	info_layer.layer = 10
	info_layer.visible = false
	add_child(info_layer)

	info_panel = PanelContainer.new()
	info_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	info_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	info_panel.offset_top = 600
	info_panel.add_theme_stylebox_override("panel", _make_style())
	info_label = Label.new()
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_panel.add_child(info_label)
	info_layer.add_child(info_panel)

	blurb_panel = PanelContainer.new()
	blurb_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	blurb_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	blurb_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	blurb_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	blurb_panel.offset_bottom = 60
	blurb_panel.add_theme_stylebox_override("panel", _make_style())
	blurb_panel.visible = false

	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 10)

	var title := Label.new()
	title.text = "You introduced pollinators!\nYour crops will grow stronger each season."
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE

	blurb_value = Label.new()
	blurb_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	blurb_value.add_theme_font_size_override("font_size", 36)
	blurb_value.mouse_filter = Control.MOUSE_FILTER_IGNORE

	box.add_child(title)
	box.add_child(blurb_value)
	blurb_panel.add_child(box)
	info_layer.add_child(blurb_panel)

func _update_info() -> void:
	var text := "PLACE BEEHIVES\n"
	text += "Click a marked spot to place a hive ($%d each)\n" % HIVE_COST
	text += "Press Enter or right-click when you're done\n"
	text += "Hives placed: %d  |  You have $%d" % [placed_this_round, HarvestCounter.score]
	info_label.text = text
	info_label.modulate = Color.WHITE

func _flash(message: String) -> void:
	info_label.text = message
	info_label.modulate = Color(1, 0.4, 0.4)
	await get_tree().create_timer(0.8).timeout
	if active:
		_update_info()

func begin() -> void:
	print("hive begin")
	if spots_node == null:
		print("NO HiveSpots node found")
	else:
		print("spots found: ", spots_node.get_child_count())
		for spot in spots_node.get_children():
			var layer = "not a physics node"
			if spot is CollisionObject2D:
				layer = spot.collision_layer
			print(spot.name, " | layer = ", layer, " | rect = ", _spot_rect(spot))
	active = true
	placed_this_round = 0
	hovered_spot = null
	info_panel.visible = true
	blurb_panel.visible = false
	info_layer.visible = true
	_update_info()
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed):
		_finish_placing()
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
	print("click, hovered spot: ", hovered_spot)
	if hovered_spot == null or _is_occupied(hovered_spot):
		return
	if HarvestCounter.score < HIVE_COST:
		_flash("Not enough money!")
		return

	HarvestCounter.score -= HIVE_COST
	HarvestCounter.score_changed.emit(HarvestCounter.score)
	GameState.hives.append(str(hovered_spot.name))
	placed_this_round += 1
	hovered_spot = null
	_update_info()
	queue_redraw()

	if _all_filled():
		_finish_placing()

func _finish_placing() -> void:
	if not active:
		return
	active = false
	hovered_spot = null
	queue_redraw()

	if placed_this_round > 0:
		var old_bonus: int = GameState.yield_bonus
		var gain := placed_this_round * YIELD_PER_HIVE
		GameState.choose({"pollinators": placed_this_round * POLLINATORS_PER_HIVE}, {"yield_bonus": gain})
		await _play_blurb(old_bonus, old_bonus + gain)
	_finish()

func _play_blurb(old_value: int, new_value: int) -> void:
	print("hive blurb")
	info_panel.visible = false
	_set_bonus_text(float(old_value))
	blurb_value.modulate = Color.WHITE
	blurb_panel.modulate.a = 0.0
	blurb_panel.size = Vector2.ZERO
	blurb_panel.visible = true
	await get_tree().process_frame
	var screen := get_viewport().get_visible_rect().size
	blurb_panel.position = Vector2((screen.x - blurb_panel.size.x) / 2.0, screen.y - blurb_panel.size.y - 60.0)

	var t := create_tween()
	t.tween_property(blurb_panel, "modulate:a", 1.0, 0.4)
	t.tween_interval(0.6)
	t.tween_method(_set_bonus_text, float(old_value), float(new_value), 1.4)
	t.parallel().tween_property(blurb_value, "modulate", Color(0.4, 1, 0.4), 1.4)
	t.tween_interval(1.6)
	await t.finished

func _set_bonus_text(value: float) -> void:
	blurb_value.text = "Yield Bonus: +%d%%" % int(round(value))

func _finish() -> void:
	active = false
	hovered_spot = null
	placed_this_round = 0
	info_layer.visible = false
	blurb_panel.visible = false
	queue_redraw()
	finished.emit()

func _spot_rect(spot: Node) -> Rect2:
	for cs in spot.find_children("*", "CollisionShape2D", true, false):
		var size := Vector2.ZERO
		if cs.shape is RectangleShape2D:
			size = cs.shape.size * cs.global_scale
		elif cs.shape is CircleShape2D:
			size = Vector2.ONE * cs.shape.radius * 2.0 * cs.global_scale
		if size != Vector2.ZERO:
			return Rect2(cs.global_position - size / 2.0, size)
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
