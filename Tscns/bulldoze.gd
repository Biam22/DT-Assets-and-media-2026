extends Node2D

signal finished(completed: bool)

const PLANT_PER_TREE := 2
const SOIL_PER_TREE := 6
const TREE_LAYER_MASK := 2
const OUTLINE_COLOR := Color(1, 0.9, 0.2)
const MONEY_PER_TREE := 50

var active := false
var dragging := false
var start_pos := Vector2.ZERO
var rect := Rect2()

var hovered: Array = []
var drag_selection: Array = []

var info_layer: CanvasLayer
var info_label: Label

var money_preview_layer: CanvasLayer
var money_preview_label: Label

func _ready() -> void:
	_build_ui()
	_build_money_preview()

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

func _build_money_preview() -> void:
	money_preview_layer = CanvasLayer.new()
	money_preview_layer.layer = 11
	money_preview_layer.visible = false
	add_child(money_preview_layer)

	var lbl := Label.new()
	lbl.name = "MoneyPreview"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.add_theme_color_override("font_color", Color(0.4, 1, 0.4))
	lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	lbl.add_theme_constant_override("outline_size", 6)
	money_preview_layer.add_child(lbl)
	money_preview_label = lbl

func _update_info(count: int = 0) -> void:
	var text := "BULLDOZE MODE\n"
	text += "Drag over trees to clear them\n"
	text += "More trees means more sun for your plants, but the soil will suffer\n"
	text += "Right-click to go back\n"
	if count > 0:
		var word := "tree" if count == 1 else "trees"
		text += "%d %s selected\n" % [count, word]
		text += "Money: +$%d" % (count * MONEY_PER_TREE)
	else:
		text += "Nothing selected"
	info_label.text = text

	if count > 0 and dragging:
		money_preview_layer.visible = true
		money_preview_label.text = "+$%d" % (count * MONEY_PER_TREE)
		var mouse_pos := get_viewport().get_canvas_transform().affine_inverse() * get_global_mouse_position()
		money_preview_label.position = mouse_pos + Vector2(0, -40)
	else:
		money_preview_layer.visible = false

func begin(_type: String = "") -> void:
	active = true
	info_layer.visible = true
	_update_info()

func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		_finish(false)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			dragging = true
			hovered.clear()
			start_pos = get_global_mouse_position()
			rect = Rect2(start_pos, Vector2.ZERO)
		else:
			dragging = false
			_bulldoze_selected()
			rect = Rect2()
			drag_selection.clear()
			queue_redraw()
	elif event is InputEventMouseMotion:
		if dragging:
			rect = Rect2(start_pos, get_global_mouse_position() - start_pos).abs()
			_highlight_selected()
		else:
			_update_hover()
		queue_redraw()

func _update_hover() -> void:
	hovered.clear()
	var query := PhysicsPointQueryParameters2D.new()
	query.position = get_global_mouse_position()
	query.collide_with_areas = true
	query.collide_with_bodies = false
	query.collision_mask = TREE_LAYER_MASK
	for hit in get_world_2d().direct_space_state.intersect_point(query, 8):
		var tree := _tree_root(hit.collider)
		if tree != null and tree not in hovered:
			hovered.append(tree)

func _tree_root(node: Node) -> Node:
	while node != null and not node.is_in_group("trees"):
		node = node.get_parent()
	return node

func _get_selected() -> Array:
	var selected := []
	if rect.size.x < 1.0 or rect.size.y < 1.0:
		return selected

	var shape := RectangleShape2D.new()
	shape.size = rect.size

	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, rect.get_center())
	query.collide_with_areas = true
	query.collide_with_bodies = false
	query.collision_mask = TREE_LAYER_MASK

	var hits := get_world_2d().direct_space_state.intersect_shape(query, 64)
	for hit in hits:
		var tree := _tree_root(hit.collider)
		if tree != null and tree not in selected:
			selected.append(tree)
	return selected

func _clear_highlight() -> void:
	for tree in get_tree().get_nodes_in_group("trees"):
		tree.modulate = Color.WHITE

func _highlight_selected() -> void:
	drag_selection = _get_selected()
	for tree in get_tree().get_nodes_in_group("trees"):
		tree.modulate = Color(0.6, 1, 0.6) if tree in drag_selection else Color.WHITE
	_update_info(drag_selection.size())

func _bulldoze_selected() -> void:
	var selected := _get_selected()
	if selected.is_empty():
		_clear_highlight()
		_update_info()
		return

	var count := selected.size()
	var total_money := count * MONEY_PER_TREE

	for tree in selected:
		GameState.cleared_trees.append(str(tree.name))
		tree.remove_from_group("trees")
		var tween := create_tween()
		tween.tween_property(tree, "modulate:a", 0.0, 0.3)
		tween.tween_callback(tree.queue_free)

	GameState.choose(
		{"plant_health": count * PLANT_PER_TREE, "soil_health": -count * SOIL_PER_TREE},
		{"plant_health": -count * 2, "soil_health": -count * 2}
	)

	GameState.money += total_money

	active = false
	hovered.clear()
	drag_selection.clear()
	money_preview_layer.visible = false
	queue_redraw()
	await get_tree().create_timer(0.6).timeout
	_finish(true)

func _finish(completed: bool) -> void:
	active = false
	dragging = false
	rect = Rect2()
	hovered.clear()
	drag_selection.clear()
	info_layer.visible = false
	if money_preview_layer:
		money_preview_layer.visible = false
	_clear_highlight()
	queue_redraw()
	finished.emit(completed)

func _tree_rect(tree: Node) -> Rect2:
	for cs in tree.find_children("*", "CollisionShape2D", true, false):
		if cs.shape is RectangleShape2D:
			var size: Vector2 = cs.shape.size * cs.global_scale
			return Rect2(cs.global_position - size / 2.0, size)
	return Rect2()

func _draw() -> void:
	if not active:
		return
	var outlined := drag_selection if dragging else hovered
	for tree in outlined:
		if is_instance_valid(tree):
			draw_rect(_tree_rect(tree), OUTLINE_COLOR, false, 3.0)
	if dragging:
		draw_rect(rect, Color(0.4, 1, 0.4, 0.25), true)
		draw_rect(rect, Color(1.0, 0.243, 0.063, 1.0), false, 2.0)
