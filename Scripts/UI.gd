extends Node
class_name UIHelpers

static func ensure_minimum_control_size(control: Control, min_size := Vector2(36, 36)) -> void:
	if control.custom_minimum_size.x < min_size.x:
		control.custom_minimum_size.x = min_size.x
	if control.custom_minimum_size.y < min_size.y:
		control.custom_minimum_size.y = min_size.y

static func build_button(text: String, callback_target: Object, callback_method: StringName) -> Button:
	var button := Button.new()
	button.text = text
	ensure_minimum_control_size(button)
	button.pressed.connect(func():
		if callback_target and callback_target.has_method(callback_method):
			callback_target.call(callback_method, button)
	)
	return button

static func build_progress_bar() -> ProgressBar:
	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = 100
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return bar

static func wrap_text(text: String) -> RichTextLabel:
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.text = text
	label.scroll_active = false
	return label
