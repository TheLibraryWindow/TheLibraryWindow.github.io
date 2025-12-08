extends Control

signal logout_requested()
signal reset_requested()

const CoursesScene := preload("res://Scenes/Courses.tscn")
const LessonScene := preload("res://Scenes/LessonView.tscn")

@onready var name_label: Label = $Main/VBox/HeaderRow/UserInfo/UserName
@onready var level_label: Label = $Main/VBox/HeaderRow/UserInfo/LevelLabel
@onready var grade_label: Label = $Main/VBox/HeaderRow/UserInfo/GradeLabel
@onready var continue_button: Button = $Main/VBox/HeaderRow/ContinueButton
@onready var nav_menu: Navigation = $Main/VBox/Body/NavPanel/NavMenu
@onready var content_panel: Control = $Main/VBox/Body/ContentPanel/Sections
@onready var home_section: Control = $Main/VBox/Body/ContentPanel/Sections/HomeSection
@onready var courses_section: Control = $Main/VBox/Body/ContentPanel/Sections/CoursesSection
@onready var progress_section: Control = $Main/VBox/Body/ContentPanel/Sections/ProgressSection
@onready var profile_section: Control = $Main/VBox/Body/ContentPanel/Sections/ProfileSection
@onready var lesson_section: Control = $Main/VBox/Body/ContentPanel/Sections/LessonSection
@onready var skill_bars := {
	"Listening": $Main/VBox/Body/ContentPanel/Sections/HomeSection/HomeVBox/SkillGrid/ListeningBar,
	"Speaking": $Main/VBox/Body/ContentPanel/Sections/HomeSection/HomeVBox/SkillGrid/SpeakingBar,
	"Reading": $Main/VBox/Body/ContentPanel/Sections/HomeSection/HomeVBox/SkillGrid/ReadingBar,
	"Writing": $Main/VBox/Body/ContentPanel/Sections/HomeSection/HomeVBox/SkillGrid/WritingBar
}
@onready var courses_holder: Control = $Main/VBox/Body/ContentPanel/Sections/CoursesSection/CoursesHolder
@onready var progress_list: VBoxContainer = $Main/VBox/Body/ContentPanel/Sections/ProgressSection/Scroll/VBox
@onready var profile_name: LineEdit = $Main/VBox/Body/ContentPanel/Sections/ProfileSection/ProfileVBox/DisplayName
@onready var profile_level: OptionButton = $Main/VBox/Body/ContentPanel/Sections/ProfileSection/ProfileVBox/LevelDropdown
@onready var profile_save_button: Button = $Main/VBox/Body/ContentPanel/Sections/ProfileSection/ProfileVBox/SaveNameButton
@onready var profile_reset_button: Button = $Main/VBox/Body/ContentPanel/Sections/ProfileSection/ProfileVBox/ResetButton
@onready var profile_logout_button: Button = $Main/VBox/Body/ContentPanel/Sections/ProfileSection/ProfileVBox/LogoutButton
@onready var lesson_holder: Control = $Main/VBox/Body/ContentPanel/Sections/LessonSection/VBox/LessonHolder
@onready var lesson_back_button: Button = $Main/VBox/Body/ContentPanel/Sections/LessonSection/VBox/BackButton

var progress_manager: ProgressManager
var lesson_loader: LessonLoader
var username := ""
var courses_view: Node
var lesson_view: Node
var active_section := "dashboard"

func _ready() -> void:
	nav_menu.section_changed.connect(_on_section_changed)
	continue_button.pressed.connect(_on_continue_pressed)
	profile_save_button.pressed.connect(_on_save_profile)
	profile_reset_button.pressed.connect(func(): emit_signal("reset_requested"))
	profile_logout_button.pressed.connect(func(): emit_signal("logout_requested"))
	lesson_back_button.pressed.connect(_close_lesson)

func configure(user: String, progress_mgr: ProgressManager, lesson_loader_ref: LessonLoader) -> void:
	username = user
	progress_manager = progress_mgr
	lesson_loader = lesson_loader_ref
	progress_manager.profile_changed.connect(_on_profile_changed)
	progress_manager.profile_loaded.connect(_on_profile_changed)
	_fill_level_dropdown()
	_on_profile_changed(progress_manager.profile)
	_show_section("dashboard")

func _fill_level_dropdown() -> void:
	profile_level.clear()
	for level in ProgressManager.LEVELS:
		profile_level.add_item(level)
	profile_level.item_selected.connect(_on_level_changed)

