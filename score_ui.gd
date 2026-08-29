extends Control

@onready var harvested_label: Label = $TextureRect/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Harvested_label
@onready var score_label: Label = $TextureRect/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Score_label
@onready var continue_button: Button = $TextureRect/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Continue_button

func _ready() -> void:
	visible = false
	
	if continue_button == null:
		push_warning("Score UI: continue_button is null — this instance may be a broken duplicate.")
		return
	
	continue_button.pressed.connect(_on_continue_pressed)

func show_results() -> void:
	if harvested_label == null or score_label == null:
		push_warning("Score UI: labels not found — cannot show results.")
		return
	
	harvested_label.text = "Plants Harvested: %s" % HarvestCounter.count
	score_label.text = "Money Earned: $%s" % HarvestCounter.score
	visible = true

func _on_continue_pressed() -> void:
	get_tree().change_scene_to_file("res://Tscns/title_screen.tscn")
