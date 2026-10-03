extends Node2D



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	TutorialUI.tutorial_finished.connect(_on_tutorial_finished)


func _on_tutorial_finished() -> void:
	get_tree().change_scene_to_file("res://Tscns/title_screen.tscn")
	
	
		
