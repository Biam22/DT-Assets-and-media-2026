extends Control

signal ok_pressed
signal choice_done

const GOOD_COLOR := Color(0.4, 1, 0.4)
const BAD_COLOR := Color(1, 0.35, 0.35)

const STATS := [
	{"key": "soil_health", "name": "Soil Health", "unit": ""},
	{"key": "plant_health", "name": "Plant Health", "unit": ""},
	{"key": "yield", "name": "Yield", "unit": ""},
	{"key": "crops", "name": "Expected Harvest", "unit": " crops"},
]

const CHOICES := {
	1: {
		"prompt": "Your seedlings are in the ground. What will you do?",
		"options_text": "1. The local forestry company has offered to buy your surrounding trees (clear them for profit)\n2. Your neighbor has spare beehives — do you take them?",
		"options": [
			{
				"button": "1. Bulldoze",
				"tool": "bulldoze",
				"title": "You cleared the trees.",
				"note": "Removing tree cover increases sunlight and space for crops, but exposes soil to erosion. A big trade-off for quick bit of cash.",
			},
			{
				"button": "2. Bee hives",
				"tool": "hives",
				"title": "You installed bee hives.",
				"note": "Pollinators increase crop yields and support plant health. Benefits accumulate each season.",
			},
		],
	},
	2: {
	"prompt": "Your soil is running low on nutrients.",
	"options_text": "1. Heavy synthetic fertilizer \n2. Natural compost",
	"options": [
		{
			"button": "1. Fertilizer",
			"tool": "fertilizer",
			"now": {"plant_health": 40, "soil_health": -40},
			"per_season": {"plant_health": -25, "soil_health": -25},
			"title": "You applied synthetic fertilizer.",
			"note": "Synthetic fertilizers boost plants fast but damage the soil. The effect gets weaker every season.",
		},
		{
			"button": "2. Compost",
			"tool": "compost",
			"now": {"plant_health": 10, "soil_health": 10},
			"per_season": {"plant_health": 5, "soil_health": 10},
			"title": "You applied compost.",
			"note": "Compost helps the soil hold water and stay alive. The soil gets richer every season from now.",
		},
	],
},
3: {
	"prompt": "Weeds are overwhelming your crops.",
	"options_text": "1. Spray herbicide\n2. Plant natives",
	"options": [
		{
			"button": "1. Herbicide",
			"tool": "herbicide",
			"now": {"plant_health": 35, "soil_health": -45},
			"per_season": {"plant_health": -20, "soil_health": -20},
			"title": "You sprayed your plants with herbicide.",
			"note": "Herbicides eliminate weeds quickly but also kill soil microorganisms. Soil health now declines.",
		},
		{
			"button": "2. Native plants",
			"tool": "natives",
			"now": {"plant_health": 10, "soil_health": 20},
			"per_season": {"plant_health": 10, "soil_health": 5},
			"title": "You planted natives.",
			"note": "Native plants crowd out weeds and feed the soil. It takes time to show but will improve conditions each season.",
		},
	],
}
}

@onready var summary_panel: PanelContainer = $TextureRect/CenterContainer/PanelContainer
@onready var harvested_label: Label = $TextureRect/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Harvested_label
@onready var score_label: Label = $TextureRect/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Score_label
@onready var continue_button: Button = $TextureRect/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Continue_button
@onready var summary_box: VBoxContainer = $TextureRect/CenterContainer/PanelContainer/MarginContainer/VBoxContainer

@onready var choice_panel: PanelContainer = $TextureRect/CenterContainer/PanelContainer2
@onready var prompt_label: Label = $TextureRect/CenterContainer/PanelContainer2/MarginContainer2/VBoxContainer2/Invest_label
@onready var options_label: Label = $TextureRect/CenterContainer/PanelContainer2/MarginContainer2/VBoxContainer2/Spend_label
@onready var choice_button_1: Button = $TextureRect/CenterContainer/PanelContainer2/MarginContainer2/VBoxContainer2/HBoxContainer/Choice_button
@onready var choice_button_2: Button = $TextureRect/CenterContainer/PanelContainer2/MarginContainer2/VBoxContainer2/HBoxContainer/Choice_button2

var blurb_layer: CanvasLayer
var blurb_panel: PanelContainer
var blurb_title: Label
var blurb_rows: VBoxContainer
var blurb_note: Label
var blurb_ok: Button
var season_title: Label
var stats_grid: GridContainer
var choosing := false

