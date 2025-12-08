extends Control
class_name LessonView

signal lesson_completed(payload: Dictionary)

@onready var title_label: Label = $Margin/VBox/Header/Title
@onready var subtitle_label: Label = $Margin/VBox/Header/Subtitle
@onready var objectives_label: RichTextLabel = $Margin/VBox/Body/Objectives
@onready var instructions_label: RichTextLabel = $Margin/VBox/Body/Instructions
@onready var dialogue_label: RichTextLabel = $Margin/VBox/Body/Dialogue
@onready var questions_container: VBoxContainer = $Margin/VBox/Body/Questions
@onready var status_label: Label = $Margin/VBox/Footer/Status
@onready var complete_button: Button = $Margin/VBox/Footer/CompleteButton

var level_code := ""
var skill := ""
var lesson_data: Dictionary = {}
var progress_manager: ProgressManager
var question_controls: Array = []
var graded := false

func _ready() -> void:
	complete_button.pressed.connect(_on_complete_pressed)

func configure(level: String, skill_name: String, data: Dictionary, progress_mgr: ProgressManager) -> void:
	level_code = level
	skill = skill_name
	lesson_data = data.duplicate(true)
	progress_manager = progress_mgr
	graded = false
	status_label.text = ""
	complete_button.text = "Submit lesson"
	_build_ui()

func _build_ui() -> void:
	title_label.text = "%s · %s" % [level_code, lesson_data.get("title", "Lesson")]
	subtitle_label.text = skill
	var objectives: Array = lesson_data.get("objectives", [])
	objectives_label.text = "" if objectives.is_empty() else "• " + "\n• ".join(objectives)
	instructions_label.text = lesson_data.get("instructions", "")
	dialogue_label.text = lesson_data.get("dialogue", "")
	for child in questions_container.get_children():
		child.queue_free()
	question_controls.clear()
	var questions: Array = lesson_data.get("questions", [])
	for question in questions:
		var block := VBoxContainer.new()
		block.add_theme_constant_override("separation", 6)
		var prompt := Label.new()
		prompt.text = question.get("prompt", "")
		block.add_child(prompt)
		if question.get("type", "mc") == "mc":
			var options_box := VBoxContainer.new()
			var group := ButtonGroup.new()
			for option in question.get("options", []):
				var btn := Button.new()
				btn.text = option
				btn.toggle_mode = true
				btn.button_group = group
				btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				options_box.add_child(btn)
			block.add_child(options_box)
			question_controls.append({
				"id": question.get("id", ""),
				"type": "mc",
				"group": group,
				"options_box": options_box,
				"answer": question.get("answer", "")
			})
		else:
			var input := LineEdit.new()
			input.placeholder_text = "Type your response"
			block.add_child(input)
			question_controls.append({
				"id": question.get("id", ""),
				"type": "text",
				"input": input,
				"answer": question.get("answer", "")
			})
		questions_container.add_child(block)

func _collect_results() -> Dictionary:
	var attempted := 0
	var correct := 0
	for entry in question_controls:
		var given := ""
		if entry["type"] == "mc":
			for btn in entry["options_box"].get_children():
				if btn is Button and btn.button_pressed:
					given = btn.text
					break
		else:
			var input := entry["input"] as LineEdit
			given = input.text.strip_edges()
		if given.is_empty():
			continue
		attempted += 1
		var expected := String(entry.get("answer", "")).strip_edges()
		if entry["type"] == "text":
			if given.to_lower() == expected.to_lower():
				correct += 1
		else:
			if given == expected:
				correct += 1
	return {
		"level": level_code,
		"skill": skill,
		"lesson_id": lesson_data.get("id", ""),
		"correct": correct,
		"attempted": attempted
	}

func _on_complete_pressed() -> void:
	if graded:
		status_label.text = "Lesson already submitted."
		return
	var result := _collect_results()
	if result.get("attempted", 0) == 0:
		status_label.text = "Answer at least one prompt to submit."
		return
	graded = true
	status_label.text = "Recorded %.0f%% accuracy" % (float(result["correct"]) / float(result["attempted"]) * 100.0)
	complete_button.disabled = true
	emit_signal("lesson_completed", result)
