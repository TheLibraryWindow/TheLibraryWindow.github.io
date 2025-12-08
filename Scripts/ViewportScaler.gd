extends Node

const LANDSCAPE := Vector2i(1280, 720)
const PORTRAIT := Vector2i(720, 1280)
const MOBILE_SHORT_EDGE_THRESHOLD := 820

const JS_VIEWPORT_QUERY := "(function(){return {width: window.innerWidth || 0, height: window.innerHeight || 0};})()"

func _ready() -> void:
	_update_viewport()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		_update_viewport()

func _update_viewport() -> void:
	var viewport: Viewport = get_viewport()
	var device_size := _get_device_view_size()
	if device_size == Vector2i.ZERO:
		return

	var target: Vector2i = PORTRAIT if device_size.x < device_size.y else LANDSCAPE
	if _is_mobile_view(device_size):
		viewport.content_scale_size = device_size
	else:
		viewport.content_scale_size = target

func _get_device_view_size() -> Vector2i:
	var win_size: Vector2i = DisplayServer.window_get_size()
	if OS.has_feature("web") and Engine.has_singleton("JavaScriptBridge"):
		var js_bridge: Object = Engine.get_singleton("JavaScriptBridge")
		var js_result: Variant = js_bridge.call("eval", JS_VIEWPORT_QUERY, true)
		if js_result is Dictionary:
			var width := int(js_result.get("width", 0))
			var height := int(js_result.get("height", 0))
			if width > 0 and height > 0:
				return Vector2i(width, height)
	return win_size

func _is_mobile_view(size: Vector2i) -> bool:
	var shortest_edge: int = min(size.x, size.y)
	return shortest_edge <= MOBILE_SHORT_EDGE_THRESHOLD
