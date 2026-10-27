extends Enemy
## Nietoperz - latający: unosi się nad drogą i omija blokadę żołnierzy.

const HOVER_HEIGHT := 22.0
const WING_COLOR := Color(0.35, 0.2, 0.45)


func _body_offset() -> Vector2:
	return Vector2(0, -HOVER_HEIGHT)


## Pozycja ciała z lekkim bujaniem w locie.
func _flight_pos() -> Vector2:
	return Vector2(0, -HOVER_HEIGHT + sin(anim * 8.0) * 3.0)


func _draw_body(tint: Color) -> void:
	var p := _flight_pos()
	var wing := sin(anim * 18.0) * 6.0
	draw_colored_polygon(PackedVector2Array([p, p + Vector2(-20, -8 + wing), p + Vector2(-12, 6)]), WING_COLOR * tint)
	draw_colored_polygon(PackedVector2Array([p, p + Vector2(20, -8 + wing), p + Vector2(12, 6)]), WING_COLOR * tint)
	draw_circle(p, 8.0, Color(0.45, 0.25, 0.55) * tint)


func _draw_face() -> void:
	var p := _flight_pos()
	draw_circle(p + Vector2(-3, -2), 1.8, Color(1, 0.3, 0.3))
	draw_circle(p + Vector2(3, -2), 1.8, Color(1, 0.3, 0.3))


func _draw_health_bar() -> void:
	UiDraw.health_bar(self, _flight_pos() + Vector2(0, -18), hp / max_hp, 24.0, HEALTH_BAR_COLOR)
