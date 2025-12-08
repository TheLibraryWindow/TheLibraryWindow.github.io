extends Node
class_name ProgressManager

signal profile_loaded(profile: Dictionary)
signal profile_changed(profile: Dictionary)

const LEVELS := ["A1", "A2", "B1", "B2", "C1", "C2"]
const SKILLS := ["Listening", "Speaking", "Reading", "Writing"]

var profile: Dictionary = {}
var profile_path := ""
var username := ""

func load_profile(user: String) -> Dictionary:
	username = user
	profile_path = "user://skillpath_profile_%s.json" % user
	if FileAccess.file_exists(profile_path):
		var file := FileAccess.open(profile_path, FileAccess.READ)
		var text := file.get_as_text()
		file.close()
		if not text.is_empty():
			var json := JSON.new()
			if json.parse(text) == OK and typeof(json.data) == TYPE_DICTIONARY:
				profile = json.data
	if profile.is_empty():
		profile = _default_profile(user)
		_persist()
	else:
		if _ensure_profile_defaults():
			_persist()
	emit_signal("profile_loaded", profile)
	return profile

func _default_profile(user: String) -> Dictionary:
	var base_levels := {}
	var lesson_log := {}
	for level in LEVELS:
		base_levels[level] = {}
		lesson_log[level] = {}
		for skill in SKILLS:
			base_levels[level][skill] = {"correct": 0, "attempted": 0}
			lesson_log[level][skill] = {}
	return {
		"username": user,
		"display_name": user.capitalize(),
		"current_level": "A1",
		"placement": {
			"completed": false,
			"score": 0.0,
			"level": "A1"
		},
		"overall": {
			"accuracy": 0.0,
			"grade": "F"
		},
		"skills": base_levels,
		"lessons": lesson_log,
		"last_activity": {
			"level": "",
			"skill": "",
			"lesson_id": ""
		}
	}

func _ensure_profile_defaults() -> bool:
	var changed := false
	if not profile.has("display_name"):
		profile["display_name"] = username.capitalize()
		changed = true
	if not profile.has("current_level"):
		profile["current_level"] = "A1"
		changed = true
	if not profile.has("placement"):
		profile["placement"] = {"completed": false, "score": 0.0, "level": "A1"}
		changed = true
	if not profile.has("overall"):
		profile["overall"] = {"accuracy": 0.0, "grade": "F"}
		changed = true
	if not profile.has("skills"):
		profile["skills"] = {}
		changed = true
	if not profile.has("lessons"):
		profile["lessons"] = {}
		changed = true
	for level in LEVELS:
		if not profile["skills"].has(level):
			profile["skills"][level] = {}
			changed = true
		for skill in SKILLS:
			if not profile["skills"][level].has(skill):
				profile["skills"][level][skill] = {"correct": 0, "attempted": 0}
				changed = true
		if not profile["lessons"].has(level):
			profile["lessons"][level] = {}
			changed = true
		for skill in SKILLS:
			if not profile["lessons"][level].has(skill):
				profile["lessons"][level][skill] = {}
				changed = true
	if not profile.has("last_activity"):
		profile["last_activity"] = {"level": "", "skill": "", "lesson_id": ""}
		changed = true
	return changed

func _persist() -> void:
	if profile_path.is_empty():
		return
	var file := FileAccess.open(profile_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(profile, "  "))
	file.close()

func _emit_change() -> void:
	_persist()
	emit_signal("profile_changed", profile)

func reset_profile() -> void:
	if username.is_empty():
		return
	profile = _default_profile(username)
	_emit_change()

func apply_placement_result(level: String, score_pct: float) -> void:
	profile["placement"] = {
		"completed": true,
		"score": score_pct,
		"level": level
	}
	profile["current_level"] = level
	profile["overall"]["accuracy"] = score_pct
	profile["overall"]["grade"] = _grade_from_pct(score_pct)
	_emit_change()

func set_display_name(name: String) -> void:
	profile["display_name"] = name.strip_edges() if not name.strip_edges().is_empty() else profile["display_name"]
	_emit_change()

