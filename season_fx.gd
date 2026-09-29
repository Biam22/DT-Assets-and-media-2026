extends Node

var canvas: CanvasLayer
var fade: ColorRect
var label: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	canvas = CanvasLayer.new()
	canvas.layer = 100
	add_child(canvas)

	fade = ColorRect.new()
	fade.color = Color.BLACK
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.modulate.a = 0.0
	canvas.add_child(fade)

	label = Label.new()
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 64)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 12)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.modulate.a = 0.0
	canvas.add_child(label)

func transition_to_next_season() -> void:
	fade.mouse_filter = Control.MOUSE_FILTER_STOP

	var out_tween := create_tween()
	out_tween.tween_property(fade, "modulate:a", 1.0, 0.8)
	await out_tween.finished

	get_tree().reload_current_scene()
	await get_tree().process_frame
	await get_tree().process_frame

	label.text = "Season %d" % GameState.level

	var in_tween := create_tween()
	in_tween.tween_property(fade, "modulate:a", 0.0, 0.8)
	in_tween.tween_property(label, "modulate:a", 1.0, 0.4)
	in_tween.tween_interval(1.4)
	in_tween.tween_property(label, "modulate:a", 0.0, 0.7)
	await in_tween.finished

	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
