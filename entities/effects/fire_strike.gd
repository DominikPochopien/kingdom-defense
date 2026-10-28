class_name FireStrike
extends Effect
## Pojedyncze uderzenie Deszczu ognia: meteor spada przez `delay` sekund, potem wybucha.
## Grafika: assets/effects/fire_rain.png (klatki: meteor wysoko, meteor nisko, uderzenie, ogień).

const FALL_SPEED := 400.0
const FIRE_RAIN := preload("res://assets/effects/fire_rain.png")
const FRAME := Vector2(24, 32)
## poniżej tej wysokości meteor pokazuje się w klatce "nisko"
const LOW_HEIGHT := 60.0

var delay := 0.0


func setup(at: Vector2, fall_delay: float) -> void:
	position = at
	delay = fall_delay


func tick(dt: float) -> void:
	delay -= dt
	if delay <= 0:
		done = true
		world.explode(position, Balance.FIRE_RADIUS, Balance.FIRE_DAMAGE, true, false)


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _draw() -> void:
	draw_arc(Vector2.ZERO, Balance.FIRE_RADIUS, 0, TAU, 32, Color(1, 0.4, 0.1, 0.5), 2.0)
	# meteor spada pionowo; dolna krawędź klatki to jego czubek
	var height := maxf(0.0, delay) * FALL_SPEED
	var index := 0 if height > LOW_HEIGHT else 1
	var size := FRAME * LevelScene.PIXEL
	draw_texture_rect_region(FIRE_RAIN, Rect2(Vector2(-size.x / 2.0, -height - size.y), size),
		Rect2(Vector2(index * FRAME.x, 0), FRAME))
