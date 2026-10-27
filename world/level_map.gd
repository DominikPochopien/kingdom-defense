class_name LevelMap
extends Node2D
## Tło poziomu: trawa, rzeka, drogi, mosty (stałe i zwodzone), drzewa i podstawy pod wieże.

const GRASS := Color(0.36, 0.62, 0.3)
const GRASS_STRIPE := Color(0.38, 0.65, 0.32, 0.5)
const ROAD_EDGE := Color(0.42, 0.3, 0.18)
const ROAD := Color(0.76, 0.62, 0.4)
const RIVER_COLOR := Color(0.0, 0.62, 0.9)
const PLANKS := Color(0.55, 0.38, 0.2)
const PLANK_LINE := Color(0.33, 0.22, 0.1)
const BRIDGE_RAIL := Color(0.3, 0.2, 0.1)
const BRIDGE_HALF_WIDTH := 30.0
const MAX_TREES := 60

var _level: Dictionary = {}
var _paths: PathNetwork
var _bridges: BridgeSystem
var _spots: Array[BuildSpot] = []
## drzewa: [pozycja, skala]
var _trees: Array = []


func setup(level: Dictionary, level_index: int, paths: PathNetwork, bridges: BridgeSystem, spots: Array[BuildSpot]) -> void:
	_level = level
	_paths = paths
	_bridges = bridges
	_spots = spots
	_place_trees(level_index)


## Losowe (ale stałe dla poziomu) drzewa z dala od dróg, rzeki, podstaw i przycisków.
func _place_trees(level_index: int) -> void:
	_trees.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = 7 + level_index * 13
	var river := PackedVector2Array(_level.get("river", []))
	var tries := 0
	while _trees.size() < MAX_TREES and tries < 800:
		tries += 1
		var p := Vector2(rng.randf_range(10, GameConfig.W - 10), rng.randf_range(GameConfig.TOP + 10, GameConfig.H - 10))
		if p.distance_to(_paths.nearest_point(p)) < 60:
			continue
		if not river.is_empty() and _is_near_polygon(p, river):
			continue
		if _is_free_for_tree(p):
			_trees.append([p, rng.randf_range(0.7, 1.2)])


static func _is_near_polygon(p: Vector2, poly: PackedVector2Array) -> bool:
	for o in [Vector2.ZERO, Vector2(22, 0), Vector2(-22, 0), Vector2(0, 22), Vector2(0, -22)]:
		if Geometry2D.is_point_in_polygon(p + o, poly):
			return true
	return false


func _is_free_for_tree(p: Vector2) -> bool:
	for s in _spots:
		if s.position.distance_to(p) < 50:
			return false
	# dolne rogi zajmują przyciski interfejsu
	return not (p.y > GameConfig.H - 80 and (p.x < 300 or p.x > GameConfig.W - 230))


# ---------------- rysowanie ----------------
func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if _paths == null:
		return
	draw_rect(Rect2(0, 0, GameConfig.W, GameConfig.H), GRASS)
	for i in 8:
		draw_rect(Rect2(0, i * 90, GameConfig.W, 45), GRASS_STRIPE)
	if _level.has("river"):
		_draw_river(_level.river)
	_draw_roads()
	for fb in _level.get("fixed_bridges", []):
		_draw_bridge_planks(fb.a, fb.b, 1.0, fb.get("vertical", false))
	for i in _bridges.defs.size():
		_draw_drawbridge(i)
	_draw_trees()
	_draw_spots()


func _draw_roads() -> void:
	for r in _paths.routes:
		draw_polyline(PackedVector2Array(r.points), ROAD_EDGE, 64.0)
		for p in r.points:
			draw_circle(p, 32.0, ROAD_EDGE)
	for r in _paths.routes:
		draw_polyline(PackedVector2Array(r.points), ROAD, 52.0)
		for p in r.points:
			draw_circle(p, 26.0, ROAD)


func _draw_trees() -> void:
	for tree in _trees:
		var p: Vector2 = tree[0]
		var sc: float = tree[1]
		draw_rect(Rect2(p + Vector2(-3, 4) * sc, Vector2(6, 12) * sc), Color(0.4, 0.27, 0.15))
		draw_circle(p + Vector2(0, -6) * sc, 16.0 * sc, Color(0.15, 0.42, 0.2))
		draw_circle(p + Vector2(-4, -10) * sc, 9.0 * sc, Color(0.22, 0.52, 0.27))


func _draw_spots() -> void:
	for s in _spots:
		draw_circle(s.position, 27.0, Color(0.3, 0.3, 0.32))
		draw_circle(s.position, 23.0, Color(0.55, 0.55, 0.58) if s.is_empty() else Color(0.45, 0.45, 0.48))


