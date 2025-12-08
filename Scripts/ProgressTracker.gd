extends Node
class_name ProgressTracker

var progress_data: Dictionary = {}
var score_letter := "F"

func _ready() -> void:
	if progress_data.is_empty():
		progress_data = {
			"B1": _empty_skill_tracker(),
			"B2": _empty_skill_tracker(),
			"C1": _empty_skill_tracker()
		}

func _empty_skill_tracker() -> Dictionary:
	return {
		"Listening": {"correct": 0, "attempted": 0},
		"Speaking": {"correct": 0, "attempted": 0},
		"Reading": {"correct": 0, "attempted": 0},
		"Writing": {"correct": 0, "attempted": 0}
	}

func record_result(level: String, skill: String, correct: int, attempted: int) -> void:
	if not progress_data.has(level):
		progress_data[level] = _empty_skill_tracker()
	if not progress_data[level].has(skill):
		progress_data[level][skill] = {"correct": 0, "attempted": 0}
	progress_data[level][skill]["correct"] += correct
	progress_data[level][skill]["attempted"] += attempted
	_recalculate_score()

func get_skill_progress(level: String, skill: String) -> float:
	if not progress_data.has(level):
		return 0.0
	if not progress_data[level].has(skill):
		return 0.0
	var data := progress_data[level][skill]
	if data["attempted"] == 0:
		return 0.0
	return float(data["correct"]) / float(data["attempted"])

func get_overall_percentage() -> float:
	var total_correct := 0
	var total_attempted := 0
	for level in progress_data.keys():
		for skill in progress_data[level].keys():
			total_correct += progress_data[level][skill]["correct"]
			total_attempted += progress_data[level][skill]["attempted"]
	if total_attempted == 0:
		return 0.0
	return float(total_correct) / float(total_attempted)

func _recalculate_score() -> void:
	var pct := get_overall_percentage() * 100.0
	if pct >= 90.0:
		score_letter = "A"
	elif pct >= 80.0:
		score_letter = "B"
	elif pct >= 70.0:
		score_letter = "C"
	elif pct >= 60.0:
		score_letter = "D"
	elif pct >= 50.0:
		score_letter = "E"
	else:
		score_letter = "F"

func get_score_letter() -> String:
	return score_letter
