extends ShooterTower
## Artyleria - powolne kule wybuchające obszarowo, tylko w cele naziemne.


func _draw_body() -> void:
	draw_circle(Vector2(0, 4), 22.0, Color(0.45, 0.45, 0.5))
	draw_circle(Vector2(0, 4), 22.0, Color(0.2, 0.2, 0.25), false, 2.0)
	draw_line(Vector2(0, 2), Vector2(18, -16), Color(0.15, 0.15, 0.18), 11.0)
	draw_circle(Vector2(0, 2), 9.0, Color(0.3, 0.3, 0.35))
