extends Node

const LANDSCAPE := Vector2i(1280, 720)
const PORTRAIT := Vector2i(720, 1280)
const MOBILE_SHORT_EDGE_THRESHOLD := 820

var _default_scale_mode := Viewport.CONTENT_SCALE_MODE_CANVAS_ITEMS
var _default_scale_aspect := Viewport.CONTENT_SCALE_ASPECT_KEEP

func _ready() -> void:
	var viewport := get_viewport()
	_default_scale_mode = viewport.content_scale_mode
	_default_scale_aspect = viewport.content_scale_aspect
	_update_viewport()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		_update_viewport()

func _update_viewport() -> void:
	var viewport := get_viewport()
	var win_size := DisplayServer.window_get_size()
	if win_size == Vector2i.ZERO:
		return

	var shortest_edge := min(win_size.x, win_size.y)
	var is_mobile := shortest_edge <= MOBILE_SHORT_EDGE_THRESHOLD
	if is_mobile:
		viewport.content_scale_mode = Viewport.CONTENT_SCALE_MODE_DISABLED
		viewport.content_scale_aspect = Viewport.CONTENT_SCALE_ASPECT_IGNORE
		viewport.content_scale_size = win_size
	else:
		var target := PORTRAIT if win_size.x < win_size.y else LANDSCAPE
		viewport.content_scale_mode = _default_scale_mode
		viewport.content_scale_aspect = _default_scale_aspect
		viewport.content_scale_size = target
