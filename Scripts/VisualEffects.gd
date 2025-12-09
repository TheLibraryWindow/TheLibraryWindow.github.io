extends Node
class_name VisualEffects

static func create_animated_gradient(parent: Control, colors: Array, duration: float = 8.0) -> ColorRect:
	var gradient := ColorRect.new()
	gradient.name = "AnimatedGradient"
	gradient.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gradient.set_anchors_preset(Control.PRESET_FULL_RECT)
	parent.add_child(gradient)
	parent.move_child(gradient, 0)  # Move to back
	
	var tween := gradient.create_tween()
	tween.set_loops()
	tween.set_parallel(false)
	
	for i in range(colors.size()):
		var next_color: Color = colors[i]
		var next_index := (i + 1) % colors.size()
		var target_color: Color = colors[next_index]
		tween.tween_property(gradient, "color", target_color, duration / float(colors.size()))
	
	return gradient

static func create_flowing_particles(parent: Control, count: int = 12) -> Control:
	var container := Control.new()
	container.name = "FlowingParticles"
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	parent.add_child(container)
	parent.move_child(container, 0)
	
	for i in range(count):
		var particle := ColorRect.new()
		particle.name = "Particle%d" % i
		particle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var size := randf_range(20.0, 60.0)
		particle.custom_minimum_size = Vector2(size, size)
		particle.color = Color(0.3, 0.5, 0.8, randf_range(0.1, 0.3))
		particle.position = Vector2(randf() * parent.size.x, randf() * parent.size.y)
		container.add_child(particle)
		
		var tween := particle.create_tween()
		tween.set_loops()
		var start_pos := particle.position
		var end_pos := Vector2(
			start_pos.x + randf_range(-200, 200),
			start_pos.y + randf_range(-200, 200)
		)
		tween.tween_property(particle, "position", end_pos, randf_range(3.0, 6.0))
		tween.tween_property(particle, "position", start_pos, randf_range(3.0, 6.0))
	
	return container

static func smooth_fade_in(control: CanvasItem, duration: float = 0.5) -> void:
	if not is_instance_valid(control):
		return
	control.modulate.a = 0.0
	var tween := control.create_tween()
	tween.tween_property(control, "modulate:a", 1.0, duration)

static func smooth_slide_in(control: CanvasItem, direction: Vector2, duration: float = 0.5) -> void:
	if not is_instance_valid(control):
		return
	var start_pos: Vector2 = control.position
	var offset: Vector2 = direction * 100.0
	control.position = start_pos + offset
	control.modulate.a = 0.0
	var tween := control.create_tween()
	tween.set_parallel(true)
	tween.tween_property(control, "position", start_pos, duration)
	tween.tween_property(control, "modulate:a", 1.0, duration)

static func animate_progress_bar(bar: ProgressBar, target_value: float, duration: float = 0.5) -> void:
	if not is_instance_valid(bar):
		return
	var tween := bar.create_tween()
	tween.tween_property(bar, "value", target_value, duration)

static func create_orb_animation(parent: Control, duration: float = 120.0) -> ColorRect:
	var orb := ColorRect.new()
	orb.name = "FloatingOrb"
	orb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var size := randf_range(80.0, 150.0)
	orb.custom_minimum_size = Vector2(size, size)
	orb.color = Color(0.4, 0.6, 0.9, randf_range(0.15, 0.25))
	orb.position = Vector2(randf() * parent.size.x, randf() * parent.size.y)
	parent.add_child(orb)
	
	var tween := orb.create_tween()
	tween.set_loops()
	tween.set_parallel(true)
	
	# Floating movement
	var start_pos := orb.position
	var end_pos := Vector2(
		start_pos.x + randf_range(-300, 300),
		start_pos.y + randf_range(-300, 300)
	)
	tween.tween_property(orb, "position", end_pos, duration)
	tween.tween_property(orb, "position", start_pos, duration)
	
	# Pulsing scale
	tween.tween_property(orb, "scale", Vector2(1.2, 1.2), duration * 0.5)
	tween.tween_property(orb, "scale", Vector2(1.0, 1.0), duration * 0.5)
	
	return orb

static func create_floating_orbs(parent: Control, count: int = 5) -> void:
	for i in range(count):
		create_orb_animation(parent, 120.0 + randf() * 80.0)

static func create_geometric_pattern(parent: Control, density: int = 10) -> Control:
	var container := Control.new()
	container.name = "GeometricPattern"
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	parent.add_child(container)
	parent.move_child(container, 0)
	
	for i in range(density):
		var shape := ColorRect.new()
		shape.name = "Shape%d" % i
		shape.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var size := randf_range(40.0, 120.0)
		shape.custom_minimum_size = Vector2(size, size)
		shape.color = Color(0.2, 0.3, 0.5, randf_range(0.05, 0.15))
		shape.position = Vector2(randf() * parent.size.x, randf() * parent.size.y)
		container.add_child(shape)
		
		var tween := shape.create_tween()
		tween.set_loops()
		tween.tween_property(shape, "rotation_degrees", shape.rotation_degrees + 360, randf_range(10.0, 20.0))
	
	return container

static func create_ripple_effect(parent: Control, position: Vector2, color: Color = Color.WHITE, size: float = 50.0, duration: float = 0.5) -> void:
	var ripple := ColorRect.new()
	ripple.name = "Ripple"
	ripple.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ripple.custom_minimum_size = Vector2(size, size)
	ripple.color = color
	ripple.position = position - Vector2(size * 0.5, size * 0.5)
	parent.add_child(ripple)
	
	var tween := ripple.create_tween()
	tween.set_parallel(true)
	tween.tween_property(ripple, "scale", Vector2(3.0, 3.0), duration)
	tween.tween_property(ripple, "modulate:a", 0.0, duration)
	tween.tween_callback(ripple.queue_free).set_delay(duration)

static func create_animated_background_gradient(parent: Control, colors: Array, duration: float = 8.0) -> ColorRect:
	return create_animated_gradient(parent, colors, duration)

static func create_abstract_art_background(parent: Control, num_shapes: int = 5) -> Control:
	return create_geometric_pattern(parent, num_shapes)

static func create_fluid_animation(parent: Control, num_elements: int = 10) -> Control:
	return create_flowing_particles(parent, num_elements)
