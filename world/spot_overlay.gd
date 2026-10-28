extends Node2D
## Rysowane pod wieżami: obwódka wybranego miejsca i podgląd zasięgu
## (wybranej wieży, wieży pod kursorem albo wieży wskazanej w menu budowy).

@onready var _world: GameWorld = get_parent()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var spot := _world.selected_spot
	if spot != null:
		draw_arc(spot.position, 30.0, 0, TAU, 32, Color(1, 1, 0.3), 3.0)
	var preview := _range_preview()
	if not preview.is_empty():
		draw_circle(preview.pos, preview.r, Color(1, 1, 1, 0.12))
		draw_arc(preview.pos, preview.r, 0, TAU, 64, Color(1, 1, 1, 0.7), 2.0)


## {pos, r} albo pusty słownik, gdy nie ma czego pokazać.
func _range_preview() -> Dictionary:
	var mouse := get_global_mouse_position()
	var spot := _world.selected_spot
	if spot != null:
		if not spot.is_empty():
			return {"pos": spot.aim_center, "r": spot.tower.stats.attack_range()}
		var hovered := _world.build_menu.hovered_button()
		if hovered != null and hovered.tower_type != "":
			return {"pos": spot.aim_center, "r": TowerStats.new(hovered.tower_type).attack_range()}
		return {}
	for s in _world.spots:
		if not s.is_empty() and s.contains(mouse, BuildSpot.HOVER_RADIUS):
			return {"pos": s.aim_center, "r": s.tower.stats.attack_range()}
	return {}