var tips_layer: CanvasLayer
var tips_panel: PanelContainer
var tips_title: Label
var tips_box: VBoxContainer
var tips_ok: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	visible = false
	if summary_panel:
		summary_panel.visible = false
	if choice_panel:
		choice_panel.visible = false

	if continue_button:
		continue_button.pressed.connect(_on_continue_pressed)
	if choice_button_1:
		choice_button_1.pressed.connect(_on_choice_pressed.bind(0))
	if choice_button_2:
		choice_button_2.pressed.connect(_on_choice_pressed.bind(1))

	_build_blurb()
	_build_summary_extras()
	_build_tips()

func _build_blurb() -> void:
	blurb_layer = CanvasLayer.new()
	blurb_layer.layer = 60
	add_child(blurb_layer)

	blurb_panel = PanelContainer.new()
	blurb_panel.set_anchors_preset(Control.PRESET_CENTER)
	blurb_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	blurb_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	blurb_panel.visible = false

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.85)
	style.set_content_margin_all(20)
	style.set_corner_radius_all(6)
	blurb_panel.add_theme_stylebox_override("panel", style)

	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(440, 0)
	box.add_theme_constant_override("separation", 14)

	blurb_title = Label.new()
	blurb_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	blurb_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	blurb_rows = VBoxContainer.new()
	blurb_rows.add_theme_constant_override("separation", 6)

	blurb_note = Label.new()
	blurb_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	blurb_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	blurb_ok = Button.new()
	blurb_ok.text = "OK"
	blurb_ok.custom_minimum_size = Vector2(120, 0)
	blurb_ok.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	blurb_ok.pressed.connect(func(): ok_pressed.emit())

	box.add_child(blurb_title)
	box.add_child(blurb_rows)
	box.add_child(blurb_note)
	box.add_child(blurb_ok)
	blurb_panel.add_child(box)
	blurb_layer.add_child(blurb_panel)

func _build_summary_extras() -> void:
	if summary_box == null:
		return
	for child in summary_box.get_children():
		var lbl := child as Label
		if lbl != null and lbl != harvested_label and lbl != score_label and lbl.text.to_lower().contains("season"):
			season_title = lbl
			break
	if season_title == null:
		season_title = Label.new()
		season_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		summary_box.add_child(season_title)
		summary_box.move_child(season_title, 0)

	var stats_box := VBoxContainer.new()
	stats_box.add_theme_constant_override("separation", 6)

	var header := Label.new()
	header.text = "Farm Stats"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_box.add_child(header)

	stats_grid = GridContainer.new()
	stats_grid.columns = 2
	stats_grid.add_theme_constant_override("h_separation", 32)
	stats_grid.add_theme_constant_override("v_separation", 4)
	stats_box.add_child(stats_grid)

	summary_box.add_child(stats_box)
	summary_box.move_child(stats_box, continue_button.get_index())

func _build_tips() -> void:
	tips_layer = CanvasLayer.new()
	tips_layer.layer = 70
	add_child(tips_layer)

	tips_panel = PanelContainer.new()
	tips_panel.set_anchors_preset(Control.PRESET_CENTER)
	tips_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	tips_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	tips_panel.visible = false

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.9)
	style.set_content_margin_all(24)
	style.set_corner_radius_all(8)
	tips_panel.add_theme_stylebox_override("panel", style)

	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(500, 0)
	box.add_theme_constant_override("separation", 16)

	tips_title = Label.new()
	tips_title.text = "Farming Tips"
	tips_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tips_title.add_theme_font_size_override("font_size", 32)
	tips_title.add_theme_color_override("font_color", Color(0.4, 1, 0.4))
	box.add_child(tips_title)

	tips_box = VBoxContainer.new()
	tips_box.add_theme_constant_override("separation", 10)
	box.add_child(tips_box)

	tips_ok = Button.new()
	tips_ok.text = "OK"
	tips_ok.custom_minimum_size = Vector2(120, 0)
	tips_ok.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	tips_ok.pressed.connect(func(): ok_pressed.emit())
	box.add_child(tips_ok)

	tips_panel.add_child(box)
	tips_layer.add_child(tips_panel)

func _commas(value: int) -> String:
	var text := str(absi(value))
	var out := ""
	var count := 0
	for i in range(text.length() - 1, -1, -1):
		out = text[i] + out
		count += 1
		if count % 3 == 0 and i > 0:
			out = "," + out
	return ("-" if value < 0 else "") + out