## Rzeka: wielokąt, którego pierwsza połowa punktów to jeden brzeg, a druga - drugi (od końca).
func _draw_river(poly: Array) -> void:
	draw_colored_polygon(PackedVector2Array(poly), RIVER_COLOR)
	var n := int(poly.size() / 2.0)
	var mid := PackedVector2Array()
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	for i in n:
		var a: Vector2 = poly[i]
		var b: Vector2 = poly[poly.size() - 1 - i]
		mid.append((a + b) / 2.0)
		left.append(a)
		right.append(b)
	draw_polyline(mid, Color(0.55, 0.85, 1.0, 0.35), 5.0)
	draw_polyline(left, Color(0.85, 0.95, 1.0, 0.6), 3.0)
	draw_polyline(right, Color(0.85, 0.95, 1.0, 0.6), 3.0)


## Drewniany most od a do b; frac = jaka część mostu jest opuszczona (0..1).
func _draw_bridge_planks(a: Vector2, b: Vector2, frac: float, vertical := false) -> void:
	var w := BRIDGE_HALF_WIDTH
	if vertical:
		var h := (b.y - a.y) * frac
		draw_rect(Rect2(a.x - w, a.y, w * 2.0, h), PLANKS)
		var y := a.y + 6.0
		while y < a.y + h - 2.0:
			draw_line(Vector2(a.x - w, y), Vector2(a.x + w, y), PLANK_LINE, 2.0)
			y += 14.0
		draw_line(Vector2(a.x - w, a.y), Vector2(a.x - w, a.y + h), BRIDGE_RAIL, 4.0)
		draw_line(Vector2(a.x + w, a.y), Vector2(a.x + w, a.y + h), BRIDGE_RAIL, 4.0)
		return
	var length := (b.x - a.x) * frac
	draw_rect(Rect2(a.x, a.y - w, length, w * 2.0), PLANKS)
	var x := a.x + 6.0
	while x < a.x + length - 2.0:
		draw_line(Vector2(x, a.y - w), Vector2(x, a.y + w), PLANK_LINE, 2.0)
		x += 14.0
	draw_line(Vector2(a.x, a.y - w), Vector2(a.x + length, a.y - w), BRIDGE_RAIL, 4.0)
	draw_line(Vector2(a.x, a.y + w), Vector2(a.x + length, a.y + w), BRIDGE_RAIL, 4.0)


func _draw_drawbridge(i: int) -> void:
	var br: Dictionary = _bridges.defs[i]
	var a: Vector2 = br.a
	var b: Vector2 = br.b
	var t: float = _bridges.anim[i]
	draw_rect(Rect2(a.x - 2.0, a.y - 34.0, b.x - a.x + 4.0, 68.0), RIVER_COLOR)
	var frac := 0.14 + 0.86 * t
	_draw_bridge_planks(a, b, frac)
	# wciągarka i łańcuch
	draw_circle(a + Vector2(0, -30), 6.0, Color(0.25, 0.25, 0.28))
	draw_circle(a + Vector2(0, 30), 6.0, Color(0.25, 0.25, 0.28))
	if t < 0.99:
		draw_line(a + Vector2(0, -30), a + Vector2(frac * (b.x - a.x), -30), Color(0.7, 0.7, 0.75, 0.6), 2.0)
	_draw_bridge_label(i, br)


func _draw_bridge_label(i: int, br: Dictionary) -> void:
	var a: Vector2 = br.a
	var b: Vector2 = br.b
	var is_open := _bridges.active == i
	var col := Color(0.5, 1.0, 0.5) if is_open else Color(1.0, 0.45, 0.4)
	var label := "%s: %s" % [br.name, "OTWARTY" if is_open else "PODNIESIONY"]
	if is_open:
		if _bridges.is_waiting():
			label += " (czeka na wrogów)"
		else:
			label += " (zmiana za %d s)" % int(ceil(_bridges.timer))
	var mid := (a + b) / 2.0
	draw_rect(Rect2(mid.x - 125.0, a.y - 62.0, 250.0, 22.0), Color(0, 0, 0, 0.6))
	UiDraw.text(self, Vector2(mid.x - 125.0, a.y - 46.0), label, 13, col, HORIZONTAL_ALIGNMENT_CENTER, 250.0)
	# podczas oczekiwania zaznacz strefę, w której wrogowie blokują zamknięcie mostu
	if is_open and _bridges.is_waiting():
		var pts: Array = _paths.routes[br.route].points.slice(br.zone_from, br.zone_to + 1)
		draw_polyline(PackedVector2Array(pts), Color(1, 0.3, 0.2, 0.35), 40.0)
