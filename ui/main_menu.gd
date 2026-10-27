class_name MainMenu
extends Node2D
## Ekran tytułowy (rysowany na tle mapy pierwszego poziomu).

signal play_pressed

const W := GameConfig.W
const R_PLAY := Rect2(W / 2.0 - 130, 400, 260, 64)


func handle_click(p: Vector2) -> void:
	if R_PLAY.has_point(p):
		play_pressed.emit()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(0, 0, W, GameConfig.H), Color(0, 0, 0, 0.6))
	UiDraw.text(self, Vector2(0, 230), "KINGDOM DEFENSE", 72, Color(1, 0.88, 0.3), HORIZONTAL_ALIGNMENT_CENTER, W)
	UiDraw.text(self, Vector2(0, 290), "Obroń królestwo przed hordami potworów!", 24, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, W)
	UiDraw.text(self, Vector2(0, 335), "Klikaj kamienne podstawy, aby budować wieże. Najedź na wroga lub wieżę, aby zobaczyć statystyki. Spacja = następna fala, P = pauza.",
		16, Color(0.9, 0.9, 0.9), HORIZONTAL_ALIGNMENT_CENTER, W)
	UiDraw.button(self, R_PLAY, "GRAJ", Color(0.2, 0.6, 0.25))
