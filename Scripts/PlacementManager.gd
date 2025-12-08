extends Node
class_name PlacementManager

const DATA_PATH := "res://Data/Placement.json"
const LEVEL_MAP := [
	{"threshold": 91.0, "level": "C2"},
	{"threshold": 76.0, "level": "C1"},
	{"threshold": 61.0, "level": "B2"},
	{"threshold": 41.0, "level": "B1"},
	{"threshold": 21.0, "level": "A2"},
	{"threshold": 0.0, "level": "A1"}
]

var questions: Array = []

func load_questions() -> void:
	if not questions.is_empty():
		return
	if not FileAccess.file_exists(DATA_PATH):
		push_error("Placement data missing at %s" % DATA_PATH)
		return
	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(text) != OK:
		push_error("Unable to parse placement data: %s" % json.get_error_message())
		return
	var payload: Dictionary = json.data
	if typeof(payload) != TYPE_DICTIONARY or not payload.has("questions"):
		push_error("Placement data missing questions array")
		return
	questions = payload["questions"].duplicate(true)

func get_questions() -> Array:
	return questions.duplicate(true)

func grade(responses: Dictionary) -> Dictionary:
	var total := questions.size()
	if total == 0:
		return {
			"correct": 0,
			"total": 0,
			"percentage": 0.0,
			"level": "A1"
		}
	var correct := 0
	for question_dict in questions:
		var question: Dictionary = question_dict
		var qid: String = question.get("id", "")
		if qid.is_empty():
			continue
		if not responses.has(qid):
			continue
		var user_answer := String(responses[qid]).strip_edges()
		var expected := String(question.get("answer", "")).strip_edges()
		match question.get("type", "mc"):
			"text":
				if user_answer.to_lower() == expected.to_lower():
					correct += 1
			_:
				if user_answer == expected:
					correct += 1
	var percentage := float(correct) / float(total) * 100.0
	return {
		"correct": correct,
		"total": total,
		"percentage": percentage,
		"level": determine_level(percentage)
	}

func determine_level(pct: float) -> String:
	for rule in LEVEL_MAP:
		if pct >= rule["threshold"]:
			return rule["level"]
	return "A1"
