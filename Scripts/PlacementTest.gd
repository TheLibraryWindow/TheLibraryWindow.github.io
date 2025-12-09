extends Control

signal placement_finished(score_pct: float, level: String)

@onready var level_indicator: Label = $Main/VBox/ProgressRow/LevelIndicator
@onready var question_counter: Label = $Main/VBox/ProgressRow/QuestionCounter
@onready var progress_bar: ProgressBar = $Main/VBox/ProgressRow/ProgressBar
@onready var skill_label: Label = $Main/VBox/QuestionPanel/Card/SkillLabel
@onready var prompt_label: RichTextLabel = $Main/VBox/QuestionPanel/Card/Prompt
@onready var options_container: VBoxContainer = $Main/VBox/QuestionPanel/Card/Options
@onready var text_answer: LineEdit = $Main/VBox/QuestionPanel/Card/TextAnswer
@onready var next_button: Button = $Main/VBox/QuestionPanel/Card/NavButtons/NextButton
@onready var status_label: Label = $Main/VBox/StatusLabel
@onready var summary_panel: PanelContainer = $Main/VBox/SummaryPanel
@onready var summary_result: Label = $Main/VBox/SummaryPanel/ResultVBox/ResultLabel
@onready var summary_level: Label = $Main/VBox/SummaryPanel/ResultVBox/LevelLabel
@onready var enter_dashboard_button: Button = $Main/VBox/SummaryPanel/ResultVBox/EnterButton

var placement_manager: PlacementManager
var progress_manager: ProgressManager
var username := ""
var questions: Array = []
var answers: Dictionary = {}
var current_index := 0
var current_level_index := 5  # Start at C2 (index 5), 0=A1, 1=A2, 2=B1, 3=B2, 4=C1, 5=C2
const LEVELS := ["A1", "A2", "B1", "B2", "C1", "C2"]
var ended_early: bool = false

func _ready() -> void:
	summary_panel.visible = false
	next_button.pressed.connect(_on_next)
	enter_dashboard_button.pressed.connect(_on_enter_dashboard)
	text_answer.text_submitted.connect(_on_text_answer_submitted)
	_setup_styling()
	set_process_input(true)

func setup_test(user: String, placement_mgr: PlacementManager, progress_mgr: ProgressManager) -> void:
	username = user
	placement_manager = placement_mgr
	progress_manager = progress_mgr
	questions = placement_manager.get_questions()
	
	# Select 35 questions: one question per slot (33% chance for each of the 3 questions in that slot)
	# Questions are organized into 35 slots, each with 3 completely different questions
	# Total: 35 slots × 3 questions = 105 questions
	
	# Group questions by their slot position (1-35)
	var questions_by_slot: Dictionary = {}
	for question in questions:
		var slot_pos: int = question.get("slot_position", 0)
		if slot_pos == 0:
			continue  # Skip questions without slot position
		
		if not questions_by_slot.has(slot_pos):
			questions_by_slot[slot_pos] = []
		questions_by_slot[slot_pos].append(question)
	
	# Get all slot positions and sort them
	var slot_positions: Array = []
	for slot_pos in questions_by_slot.keys():
		slot_positions.append(slot_pos)
	slot_positions.sort()
	
	# For each slot (1-35), randomly select ONE question (33% chance for each of the 3)
	var selected_questions: Array = []
	var seen_question_ids: Dictionary = {}  # Track IDs to prevent exact duplicates
	
	for slot_pos in slot_positions:
		if questions_by_slot.has(slot_pos):
			var slot_questions: Array = questions_by_slot[slot_pos]
			# Randomly select one question from this slot (33% chance each)
			if not slot_questions.is_empty():
				var selected: Dictionary = slot_questions[randi() % slot_questions.size()]
				var selected_id: String = selected.get("id", "")
				
				# Ensure we don't select the exact same question ID twice (shouldn't happen, but safety check)
				if not seen_question_ids.has(selected_id):
					seen_question_ids[selected_id] = true
					selected_questions.append(selected)
				else:
					# If somehow we got a duplicate, try another question from this slot
					for alt_question in slot_questions:
						var alt_id: String = alt_question.get("id", "")
						if not seen_question_ids.has(alt_id):
							seen_question_ids[alt_id] = true
							selected_questions.append(alt_question)
							break
		
		# Stop when we have 35 questions (one per slot)
		if selected_questions.size() >= 35:
			break
	
	# Sort selected questions by level to maintain A1 → C2 progression
	var level_order: Array[String] = ["A1", "A2", "B1", "B2", "C1", "C2"]
	selected_questions.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_level: String = a.get("level_hint", "A1")
		var b_level: String = b.get("level_hint", "A1")
		var a_index: int = level_order.find(a_level)
		var b_index: int = level_order.find(b_level)
		if a_index == -1:
			a_index = 0
		if b_index == -1:
			b_index = 0
		return a_index < b_index
	)
	
	questions = selected_questions
	answers.clear()
	current_index = 0
	current_level_index = 5  # Start at C2
	progress_bar.max_value = maxf(1, questions.size())
	_update_level_indicator()
	_render_question()

