class_name TowerIcons
## Ikony wież i gałęzi ulepszeń (poziom 4) na przyciskach menu budowy. Wieże mają ikony pixel art
## (assets/ui/icon_tower_*.png), gałęzie i Statek - rysowane kodem. Klucz to typ wieży (np. "archer")
## albo id gałęzi (np. "slow"). Ikona mieści się w kwadracie ok. 30x30.

## typ wieży -> ikona pixel art (rysowana na węźle z filtrem NEAREST)
const PIXEL_ICONS := {
	"archer": preload("res://assets/ui/icon_tower_archer.png"), "mage": preload("res://assets/ui/icon_tower_mage.png"),
	"barracks": preload("res://assets/ui/icon_tower_barracks.png"),
	"artillery": preload("res://assets/ui/icon_tower_artillery.png"), "knight_tower": preload("res://assets/ui/icon_tower_knight.png"),
}
const ICON_SIZE := 32.0

const WOOD := Color(0.6, 0.38, 0.16)
const STEEL := Color(0.85, 0.88, 0.92)
const GOLD := Color(0.95, 0.78, 0.25)
const DARK := Color(0.12, 0.12, 0.15)
const STRING_COL := Color(0.95, 0.93, 0.85)


## Rysuje ikonę `key` wyśrodkowaną w punkcie c, przeskalowaną o s.
static func draw(canvas: CanvasItem, key: String, c: Vector2, s: float) -> void:
	if PIXEL_ICONS.has(key):
		var size := Vector2.ONE * ICON_SIZE * s
		canvas.draw_texture_rect(PIXEL_ICONS[key], Rect2(c - size / 2.0, size), false)
		return
	canvas.draw_set_transform(c, 0.0, Vector2(s, s))
	match key:
		"double": _double_arrow(canvas)
		"long": _eye(canvas)
		"slow": _snowflake(canvas)
		"chain": _lightning(canvas)
		"vets": _chevrons(canvas)
		"extra": _squad(canvas)
		"blast": _explosion(canvas)
		"rapid": _fast_ball(canvas)
		"dmg": _spear(canvas)
		"hp": _shield(canvas)
		"ship": _ship(canvas)
		"fire_shot": _fireball(canvas)
		"lance": _volley(canvas)
	canvas.draw_set_transform(Vector2.ZERO)


# --- gałęzie ulepszeń ---

static func _double_arrow(canvas: CanvasItem) -> void:
	_arrow(canvas, Vector2(-13, -5), Vector2(13, -5))
	_arrow(canvas, Vector2(-13, 6), Vector2(13, 6))


static func _eye(canvas: CanvasItem) -> void:
	var top := PackedVector2Array()
	var bottom := PackedVector2Array()
	for i in 15:
		var x := -14.0 + i * 2.0
		var h := 8.0 * (1.0 - pow(x / 14.0, 2))
		top.append(Vector2(x, -h))
		bottom.append(Vector2(-x, h))
	var shape := top + bottom
	canvas.draw_colored_polygon(shape, Color(0.97, 0.95, 0.88))
	canvas.draw_circle(Vector2.ZERO, 5.5, Color(0.85, 0.6, 0.15))
	canvas.draw_circle(Vector2.ZERO, 2.5, DARK)
	canvas.draw_circle(Vector2(-2, -2), 1.2, Color.WHITE)
	shape.append(shape[0])
	canvas.draw_polyline(shape, DARK, 1.5)


static func _snowflake(canvas: CanvasItem) -> void:
	var ice := Color(0.75, 0.92, 1.0)
	for i in 6:
		var dir := Vector2.from_angle(i * TAU / 6.0)
		canvas.draw_line(Vector2.ZERO, dir * 13.0, ice, 2.5)
		var mid := dir * 8.0
		canvas.draw_line(mid, mid + dir.rotated(0.8) * 4.5, ice, 2.0)
		canvas.draw_line(mid, mid + dir.rotated(-0.8) * 4.5, ice, 2.0)
	canvas.draw_circle(Vector2.ZERO, 2.5, Color.WHITE)


static func _lightning(canvas: CanvasItem) -> void:
	var bolt := PackedVector2Array([Vector2(4, -15), Vector2(-8, 2), Vector2(-1, 2), Vector2(-5, 15),
		Vector2(9, -3), Vector2(2, -3)])
	canvas.draw_colored_polygon(bolt, Color(1.0, 0.92, 0.3))
	bolt.append(bolt[0])
	canvas.draw_polyline(bolt, Color(0.9, 0.5, 0.1), 1.5)


static func _chevrons(canvas: CanvasItem) -> void:
	for y: float in [-11.0, -3.0, 5.0]:
		canvas.draw_polyline(PackedVector2Array([Vector2(-11, y + 7), Vector2(0, y), Vector2(11, y + 7)]), GOLD, 3.5)


