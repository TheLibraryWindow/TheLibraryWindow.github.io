extends PanelContainer
class_name LevelView

signal open_level(level_code: String)

@onready var level_label: Label = $VBox/LevelLabel
@onready var tagline_label: Label = $VBox/TaglineLabel
@onready var completion_bar: ProgressBar = $VBox/CompletionBar
@onready var skills_label: Label = $VBox/SkillsLabel
@onready var completion_label: Label = $VBox/CompletionLabel
@onready var open_button: Button = $VBox/OpenButton

var level_code := ""

func _ready() -> void:
	open_button.pressed.connect(_emit_open)

func configure(code: String, tagline: String, completion_ratio: float, skill_breakdown: Dictionary = {}) -> void:
	level_code = code
	level_label.text = code
	tagline_label.text = tagline
	var pct := clampf(completion_ratio * 100.0, 0.0, 100.0)
	completion_bar.value = pct
	completion_label.text = "%.0f%% complete" % pct
	skills_label.text = _format_skills(skill_breakdown)
	open_button.text = "Enter %s" % code

func _emit_open() -> void:
	emit_signal("open_level", level_code)

func _format_skills(breakdown: Dictionary) -> String:
	if breakdown.is_empty():
		return "Skills: --"
	var parts: Array[String] = []
	for skill in ["Listening", "Speaking", "Reading", "Writing"]:
		if breakdown.has(skill):
			var pct := breakdown[skill] * 100.0
			parts.append("%s %.0f%%" % [skill.substr(0, 1), pct])
	return " · ".join(parts)
*** End File