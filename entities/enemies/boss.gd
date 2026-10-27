extends Enemy
## BOSS: Wódz - pojawia się co 5 fal i w ostatniej fali.

const HORN_COLOR := Color(0.9, 0.85, 0.7)


func _draw_body(tint: Color) -> void:
	draw_circle(Vector2.ZERO, radius, Color(0.75, 0.15, 0.15) * tint)
	# rogi
	draw_colored_polygon(PackedVector2Array([Vector2(-16, -14), Vector2(-24, -34), Vector2(-8, -20)]), HORN_COLOR)
	draw_colored_polygon(PackedVector2Array([Vector2(16, -14), Vector2(24, -34), Vector2(8, -20)]), HORN_COLOR)
