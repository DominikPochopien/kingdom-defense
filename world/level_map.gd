class_name LevelMap
extends Node2D
## Mapa poziomu. Teren, góry, drzewa i miejsca na wieże pochodzą ze sceny poziomu (LevelScene,
## edycja w Godocie). Tutaj rysowane są elementy zależne od danych poziomu: mosty stałe i zwodzone,
## wejścia do tuneli, gniazda Leśnych Łuczników i puste miejsce na Statek (z grafik paczki).

const ShipTower := preload("res://entities/towers/ship_tower.gd")
const BRIDGE_H := preload("res://assets/terrain/bridge_h.png")
const BRIDGE_V := preload("res://assets/terrain/bridge_v.png")
const TUNNEL := preload("res://assets/terrain/tunnel_entrance.png")
const ARCHER_NEST := preload("res://assets/objects/archer_nest.png")
const WINCH := preload("res://assets/objects/drawbridge_winch.png")
## wciągarki mostu zwodzonego: nad i pod jego początkiem
const WINCH_OFFSET := 30.0

var _level: Dictionary = {}
var _paths: PathNetwork
var _bridges: BridgeSystem
var _spots: Array[BuildSpot] = []
## scena poziomu z edytora - rysowana pod wszystkim, co rysuje ta mapa
var _scene: LevelScene = null
## grafiki pixel art: osobna warstwa (ostre piksele, powtarzana grafika mostów), nad sceną, pod resztą mapy
var _pixel_layer := Node2D.new()


func _ready() -> void:
	_pixel_layer.show_behind_parent = true
	_pixel_layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_pixel_layer.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_pixel_layer.draw.connect(_draw_pixel_art)
	add_child(_pixel_layer)


func setup(level: Dictionary, paths: PathNetwork, bridges: BridgeSystem, spots: Array[BuildSpot]) -> void:
	_level = level
	_paths = paths
	_bridges = bridges
	_spots = spots
	if _scene != null:
		_scene.queue_free()
	_scene = (load(level.scene) as PackedScene).instantiate()
	_scene.show_behind_parent = true
	add_child(_scene)
	move_child(_scene, 0)


# ---------------- rysowanie ----------------
func _process(_delta: float) -> void:
	queue_redraw()
	_pixel_layer.queue_redraw()


## Łańcuchy mostów zwodzonych i napis na pustym miejscu na Statek (nad warstwą pixel artu).
func _draw() -> void:
	if _paths == null:
		return
	for i in _bridges.defs.size():
		_draw_drawbridge_chain(i)
	for p in _empty_ship_berths():
		UiDraw.text(self, p + Vector2(-40, -8), "Statek", 14, Color(1, 1, 1, 0.9), HORIZONTAL_ALIGNMENT_CENTER, 80.0)


## Warstwa pixel artu: mosty (zwodzone opuszczone w takiej części, jak pokazuje animacja),
## wciągarki, wejścia do tuneli, gniazda Leśnych Łuczników i półprzezroczysty statek na pustym miejscu.
func _draw_pixel_art() -> void:
	if _paths == null:
		return
	for p in _empty_ship_berths():
		ShipTower.draw_ship(_pixel_layer, p, 0.0, Color(1, 1, 1, 0.45))
	for fb in _level.get("fixed_bridges", []):
		_draw_bridge(fb.a, fb.b, 1.0, fb.get("vertical", false))
	for i in _bridges.defs.size():
		var a: Vector2 = _bridges.defs[i].a
		_draw_bridge(a, _bridges.defs[i].b, _drawbridge_frac(i))
		_draw_pixel_sprite(WINCH, a + Vector2(0, -WINCH_OFFSET), 0.5)
		_draw_pixel_sprite(WINCH, a + Vector2(0, WINCH_OFFSET), 0.5)
	# wejście tunelu stoi na końcu drogi, która wchodzi w nie od dołu
	for t in _level.get("tunnels", []):
		_draw_pixel_sprite(TUNNEL, t.a + Vector2(0, 8), 1.0)
		_draw_pixel_sprite(TUNNEL, t.b + Vector2(0, 8), 1.0)
	for p in _level.get("archer_posts", []):
		_draw_pixel_sprite(ARCHER_NEST, p + Vector2(0, 4), 0.5)


## Grafika w skali pixel artu; anchor_y = która część wysokości jest nad punktem p (0,5 = środek, 1 = podstawa).
func _draw_pixel_sprite(tex: Texture2D, p: Vector2, anchor_y: float) -> void:
	var size := tex.get_size() * LevelScene.PIXEL
	_pixel_layer.draw_texture_rect(tex, Rect2(p - Vector2(size.x / 2.0, size.y * anchor_y), size), false)


## Drewniany most od a do b z powtarzanej grafiki; frac = jaka część mostu jest opuszczona (0..1).
func _draw_bridge(a: Vector2, b: Vector2, frac: float, vertical := false) -> void:
	var tex: Texture2D = BRIDGE_V if vertical else BRIDGE_H
	var rect: Rect2
	if vertical:
		var half := tex.get_width() * LevelScene.PIXEL / 2.0
		rect = Rect2(a.x - half, a.y, half * 2.0, (b.y - a.y) * frac)
	else:
		var half := tex.get_height() * LevelScene.PIXEL / 2.0
		rect = Rect2(a.x, a.y - half, (b.x - a.x) * frac, half * 2.0)
	# grafika w pikselach obrazka, przeskalowana do jednostek gry
	_pixel_layer.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * LevelScene.PIXEL)
	_pixel_layer.draw_texture_rect(tex, Rect2(rect.position / LevelScene.PIXEL, rect.size / LevelScene.PIXEL), true)
	_pixel_layer.draw_set_transform(Vector2.ZERO)


func _drawbridge_frac(i: int) -> float:
	return 0.14 + 0.86 * _bridges.anim[i]


## Łańcuch od wciągarki do końca opuszczanego mostu (widać go, gdy most nie jest w pełni opuszczony).
func _draw_drawbridge_chain(i: int) -> void:
	if _bridges.anim[i] >= 0.99:
		return
	var br: Dictionary = _bridges.defs[i]
	var a: Vector2 = br.a
	var b: Vector2 = br.b
	draw_line(a + Vector2(0, -WINCH_OFFSET), a + Vector2(_drawbridge_frac(i) * (b.x - a.x), -WINCH_OFFSET),
		Color(0.7, 0.7, 0.75, 0.6), 2.0)


## Miejsca na Statek, na których nic jeszcze nie stoi.
func _empty_ship_berths() -> Array[Vector2]:
	var berths: Array[Vector2] = []
	for s in _spots:
		if s.only_type == "ship" and s.is_empty():
			berths.append(s.position)
	return berths
