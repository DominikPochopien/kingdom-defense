extends SoldierTower
## Koszary - wystawiają żołnierzy, którzy blokują naziemnych wrogów.


func _draw_body() -> void:
	draw_rect(Rect2(-22, -10, 44, 30), Color(0.7, 0.3, 0.25))
	draw_rect(Rect2(-22, -10, 44, 30), Color(0.4, 0.15, 0.1), false, 2.0)
	draw_rect(Rect2(-6, 2, 12, 18), Color(0.2, 0.1, 0.05))
	# maszt z flagą
	draw_line(Vector2(0, -10), Vector2(0, -34), Color(0.3, 0.2, 0.1), 3.0)
	draw_colored_polygon(PackedVector2Array([Vector2(0, -34), Vector2(16, -28), Vector2(0, -22)]), Color(0.9, 0.8, 0.2))
