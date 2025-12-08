extends Label
class_name DragCard

@export var payload: String = ""

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_theme_color_override("font_color", Color(0.15, 0.2, 0.4))
	add_theme_color_override("font_outline_color", Color(1, 1, 1))
	add_theme_constant_override("outline_size", 1)
	add_theme_stylebox_override("normal", _build_stylebox())

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var data := {
			"drag_text": text,
			"payload": payload
		}
		var preview := Label.new()
		preview.text = text
		preview.add_theme_color_override("font_color", Color(1, 1, 1))
		preview.add_theme_stylebox_override("normal", _build_stylebox())
		set_drag_preview(preview)
		set_drag_preview_position(Vector2.ZERO)
		set_drag_preview_offset(Vector2(8, 8))
		set_drag_preview(preview)
		get_viewport().gui_embed_subwindows = false
		set_drag_preview(preview)
		var drop_event := InputEventMouseButton.new()
		set_drag_preview(preview)
		get_viewport().canvas_item_start_drag(event.button_index, preview, self, data)

func _get_drag_data(position: Vector2):
	var data := {
		"drag_text": text,
		"payload": payload
	}
	var preview := Label.new()
	preview.text = text
	preview.add_theme_stylebox_override("normal", _build_stylebox())
	set_drag_preview(preview)
	return data

func _can_drop_data(_pos, _data) -> bool:
	return false

func _build_stylebox() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.9, 0.95, 1, 0.9)
	box.border_color = Color(0.2, 0.3, 0.6)
	box.corner_radius_top_left = 6
	box.corner_radius_top_right = 6
	box.corner_radius_bottom_left = 6
	box.corner_radius_bottom_right = 6
	box.content_margin_left = 12
	box.content_margin_right = 12
	box.content_margin_top = 6
	box.content_margin_bottom = 6
	return box