static func _squad(canvas: CanvasItem) -> void:
	for x: float in [-9.0, 0.0, 9.0]:
		var y := -2.0 if x == 0.0 else 1.0
		canvas.draw_rect(Rect2(x - 3.5, y + 4, 7, 9), STEEL)
		canvas.draw_circle(Vector2(x, y), 3.5, Color(0.95, 0.8, 0.65))
		canvas.draw_arc(Vector2(x, y), 3.8, PI, TAU, 8, Color(0.55, 0.58, 0.62), 2.0)
	var green := Color(0.4, 1.0, 0.45)
	canvas.draw_line(Vector2(11, -14), Vector2(11, -6), green, 3.0)
	canvas.draw_line(Vector2(7, -10), Vector2(15, -10), green, 3.0)


static func _explosion(canvas: CanvasItem) -> void:
	canvas.draw_colored_polygon(_star(8, 15.0, 7.0), Color(1.0, 0.45, 0.1))
	canvas.draw_colored_polygon(_star(8, 9.0, 4.5), Color(1.0, 0.85, 0.25))
	canvas.draw_circle(Vector2.ZERO, 3.0, Color(1, 1, 0.85))


static func _fast_ball(canvas: CanvasItem) -> void:
	var trail := Color(1, 1, 1, 0.8)
	canvas.draw_line(Vector2(-14, -5), Vector2(-3, -5), trail, 2.0)
	canvas.draw_line(Vector2(-12, 0), Vector2(-2, 0), trail, 2.0)
	canvas.draw_line(Vector2(-14, 5), Vector2(-3, 5), trail, 2.0)
	canvas.draw_circle(Vector2(6, 0), 8.0, DARK)
	canvas.draw_circle(Vector2(4, -2), 2.5, Color(0.42, 0.42, 0.48))


static func _spear(canvas: CanvasItem) -> void:
	var dir := Vector2(1, -1).normalized()
	var perp := dir.orthogonal()
	var base := Vector2(6, -6)
	canvas.draw_line(Vector2(-13, 13), base, WOOD, 2.5)
	var mid := base + dir * 3.0
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(14, -14), mid + perp * 4.0, base, mid - perp * 4.0]), STEEL)
	canvas.draw_line(base + perp * 3.0, base - perp * 3.0, GOLD, 2.0)


static func _shield(canvas: CanvasItem) -> void:
	var shape := PackedVector2Array([Vector2(-11, -13), Vector2(11, -13), Vector2(11, 0), Vector2(6, 9),
		Vector2(0, 14), Vector2(-6, 9), Vector2(-11, 0)])
	canvas.draw_colored_polygon(shape, Color(0.7, 0.18, 0.18))
	canvas.draw_line(Vector2(0, -10), Vector2(0, 10), GOLD, 3.0)
	canvas.draw_line(Vector2(-8, -3), Vector2(8, -3), GOLD, 3.0)
	shape.append(shape[0])
	canvas.draw_polyline(shape, STEEL, 2.5)


# --- elementy wspólne ---

## Strzała od `from` (lotki) do `to` (grot).
# --- Statek ---

static func _ship(canvas: CanvasItem) -> void:
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(-15, 4), Vector2(15, 4), Vector2(10, 12), Vector2(-10, 12)]), WOOD)
	canvas.draw_line(Vector2(0, 4), Vector2(0, -14), DARK, 2.0)
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(1, -13), Vector2(12, 1), Vector2(1, 1)]), STRING_COL)
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(-1, -10), Vector2(-10, 1), Vector2(-1, 1)]), STRING_COL)
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(0, -14), Vector2(6, -12), Vector2(0, -10)]), Color(0.85, 0.15, 0.15))


static func _fireball(canvas: CanvasItem) -> void:
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(-14, -10), Vector2(2, -6), Vector2(-2, 6)]), Color(1, 0.5, 0.1, 0.7))
	canvas.draw_circle(Vector2(4, 4), 9.0, Color(1, 0.45, 0.05))
	canvas.draw_circle(Vector2(4, 4), 5.5, Color(1, 0.8, 0.25))


static func _volley(canvas: CanvasItem) -> void:
	for k in 5:
		var a := -0.8 + k * 0.4
		var p := Vector2(-10, 10) + Vector2.from_angle(a - 0.6) * 22.0
		canvas.draw_line(Vector2(-10, 10), p, Color(1, 1, 1, 0.35), 1.5)
		canvas.draw_circle(p, 3.0, DARK)


static func _arrow(canvas: CanvasItem, from: Vector2, to: Vector2) -> void:
	var dir := (to - from).normalized()
	var perp := dir.orthogonal()
	canvas.draw_line(from, to - dir * 4.0, Color(0.85, 0.7, 0.45), 1.8)
	canvas.draw_colored_polygon(PackedVector2Array([to, to - dir * 6.0 + perp * 3.5, to - dir * 6.0 - perp * 3.5]), STEEL)
	var red := Color(0.9, 0.25, 0.2)
	canvas.draw_line(from + dir * 3.0, from - perp * 3.0, red, 1.8)
	canvas.draw_line(from + dir * 3.0, from + perp * 3.0, red, 1.8)


## Gwiazda o n ramionach (punkty na przemian na promieniu outer i inner).
static func _star(n: int, outer: float, inner: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n * 2:
		var r := outer if i % 2 == 0 else inner
		pts.append(Vector2.from_angle(-PI / 2.0 + i * PI / n) * r)
	return pts
