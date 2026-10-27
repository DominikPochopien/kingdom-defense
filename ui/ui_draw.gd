class_name UiDraw
## Wspólne funkcje rysowania interfejsu (tekst, przyciski, panele, paski HP).
## Każda przyjmuje węzeł `canvas`, na którym rysuje (wywoływać z jego _draw()).

const BUTTON_GRAY := Color(0.35, 0.35, 0.4)
const BUTTON_GREEN := Color(0.2, 0.55, 0.25)
const TEXT_LIGHT := Color(0.92, 0.92, 0.95)
const PANEL_WIDTH := 250.0
const PANEL_WRAP := 34


static func font() -> Font:
	return ThemeDB.fallback_font


static func text(canvas: CanvasItem, pos: Vector2, s: String, size := 16, color := Color.WHITE,
		align := HORIZONTAL_ALIGNMENT_LEFT, width := -1.0) -> void:
	canvas.draw_string(font(), pos, s, align, width, size, color)


## Tekst wyśrodkowany w prostokącie.
static func text_in_rect(canvas: CanvasItem, r: Rect2, s: String, size: int, color: Color) -> void:
	canvas.draw_string(font(), Vector2(r.position.x, r.position.y + r.size.y / 2.0 + size * 0.35), s,
		HORIZONTAL_ALIGNMENT_CENTER, r.size.x, size, color)


## Przycisk z napisem i opcjonalnym podpisem (np. ceną); podświetla się pod kursorem.
static func button(canvas: CanvasItem, r: Rect2, label: String, color: Color, enabled := true, sub := "",
		hover := true) -> void:
	var c := color if enabled else Color(0.3, 0.3, 0.3)
	if enabled and hover and r.has_point(canvas.get_global_mouse_position()):
		c = c.lightened(0.2)
	canvas.draw_rect(r, Color(0, 0, 0, 0.5), true)
	canvas.draw_rect(r.grow(-2), c, true)
	canvas.draw_rect(r, Color(1, 1, 1, 0.8), false, 2.0)
	if sub == "":
		text_in_rect(canvas, r, label, 18, Color.WHITE)
	else:
		text_in_rect(canvas, Rect2(r.position + Vector2(0, -9), r.size), label, 16 if label.length() < 12 else 13, Color.WHITE)
		text_in_rect(canvas, Rect2(r.position + Vector2(0, 12), r.size), sub, 14, Color(1, 0.9, 0.5))


## Chorągiewka punktu zbiórki; foot = dolny koniec drzewca.
static func rally_flag(canvas: CanvasItem, foot: Vector2, scale := 1.0, color := Color(0.9, 0.2, 0.2)) -> void:
	var top := foot + Vector2(0, -18) * scale
	canvas.draw_line(foot, top, Color(0.35, 0.25, 0.15), 2.0 * scale)
	canvas.draw_colored_polygon(PackedVector2Array([top, top + Vector2(11, 4) * scale, top + Vector2(0, 8) * scale]), color)


static func health_bar(canvas: CanvasItem, p: Vector2, frac: float, width: float, color: Color) -> void:
	canvas.draw_rect(Rect2(p + Vector2(-width / 2.0, 0), Vector2(width, 4)), Color(0, 0, 0, 0.7))
	canvas.draw_rect(Rect2(p + Vector2(-width / 2.0, 0), Vector2(width * clampf(frac, 0.0, 1.0), 4)), color)


## Panel informacji: tytuł i linie [tekst, kolor]. Długie linie są zawijane.
static func panel(canvas: CanvasItem, pos: Vector2, title: String, lines: Array, color: Color) -> void:
	var all := []
	for line in lines:
		if line[0].length() > PANEL_WRAP:
			for part in wrap_text(line[0], PANEL_WRAP):
				all.append([part, line[1]])
		else:
			all.append(line)
	var h := 36.0 + all.size() * 19.0 + 6.0
	var r := clamp_to_screen(Rect2(pos, Vector2(PANEL_WIDTH, h)))
	canvas.draw_rect(r, Color(0.05, 0.05, 0.09, 0.93))
	canvas.draw_rect(r, color, false, 2.0)
	text(canvas, r.position + Vector2(10, 22), title, 17, color)
	for i in all.size():
		text(canvas, r.position + Vector2(10, 44 + i * 19), all[i][0], 14, all[i][1])


## Dzieli tekst na linie o długości najwyżej n znaków.
static func wrap_text(s: String, n: int) -> Array[String]:
	var out: Array[String] = []
	var cur := ""
	for word in s.split(" "):
		if cur != "" and cur.length() + word.length() + 1 > n:
			out.append(cur)
			cur = word
		else:
			cur = word if cur == "" else cur + " " + word
	if cur != "":
		out.append(cur)
	return out


## Przesuwa prostokąt tak, by mieścił się na ekranie pod górnym paskiem.
static func clamp_to_screen(r: Rect2) -> Rect2:
	r.position.x = clampf(r.position.x, 4.0, GameConfig.W - r.size.x - 4.0)
	r.position.y = clampf(r.position.y, GameConfig.TOP + 4.0, GameConfig.H - r.size.y - 4.0)
	return r


static func percent(v: float) -> String:
	return "%d%%" % int(round(v * 100.0))
