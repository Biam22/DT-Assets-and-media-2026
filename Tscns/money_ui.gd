extends CanvasLayer

var money_label: Label
var panel: PanelContainer

func _ready() -> void:
	layer = 50

	panel = PanelContainer.new()
	panel.name = "Panel"
	add_child(panel)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.6)
	style.set_content_margin_all(10)
	style.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", style)

	money_label = Label.new()
	money_label.name = "MoneyLabel"
	money_label.text = "$" + str(GameState.money)
	money_label.add_theme_font_size_override("font_size", 24)
	money_label.add_theme_color_override("font_outline_color", Color.BLACK)
	money_label.add_theme_constant_override("outline_size", 6)
	panel.add_child(money_label)

	panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	panel.offset_right = -16
	panel.offset_top = 12
	panel.offset_left = -200
	panel.offset_bottom = 60
	panel.size_flags_horizontal = Control.SIZE_SHRINK_END

	GameState.money_changed.connect(_on_money_changed)

func _on_money_changed(new_amount: int) -> void:
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_method(_update_label, GameState.money, new_amount, 0.6).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(money_label, "scale", Vector2(1.15, 1.15), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(money_label, "scale", Vector2(1.0, 1.0), 0.25).set_delay(0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(money_label, "modulate", Color(0.5, 1.0, 0.5), 0.2)
	tween.tween_property(money_label, "modulate", Color.WHITE, 0.25).set_delay(0.2)

func _update_label(value: float) -> void:
	money_label.text = "$" + str(int(round(value)))
