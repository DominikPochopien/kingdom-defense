extends Enemy
## Goblin - słaby, podstawowy wróg.

const SKIN := Color(0.35, 0.7, 0.25)


func _draw_body(tint: Color) -> void:
	draw_circle(Vector2.ZERO, radius, SKIN * tint)
	# uszy
	draw_colored_polygon(PackedVector2Array([Vector2(-9, -6), Vector2(-18, -12), Vector2(-8, -12)]), SKIN * tint)
	draw_colored_polygon(PackedVector2Array([Vector2(9, -6), Vector2(18, -12), Vector2(8, -12)]), SKIN * tint)