func run_choice() -> void:
	var choice: Dictionary = CHOICES.get(GameState.level, {})
	if choice.is_empty():
		return
	prompt_label.text = choice["prompt"]
	options_label.text = choice["options_text"]
	choice_button_1.text = choice["options"][0]["button"]
	choice_button_2.text = choice["options"][1]["button"]
	summary_panel.visible = false
	choice_panel.visible = true
	visible = true
	await choice_done

func _get_tool(tool_name: String) -> Node:
	if tool_name == "bulldoze":
		return get_parent().find_child("Bulldoze", true, false)
	elif tool_name == "hives":
		return get_parent().find_child("Beehives", true, false)
	elif tool_name == "fertilizer":
		return get_parent().get_node_or_null("MiniGames/Fertilizer")
	elif tool_name == "compost":
		return get_parent().get_node_or_null("MiniGames/Compost")
	elif tool_name == "herbicide":
		return get_parent().get_node_or_null("MiniGames/Herbicide")
	elif tool_name == "natives":
		return get_parent().get_node_or_null("MiniGames/Natives")
	return null

func _on_choice_pressed(index: int) -> void:
	if choosing:
		return
	var choice: Dictionary = CHOICES.get(GameState.level, {})
	if choice.is_empty():
		return
	var option: Dictionary = choice["options"][index]
	choosing = true
	var before: Dictionary = GameState.snapshot()

	if option.has("tool"):
		var tool = _get_tool(option["tool"])
		if tool == null:
			push_error("Can't find the tool node for " + str(option["tool"]))
			choosing = false
			return
		choice_panel.visible = false
		visible = false
		tool.begin(option["tool"])
		var completed: bool = await tool.finished
		visible = true
		if not completed:
			choice_panel.visible = true
			choosing = false
			return
		if option.has("now"):
			GameState.choose(option["now"], option["per_season"])
	else:
		GameState.choose(option["now"], option["per_season"])
		choice_panel.visible = false

	var after: Dictionary = GameState.snapshot()
	var rows: Array = _build_rows(before, after)
	if not rows.is_empty():
		await _show_blurb(option["title"], rows, option["note"])

	choosing = false
	visible = false
	choice_done.emit()
func _build_rows(before: Dictionary, after: Dictionary) -> Array:
	var rows := []
	for stat in STATS:
		var key: String = stat["key"]
		if key == "crops":
			print("Crops before: ", before[key], " after: ", after[key])
			rows.append({"stat": stat, "from": before[key], "to": after[key]})
		elif before[key] != after[key]:
			rows.append({"stat": stat, "from": before[key], "to": after[key]})
	return rows
	
func _set_row(value: float, label: Label, stat: Dictionary) -> void:
	var number := int(round(value))
	var text := _commas(number) if stat["key"] == "crops" else str(number)
	label.text = "%s: %s%s" % [stat["name"], text, stat["unit"]]

func _show_blurb(title: String, rows: Array, note: String) -> void:
	blurb_title.text = title
	blurb_note.text = note
	blurb_ok.text = "OK"
	for child in blurb_rows.get_children():
		child.queue_free()

	var labels := []
	for row in rows:
		var label := Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 28)
		blurb_rows.add_child(label)
		labels.append(label)
		_set_row(float(row["from"]), label, row["stat"])

	blurb_ok.disabled = true
	blurb_panel.modulate.a = 0.0
	blurb_panel.visible = true

	var t := create_tween()
	t.tween_property(blurb_panel, "modulate:a", 1.0, 0.4)
	t.tween_interval(0.6)
	var danger_labels: Array = []
	
	for i in rows.size():
		var row: Dictionary = rows[i]
		var improved: bool = row["to"] > row["from"]
		var danger: bool = row["to"] < 50
		var color: Color = GOOD_COLOR if improved else BAD_COLOR
		if danger:
			color = Color(1, 0, 0)
		var method: Callable = _set_row.bind(labels[i], row["stat"])
		if i > 0:
			t.parallel()
		t.tween_method(method, float(row["from"]), float(row["to"]), 1.2)
		t.parallel().tween_property(labels[i], "modulate", color, 1.2)
		labels[i].modulate = color
		if danger:
			danger_labels.append(labels[i])
	await t.finished
	for label in danger_labels:
		_flash_danger(label)
		
	blurb_ok.disabled = false
	blurb_ok.grab_focus()
	await ok_pressed
	blurb_panel.visible = false	
	
