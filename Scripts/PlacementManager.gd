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
	var base_questions: Array = payload["questions"].duplicate(true)
	# Generate expanded pool with variations (105 questions total)
	questions = QuestionPoolGenerator.generate_expanded_pool(base_questions)

func get_questions() -> Array:
	return questions.duplicate(true)

static func get_valid_answers(question: Dictionary) -> Array[String]:
	# Returns an array of valid answers, including synonyms
	# First check if question has explicit accepted_answers field
	if question.has("accepted_answers") and question["accepted_answers"] is Array:
		var accepted: Array = question["accepted_answers"]
		var valid_answers: Array[String] = []
		for answer in accepted:
			valid_answers.append(String(answer).strip_edges().to_lower())
		return valid_answers
	
	var base_answer: String = question.get("answer", "").strip_edges().to_lower()
	var prompt: String = question.get("prompt", "").to_lower()
	var valid_answers: Array[String] = [base_answer]
	
	# Check if this is a synonym question - also check by answer "mad" which is the base answer for angry
	if "synonym" in prompt or "another word" in prompt or "word meaning" in prompt or base_answer == "mad":
		var target_word: String = ""
		# Extract the target word from the prompt - handle various formats
		if "synonym for" in prompt:
			var parts := prompt.split("synonym for")
			if parts.size() > 1:
				# Extract word after "synonym for", removing quotes, punctuation, and whitespace
				target_word = parts[1].replace("'", "").replace("\"", "").replace(".", "").replace(",", "").replace("?", "").strip_edges().to_lower()
		elif "another word for" in prompt:
			var parts := prompt.split("another word for")
			if parts.size() > 1:
				target_word = parts[1].replace("'", "").replace("\"", "").replace(".", "").replace(",", "").replace("?", "").strip_edges().to_lower()
		elif "synonym" in prompt and "'" in prompt:
			# Try to extract word in quotes
			var quote_start := prompt.find("'")
			if quote_start != -1:
				var after_quote := prompt.substr(quote_start + 1)
				var quote_end := after_quote.find("'")
				if quote_end != -1:
					target_word = after_quote.substr(0, quote_end).strip_edges().to_lower()
		
		# If we couldn't extract from prompt but answer is "mad", assume it's the angry question
		if target_word.is_empty() and base_answer == "mad":
			target_word = "angry"
		
		# Add synonyms based on target word
		match target_word:
			"angry":
				valid_answers.append_array(["mad", "furious", "irritated", "annoyed", "cross", "livid", "enraged", "incensed", "wrathful", "irate", "fuming", "outraged", "indignant", "vexed", "exasperated", "aggravated", "resentful", "upset", "displeased", "provoked"])
			"ubiquitous":
				valid_answers.append_array(["omnipresent", "everywhere", "pervasive", "universal", "widespread", "commonplace", "prevalent"])
			"prudent":
				valid_answers.append_array(["careful", "cautious", "wise", "judicious", "sensible", "discreet", "circumspect", "shrewd"])
			"resilient":
				valid_answers.append_array(["tough", "strong", "durable", "flexible", "adaptable", "robust", "hardy", "buoyant"])
			"pinnacle":
				valid_answers.append_array(["peak", "summit", "apex", "zenith", "climax", "height", "top", "acme"])
			"therefore":
				valid_answers.append_array(["thus", "hence", "consequently", "accordingly", "so", "as a result"])
			"conversely":
				valid_answers.append_array(["on the other hand", "in contrast", "oppositely", "contrarily", "instead"])
			"however":
				valid_answers.append_array(["but", "yet", "nevertheless", "nonetheless", "still", "though", "although"])
			"kind regards":
				valid_answers.append_array(["best regards", "regards", "sincerely", "yours sincerely", "yours faithfully", "respectfully"])
			"call off":
				valid_answers.append_array(["cancel", "postpone", "abandon", "scrub", "abort"])
	
	return valid_answers

