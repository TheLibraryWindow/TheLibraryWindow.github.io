extends ScrollContainer
class_name SkillsView

signal lesson_requested(level: String, skill: String, lesson_data: Dictionary)

@onready var skill_list: VBoxContainer = $SkillList

var level_code := ""
var level_payload: Dictionary = {}
var progress_manager: ProgressManager

func configure(level: String, payload: Dictionary, progress_mgr: ProgressManager) -> void:
	level_code = level
	level_payload = payload.duplicate(true)
	progress_manager = progress_mgr
	_render()

func refresh_state() -> void:
	_render()

func _render() -> void:
	if not is_instance_valid(skill_list):
		return
	for child in skill_list.get_children():
		child.queue_free()
	if level_payload.is_empty():
		return
	var skills: Dictionary = level_payload.get("skills", {})
	for skill in skills.keys():
		var skill_panel := PanelContainer.new()
		skill_panel.add_theme_constant_override("margin_left", 12)
		skill_panel.add_theme_constant_override("margin_right", 12)
		skill_panel.add_theme_constant_override("margin_top", 8)
		skill_panel.add_theme_constant_override("margin_bottom", 8)
		var vbox := VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 8)
		var header := Label.new()
		header.text = "%s" % skill
		header.add_theme_color_override("font_color", Color(0.8, 0.94, 1))
		vbox.add_child(header)
		var lessons: Array = skills[skill]
		for idx in range(lessons.size()):
			var lesson: Dictionary = lessons[idx]
			var button := Button.new()
			button.text = "%02d · %s" % [idx + 1, lesson.get("title", "Lesson")]
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			button.set_meta("lesson", lesson)
			button.set_meta("skill", skill)
			var unlocked := _is_lesson_unlocked(skill, lessons, idx)
			button.disabled = not unlocked
			var completed := progress_manager.has_completed_lesson(level_code, skill, lesson.get("id", ""))
			if completed:
				button.text += "  (✓ %.0f%% )" % (progress_manager.get_lesson_accuracy(level_code, skill, lesson.get("id", "")) * 100.0)
			button.pressed.connect(func(): _on_lesson_pressed(button))
			vbox.add_child(button)
		skill_panel.add_child(vbox)
		skill_list.add_child(skill_panel)

func _is_lesson_unlocked(skill: String, lessons: Array, idx: int) -> bool:
	if idx == 0:
		return true
	var previous: Dictionary = lessons[idx - 1]
	return progress_manager.has_completed_lesson(level_code, skill, previous.get("id", ""))

func _on_lesson_pressed(button: Button) -> void:
	var lesson: Dictionary = button.get_meta("lesson")
	var skill := String(button.get_meta("skill"))
	var payload := lesson.duplicate(true)
	emit_signal("lesson_requested", level_code, skill, payload)
