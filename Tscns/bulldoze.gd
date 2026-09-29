extends Node2D

signal finished

const COST_PER_BLOCK := 5
const TREE_LAYER_MASK := 2
const OUTLINE_COLOR := Color(1, 0.9, 0.2)

var active := false
var dragging := false
var start_pos := Vector2.ZERO
var rect := Rect2()

var hovered: Array = []
var drag_selection: Array = []

var info_layer: CanvasLayer
var info_panel: PanelContainer
var info_label: Label
var blurb_panel: PanelContainer
var blurb_value: Label

func _ready() -> void:
	_build_ui()

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
	info_panel.offset_top = 12
	info_panel.add_theme_stylebox_override("panel", _make_style())
	info_label = Label.new()
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_panel.add_child(info_label)
	info_layer.add_child(info_panel)

	blurb_panel = PanelContainer.new()
	blurb_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	blurb_panel.set_anchors_preset(Control.PRESET_CENTER)
	blurb_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	blurb_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	blurb_panel.add_theme_stylebox_override("panel", _make_style())
	blurb_panel.visible = false

	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 10)

	var title := Label.new()
	title.text = "You bulldozed the trees.\nYour soil health has degraded!"
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

func _update_info(count: int = 0) -> void:
	var cost := count * COST_PER_BLOCK
	var text := "BULLDOZE TREES\n"
	text += "Click and drag over trees to select them ($%d each)\n" % COST_PER_BLOCK
	text += "Release to clear them  |  Right-click to skip\n"
	if count > 0:
		text += "%d selected = $%d  (you have $%d)" % [count, cost, HarvestCounter.score]
	else:
		text += "You have $%d" % HarvestCounter.score
	info_label.text = text
	var too_expensive := cost > HarvestCounter.score
	info_label.modulate = Color(1, 0.4, 0.4) if too_expensive else Color.WHITE

func begin() -> void:
	active = true
	info_panel.visible = true
	blurb_panel.visible = false
	info_layer.visible = true
	_update_info()

func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		_finish()
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
		tree.modulate = Color(1, 0.4, 0.4) if tree in drag_selection else Color.WHITE
	_update_info(drag_selection.size())

func _bulldoze_selected() -> void:
	var selected := _get_selected()
	var cost := selected.size() * COST_PER_BLOCK
	if selected.is_empty() or cost > HarvestCounter.score:
		_clear_highlight()
		_update_info()
		return

	HarvestCounter.score -= cost
	HarvestCounter.score_changed.emit(HarvestCounter.score)

	for tree in selected:
		GameState.cleared_trees.append(str(tree.name))
		tree.remove_from_group("trees")
		var tween := create_tween()
		tween.tween_property(tree, "modulate:a", 0.0, 0.3)
		tween.tween_callback(tree.queue_free)

	var old_soil: int = GameState.soil_health
	GameState.choose({"soil_health": -30, "trees_cleared": selected.size()}, {})

	active = false
	hovered.clear()
	drag_selection.clear()
	queue_redraw()
	await _play_blurb(old_soil, GameState.soil_health)
	_finish()

func _play_blurb(old_value: int, new_value: int) -> void:
	info_panel.visible = false
	blurb_value.text = "Soil Health: %d" % old_value
	blurb_value.modulate = Color.WHITE
	blurb_panel.modulate.a = 0.0
	blurb_panel.visible = true

	var t := create_tween()
	t.tween_property(blurb_panel, "modulate:a", 1.0, 0.4)
	t.tween_interval(0.6)
	t.tween_method(_set_soil_text, float(old_value), float(new_value), 1.4)
	t.parallel().tween_property(blurb_value, "modulate", Color(1, 0.3, 0.3), 1.4)
	t.tween_interval(1.6)
	await t.finished

func _set_soil_text(value: float) -> void:
	blurb_value.text = "Soil Health: %d" % int(round(value))

func _finish() -> void:
	active = false
	dragging = false
	rect = Rect2()
	hovered.clear()
	drag_selection.clear()
	info_layer.visible = false
	blurb_panel.visible = false
	_clear_highlight()
	queue_redraw()
	finished.emit()

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
		draw_rect(rect, Color(1, 0.3, 0.3, 0.25), true)
		draw_rect(rect, Color(1, 0.3, 0.3), false, 2.0)
