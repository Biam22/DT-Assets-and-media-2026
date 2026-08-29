extends Control
signal step_dismissed(index: int)
signal tutorial_finished

@onready var boxes: Array[Control] = [$Blocker/Info_Box, $Blocker/Info_Box2, $Blocker/Info_Box3, $Blocker/Info_Box4, $Blocker/Info_Box5, $Blocker/Info_Box6, $Blocker/Info_Box7, $Blocker/Info_Box8]
@onready var ok_button: Button = $Blocker/Next
@onready var blocker: Control = $Blocker

var current_index: int = -1
var auto_advance_steps: Array[bool] = [true, false, false, false, false, false, false, false]
var block_input_steps: Array[bool] = [true, true, true, true, true, true, true, true]

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	blocker.set_anchors_preset(Control.PRESET_FULL_RECT)
	blocker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for box in boxes:
		box.visible = false
	ok_button.visible = false
	ok_button.pressed.connect(_on_ok_pressed)

func show_step(index: int) -> void:
	if index < 0 or index >= boxes.size():
		return
	if current_index >= 0:
		boxes[current_index].visible = false
	current_index = index
	boxes[index].visible = true
	ok_button.visible = true
	ok_button.text = "Return" if index == boxes.size() - 1 else "Ok!"
	_set_blocking(block_input_steps[index])

func _on_ok_pressed() -> void:
	if current_index == -1:
		return
	var was_last_step := current_index == boxes.size() - 1

	boxes[current_index].visible = false
	ok_button.visible = false
	var dismissed := current_index
	current_index = -1
	step_dismissed.emit(dismissed)

	if was_last_step:
		_set_blocking(false)
		tutorial_finished.emit()
		return

	if dismissed < auto_advance_steps.size() and auto_advance_steps[dismissed]:
		show_step(dismissed + 1)
	else:
		_set_blocking(false)

func _set_blocking(should_block: bool) -> void:
	blocker.mouse_filter = Control.MOUSE_FILTER_STOP if should_block else Control.MOUSE_FILTER_IGNORE
