extends Node
class_name QuestionPoolGenerator

# Uses questions exactly as provided - no modifications
# Questions already have IDs like "1a", "1b", "1c" which indicate their slot
# Total: 35 slots × 3 questions = 105 questions

static func generate_expanded_pool(base_questions: Array) -> Array:
	var expanded: Array = []
	
	# Use questions exactly as provided - just add slot_position metadata
	for question in base_questions:
		var qid: String = question.get("id", "")
		if qid.is_empty():
			continue
		
		# Extract slot number from ID (e.g., "1a" -> 1, "23b" -> 23)
		var slot_number := 0
		var numeric_part := ""
		for i in range(qid.length()):
			var char := qid[i]
			if char.is_valid_int():
				numeric_part += char
			else:
				break
		
		if not numeric_part.is_empty():
			slot_number = numeric_part.to_int()
		
		# Determine slot option (a=1, b=2, c=3)
		var slot_option := 1
		var letter_part := qid.substr(numeric_part.length())
		if letter_part.length() > 0:
			match letter_part.to_lower():
				"a":
					slot_option = 1
				"b":
					slot_option = 2
				"c":
					slot_option = 3
		
		# Use question exactly as provided, just add slot metadata and remove skill from display
		var question_copy: Dictionary = question.duplicate(true)
		question_copy["slot_position"] = slot_number
		question_copy["slot_option"] = slot_option
		question_copy.erase("skill")  # Remove skill from display only
		expanded.append(question_copy)
	
	return expanded
