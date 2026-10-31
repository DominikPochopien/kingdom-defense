@tool
class_name BridgeArt
extends RefCounted
## Rysowanie mostów z grafik tools/gen_bridges.py (opis w assets/README_grafiki.md, "Mosty stałe
## i most zwodzony"). Używa go mapa w grze (world/level_map.gd) i podgląd obiektu w edytorze
## (world/level_object.gd). Punkty a i b to końce mostu we współrzędnych płótna (jednostki gry).
## Płótno musi mieć texture_filter = NEAREST.

## jednostek gry na piksel grafiki (LevelScene.PIXEL - bez odwołania, bo level_scene.gd ładuje level_object.gd)
const PIXEL := 2
## długości gotowych mostów w pikselach grafiki
const LENGTHS := [48, 64, 80, 96, 112]
const H := [
	preload("res://assets/terrain/bridge_h_48.png"), preload("res://assets/terrain/bridge_h_64.png"),
	preload("res://assets/terrain/bridge_h_80.png"), preload("res://assets/terrain/bridge_h_96.png"),
	preload("res://assets/terrain/bridge_h_112.png"),
]
const V := [
	preload("res://assets/terrain/bridge_v_48.png"), preload("res://assets/terrain/bridge_v_64.png"),
	preload("res://assets/terrain/bridge_v_80.png"), preload("res://assets/terrain/bridge_v_96.png"),
	preload("res://assets/terrain/bridge_v_112.png"),
]
const DRAWBRIDGE := preload("res://assets/terrain/drawbridge.png")
## środek pokładu w poprzek mostu (wiersze 0-45 to most, dalej cień na wodzie)
const DECK_MID := 22.5
## most innej długości: początek i koniec z najdłuższej grafiki, środek z powtarzanych kawałków
## (słupki poręczy co 8 px, więc kawałek i zaokrąglenie długości to wielokrotność 8)
const END := 16
const PIECE := 16
const POST_STEP := 8
## most zwodzony: klatki 96×64, zawias po przyczółku, cały most (przyczółek + pokład) ma 80 px
const DRAW_FRAME := Vector2(96, 64)
const DRAW_FRAMES := 6
const DRAW_LENGTH := 80.0
const DRAW_DECK_MID := 31.5


## Most stały od a do b (poziomy albo pionowy). Gotowa grafika, gdy długość pasuje,
## inaczej złożona z kawałków i wyśrodkowana między a i b.
static func draw_bridge(canvas: CanvasItem, a: Vector2, b: Vector2, vertical: bool) -> void:
	var length := roundi(a.distance_to(b) / PIXEL)
	var mid := (a + b) / 2.0 / PIXEL
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * PIXEL)
	var i := LENGTHS.find(length)
	if i >= 0:
		var tex: Texture2D = V[i] if vertical else H[i]
		_piece(canvas, tex, 0, length, mid, -length / 2.0, vertical)
	else:
		var tex: Texture2D = V.back() if vertical else H.back()
		var full: int = LENGTHS.back()
		var inner := ceili(maxf(length - 2 * END, 0) / float(POST_STEP)) * POST_STEP
		var start := -(inner + 2 * END) / 2.0
		_piece(canvas, tex, 0, END, mid, start, vertical)
		var done := 0
		while done < inner:
			var n := mini(PIECE, inner - done)
			_piece(canvas, tex, END, n, mid, start + END + done, vertical)
			done += n
		_piece(canvas, tex, full - END, END, mid, start + END + inner, vertical)
	canvas.draw_set_transform(Vector2.ZERO)


## Most zwodzony (poziomy, zawias przy a). lowered: 0 = podniesiony, 1 = opuszczony.
static func draw_drawbridge(canvas: CanvasItem, a: Vector2, b: Vector2, lowered: float) -> void:
	var frame := clampi(roundi((1.0 - lowered) * (DRAW_FRAMES - 1)), 0, DRAW_FRAMES - 1)
	var stretch := (b.x - a.x) / PIXEL / DRAW_LENGTH
	var dest := Rect2(a / PIXEL - Vector2(0, DRAW_DECK_MID), Vector2(DRAW_FRAME.x * stretch, DRAW_FRAME.y))
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * PIXEL)
	canvas.draw_texture_rect_region(DRAWBRIDGE, dest, Rect2(Vector2(frame * DRAW_FRAME.x, 0), DRAW_FRAME))
	canvas.draw_set_transform(Vector2.ZERO)


## Kawałek grafiki mostu: n px wzdłuż mostu od src, rysowany od at (względem środka mid), w pikselach grafiki.
static func _piece(canvas: CanvasItem, tex: Texture2D, src: int, n: int, mid: Vector2, at: float, vertical: bool) -> void:
	if vertical:
		var size := Vector2(tex.get_width(), n)
		canvas.draw_texture_rect_region(tex, Rect2(mid + Vector2(-DECK_MID, at), size), Rect2(Vector2(0, src), size))
	else:
		var size := Vector2(n, tex.get_height())
		canvas.draw_texture_rect_region(tex, Rect2(mid + Vector2(at, -DECK_MID), size), Rect2(Vector2(src, 0), size))
