extends Node

const LANDSCAPE := Vector2i(1280, 720)
const PORTRAIT := Vector2i(720, 1280)
const MOBILE_SHORT_EDGE_THRESHOLD := 820

func _ready() -> void:
	_update_viewport()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		_update_viewport()

func _update_viewport() -> void:
	var viewport: Viewport = get_viewport()
	var win_size: Vector2i = DisplayServer.window_get_size()
	if win_size == Vector2i.ZERO:
		return

	var target: Vector2i = PORTRAIT if win_size.x < win_size.y else LANDSCAPE
	var shortest_edge: int = min(win_size.x, win_size.y)
	if shortest_edge <= MOBILE_SHORT_EDGE_THRESHOLD:
		viewport.content_scale_size = win_size
	else:
		viewport.content_scale_size = target
