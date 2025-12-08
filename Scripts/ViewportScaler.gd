extends Node

const DESKTOP_DEFAULT := Vector2i(1600, 900)
const DESKTOP_MIN := Vector2i(1280, 720)
const DESKTOP_MAX := Vector2i(2048, 1152)

func _ready() -> void:
	_update_viewport()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		_update_viewport()

func _update_viewport() -> void:
	var viewport := get_viewport()
	var window_size := DisplayServer.window_get_size()
	var target_size := _get_desktop_view_size(window_size)

	viewport.content_scale_mode = Viewport.CONTENT_SCALE_MODE_CANVAS_ITEMS
	viewport.content_scale_aspect = Viewport.CONTENT_SCALE_ASPECT_KEEP
	viewport.content_scale_size = target_size

func _get_desktop_view_size(window_size: Vector2i) -> Vector2i:
	if window_size == Vector2i.ZERO:
		return DESKTOP_DEFAULT

	var width := clampi(window_size.x, DESKTOP_MIN.x, DESKTOP_MAX.x)
	var height := clampi(window_size.y, DESKTOP_MIN.y, DESKTOP_MAX.y)

	# Maintain a 16:9 friendly aspect ratio for consistent desktop layout.
	var target_aspect := float(DESKTOP_DEFAULT.x) / float(DESKTOP_DEFAULT.y)
	var current_aspect := float(width) / float(height)
	if current_aspect > target_aspect:
		width = int(round(height * target_aspect))
	else:
		height = int(round(width / target_aspect))

	return Vector2i(width, height)