func set_current_level(level: String) -> void:
	if level in LEVELS:
		profile["current_level"] = level
		_emit_change()

func record_lesson_result(level: String, skill: String, lesson_id: String, correct: int, attempted: int) -> void:
	if not level in LEVELS:
		return
	if not skill in SKILLS:
		return
	if not profile["skills"].has(level):
		profile["skills"][level] = {}
	if not profile["skills"][level].has(skill):
		profile["skills"][level][skill] = {"correct": 0, "attempted": 0}
	if not profile["lessons"].has(level):
		profile["lessons"][level] = {}
	if not profile["lessons"][level].has(skill):
		profile["lessons"][level][skill] = {}
	var previous: Dictionary = profile["lessons"][level][skill].get(lesson_id, {})
	if not previous.is_empty():
		profile["skills"][level][skill]["correct"] -= previous.get("correct", 0)
		profile["skills"][level][skill]["attempted"] -= previous.get("attempted", 0)
	profile["skills"][level][skill]["correct"] += correct
	profile["skills"][level][skill]["attempted"] += attempted
	var accuracy := 0.0
	if attempted > 0:
		accuracy = float(correct) / float(attempted)
	profile["lessons"][level][skill][lesson_id] = {
		"correct": correct,
		"attempted": attempted,
		"accuracy": accuracy,
		"completed": true
	}
	profile["last_activity"] = {
		"level": level,
		"skill": skill,
		"lesson_id": lesson_id
	}
	profile["overall"]["accuracy"] = _recalculate_overall_pct()
	profile["overall"]["grade"] = _grade_from_pct(profile["overall"]["accuracy"])
	_emit_change()

func _recalculate_overall_pct() -> float:
	var total_correct := 0
	var total_attempted := 0
	for level in profile["skills"].keys():
		for skill in profile["skills"][level].keys():
			total_correct += profile["skills"][level][skill]["correct"]
			total_attempted += profile["skills"][level][skill]["attempted"]
	if total_attempted == 0:
		return profile["overall"].get("accuracy", 0.0)
	return float(total_correct) / float(total_attempted) * 100.0

func _grade_from_pct(pct: float) -> String:
	if pct >= 90.0:
		return "A"
	elif pct >= 80.0:
		return "B"
	elif pct >= 70.0:
		return "C"
	elif pct >= 60.0:
		return "D"
	elif pct >= 50.0:
		return "E"
	return "F"

func get_skill_accuracy(level: String, skill: String) -> float:
	if not profile["skills"].has(level):
		return 0.0
	if not profile["skills"][level].has(skill):
		return 0.0
	var attempted: int = profile["skills"][level][skill]["attempted"]
	if attempted == 0:
		return 0.0
	return float(profile["skills"][level][skill]["correct"]) / float(attempted)

func get_overall_grade() -> String:
	return profile["overall"].get("grade", "F")

func get_overall_accuracy() -> float:
	return profile["overall"].get("accuracy", 0.0)

func get_last_activity() -> Dictionary:
	return profile.get("last_activity", {})

func has_completed_lesson(level: String, skill: String, lesson_id: String) -> bool:
	if not profile["lessons"].has(level):
		return false
	if not profile["lessons"][level].has(skill):
		return false
	return profile["lessons"][level][skill].get(lesson_id, {}).get("completed", false)

func get_lesson_accuracy(level: String, skill: String, lesson_id: String) -> float:
	if not has_completed_lesson(level, skill, lesson_id):
		return 0.0
	return profile["lessons"][level][skill][lesson_id].get("accuracy", 0.0)

func get_level_completion(level: String, total_lessons: int) -> float:
	if total_lessons <= 0:
		return 0.0
	var completed := 0
	if profile["lessons"].has(level):
		for skill in profile["lessons"][level].keys():
			for lesson_id in profile["lessons"][level][skill].keys():
				if profile["lessons"][level][skill][lesson_id].get("completed", false):
					completed += 1
	return float(completed) / float(total_lessons)
