extends Control

signal placement_finished(score_pct: float, level: String)

@onready var question_counter: Label = $Main/VBox/ProgressRow/QuestionCounter
@onready var progress_bar: ProgressBar = $Main/VBox/ProgressRow/ProgressBar
@onready var skill_label: Label = $Main/VBox/QuestionPanel/Card/SkillLabel
@onready var prompt_label: RichTextLabel = $Main/VBox/QuestionPanel/Card/Prompt
@onready var options_container: VBoxContainer = $Main/VBox/QuestionPanel/Card/Options
@onready var text_answer: LineEdit = $Main/VBox/QuestionPanel/Card/TextAnswer
@onready var prev_button: Button = $Main/VBox/QuestionPanel/Card/NavButtons/PrevButton
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

func _ready() -> void:
	summary_panel.visible = false
	prev_button.pressed.connect(_on_prev)
	next_button.pressed.connect(_on_next)
	enter_dashboard_button.pressed.connect(_on_enter_dashboard)

func setup_test(user: String, placement_mgr: PlacementManager, progress_mgr: ProgressManager) -> void:
	username = user
	placement_manager = placement_mgr
	progress_manager = progress_mgr
	questions = placement_manager.get_questions()
	if questions.size() > 35:
		questions = questions.slice(0, 35)
	answers.clear()
	current_index = 0
	progress_bar.max_value = maxf(1, questions.size())
	_render_question()

func _clear_options() -> void:
	for child in options_container.get_children():
		child.queue_free()

func _render_question() -> void:
	if questions.is_empty():
		return
	var question: Dictionary = questions[current_index]
	question_counter.text = "Question %d / %d" % [current_index + 1, questions.size()]
	progress_bar.value = current_index + 1
	skill_label.text = "%s · %s" % [question.get("level_hint", ""), question.get("skill", "Focus")]
	prompt_label.text = question.get("prompt", "")
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
			if option == saved_answer:
				btn.button_pressed = true
			options_container.add_child(btn)
	else:
		options_container.hide()
		text_answer.show()
		text_answer.text = saved_answer
	text_answer.caret_column = text_answer.text.length()
	prev_button.disabled = current_index == 0
	next_button.text = "Submit Test" if current_index == questions.size() - 1 else "Next"

func _on_prev() -> void:
	if current_index == 0:
		return
	_save_current_answer(false)
	current_index -= 1
	_render_question()

func _on_next() -> void:
	if not _save_current_answer(true):
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
	return true

func _submit_test() -> void:
	if answers.size() < questions.size():
		status_label.text = "Answer all questions before submitting."
		return
	var result: Dictionary = placement_manager.grade(answers)
	_show_summary(result)

func _show_summary(result: Dictionary) -> void:
	$Main/VBox/QuestionPanel.visible = false
	$Main/VBox/ProgressRow.visible = false
	summary_panel.visible = true
	summary_result.text = "Score: %d / %d (%.1f%%)" % [result.get("correct", 0), result.get("total", 0), result.get("percentage", 0.0)]
	summary_level.text = "Assigned level: %s" % result.get("level", "A1")
	enter_dashboard_button.text = "Enter Hub"
	enter_dashboard_button.set_meta("score", result.get("percentage", 0.0))
	enter_dashboard_button.set_meta("level", result.get("level", "A1"))

func _on_enter_dashboard() -> void:
	var score := float(enter_dashboard_button.get_meta("score"))
	var level := String(enter_dashboard_button.get_meta("level"))
	emit_signal("placement_finished", score, level)
