extends Button

@onready var confirm_dialog: ConfirmationDialog = $"../Score/ConfirmationDialog"
@onready var score_screen = $"../Score"

func _ready() -> void:
	confirm_dialog.confirmed.connect(_on_season_confirmed)
	pressed.connect(_on_end_season_button_pressed)

func _on_end_season_button_pressed() -> void:
	confirm_dialog.dialog_text = "This will sell all your plants. Continue?"
	confirm_dialog.popup_centered()

func _on_season_confirmed() -> void:
	score_screen.show_results()
