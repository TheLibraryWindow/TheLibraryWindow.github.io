extends Control
class_name CoursesView

signal lesson_requested(level: String, skill: String, lesson_data: Dictionary)

const LevelCardScene := preload("res://Scenes/LevelView.tscn")
const SkillsScene := preload("res://Scenes/SkillsView.tscn")

@onready var level_grid: GridContainer = $VBox/LevelGrid
@onready var level_detail: PanelContainer = $VBox/LevelDetail
@onready var level_title: Label = $VBox/LevelDetail/Header/LevelTitle
@onready var skills_host: Control = $VBox/LevelDetail/SkillsHost

var progress_manager: ProgressManager
var lesson_loader: LessonLoader
var skills_view: SkillsView
var level_payloads: Dictionary = {}
var level_totals: Dictionary = {}

func configure(progress_mgr: ProgressManager, loader: LessonLoader) -> void:
	progress_manager = progress_mgr
	lesson_loader = loader
	_load_level_payloads()
	_render_level_cards()

func refresh_state() -> void:
	_render_level_cards()
	if skills_view:
		skills_view.refresh_state()

func _load_level_payloads() -> void:
	level_payloads.clear()
	level_totals.clear()
	for level in ProgressManager.LEVELS:
		var data := lesson_loader.load_lessons(level)
		if data.is_empty():
			continue
		level_payloads[level] = data.duplicate(true)
		var total := 0
		var skills: Dictionary = data.get("skills", {})
		for skill in skills.keys():
			total += skills[skill].size()
		level_totals[level] = total

func _render_level_cards() -> void:
	if not is_instance_valid(level_grid):
		return
	for child in level_grid.get_children():
		child.queue_free()
	for level in ProgressManager.LEVELS:
		if not level_payloads.has(level):
			continue
		var card := LevelCardScene.instantiate()
		level_grid.add_child(card)
		var tagline: String = level_payloads[level].get("tagline", "")
		var completion := progress_manager.get_level_completion(level, level_totals.get(level, 0))
		var breakdown := {}
		for skill in ProgressManager.SKILLS:
			breakdown[skill] = progress_manager.get_skill_accuracy(level, skill)
		card.configure(level, tagline, completion, breakdown)
		card.open_level.connect(func(code: String): _show_level(code))

func _show_level(level: String) -> void:
	if not level_payloads.has(level):
		return
	level_detail.visible = true
	level_title.text = "%s pathway" % level
	if skills_view:
		skills_view.queue_free()
	skills_view = SkillsScene.instantiate()
	skills_view.configure(level, level_payloads[level], progress_manager)
	skills_view.lesson_requested.connect(_on_lesson_requested)
	skills_host.add_child(skills_view)

func _on_lesson_requested(level: String, skill: String, lesson_data: Dictionary) -> void:
	emit_signal("lesson_requested", level, skill, lesson_data)