func _clear_options() -> void:
	for child in options_container.get_children():
		child.queue_free()

func _render_question() -> void:
	if ended_early:
		return
	if questions.is_empty():
		return
	var question: Dictionary = questions[current_index]
	question_counter.text = "Question %d / %d" % [current_index + 1, questions.size()]
	progress_bar.value = current_index + 1
	skill_label.text = ""  # Don't show level or skill
	
	# Center align the prompt text using BBCode
	var prompt_text: String = question.get("prompt", "")
	prompt_label.text = "[center]%s[/center]" % prompt_text
	prompt_label.bbcode_enabled = true
	
	status_label.text = ""
	_clear_options()
	var saved_answer: String = answers.get(question.get("id", ""), "")
	if question.get("type", "mc") == "mc":
		text_answer.hide()
		options_container.show()
		var group := ButtonGroup.new()
		var opts: Array = question.get("options", [])
		for option in opts:
			var btn := Button.new()
			btn.text = option
			btn.toggle_mode = true
			btn.button_group = group
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			btn.focus_mode = Control.FOCUS_NONE
			options_container.add_child(btn)
			
			# Apply initial styling (white background, black text)
			var normal_style := StyleBoxFlat.new()
			normal_style.bg_color = Color.WHITE
			normal_style.border_width_left = 2
			normal_style.border_width_top = 2
			normal_style.border_width_right = 2
			normal_style.border_width_bottom = 2
			normal_style.border_color = Color.TRANSPARENT
			normal_style.content_margin_left = 12
			normal_style.content_margin_top = 12
			normal_style.content_margin_right = 12
			normal_style.content_margin_bottom = 12
			normal_style.corner_radius_top_left = 8
			normal_style.corner_radius_top_right = 8
			normal_style.corner_radius_bottom_left = 8
			normal_style.corner_radius_bottom_right = 8
			btn.add_theme_stylebox_override("normal", normal_style)
			var hover_style := normal_style.duplicate()
			hover_style.bg_color = Color(0.95, 0.95, 0.95, 1.0)
			btn.add_theme_stylebox_override("hover", hover_style)
			var pressed_style := normal_style.duplicate()
			pressed_style.bg_color = Color(0.9, 0.9, 0.9, 1.0)
			btn.add_theme_stylebox_override("pressed", pressed_style)
			btn.add_theme_color_override("font_color", Color.BLACK)
			btn.add_theme_color_override("font_hover_color", Color.BLACK)
			btn.add_theme_color_override("font_pressed_color", Color.BLACK)
			
			if option == saved_answer:
				btn.button_pressed = true
			# Connect to update styling when toggled
			btn.toggled.connect(_on_option_toggled.bind(btn))
			# Update initial styling if already selected
			if btn.button_pressed:
				_on_option_toggled(true, btn)
	else:
		options_container.hide()
		text_answer.show()
		text_answer.text = saved_answer
		text_answer.caret_column = text_answer.text.length()
		text_answer.grab_focus()
	next_button.text = "Submit Test" if current_index == questions.size() - 1 else "Next"

func _on_next() -> void:
	if not _save_current_answer(true):
		return
	if _maybe_end_early():
		return
	if current_index == questions.size() - 1:
		_submit_test()
		return
	current_index += 1
	_render_question()

func _save_current_answer(require_input: bool) -> bool:
	if questions.is_empty():
		return false
	var question: Dictionary = questions[current_index]
	var qid: String = question.get("id", "")
	var value: String = ""
	if question.get("type", "mc") == "mc":
		for child in options_container.get_children():
			if child is Button and child.button_pressed:
				value = child.text
				break
	else:
		value = text_answer.text.strip_edges()
	if require_input and value.is_empty():
		status_label.text = "Answer required before continuing."
		return false
	if not value.is_empty():
		answers[qid] = value
		_update_level_indicator()
	return true

func _submit_test() -> void:
	if answers.size() < questions.size():
		status_label.text = "Answer all questions before submitting."
		return
	var result: Dictionary = placement_manager.grade(answers, questions)
	_show_summary(result)

