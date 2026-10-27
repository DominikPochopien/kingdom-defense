class_name LevelSelect
extends Node2D
## Ekran wyboru poziomu: stała siatka 3x2 kart, przy większej liczbie poziomów - strony.

signal back_pressed
signal new_game_requested(level: int)
signal continue_requested(level: int)

const W := GameConfig.W
const H := GameConfig.H
const SLOTS := 6
const COLUMNS := 3
const R_BACK := Rect2(20, H - 70, 160, 50)
const R_PREV := Rect2(W / 2.0 - 150, H - 70, 120, 50)
const R_NEXT := Rect2(W / 2.0 + 30, H - 70, 120, 50)
const CARD_LOCKED_HINT := "Ukończ poprzedni poziom, aby odblokować"

var save: SaveManager
var page := 0


## Otwiera ekran na stronie z podanym poziomem.
func open_at(level: int) -> void:
	page = clampi(floori(level / float(SLOTS)), 0, page_count() - 1)


func page_count() -> int:
	return maxi(1, ceili(float(LevelData.count()) / SLOTS))


## Numer poziomu w slocie (0-5) bieżącej strony albo -1, gdy slot jest pusty.
func _slot_level(slot: int) -> int:
	var i := page * SLOTS + slot
	return i if i < LevelData.count() else -1


func _slot_rect(slot: int) -> Rect2:
	var col := slot % COLUMNS
	var row := floori(slot / float(COLUMNS))
	return Rect2(35 + col * 410, 112 + row * 268, 390, 252)


func _card_buttons(level: int, r: Rect2) -> Array[UiButton]:
	var res: Array[UiButton] = []
	if not save.is_unlocked(level):
		return res
	var y := r.position.y + r.size.y - 54.0
	var continue_color := Color(0.2, 0.4, 0.7)
	if save.has_run(level):
		res.append(UiButton.new(Rect2(r.position.x + 12, y, 178, 44), "new", "Nowa gra"))
		res.append(UiButton.new(Rect2(r.position.x + 200, y, 178, 44), "continue",
			"Kontynuuj (fala %d)" % (save.run_waves[level] + 1), continue_color))
	else:
		res.append(UiButton.new(Rect2(r.position.x + 12, y, 366, 44), "new", "Graj"))
	for b in res:
		b.level = level
	return res


func _all_buttons() -> Array[UiButton]:
	var res: Array[UiButton] = []
	for slot in SLOTS:
		var level := _slot_level(slot)
		if level >= 0:
			res.append_array(_card_buttons(level, _slot_rect(slot)))
	return res


func handle_click(p: Vector2) -> void:
	if R_BACK.has_point(p):
		back_pressed.emit()
		return
	if page_count() > 1:
		if R_PREV.has_point(p) and page > 0:
			page -= 1
			return
		if R_NEXT.has_point(p) and page < page_count() - 1:
			page += 1
			return
	var b := UiButton.find_at(_all_buttons(), p)
	if b == null:
		return
	if b.action == "continue":
		continue_requested.emit(b.level)
	else:
		new_game_requested.emit(b.level)


# ---------------- rysowanie ----------------
func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(0, 0, W, H), Color(0.1, 0.12, 0.16))
	for i in 12:
		draw_rect(Rect2(0, i * 60, W, 30), Color(0.12, 0.14, 0.19))
	UiDraw.text(self, Vector2(0, 80), "WYBIERZ POZIOM", 50, Color(1, 0.88, 0.3), HORIZONTAL_ALIGNMENT_CENTER, W)
	for slot in SLOTS:
		var level := _slot_level(slot)
		if level < 0:
			_draw_empty_slot(_slot_rect(slot))
		else:
			_draw_card(level, _slot_rect(slot))
	UiDraw.button(self, R_BACK, "Wstecz", UiDraw.BUTTON_GRAY)
	if page_count() > 1:
		UiDraw.button(self, R_PREV, "< Poprz.", UiDraw.BUTTON_GRAY, page > 0)
		UiDraw.button(self, R_NEXT, "Nast. >", UiDraw.BUTTON_GRAY, page < page_count() - 1)
		UiDraw.text(self, Vector2(0, H - 38), "Strona %d / %d" % [page + 1, page_count()], 16,
			Color(0.85, 0.85, 0.9), HORIZONTAL_ALIGNMENT_CENTER, W)


