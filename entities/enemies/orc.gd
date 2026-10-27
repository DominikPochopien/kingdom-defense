extends Enemy
## Ork pancerny - wolny, odporny na obrażenia fizyczne.


func _draw_body(tint: Color) -> void:
	draw_circle(Vector2.ZERO, radius, Color(0.2, 0.5, 0.2) * tint)
	# hełm
	draw_arc(Vector2.ZERO, radius - 2, PI, TAU, 16, Color(0.6, 0.6, 0.65), 5.0)
