extends Control

@onready var summary_panel: PanelContainer = $TextureRect/CenterContainer/PanelContainer
@onready var harvested_label: Label = $TextureRect/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Harvested_label
@onready var score_label: Label = $TextureRect/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Score_label
@onready var continue_button: Button = $TextureRect/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Continue_button

@onready var choice_panel: PanelContainer = $TextureRect/CenterContainer/PanelContainer2
@onready var choice_button_1: Button = $TextureRect/CenterContainer/PanelContainer2/MarginContainer2/VBoxContainer2/HBoxContainer/Choice_button
@onready var choice_button_2: Button = $TextureRect/CenterContainer/PanelContainer2/MarginContainer2/VBoxContainer2/HBoxContainer/Choice_button2
@onready var bulldoze_tool: Node2D = get_parent().get_node("Bulldoze")
@onready var hive_tool: Node = get_parent().find_child("Beehives", true, false)
func _ready() -> void:
	print("Score is at: ", get_path(), " | parent children: ", get_parent().get_children())
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	visible = false
	if summary_panel:
		summary_panel.visible = false
	if choice_panel:
		choice_panel.visible = false
	
	if continue_button:
		continue_button.pressed.connect(_on_continue_pressed)
	if choice_button_1:
		choice_button_1.pressed.connect(_on_bulldoze_pressed)
	if choice_button_2:
		choice_button_2.pressed.connect(_on_pollinators_pressed)
	if not bulldoze_tool.finished.is_connected(_start_next_season):
		bulldoze_tool.finished.connect(_start_next_season)
	if hive_tool:
		hive_tool.finished.connect(_start_next_season)
func show_results() -> void:
	if harvested_label == null or score_label == null:
		push_warning("Score UI: Labels not found — check scene tree node names.")
		return
	
	harvested_label.text = "Plants Harvested: %s" % HarvestCounter.count
	score_label.text = "Money Earned: $%s" % HarvestCounter.score
	
	summary_panel.visible = true
	if choice_panel:
		choice_panel.visible = false
		
	get_tree().paused = true
	visible = true

func _on_continue_pressed() -> void:
	if summary_panel:
		summary_panel.visible = false
	if choice_panel:
		choice_panel.visible = true

func _on_bulldoze_pressed() -> void:
	visible = false                 
	get_tree().paused = false      
	bulldoze_tool.begin()
	

func _on_pollinators_pressed() -> void:
	visible = false
	get_tree().paused = false
	hive_tool.begin()
	
func _exit_tree() -> void:
	if bulldoze_tool and bulldoze_tool.finished.is_connected(_start_next_season):
		bulldoze_tool.finished.disconnect(_start_next_season)


func _start_next_season() -> void:
	if not is_inside_tree():
		return
	visible = false
	get_tree().paused = false
	HarvestCounter.count = 0
	GameState.start_level()
	SeasonFX.transition_to_next_season()
