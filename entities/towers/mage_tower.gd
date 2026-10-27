extends ShooterTower
## Magowie - wolne, mocne pociski magiczne (ignorują pancerz, liczy się odporność na magię).


func _draw_body() -> void:
	draw_rect(Rect2(-13, -22, 26, 42), Color(0.45, 0.3, 0.65))
	draw_rect(Rect2(-13, -22, 26, 42), Color(0.25, 0.15, 0.4), false, 2.0)
	draw_colored_polygon(PackedVector2Array([Vector2(-17, -22), Vector2(17, -22), Vector2(0, -46)]), Color(0.3, 0.2, 0.6))
	draw_circle(Vector2(0, -50), 6.0, Color(0.5, 0.9, 1.0))
