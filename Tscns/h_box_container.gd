extends HBoxContainer

@onready var count_label: Label = $Counting
@onready var panel: PanelContainer = get_parent()

func _ready() -> void:
	visible = false
	panel.visible = false
	HarvestCounter.harvest_count_changed.connect(_on_harvest_count_changed)
	count_label.text = str(HarvestCounter.count)
	
func _on_harvest_count_changed(new_count: int) -> void:
	visible = true
	panel.visible = true
	count_label.text = str(new_count)
	var tween: Tween = create_tween()
	tween.tween_property(count_label, "scale", Vector2(1.25, 1.25), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(count_label, "scale", Vector2(1, 1), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
