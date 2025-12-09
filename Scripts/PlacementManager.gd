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
		var user_answer: String = String(responses[qid]).strip_edges().to_lower()
		var valid_answers: Array[String] = get_valid_answers(question)
		
		match question.get("type", "mc"):
			"text":
				# Check if user answer matches any valid answer (including synonyms)
				var is_correct := false
				for valid in valid_answers:
					if user_answer == valid.to_lower():
						is_correct = true
						break
				if is_correct:
					correct += 1
			_:
				# Multiple choice - exact match
				var expected: String = String(question.get("answer", "")).strip_edges()
				if user_answer == expected.to_lower():
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
