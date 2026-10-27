class_name FloatingText
extends Effect
## Napis unoszący się w górę i znikający po sekundzie (obrażenia, złoto, komunikaty).

const LIFETIME := 1.0
const RISE_SPEED := 28.0
const FONT_SIZE := 15

var text := ""
var color := Color.WHITE

var _t := 0.0


func setup(at: Vector2, message: String, text_color: Color) -> void:
	position = at
	text = message
	color = text_color


func tick(dt: float) -> void:
	_t += dt
	position.y -= RISE_SPEED * dt
	if _t >= LIFETIME:
		done = true


func _draw() -> void:
	var col := color
	col.a = 1.0 - _t
	UiDraw.text(self, Vector2.ZERO, text, FONT_SIZE, col)