func _show_summary(result: Dictionary) -> void:
	$Main/VBox/QuestionPanel.visible = false
	$Main/VBox/ProgressRow.visible = false
	summary_panel.visible = true
	var points: float = result.get("weighted_correct", 0.0)
	var points_total: float = maxf(0.001, result.get("weighted_total", 1.0))
	var raw_correct: int = int(result.get("correct", 0))
	var raw_total: int = int(result.get("total", 0))
	var pct: float = result.get("percentage", 0.0)
	summary_result.text = "Points: %.1f / %.1f (%.1f%%)\nCorrect: %d / %d" % [points, points_total, pct, raw_correct, raw_total]
	summary_level.text = "Assigned level: %s" % result.get("level", "A1")
	enter_dashboard_button.text = "Enter Hub"
	enter_dashboard_button.set_meta("score", result.get("percentage", 0.0))
	enter_dashboard_button.set_meta("level", result.get("level", "A1"))

func _maybe_end_early() -> bool:
	# Evaluate current answers with the official grading (band caps) and stop early if a band cap is triggered.
	var answered_questions: Array = []
	for q in questions:
		var aqid: String = q.get("id", "")
		if answers.has(aqid):
			answered_questions.append(q)
	
	if answered_questions.is_empty():
		return false
	
	var provisional: Dictionary = placement_manager.grade(answers, answered_questions)
	if provisional.get("band_stop_triggered", false):
		ended_early = true
		_show_summary(provisional)
		return true
	return false

func _on_enter_dashboard() -> void:
	var score := float(enter_dashboard_button.get_meta("score"))
	var level := String(enter_dashboard_button.get_meta("level"))
	emit_signal("placement_finished", score, level)

func _on_text_answer_submitted(_text: String) -> void:
	# When Enter is pressed in text answer field, move to next question
	_on_next()

func _setup_styling() -> void:
	# Style the prompt label with white background and black text
	var prompt_style := StyleBoxFlat.new()
	prompt_style.bg_color = Color.WHITE
	prompt_style.content_margin_left = 16
	prompt_style.content_margin_top = 16
	prompt_style.content_margin_right = 16
	prompt_style.content_margin_bottom = 16
	prompt_style.corner_radius_top_left = 8
	prompt_style.corner_radius_top_right = 8
	prompt_style.corner_radius_bottom_left = 8
	prompt_style.corner_radius_bottom_right = 8
	prompt_label.add_theme_stylebox_override("normal", prompt_style)
	prompt_label.add_theme_color_override("default_color", Color.BLACK)
	
	# Style the text answer field
	var text_style := StyleBoxFlat.new()
	text_style.bg_color = Color.WHITE
	text_style.content_margin_left = 12
	text_style.content_margin_top = 12
	text_style.content_margin_right = 12
	text_style.content_margin_bottom = 12
	text_style.corner_radius_top_left = 8
	text_style.corner_radius_top_right = 8
	text_style.corner_radius_bottom_left = 8
	text_style.corner_radius_bottom_right = 8
	text_answer.add_theme_stylebox_override("normal", text_style)
	text_answer.add_theme_color_override("font_color", Color.BLACK)
	text_answer.add_theme_color_override("font_placeholder_color", Color(0.5, 0.5, 0.5, 1.0))

func _on_option_toggled(button_pressed: bool, button: Button) -> void:
	# Update button styling when toggled to show selection more obviously
	if button_pressed:
		var selected_style := StyleBoxFlat.new()
		selected_style.bg_color = Color(0.85, 0.95, 0.85, 1.0)  # Light green background
		selected_style.border_width_left = 3
		selected_style.border_width_top = 3
		selected_style.border_width_right = 3
		selected_style.border_width_bottom = 3
		selected_style.border_color = Color(0.2, 0.8, 0.3, 1.0)  # Green border
		selected_style.content_margin_left = 12
		selected_style.content_margin_top = 12
		selected_style.content_margin_right = 12
		selected_style.content_margin_bottom = 12
		selected_style.corner_radius_top_left = 8
		selected_style.corner_radius_top_right = 8
		selected_style.corner_radius_bottom_left = 8
		selected_style.corner_radius_bottom_right = 8
		button.add_theme_stylebox_override("normal", selected_style)
		button.add_theme_stylebox_override("hover", selected_style)
		button.add_theme_stylebox_override("pressed", selected_style)
	else:
		# Reset to normal styling
		var normal_style := StyleBoxFlat.new()
		normal_style.bg_color = Color.WHITE
		normal_style.border_width_left = 2
		normal_style.border_width_top = 2
		normal_style.border_width_right = 2
		normal_style.border_width_bottom = 2
		normal_style.border_color = Color.TRANSPARENT
		normal_style.content_margin_left = 12
		normal_style.content_margin_top = 12
		normal_style.content_margin_right = 12
		normal_style.content_margin_bottom = 12
		normal_style.corner_radius_top_left = 8
		normal_style.corner_radius_top_right = 8
		normal_style.corner_radius_bottom_left = 8
		normal_style.corner_radius_bottom_right = 8
		button.add_theme_stylebox_override("normal", normal_style)
		var hover_style := normal_style.duplicate()
		hover_style.bg_color = Color(0.95, 0.95, 0.95, 1.0)
		button.add_theme_stylebox_override("hover", hover_style)
		var pressed_style := normal_style.duplicate()
		pressed_style.bg_color = Color(0.9, 0.9, 0.9, 1.0)
		button.add_theme_stylebox_override("pressed", pressed_style)
		button.add_theme_color_override("font_color", Color.BLACK)
		button.add_theme_color_override("font_hover_color", Color.BLACK)
		button.add_theme_color_override("font_pressed_color", Color.BLACK)