func _draw_empty_slot(r: Rect2) -> void:
	draw_rect(r, Color(0.14, 0.16, 0.2))
	draw_rect(r, Color(0.35, 0.37, 0.42), false, 2.0)
	UiDraw.text(self, Vector2(r.position.x, r.position.y + r.size.y / 2.0 - 6.0), "?", 54,
		Color(0.35, 0.37, 0.42), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	UiDraw.text(self, Vector2(r.position.x, r.position.y + r.size.y / 2.0 + 28.0), "Wkrótce", 18,
		Color(0.5, 0.52, 0.58), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)


func _draw_card(i: int, r: Rect2) -> void:
	var level := LevelData.get_level(i)
	var locked := not save.is_unlocked(i)
	var hovered := r.has_point(get_global_mouse_position()) and not locked
	draw_rect(r, Color(0.26, 0.3, 0.38) if hovered else Color(0.2, 0.22, 0.28))
	draw_rect(r, Color(1, 0.88, 0.3) if hovered else Color(0.6, 0.6, 0.65), false, 3.0)
	var preview := Rect2(r.position + Vector2(12, 12), Vector2(176, 99))
	_draw_minimap(level, preview)
	if locked:
		draw_rect(preview, Color(0, 0, 0, 0.7))
		UiDraw.text(self, Vector2(preview.position.x, preview.position.y + 56), "ZABLOKOWANY", 16,
			Color(1, 1, 1, 0.9), HORIZONTAL_ALIGNMENT_CENTER, preview.size.x)
	_draw_card_details(i, level, r)
	if locked:
		UiDraw.text(self, Vector2(r.position.x, r.position.y + r.size.y - 30), CARD_LOCKED_HINT, 14,
			Color(1, 0.7, 0.4), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	for b in _card_buttons(i, r):
		b.draw(self)


## Miniatura mapy (16:9): rzeka, drogi i miejsca budowy.
func _draw_minimap(level: Dictionary, pr: Rect2) -> void:
	var sc := pr.size.x / W
	draw_rect(pr, LevelMap.GRASS)
	if level.has("river"):
		var river := PackedVector2Array()
		for q in level.river:
			river.append(pr.position + _clamp_to_map(q) * sc)
		draw_colored_polygon(river, LevelMap.RIVER_COLOR)
	for route in LevelData.routes_of(level):
		var pts := PackedVector2Array()
		for p in route:
			pts.append(pr.position + _clamp_to_map(p) * sc)
		draw_polyline(pts, LevelMap.ROAD, 6.0)
	for sp in level.spots:
		draw_circle(pr.position + sp * sc, 2.5, Color(0.6, 0.6, 0.65))


static func _clamp_to_map(p: Vector2) -> Vector2:
	return Vector2(clampf(p.x, 0.0, float(W)), clampf(p.y, 0.0, float(H)))


func _draw_card_details(i: int, level: Dictionary, r: Rect2) -> void:
	var x0 := r.position.x + 200.0
	var y0 := r.position.y
	UiDraw.text(self, Vector2(x0, y0 + 34), "%d. %s" % [i + 1, level.name], 20, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, 180.0)
	var difficulty_color := Color(0.5, 0.9, 0.5) if level.difficulty == "Łatwy" else Color(1, 0.5, 0.4)
	UiDraw.text(self, Vector2(x0, y0 + 58), level.difficulty, 15, difficulty_color)
	UiDraw.text(self, Vector2(x0, y0 + 80), "Fale: %d   Życia: %d" % [level.waves, level.lives], 14, Color(0.9, 0.9, 0.9))
	UiDraw.text(self, Vector2(x0, y0 + 100), "Złoto: %d" % level.gold, 14, Color(1, 0.88, 0.3))
	if save.is_completed(i):
		UiDraw.text(self, Vector2(x0 + 90.0, y0 + 100), "✔ Ukończono", 14, Color(0.5, 1, 0.5))
	# opis (najwyżej 4 linie)
	var lines := UiDraw.wrap_text(level.desc, 58)
	for k in mini(lines.size(), 4):
		var line := lines[k]
		if k == 3 and lines.size() > 4:
			line += "…"
		UiDraw.text(self, Vector2(r.position.x + 14, y0 + 132 + k * 17), line, 13, Color(0.8, 0.85, 0.9))
