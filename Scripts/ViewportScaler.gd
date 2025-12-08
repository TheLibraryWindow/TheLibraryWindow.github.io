extends Node

const LANDSCAPE := Vector2i(1280, 720)
const PORTRAIT := Vector2i(720, 1280)

func _ready() -> void:
	_update_viewport()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		_update_viewport()

func _update_viewport() -> void:
	var win_size := DisplayServer.window_get_size()
	var target := PORTRAIT if win_size.x < win_size.y else LANDSCAPE
	get_viewport().content_scale_size = target