func _input(event: InputEvent) -> void:
	# Handle Enter and Spacebar to move to next question when answer is selected
	if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and (event.keycode == KEY_ENTER or event.keycode == KEY_SPACE)):
		# Only proceed if we're not on the summary screen
		if summary_panel.visible:
			return
		
		# Check if we have a selected answer (for multiple choice) or text input (for text questions)
		if questions.is_empty():
			return
		
		var question: Dictionary = questions[current_index]
		if question.get("type", "mc") == "mc":
			# Check if any option is selected
			for child in options_container.get_children():
				if child is Button and child.button_pressed:
					_on_next()
					get_viewport().set_input_as_handled()
					return
		else:
			# For text questions, Enter is already handled by text_submitted signal
			# But Spacebar should also work
			if event.keycode == KEY_SPACE and not text_answer.text.strip_edges().is_empty():
				_on_next()
				get_viewport().set_input_as_handled()

func _check_and_update_level(question: Dictionary, user_answer: String) -> void:
	var question_level: String = question.get("level_hint", "")
	if question_level.is_empty():
		return
	
	var is_correct := false
	match question.get("type", "mc"):
		"text":
			# Check against valid answers including synonyms
			var valid_answers: Array[String] = PlacementManager.get_valid_answers(question)
			var user_lower: String = user_answer.to_lower().strip_edges()
			for valid in valid_answers:
				var valid_lower: String = String(valid).to_lower().strip_edges()
				if user_lower == valid_lower:
					is_correct = true
					break
		_:
			var correct_answer: String = String(question.get("answer", ""))
			is_correct = user_answer.strip_edges() == correct_answer.strip_edges()
	
	var question_level_index := LEVELS.find(question_level)
	if question_level_index == -1:
		return
	
	# Update level based on answer
	if is_correct:
		# If correct, stay at C2 or move up to question's level if higher
		if question_level_index > current_level_index:
			current_level_index = question_level_index
		# Otherwise stay at current level (C2 or higher)
	else:
		# If wrong, move down one level (minimum A1)
		if current_level_index > 0:
			current_level_index -= 1
		# If already at A1, stay at A1
	
	_update_level_indicator()

func _update_level_indicator() -> void:
	if not is_instance_valid(level_indicator):
		return
	
	# Provisional level based on answered questions using the official grading logic
	var answered_questions: Array = []
	for q in questions:
		var aqid: String = q.get("id", "")
		if answers.has(aqid):
			answered_questions.append(q)
	
	if answered_questions.is_empty():
		level_indicator.text = "—"
		level_indicator.modulate = Color(0.7, 0.7, 0.7, 1.0)
		return
	
	var provisional: Dictionary = placement_manager.grade(answers, answered_questions)
	var level: String = provisional.get("level", "A1")
	var new_text := level
	var new_color: Color
	
	match level:
		"A1", "A2":
			new_color = Color(0.6, 0.8, 1.0, 1.0)
		"B1", "B2", "C1", "C2":
			new_color = Color(0.4, 0.9, 0.5, 1.0)
		_:
			new_color = Color(0.6, 0.9, 1, 1)
	
	# Only animate if the text actually changed
	if level_indicator.text != new_text:
		var tween := level_indicator.create_tween()
		tween.set_parallel(true)
		tween.tween_property(level_indicator, "scale", Vector2(1.2, 1.2), 0.15)
		tween.tween_property(level_indicator, "scale", Vector2(1.0, 1.0), 0.15).set_delay(0.15)
	
	level_indicator.text = new_text
	level_indicator.modulate = new_color
