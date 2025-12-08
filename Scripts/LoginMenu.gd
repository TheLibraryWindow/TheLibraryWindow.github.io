extends Control

const AuthManagerClass := preload("res://Scripts/AuthManager.gd")
const UIHelpersClass := preload("res://Scripts/UI.gd")

const TARGET_DESKTOP_SIZE := Vector2(1280.0, 720.0)
const PANEL_BASE_SIZE := Vector2(520.0, 640.0)
const PANEL_MIN_SIZE := Vector2(320.0, 520.0)
const MOBILE_BREAKPOINT := 820.0
const TITLE_FONT_SIZE := 44
const SUBTITLE_FONT_SIZE := 22
const TAGLINE_FONT_SIZE := 18
const FLOW_LINE_MIN_HEIGHT := 320.0
const MOBILE_MARGIN := Vector4(16.0, 24.0, 16.0, 24.0) # left, top, right, bottom

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
	"Sleek, mobile-first coaching",
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
		UIHelpersClass.apply_touch_target(field)
		_connect_virtual_keyboard(field)

	var buttons := [login_button, register_button]
	for btn in buttons:
		UIHelpersClass.apply_touch_target(btn)
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
	var screen_size := viewport_size

	var width_ratio: float = clampf(screen_size.x / TARGET_DESKTOP_SIZE.x, 0.5, 1.0)
	var height_ratio: float = clampf(screen_size.y / TARGET_DESKTOP_SIZE.y, 0.6, 1.0)
	var is_mobile := screen_size.x <= MOBILE_BREAKPOINT

	_adjust_layout_margins(is_mobile)

	if is_mobile:
		var mobile_width := clampf(screen_size.x - (MOBILE_MARGIN.x + MOBILE_MARGIN.z), PANEL_MIN_SIZE.x, screen_size.x)
		var mobile_height := clampf(screen_size.y - (MOBILE_MARGIN.y + MOBILE_MARGIN.w), PANEL_MIN_SIZE.y, screen_size.y)
		panel.custom_minimum_size = Vector2(mobile_width, mobile_height)
	else:
		var panel_size := PANEL_BASE_SIZE * Vector2(width_ratio, height_ratio)
		panel_size.x = clampf(panel_size.x, PANEL_MIN_SIZE.x, PANEL_BASE_SIZE.x)
		panel_size.y = clampf(panel_size.y, PANEL_MIN_SIZE.y, PANEL_BASE_SIZE.y)
		panel.custom_minimum_size = panel_size

	var text_scale: float = clampf(minf(width_ratio, height_ratio), 0.8, 1.0)
	if is_mobile:
		text_scale = clampf(text_scale * 0.98, 0.85, 1.0)

	_apply_font_scale(text_scale)
	_update_flow_lines(screen_size, is_mobile)

func _apply_font_scale(font_scale: float) -> void:
	title_label.add_theme_font_size_override("font_size", roundi(TITLE_FONT_SIZE * font_scale))
	subtitle_label.add_theme_font_size_override("font_size", roundi(SUBTITLE_FONT_SIZE * (font_scale + 0.05)))
	tagline_label.add_theme_font_size_override("font_size", roundi(TAGLINE_FONT_SIZE * font_scale))

func _update_flow_lines(viewport_size: Vector2, is_mobile: bool) -> void:
	var target_height: float = maxf(viewport_size.y * (0.5 if is_mobile else 0.7), FLOW_LINE_MIN_HEIGHT)
	for line in flow_lines.get_children():
		if line is ColorRect:
			line.custom_minimum_size.y = target_height

	var flow_color := flow_lines.modulate
	flow_color.a = 0.05 if is_mobile else 0.08
	flow_lines.modulate = flow_color

func _connect_virtual_keyboard(field: LineEdit) -> void:
	field.mouse_filter = Control.MOUSE_FILTER_STOP
	field.focus_mode = Control.FOCUS_ALL
	field.focus_entered.connect(func():
		_show_virtual_keyboard(field)
	)
	field.focus_exited.connect(_hide_virtual_keyboard)
	field.gui_input.connect(func(event: InputEvent):
		if (event is InputEventScreenTouch or event is InputEventMouseButton) and event.pressed:
			field.grab_focus()
			_show_virtual_keyboard(field)
	)

func _show_virtual_keyboard(field: LineEdit) -> void:
	if not DisplayServer.has_feature(DisplayServer.FEATURE_VIRTUAL_KEYBOARD):
		return
	var rect := field.get_global_rect()
	var rect_i := Rect2i(Vector2i(rect.position), Vector2i(rect.size))
	DisplayServer.virtual_keyboard_show(field.text, rect_i)

func _hide_virtual_keyboard() -> void:
	if not DisplayServer.has_feature(DisplayServer.FEATURE_VIRTUAL_KEYBOARD):
		return
	DisplayServer.virtual_keyboard_hide()

func _adjust_layout_margins(is_mobile: bool) -> void:
	var side_margin := MOBILE_MARGIN.x if is_mobile else 96.0
	var top_margin := MOBILE_MARGIN.y if is_mobile else 72.0
	var bottom_margin := MOBILE_MARGIN.x if is_mobile else 72.0

	for margin_name in ["left", "right"]:
		layout_container.add_theme_constant_override("margin_%s" % margin_name, side_margin)
	layout_container.add_theme_constant_override("margin_top", top_margin)
	layout_container.add_theme_constant_override("margin_bottom", bottom_margin)

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
