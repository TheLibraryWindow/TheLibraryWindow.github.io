extends Node
class_name LessonLoader

@export var data_dir: String = "res://Data"

func load_lessons(level: String) -> Dictionary:
	var file_path := "%s/%s.json" % [data_dir, level]
	if not FileAccess.file_exists(file_path):
		push_warning("Lesson file not found: %s" % file_path)
		return {}
	var file := FileAccess.open(file_path, FileAccess.READ)
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	var error := json.parse(text)
	if error != OK:
		push_error("Failed to parse %s: %s" % [file_path, json.get_error_message()])
		return {}
	var result := json.data
	return result if typeof(result) == TYPE_DICTIONARY else {}

func get_skills(level_data: Dictionary) -> Array:
	if not level_data.has("skills"):
		return []
	return level_data["skills"].keys()

func get_lessons_for(level_data: Dictionary, skill: String) -> Array:
	if level_data.is_empty():
		return []
	if not level_data.has("skills"):
		return []
	var skills := level_data["skills"]
	if not skills.has(skill):
		return []
	return skills[skill]

func get_lesson(level: String, skill: String, index: int = 0) -> Dictionary:
	var level_data := load_lessons(level)
	var lessons := get_lessons_for(level_data, skill)
	if index >= lessons.size():
		return {}
	return lessons[index]

func find_lesson(level: String, lesson_id: String) -> Dictionary:
	if lesson_id.is_empty():
		return {}
	var level_data := load_lessons(level)
	if level_data.is_empty():
		return {}
	var skills := level_data.get("skills", {})
	for skill in skills.keys():
		for lesson in skills[skill]:
			if lesson.get("id", "") == lesson_id:
				var payload := lesson.duplicate(true)
				payload["skill"] = skill
				return payload
	return {}