func show_results() -> void:
	var result: Dictionary = GameState.last_harvest
	if result.is_empty():
		push_warning("No harvest to show yet")
		return

	harvested_label.text = "Crops Harvested: %s of %s" % [_commas(int(result["crops"])), _commas(int(result["potential"]))]
	score_label.text = "Yield: %d of 200  (%d%%)" % [int(result["yield"]), int(round(result["yield"] / 2.0))]
	if season_title:
		season_title.text = "Season %d completed!" % int(result["season"])
	continue_button.text = "See Final Score" if GameState.level >= GameState.TOTAL_SEASONS else "Continue"
	_fill_stats(result)

	choice_panel.visible = false
	summary_panel.visible = true
	visible = true

func _fill_stats(result: Dictionary) -> void:
	if stats_grid == null:
		return
	for child in stats_grid.get_children():
		child.queue_free()
	_add_stat_row("Soil Health", str(int(result["soil_health"])), signi(int(result["soil_health"]) - 100))
	_add_stat_row("Plant Health", str(int(result["plant_health"])), signi(int(result["plant_health"]) - 100))
	_add_stat_row("Yield", str(int(result["yield"])), signi(int(result["yield"]) - 200))
	_add_stat_row("Total Crops", _commas(GameState.total_crops), 0)

func _add_stat_row(stat_name: String, value: String, good: int) -> void:
	var name_label := Label.new()
	name_label.text = stat_name
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", 18)

	var value_label := Label.new()
	value_label.text = value
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.add_theme_font_size_override("font_size", 18)
	if good > 0:
		value_label.add_theme_color_override("font_color", GOOD_COLOR)
	elif good < 0:
		value_label.add_theme_color_override("font_color", BAD_COLOR)

	stats_grid.add_child(name_label)
	stats_grid.add_child(value_label)

func _on_continue_pressed() -> void:
	if GameState.level >= GameState.TOTAL_SEASONS:
		_show_final()
	else:
		_start_next_season()

func _end_score() -> int:
	return GameState.money * (GameState.soil_health + GameState.plant_health)

func _rating_text() -> String:
	var score := _end_score()
	if score >= 50000000:
		return "Good ending: You looked after the land and it looked after you. The soil is healthy, the crops are strong, and you made a living."
	if score >= 15000000:
		return "Average ending: You got by. Some choices helped, some hurt. The farm survived but it could be better."
	return "Bad ending: The soil is worn out and the money is short. The land will need time to recover before it can farm again."

func _show_final() -> void:
	summary_panel.visible = false
	blurb_title.text = "Harvest complete!"
	for child in blurb_rows.get_children():
		child.queue_free()
	for entry in GameState.season_history:
		var label := Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.text = "Season %d:  %s crops" % [int(entry["season"]), _commas(int(entry["crops"]))]
		blurb_rows.add_child(label)

	var total_label := Label.new()
	total_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	total_label.add_theme_font_size_override("font_size", 32)
	total_label.add_theme_color_override("font_color", GOOD_COLOR)
	total_label.text = "Total: %s crops" % _commas(GameState.total_crops)
	blurb_rows.add_child(total_label)

	var money_label := Label.new()
	money_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	money_label.add_theme_font_size_override("font_size", 24)
	money_label.text = "Money: $%s" % _commas(GameState.money)
	blurb_rows.add_child(money_label)

	var score_label := Label.new()
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.add_theme_font_size_override("font_size", 24)
	score_label.text = "End Score: %s" % _commas(_end_score())
	blurb_rows.add_child(score_label)

	blurb_note.text = _rating_text()
	blurb_ok.text = "Play Again"
	blurb_ok.disabled = false
	blurb_panel.modulate.a = 1.0
	blurb_panel.visible = true
	blurb_ok.grab_focus()
	await ok_pressed

	if GameState.playthrough == 1:
		await _show_tips()
		_save_score()
	else:
		await _show_comparison()

	GameState.reset_run()
	get_tree().reload_current_scene()

