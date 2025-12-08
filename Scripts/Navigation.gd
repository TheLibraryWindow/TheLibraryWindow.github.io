extends VBoxContainer
class_name Navigation

signal section_changed(section: String)

@export var default_section := "dashboard"

var button_map: Dictionary = {}
var button_group := ButtonGroup.new()
var suppress_emit := false

func _ready() -> void:
	for child in get_children():
		if child is Button:
			var section: String = child.get_meta("section") if child.has_meta("section") else child.name.to_lower()
			button_map[section] = child
			child.toggle_mode = true
			child.button_group = button_group
			child.pressed.connect(func(): _on_button_pressed(section))
			_setup_button_hover(child)
	if button_map.has(default_section):
		suppress_emit = true
		button_map[default_section].button_pressed = true
		suppress_emit = false

func _setup_button_hover(button: Button) -> void:
	button.mouse_entered.connect(func(): _on_button_hover(button, true))
	button.mouse_exited.connect(func(): _on_button_hover(button, false))

func _on_button_hover(button: Button, is_hovered: bool) -> void:
	if not button:
		return
	var tween := button.create_tween()
	if is_hovered:
		tween.tween_property(button, "modulate", Color(1.1, 1.1, 1.15, 1.0), 0.15)
	else:
		tween.tween_property(button, "modulate", Color.WHITE, 0.15)

func _on_button_pressed(section: String) -> void:
	if suppress_emit:
		return
	emit_signal("section_changed", section)

func set_active(section: String) -> void:
	if not button_map.has(section):
		return
	suppress_emit = true
	button_map[section].button_pressed = true
	suppress_emit = false
