extends Node2D
## Rysowane nad jednostkami: obwódka wybranego wroga i podgląd celowania umiejętnością.

const REINF_MARKER_RADIUS := 24.0

@onready var _world: GameWorld = get_parent()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var enemy := _world.selected_enemy
	if Enemy.is_alive(enemy):
		draw_arc(enemy.body_position(), enemy.radius + 8.0, 0, TAU, 24, Color(1, 1, 0.3), 2.0)
	var mouse := get_global_mouse_position()
	match _world.abilities.targeting:
		Abilities.Kind.FIRE:
			draw_circle(mouse, Balance.FIRE_SPREAD, Color(1, 0.3, 0.1, 0.2))
			draw_arc(mouse, Balance.FIRE_SPREAD, 0, TAU, 48, Color(1, 0.4, 0.1), 2.0)
		Abilities.Kind.REINFORCEMENTS:
			var c := _world.paths.nearest_point(mouse)
			draw_circle(c, REINF_MARKER_RADIUS, Color(0.3, 0.7, 1, 0.3))
			draw_arc(c, REINF_MARKER_RADIUS, 0, TAU, 24, Color(0.4, 0.8, 1), 2.0)