func _on_level_changed(index: int) -> void:
	var level := profile_level.get_item_text(index)
	progress_manager.set_current_level(level)

func _on_profile_changed(profile: Dictionary) -> void:
	if profile.is_empty():
		return
	name_label.text = profile.get("display_name", username)
	level_label.text = "Level: %s" % profile.get("current_level", "A1")
	grade_label.text = "Overall: %s (%.0f%%)" % [progress_manager.get_overall_grade(), progress_manager.get_overall_accuracy()]
	profile_name.text = profile.get("display_name", username)
	var current_level := profile.get("current_level", "A1")
	for idx in range(profile_level.item_count):
		if profile_level.get_item_text(idx) == current_level:
			profile_level.select(idx)
			break
	_refresh_skill_bars(current_level)
	_refresh_progress_list()
	if courses_view:
		(courses_view as CoursesView).refresh_state()

func _refresh_skill_bars(level: String) -> void:
	for skill in skill_bars.keys():
		var pct := progress_manager.get_skill_accuracy(level, skill) * 100.0
		(skill_bars[skill] as ProgressBar).value = pct

func _refresh_progress_list() -> void:
	for child in progress_list.get_children():
		child.queue_free()
	var overall := Label.new()
	overall.text = "Overall accuracy: %.1f%% (Grade %s)" % [progress_manager.get_overall_accuracy(), progress_manager.get_overall_grade()]
	progress_list.add_child(overall)
	for level in ProgressManager.LEVELS:
		var header := Label.new()
		header.text = "%s" % level
		header.add_theme_color_override("font_color", Color(0.7, 0.9, 1))
		progress_list.add_child(header)
		for skill in ProgressManager.SKILLS:
			var item := Label.new()
			var pct := progress_manager.get_skill_accuracy(level, skill) * 100.0
			item.text = "  %s: %.1f%%" % [skill, pct]
			progress_list.add_child(item)

func _on_section_changed(section: String) -> void:
	if section == active_section:
		return
	_show_section(section)

func _show_section(section: String) -> void:
	active_section = section
	if section in [\"dashboard\", \"courses\", \"progress\", \"profile\"]:
		nav_menu.set_active(section)
	for node in [home_section, courses_section, progress_section, profile_section, lesson_section]:
		node.visible = false
	match section:
		"dashboard":
			home_section.visible = true
		"courses":
			courses_section.visible = true
			_ensure_courses_view()
		"progress":
			progress_section.visible = true
		"profile":
			profile_section.visible = true
		"lesson":
			lesson_section.visible = true

func _ensure_courses_view() -> void:
	if courses_view:
		return
	courses_view = CoursesScene.instantiate()
	(courses_view as CoursesView).configure(progress_manager, lesson_loader)
	(courses_view as CoursesView).lesson_requested.connect(_on_lesson_requested)
	courses_holder.add_child(courses_view)

func _on_lesson_requested(level: String, skill: String, lesson_data: Dictionary) -> void:
	_show_section("lesson")
	if lesson_view:
		lesson_view.queue_free()
	lesson_view = LessonScene.instantiate()
	(lesson_view as LessonView).configure(level, skill, lesson_data, progress_manager)
	(lesson_view as LessonView).lesson_completed.connect(_on_lesson_completed)
	lesson_holder.add_child(lesson_view)

func _on_lesson_completed(payload: Dictionary) -> void:
	var level := payload.get("level", "")
	var skill := payload.get("skill", "")
	var lesson_id := payload.get("lesson_id", "")
	var correct := payload.get("correct", 0)
	var attempted := payload.get("attempted", 0)
	progress_manager.record_lesson_result(level, skill, lesson_id, correct, attempted)
	if courses_view:
		(courses_view as CoursesView).refresh_state()

func _close_lesson() -> void:
	if lesson_view:
		lesson_view.queue_free()
		lesson_view = null
	_show_section("courses")

func _on_continue_pressed() -> void:
	var last := progress_manager.get_last_activity()
	if last.get("lesson_id", "").is_empty():
		_show_section("courses")
		return
	var lesson_data := lesson_loader.find_lesson(last.get("level", ""), last.get("lesson_id", ""))
	if lesson_data.is_empty():
		_show_section("courses")
		return
	var skill := lesson_data.get("skill", last.get("skill", "Listening"))
	_on_lesson_requested(last.get("level", ""), skill, lesson_data)

func _on_save_profile() -> void:
	progress_manager.set_display_name(profile_name.text)

func get_active_section() -> String:
	return active_section
*** End File