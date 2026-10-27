class_name FireStrike
extends Effect
## Pojedyncze uderzenie Deszczu ognia: kula spada przez `delay` sekund, potem wybucha.

const FALL_SPEED := 400.0

var delay := 0.0


func setup(at: Vector2, fall_delay: float) -> void:
	position = at
	delay = fall_delay


func tick(dt: float) -> void:
	delay -= dt
	if delay <= 0:
		done = true
		world.explode(position, Balance.FIRE_RADIUS, Balance.FIRE_DAMAGE, true, false)


func _draw() -> void:
	draw_arc(Vector2.ZERO, Balance.FIRE_RADIUS, 0, TAU, 32, Color(1, 0.4, 0.1, 0.5), 2.0)
	draw_circle(Vector2(0, -maxf(0.0, delay) * FALL_SPEED), 9.0, Color(1, 0.6, 0.1))
