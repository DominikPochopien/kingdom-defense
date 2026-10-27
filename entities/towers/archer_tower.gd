extends ShooterTower
## Łucznicy - szybkie strzały, trafiają też latających.


func _draw_body() -> void:
	draw_rect(Rect2(-16, -8, 32, 28), Color(0.55, 0.4, 0.25))
	draw_rect(Rect2(-16, -8, 32, 28), Color(0.3, 0.2, 0.1), false, 2.0)
	draw_colored_polygon(PackedVector2Array([Vector2(-23, -8), Vector2(23, -8), Vector2(0, -36)]), Color(0.2, 0.6, 0.3))
	draw_circle(Vector2(0, 2), 5.0, Color(0.15, 0.1, 0.05))
