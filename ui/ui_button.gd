class_name UiButton
extends RefCounted
## Prosty przycisk rysowany kodem: prostokąt, napis i akcja wykonywana po kliknięciu.

var rect: Rect2
## identyfikator akcji, np. "build", "upgrade", "continue"
var action := ""
var label := ""
var sub := ""
## klucz ikony (TowerIcons); gdy ustawiony, zamiast napisu rysujemy ikonę
var icon := ""
var enabled := true
var color := UiDraw.BUTTON_GREEN
## dodatkowe dane akcji (np. typ wieży, id gałęzi, numer poziomu)
var tower_type := ""
var branch_id := ""
var description := ""
var level := -1


func _init(r: Rect2, button_action: String, text: String, button_color := UiDraw.BUTTON_GREEN,
		sub_text := "", is_enabled := true) -> void:
	rect = r
	action = button_action
	label = text
	color = button_color
	sub = sub_text
	enabled = is_enabled


func contains(p: Vector2) -> bool:
	return rect.has_point(p)


func draw(canvas: CanvasItem) -> void:
	if icon != "":
		UiDraw.icon_button(canvas, rect, icon, color, enabled, sub)
	else:
		UiDraw.button(canvas, rect, label, color, enabled, sub)


## Pierwszy przycisk z listy pod punktem p albo null.
static func find_at(buttons: Array, p: Vector2) -> UiButton:
	for b in buttons:
		if b.contains(p):
			return b
	return null
