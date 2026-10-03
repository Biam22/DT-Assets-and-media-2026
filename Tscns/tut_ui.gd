extends Control
signal step_dismissed(index: int)
signal tutorial_finished

@onready var boxes: Array[Control] = [$Blocker/Info_Box, $Blocker/Info_Box2, $Blocker/Info_Box3, $Blocker/Info_Box4, $Blocker/Info_Box5, $Blocker/Info_Box6, $Blocker/Info_Box7, $Blocker/Info_Box8]
@onready var ok_button: Button = $Blocker/Next
@onready var blocker: Control = $Blocker

var current_index: int = -1
var last_step: int = -1

var block_input_steps: Array[bool] = [false, false, false, false, false, false, false, false]

func _final_step() -> int:
	return boxes.size() - 1 if last_step < 0 else last_step

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
	var is_final: bool = index == _final_step()
	ok_button.visible = true
	ok_button.text = "Return" if is_final else "Ok!"
	_set_blocking(block_input_steps[index])


func clear_message() -> void:
	if current_index >= 0:
		boxes[current_index].visible = false
	ok_button.visible = false

func message_visible() -> bool:
	return current_index >= 0 and boxes[current_index].visible

func _on_ok_pressed() -> void:
	if current_index == -1:
		return

	var dismissed := current_index
	if dismissed == _final_step():
		clear_message()
		current_index = -1
		step_dismissed.emit(dismissed)
		tutorial_finished.emit()
		return

	clear_message()
	step_dismissed.emit(dismissed)

func _set_blocking(should_block: bool) -> void:
	blocker.mouse_filter = Control.MOUSE_FILTER_STOP if should_block else Control.MOUSE_FILTER_IGNORE
