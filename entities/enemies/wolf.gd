extends Enemy
## Wilk - szybki i kruchy.


func _draw_body(tint: Color) -> void:
	draw_circle(Vector2.ZERO, radius, Color(0.55, 0.55, 0.6) * tint)
	# pysk i ucho
	draw_circle(Vector2(-10, 0), 7.0, Color(0.5, 0.5, 0.55) * tint)
	draw_colored_polygon(PackedVector2Array([Vector2(-12, -6), Vector2(-9, -15), Vector2(-5, -6)]), Color(0.45, 0.45, 0.5) * tint)
