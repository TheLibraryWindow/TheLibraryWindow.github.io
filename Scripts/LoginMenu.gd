extends Control

const AuthManagerClass := preload("res://Scripts/AuthManager.gd")
const UIHelpersClass := preload("res://Scripts/UI.gd")

const TARGET_DESKTOP_SIZE := Vector2(1600.0, 900.0)
const PANEL_BASE_SIZE := Vector2(560.0, 640.0)
const PANEL_MIN_SIZE := Vector2(360.0, 540.0)
const PANEL_MAX_SCALE := 1.25
const TITLE_FONT_SIZE := 44
const SUBTITLE_FONT_SIZE := 22
const TAGLINE_FONT_SIZE := 18
const FLOW_LINE_MIN_HEIGHT := 360.0
const LAYOUT_MARGIN_RATIO := Vector2(0.08, 0.06)
const LAYOUT_MARGIN_MIN := Vector2(96.0, 72.0)
const LAYOUT_MARGIN_MAX := Vector2(180.0, 144.0)

signal user_ready(username: String)

@onready var tagline_label: Label = $Layout/Panel/VBox/Tagline
@onready var title_label: Label = $Layout/Panel/VBox/Title
@onready var subtitle_label: Label = $Layout/Panel/VBox/Subtitle
@onready var login_username: LineEdit = $Layout/Panel/VBox/TabContainer/Login/LoginUser
@onready var login_password: LineEdit = $Layout/Panel/VBox/TabContainer/Login/LoginPass
@onready var login_button: Button = $Layout/Panel/VBox/TabContainer/Login/LoginButton
@onready var login_status: Label = $Layout/Panel/VBox/TabContainer/Login/LoginStatus
@onready var register_username: LineEdit = $Layout/Panel/VBox/TabContainer/Register/RegisterUser
@onready var register_password: LineEdit = $Layout/Panel/VBox/TabContainer/Register/RegisterPass
@onready var register_button: Button = $Layout/Panel/VBox/TabContainer/Register/RegisterButton
@onready var register_status: Label = $Layout/Panel/VBox/TabContainer/Register/RegisterStatus
@onready var timer: Timer = $TaglineTimer
@onready var panel: PanelContainer = $Layout/Panel
@onready var flow_lines: HBoxContainer = $FlowLines
@onready var layout_container: Control = $Layout

var phrases := [
	"Adaptive Trinity ISE prep",
	"Precision desktop coaching",
	"Animated guidance for every skill",
	"Track Listening · Speaking · Reading · Writing",
	"Earn badges as you climb from B1 to C1"
]
var phrase_index := 0
var auth_manager: Node

func _ready() -> void:
	_prepare_theme()
	_setup_auth()
	login_button.pressed.connect(_handle_login)
	register_button.pressed.connect(_handle_register)
	timer.timeout.connect(_cycle_tagline)
	get_viewport().size_changed.connect(_on_viewport_resized)
	_apply_responsive_layout()

func _prepare_theme() -> void:
	var inputs: Array[LineEdit] = [login_username, login_password, register_username, register_password]
	for field in inputs:
		UIHelpersClass.ensure_minimum_control_size(field)
		field.mouse_filter = Control.MOUSE_FILTER_STOP
		field.focus_mode = Control.FOCUS_ALL

	var buttons := [login_button, register_button]
	for btn in buttons:
		UIHelpersClass.ensure_minimum_control_size(btn)
		btn.theme_type_variation = "SkillPathPrimary"

func _setup_auth() -> void:
	auth_manager = AuthManagerClass.new()
	add_child(auth_manager)
	auth_manager.user_registered.connect(_on_user_registered)
	auth_manager.user_authenticated.connect(_on_user_authenticated)
	auth_manager.auth_error.connect(_on_auth_error)

func _cycle_tagline() -> void:
	phrase_index = (phrase_index + 1) % phrases.size()
	tagline_label.text = phrases[phrase_index]

func _on_viewport_resized() -> void:
	_apply_responsive_layout()

func _apply_responsive_layout() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var width_ratio := viewport_size.x / TARGET_DESKTOP_SIZE.x
	var height_ratio := viewport_size.y / TARGET_DESKTOP_SIZE.y
	var scale := clampf(minf(width_ratio, height_ratio), 0.85, PANEL_MAX_SCALE)

	var panel_size := PANEL_BASE_SIZE * Vector2(scale, scale)
	panel_size.x = clampf(panel_size.x, PANEL_MIN_SIZE.x, PANEL_BASE_SIZE.x * PANEL_MAX_SCALE)
	panel_size.y = clampf(panel_size.y, PANEL_MIN_SIZE.y, PANEL_BASE_SIZE.y * PANEL_MAX_SCALE)
	panel.custom_minimum_size = panel_size

	var text_scale := clampf(scale, 0.9, 1.2)
	_apply_font_scale(text_scale)
	_adjust_layout_margins(viewport_size)
	_update_flow_lines(viewport_size)

func _apply_font_scale(font_scale: float) -> void:
	title_label.add_theme_font_size_override("font_size", roundi(TITLE_FONT_SIZE * font_scale))
	subtitle_label.add_theme_font_size_override("font_size", roundi(SUBTITLE_FONT_SIZE * (font_scale + 0.05)))
	tagline_label.add_theme_font_size_override("font_size", roundi(TAGLINE_FONT_SIZE * font_scale))

func _update_flow_lines(viewport_size: Vector2) -> void:
	var target_height: float = maxf(viewport_size.y * 0.65, FLOW_LINE_MIN_HEIGHT)
	for line in flow_lines.get_children():
		if line is ColorRect:
			line.custom_minimum_size.y = target_height

	var flow_color := flow_lines.modulate
	flow_color.a = 0.08
	flow_lines.modulate = flow_color

func _adjust_layout_margins(viewport_size: Vector2) -> void:
	var horizontal_margin := clampf(viewport_size.x * LAYOUT_MARGIN_RATIO.x, LAYOUT_MARGIN_MIN.x, LAYOUT_MARGIN_MAX.x)
	var vertical_margin := clampf(viewport_size.y * LAYOUT_MARGIN_RATIO.y, LAYOUT_MARGIN_MIN.y, LAYOUT_MARGIN_MAX.y)

	layout_container.add_theme_constant_override("margin_left", horizontal_margin)
	layout_container.add_theme_constant_override("margin_right", horizontal_margin)
	layout_container.add_theme_constant_override("margin_top", vertical_margin)
	layout_container.add_theme_constant_override("margin_bottom", vertical_margin)

func _handle_login() -> void:
	login_status.text = ""
	if auth_manager.authenticate(login_username.text, login_password.text):
		return
	# Errors are handled via signal

func _handle_register() -> void:
	register_status.text = ""
	auth_manager.register_user(register_username.text, register_password.text)

func _on_user_registered(username: String) -> void:
	register_status.text = "Welcome, %s. You can log in now." % username
	register_status.modulate = Color(0.6, 1, 0.7, 1)

func _on_user_authenticated(username: String) -> void:
	login_status.text = "Hello %s — syncing progress..." % username
	login_status.modulate = Color(0.6, 1, 0.7, 1)
	emit_signal("user_ready", username)

func _on_auth_error(message: String) -> void:
	login_status.text = message
	login_status.modulate = Color(1, 0.6, 0.6, 1)
	register_status.text = message
	register_status.modulate = Color(1, 0.6, 0.6, 1)
