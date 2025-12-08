extends Control

const LoginScene := preload("res://Scenes/LoginMenu.tscn")
const PlacementScene := preload("res://Scenes/PlacementTest.tscn")
const DashboardScene := preload("res://Scenes/Dashboard.tscn")

@onready var view_root: Control = $ViewRoot

var progress_manager := ProgressManager.new()
var placement_manager := PlacementManager.new()
var lesson_loader := LessonLoader.new()

var active_view: Control
var current_user := ""

func _ready() -> void:
	add_child(progress_manager)
	add_child(placement_manager)
	add_child(lesson_loader)
	placement_manager.load_questions()
	_show_login()

func _clear_active() -> void:
	if active_view and is_instance_valid(active_view):
		active_view.queue_free()
		active_view = null

func _show_login() -> void:
	_clear_active()
	var login := LoginScene.instantiate()
	login.user_ready.connect(_on_user_ready)
	view_root.add_child(login)
	active_view = login

func _show_placement() -> void:
	_clear_active()
	var placement := PlacementScene.instantiate()
	placement.placement_finished.connect(_on_placement_finished)
	view_root.add_child(placement)
	placement.call_deferred("setup_test", current_user, placement_manager, progress_manager)
	active_view = placement

func _show_dashboard() -> void:
	_clear_active()
	var dashboard := DashboardScene.instantiate()
	dashboard.logout_requested.connect(_on_logout_requested)
	dashboard.reset_requested.connect(_on_reset_requested)
	view_root.add_child(dashboard)
	dashboard.call_deferred("configure", current_user, progress_manager, lesson_loader)
	active_view = dashboard

func _on_user_ready(username: String) -> void:
	current_user = username
	progress_manager.load_profile(username)
	if progress_manager.profile.get("placement", {}).get("completed", false):
		_show_dashboard()
	else:
		_show_placement()

func _on_placement_finished(score: float, level: String) -> void:
	progress_manager.apply_placement_result(level, score)
	_show_dashboard()

func _on_logout_requested() -> void:
	current_user = ""
	_show_login()

func _on_reset_requested() -> void:
	progress_manager.reset_profile()
	_show_placement()
*** End File