extends Node
class_name VisualEffects

# Fluid animation and abstract art generator for professional UI enhancement

signal animation_completed(anim_name: String)

# Abstract art patterns
static func create_animated_gradient(parent: Control, colors: Array, duration: float = 8.0) -> ColorRect:
	var gradient := ColorRect.new()
	gradient.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gradient.anchor_right = 1.0
	gradient.anchor_bottom = 1.0
	parent.add_child(gradient)
	parent.move_child(gradient, 0)  # Move to back
	
	var tween := gradient.create_tween()
	tween.set_loops()
	tween.set_parallel(true)
	
	for i in range(colors.size()):
		var next_color: Color = colors[(i + 1) % colors.size()]
		tween.tween_property(gradient, "color", next_color, duration / colors.size())
	
	return gradient

static func create_flowing_particles(parent: Control, count: int = 12) -> Control:
	var particles := Control.new()
	particles.name = "FlowingParticles"
	particles.mouse_filter = Control.MOUSE_FILTER_IGNORE
	particles.anchor_right = 1.0
	particles.anchor_bottom = 1.0
	parent.add_child(particles)
	parent.move_child(particles, 0)
	
	for i in count:
		var particle := ColorRect.new()
		particle.size = Vector2(3, 80 + randf() * 120)
		particle.color = Color(0.2, 0.5, 0.8, 0.15 + randf() * 0.1)
		particle.position = Vector2(randf() * parent.size.x, -100 - randf() * 200)
		particles.add_child(particle)
		
		var tween := particle.create_tween()
		tween.set_loops()
		tween.set_parallel(false)
		var start_x := particle.position.x
		var drift := (randf() - 0.5) * 200
		var speed := 8.0 + randf() * 4.0
		
		tween.tween_property(particle, "position:y", parent.size.y + 200, speed)
		tween.tween_callback(func(): particle.position.y = -200)
		tween.tween_property(particle, "position:x", start_x + drift, speed * 0.5)
		tween.tween_property(particle, "position:x", start_x, speed * 0.5)
	
	return particles

static func create_orb_animation(parent: Control, radius: float = 150.0) -> Control:
	var orb := Control.new()
	orb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	orb.custom_minimum_size = Vector2(radius * 2, radius * 2)
	parent.add_child(orb)
	
	var circle := ColorRect.new()
	circle.size = Vector2(radius * 2, radius * 2)
	circle.color = Color(0.3, 0.6, 0.9, 0.08)
	circle.position = Vector2(-radius, -radius)
	orb.add_child(circle)
	
	var tween := orb.create_tween()
	tween.set_loops()
	tween.set_parallel(true)
	
	# Floating movement
	var center := parent.size / 2.0
	var offset := Vector2(randf_range(-200, 200), randf_range(-200, 200))
	tween.tween_property(orb, "position", center + offset, 12.0)
	tween.tween_property(orb, "position", center - offset, 12.0)
	
	# Pulsing scale
	tween.tween_property(circle, "scale", Vector2(1.3, 1.3), 4.0)
	tween.tween_property(circle, "scale", Vector2(1.0, 1.0), 4.0)
	
	return orb

static func create_geometric_pattern(parent: Control) -> Control:
	var pattern := Control.new()
	pattern.name = "GeometricPattern"
	pattern.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(pattern)
	parent.move_child(pattern, 0)
	
	var lines := []
	for i in range(8):
		var line := ColorRect.new()
		line.custom_minimum_size = Vector2(2, 0)
		line.color = Color(0.4, 0.7, 1.0, 0.06)
		line.anchor_right = 1.0
		line.anchor_bottom = 1.0
		pattern.add_child(line)
		lines.append(line)
		
		var tween := line.create_tween()
		tween.set_loops()
		var angle := (i / 8.0) * TAU
		var distance := 800.0
		var start_pos := Vector2(cos(angle), sin(angle)) * distance
		var end_pos := Vector2(cos(angle + PI), sin(angle + PI)) * distance
		
		tween.tween_property(line, "position", start_pos, 0.0)
		tween.tween_property(line, "position", end_pos, 20.0)
		tween.tween_property(line, "position", start_pos, 0.0)
	
	return pattern

static func smooth_fade_in(node: CanvasItem, duration: float = 0.6) -> Tween:
	if not node:
		return null
	node.modulate.a = 0.0
	var tween := node.create_tween()
	tween.tween_property(node, "modulate:a", 1.0, duration)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	return tween

static func smooth_slide_in(node: Control, from_offset: Vector2, duration: float = 0.5) -> Tween:
	if not node:
		return null
	var final_pos := node.position
	node.position = final_pos + from_offset
	node.modulate.a = 0.0
	var tween := node.create_tween()
	tween.set_parallel(true)
	tween.tween_property(node, "position", final_pos, duration)
	tween.tween_property(node, "modulate:a", 1.0, duration)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	return tween

static func create_glow_effect(node: Control, color: Color = Color(0.4, 0.7, 1.0, 0.3)) -> void:
	var glow := ColorRect.new()
	glow.name = "GlowEffect"
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.color = color
	glow.anchor_left = -0.1
	glow.anchor_top = -0.1
	glow.anchor_right = 1.1
	glow.anchor_bottom = 1.1
	node.add_child(glow)
	node.move_child(glow, 0)
	
	var tween := glow.create_tween()
	tween.set_loops()
	tween.tween_property(glow, "modulate:a", color.a * 0.5, 2.0)
	tween.tween_property(glow, "modulate:a", color.a, 2.0)

static func animate_progress_bar(bar: ProgressBar, target_value: float, duration: float = 1.0) -> Tween:
	if not bar:
		return null
	var tween := bar.create_tween()
	tween.tween_property(bar, "value", target_value, duration)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	return tween

static func create_ripple_effect(parent: Control, center: Vector2, color: Color = Color(0.5, 0.8, 1.0, 0.4)) -> void:
	var ripple := ColorRect.new()
	ripple.position = center - Vector2(10, 10)
	ripple.size = Vector2(20, 20)
	ripple.color = color
	parent.add_child(ripple)
	
	var tween := ripple.create_tween()
	tween.set_parallel(true)
	tween.tween_property(ripple, "size", Vector2(200, 200), 0.8)
	tween.tween_property(ripple, "position", center - Vector2(100, 100), 0.8)
	tween.tween_property(ripple, "modulate:a", 0.0, 0.8)
	tween.tween_callback(ripple.queue_free)
