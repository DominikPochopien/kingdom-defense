extends SoldierTower
## Wieża Rycerska - darmowa wieża poziomu (pole "special_tower"). Nie można jej sprzedać.
## Rycerze z włóczniami biją też latających wrogów; każdy poziom dodaje rycerza.


func _draw_body() -> void:
	draw_circle(Vector2(0, 4), 24.0, Color(1, 0.5, 0.1))
	draw_arc(Vector2(0, 4), 24.0, 0, TAU, 32, Color(1, 0.9, 0.2), 3.0)
	draw_rect(Rect2(-16, -10, 32, 28), Color(0.7, 0.7, 0.75))
	draw_rect(Rect2(-16, -10, 32, 28), Color(0.4, 0.4, 0.45), false, 2.0)
	draw_line(Vector2(0, -10), Vector2(0, -34), Color(0.9, 0.9, 0.9), 3.0)
	draw_circle(Vector2(0, -36), 6.0, Color(1, 0.8, 0.2))