func grade(responses: Dictionary, asked_questions: Array = []) -> Dictionary:
	# Use only the questions that were shown to the user.
	var asked: Array = asked_questions
	if asked.is_empty():
		asked = questions.duplicate(true)
	if asked.is_empty():
		return {
			"correct": 0,
			"total": 0,
			"percentage": 0.0,
			"level": "A1",
			"weighted_correct": 0.0,
			"weighted_total": 0.0
		}
	
	# Weights per level
	var level_weights: Dictionary = {
		"A1": 1.0, "A2": 1.0,
		"B1": 2.0, "B2": 3.0,
		"C1": 4.0, "C2": 5.0
	}
	
	# Band caps configuration
	var band_for_level: Dictionary = {
		"A1": "A", "A2": "A",
		"B1": "B", "B2": "B",
		"C1": "C", "C2": "C"
	}
	var band_cap_level: Dictionary = {"C": "B2", "B": "A2", "A": "A1"}
	var min_items_per_band: int = 4
	var stop_up_threshold: float = 0.2   # not used for now, reserved
	var stop_down_threshold: float = 0.6
	
	var correct := 0
	var total := 0
	var weighted_correct := 0.0
	var weighted_total := 0.0
	var wrong_by_band: Dictionary = {"A": 0, "B": 0, "C": 0}
	var seen_by_band: Dictionary = {"A": 0, "B": 0, "C": 0}
	var band_stop_triggered: bool = false
	
	for question_dict in asked:
		var question: Dictionary = question_dict
		var qid: String = question.get("id", "")
		if qid.is_empty():
			continue
		total += 1
		
		var level: String = question.get("level_hint", "A1")
		var weight: float = float(level_weights.get(level, 1.0))
		weighted_total += weight
		
		var band: String = band_for_level.get(level, "A")
		seen_by_band[band] = seen_by_band.get(band, 0) + 1
		
		if not responses.has(qid):
			wrong_by_band[band] = wrong_by_band.get(band, 0) + 1
			continue
		
		var user_answer: String = String(responses[qid]).strip_edges().to_lower()
		var valid_answers: Array[String] = get_valid_answers(question)
		var is_correct := false
		
		match question.get("type", "mc"):
			"text":
				for valid in valid_answers:
					if user_answer == valid.to_lower():
						is_correct = true
						break
			_:
				var expected: String = String(question.get("answer", "")).strip_edges()
				if user_answer == expected.to_lower():
					is_correct = true
		
		if is_correct:
			correct += 1
			weighted_correct += weight
		else:
			wrong_by_band[band] = wrong_by_band.get(band, 0) + 1
	
	var percentage := 0.0
	if weighted_total > 0.0:
		percentage = weighted_correct / weighted_total * 100.0
	
	var level_result: String = determine_level(percentage)
	
	# Apply band-based caps if user struggles within a band after enough items
	var cap_level: String = level_result
	for band in ["C", "B", "A"]:
		var seen: int = int(seen_by_band.get(band, 0))
		var wrong: int = int(wrong_by_band.get(band, 0))
		if seen >= min_items_per_band and seen > 0:
			var wrong_rate := float(wrong) / float(seen)
			if wrong_rate >= stop_down_threshold:
				cap_level = band_cap_level.get(band, cap_level)
				band_stop_triggered = true
				break  # apply the first (higher) band cap encountered
	
	return {
		"correct": correct,
		"total": total,
		"weighted_correct": weighted_correct,
		"weighted_total": weighted_total,
		"percentage": percentage,
		"level": cap_level,
		"level_uncapped": level_result,
		"band_stop_triggered": band_stop_triggered,
		"seen_by_band": seen_by_band,
		"wrong_by_band": wrong_by_band,
		"band_thresholds": {
			"min_items_per_band": min_items_per_band,
			"stop_down_threshold": stop_down_threshold
		}
	}

func determine_level(pct: float) -> String:
	for rule in LEVEL_MAP:
		if pct >= rule["threshold"]:
			return rule["level"]
	return "A1"
