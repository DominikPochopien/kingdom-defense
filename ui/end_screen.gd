class_name EndScreen
extends Node2D
## Ekran zwycięstwa / porażki z przyciskami: następny poziom, jeszcze raz, wybór poziomu.

signal next_level_pressed
signal retry_pressed
signal levels_pressed

const W := GameConfig.W
const H := GameConfig.H

var won := false
var has_next_level := false
## życia (po wygranej) albo osiągnięta fala (po przegranej)
var lives := 0
var wave := 0


func show_result(is_win: bool, next_available: bool, lives_left: int, reached_wave: int) -> void:
	won = is_win
	has_next_level = next_available
	lives = lives_left
	wave = reached_wave


func _buttons() -> Array[UiButton]:
	var res: Array[UiButton] = []
	var y := H / 2.0 + 30.0
	if won and has_next_level:
		res.append(UiButton.new(Rect2(W / 2.0 - 130, y, 260, 56), "next", "Następny poziom"))
		y += 70.0
	res.append(UiButton.new(Rect2(W / 2.0 - 130, y, 260, 56), "again", "Zagraj ponownie"))
	y += 70.0
	res.append(UiButton.new(Rect2(W / 2.0 - 130, y, 260, 56), "levels", "Wybór poziomu"))
	return res


func handle_click(p: Vector2) -> void:
	var b := UiButton.find_at(_buttons(), p)
	if b == null:
		return
	match b.action:
		"next":
			next_level_pressed.emit()
		"again":
			retry_pressed.emit()
		"levels":
			levels_pressed.emit()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(0, 0, W, H), Color(0, 0, 0, 0.65))
	if won:
		UiDraw.text(self, Vector2(0, 250), "ZWYCIĘSTWO!", 72, Color(1, 0.88, 0.3), HORIZONTAL_ALIGNMENT_CENTER, W)
		UiDraw.text(self, Vector2(0, 310), "Królestwo uratowane. Pozostało żyć: %d" % lives, 24, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, W)
	else:
		UiDraw.text(self, Vector2(0, 250), "PORAŻKA", 72, Color(0.95, 0.3, 0.3), HORIZONTAL_ALIGNMENT_CENTER, W)
		UiDraw.text(self, Vector2(0, 310), "Doszedłeś do fali %d. Spróbuj jeszcze raz!" % wave, 24, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, W)
	for b in _buttons():
		b.draw(self)
