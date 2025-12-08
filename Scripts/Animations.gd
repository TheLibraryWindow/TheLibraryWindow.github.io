extends Node
class_name AnimationHelper

@export var highlight_color := Color(1, 0.8, 0.2, 0.7)
@export var pulse_time := 0.4

func flash_control(control: Control, times: int = 2) -> void:
	if control == null:
		return
	var tween := create_tween()
	var original := control.modulate
	for i in times:
		tween.tween_property(control, "modulate", highlight_color, pulse_time)
		tween.tween_property(control, "modulate", original, pulse_time)

func move_pointer(pointer: Node2D, path: Array[Vector2]) -> void:
	if pointer == null or path.is_empty():
		return
	var tween := create_tween()
	pointer.visible = true
	tween.tween_property(pointer, "position", path[0], pulse_time)
	for i in range(1, path.size()):
		tween.tween_property(pointer, "position", path[i], pulse_time)

func fade_in(control: CanvasItem, duration: float = 0.5) -> void:
	if control == null:
		return
	control.modulate.a = 0
	var tween := create_tween()
	tween.tween_property(control, "modulate:a", 1.0, duration)
