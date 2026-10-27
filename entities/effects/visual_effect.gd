class_name VisualEffect
extends Effect
## Animacja bez wpływu na grę: "boom" (wybuch), "death" (śmierć wroga), "heal" (rytuał szamana),
## "zap" (błyskawica między dwoma punktami), "ring" (budowa/ulepszenie).

var kind := ""
var radius := 0.0
var duration := 0.4
## punkt końcowy błyskawicy (współrzędne świata)
var target_pos := Vector2.ZERO

var _t := 0.0


func setup(at: Vector2, effect_kind: String, effect_radius: float, to: Vector2, effect_duration: float) -> void:
	position = at
	kind = effect_kind
	radius = effect_radius
	target_pos = to
	duration = effect_duration


func tick(dt: float) -> void:
	_t += dt
	if _t >= duration:
		done = true


func _draw() -> void:
	var k := _t / duration
	match kind:
		"boom":
			draw_circle(Vector2.ZERO, radius * (0.4 + 0.6 * k), Color(1, 0.55, 0.1, 0.6 * (1.0 - k)))
			draw_arc(Vector2.ZERO, radius * k, 0, TAU, 32, Color(1, 0.9, 0.4, 1.0 - k), 3.0)
		"death":
			draw_circle(Vector2.ZERO, radius * k, Color(0.9, 0.9, 0.9, 0.5 * (1.0 - k)))
		"heal":
			draw_arc(Vector2.ZERO, radius * k, 0, TAU, 40, Color(0.4, 1, 0.5, 1.0 - k), 4.0)
			draw_circle(Vector2.ZERO, radius * k, Color(0.3, 1, 0.4, 0.15 * (1.0 - k)))
		"zap":
			var to := target_pos - position
			var mid := to / 2.0 + Vector2(randf_range(-8, 8), randf_range(-8, 8))
			draw_line(Vector2.ZERO, mid, Color(0.85, 0.95, 1.0), 3.0)
			draw_line(mid, to, Color(0.85, 0.95, 1.0), 3.0)
		"ring":
			draw_arc(Vector2.ZERO, radius * (0.3 + k), 0, TAU, 32, Color(0.4, 0.8, 1, 1.0 - k), 3.0)
