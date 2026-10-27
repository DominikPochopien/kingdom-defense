extends Node2D
## Rysowane nad jednostkami: obwódka wybranego wroga, podgląd celowania umiejętnością
## i punkt zbiórki (wybranej wieży z żołnierzami albo wskazywany właśnie przez gracza).

const REINF_MARKER_RADIUS := 24.0

@onready var _world: GameWorld = get_parent()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var enemy := _world.selected_enemy
	if Enemy.is_alive(enemy):
		draw_arc(enemy.body_position(), enemy.radius + 8.0, 0, TAU, 24, Color(1, 1, 0.3), 2.0)
	var mouse := get_global_mouse_position()
	_draw_rally(mouse)
	match _world.abilities.targeting:
		Abilities.Kind.FIRE:
			draw_circle(mouse, Balance.FIRE_SPREAD, Color(1, 0.3, 0.1, 0.2))
			draw_arc(mouse, Balance.FIRE_SPREAD, 0, TAU, 48, Color(1, 0.4, 0.1), 2.0)
		Abilities.Kind.REINFORCEMENTS:
			var c := _world.paths.nearest_point(mouse)
			draw_circle(c, REINF_MARKER_RADIUS, Color(0.3, 0.7, 1, 0.3))
			draw_arc(c, REINF_MARKER_RADIUS, 0, TAU, 24, Color(0.4, 0.8, 1), 2.0)


func _draw_rally(mouse: Vector2) -> void:
	if _world.abilities.is_targeting():
		return
	if _world.is_placing_rally():
		var tower := _world.rally_tower
		draw_circle(tower.position, tower.rally_range(), Color(1, 0.85, 0.3, 0.1))
		draw_arc(tower.position, tower.rally_range(), 0, TAU, 64, Color(1, 0.85, 0.3, 0.8), 2.0)
		var point := _world.rally_point_for(mouse)
		var ok := tower.can_rally_to(point)
		var col := Color(0.4, 1, 0.4) if ok else Color(1, 0.3, 0.3)
		draw_line(tower.position, point, Color(col, 0.5), 2.0)
		draw_arc(point, SoldierTower.FORMATION_RADIUS + 6.0, 0, TAU, 24, col, 2.0)
		UiDraw.rally_flag(self, point, 1.0, col)
		return
	var spot := _world.selected_spot
	if spot != null and spot.tower is SoldierTower:
		var tower := spot.tower as SoldierTower
		draw_arc(tower.rally, SoldierTower.FORMATION_RADIUS + 6.0, 0, TAU, 24, Color(1, 0.85, 0.3, 0.7), 1.5)
		UiDraw.rally_flag(self, tower.rally)