func _show_tips() -> void:
	for child in tips_box.get_children():
		child.queue_free()

	var tips := [
		{"text": "Tip 1: Did you know that?: Synthetic fertilizers and pesticides give quick results but reduce soil health over time!", "image": "res://Sprites/Tip images/Chem_tip.png"},
		{"text": "Tip 2: Did you know that?: Clearing trees for short-term profit exposes soil to erosion and reduces long-term crop yield!", "image": "res://Sprites/Tip images/Tree_tip.png"},
		{"text": "Tip 3: Did you know that?: Compost and native plants build soil health slowly but provide lasting benefits to crops and the environment!", "image": "res://Sprites/Tip images/Compost_tip.png"},
		{"text": "Tip 4: Did you know that?: Pollinators like bees increase crop yields and support plant health!", "image": "res://Sprites/Tip images/Beehive_tip.png"},
	]

	tips_ok.disabled = false
	tips_panel.modulate.a = 1.0
	tips_panel.visible = true
	tips_ok.text = "Next"

	for i in tips.size():
		for child in tips_box.get_children():
			child.queue_free()

		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 12)

		var tex := TextureRect.new()
		tex.texture = load(tips[i]["image"])
		tex.custom_minimum_size = Vector2(240, 240)
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hbox.add_child(tex)

		var lbl := Label.new()
		lbl.text = tips[i]["text"]
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.add_theme_font_size_override("font_size", 20)
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(lbl)

		tips_box.add_child(hbox)

		if i < tips.size() - 1:
			tips_ok.text = "Next"
		else:
			tips_ok.text = "Play Again"

		tips_ok.grab_focus()
		await ok_pressed

func _save_score() -> void:
	if GameState.playthrough == 1:
		GameState.previous_score = _end_score()
		GameState.playthrough = 2

func _show_comparison() -> void:
	for child in tips_box.get_children():
		child.queue_free()

	var current_score := _end_score()
	var difference: int = current_score - GameState.previous_score

	var title := Label.new()
	title.text = "Score Comparison"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.4, 1, 0.4))
	tips_box.add_child(title)

	var old_label := Label.new()
	old_label.text = "First playthrough: %s" % _commas(GameState.previous_score)
	old_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	old_label.add_theme_font_size_override("font_size", 22)
	tips_box.add_child(old_label)

	var new_label := Label.new()
	new_label.text = "Second playthrough: %s" % _commas(current_score)
	new_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	new_label.add_theme_font_size_override("font_size", 22)
	tips_box.add_child(new_label)

	var diff_label := Label.new()
	diff_label.text = "Difference: %s" % _commas(difference)
	diff_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	diff_label.add_theme_font_size_override("font_size", 24)
	if difference > 0:
		diff_label.add_theme_color_override("font_color", GOOD_COLOR)
	elif difference < 0:
		diff_label.add_theme_color_override("font_color", BAD_COLOR)
	tips_box.add_child(diff_label)

	var rating := Label.new()
	if difference > 0:
		rating.text = "You improved! Your farming choices made a real difference."
	elif difference < 0:
		rating.text = "Your score went down. Try more sustainable choices next time."
	else:
		rating.text = "Same score. Try different choices to see how they affect the outcome."
	rating.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rating.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rating.add_theme_font_size_override("font_size", 20)
	tips_box.add_child(rating)

	tips_ok.disabled = false
	tips_panel.modulate.a = 1.0
	tips_panel.visible = true
	tips_ok.text = "next"
	tips_ok.grab_focus()
	await ok_pressed
	tips_panel.visible = false
		

func _start_next_season() -> void:
	if not is_inside_tree():
		return
	visible = false
	GameState.start_level()
	SeasonFX.transition_to_next_season()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				_skip_to_choice(1)
			KEY_2:
				_skip_to_choice(2)
			KEY_3:
				_skip_to_choice(3)

func _skip_to_choice(level: int) -> void:
	if choosing:
		return
	if level <= GameState.level:
		return
	while GameState.level < level:
		if GameState.level == 1:
			GameState.choose({"plant_health": 2, "soil_health": 2}, {"plant_health": 1, "soil_health": 1})
		elif GameState.level == 2:
			GameState.choose({"plant_health": 5, "soil_health": 10}, {"plant_health": 5, "soil_health": 10})
		elif GameState.level == 3:
			return
		GameState.start_level()
	visible = false
	choice_panel.visible = false
	summary_panel.visible = false
	
func _flash_danger(label: Label) -> void:
	var tween := create_tween()
	tween.tween_property(label, "modulate", Color(1, 0, 0), 0.15)
	tween.tween_property(label, "modulate", Color(1, 1, 1), 0.15)
	tween.tween_property(label, "modulate", Color(1, 0, 0), 0.15)
	tween.tween_property(label, "modulate", Color(1, 1, 1), 0.15)
	tween.tween_property(label, "modulate", Color(1, 0, 0), 0.15)
