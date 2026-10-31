class_name LevelMap
extends Node2D
## Mapa poziomu. Teren, góry, drzewa i miejsca na wieże pochodzą ze sceny poziomu (LevelScene,
## edycja w Godocie). Tutaj rysowane są elementy zależne od danych poziomu: mosty stałe i zwodzone,
## wejścia do tuneli, portale, gniazda Leśnych Łuczników i puste miejsce na Statek (z grafik paczki).

const ShipTower := preload("res://entities/towers/ship_tower.gd")
const TUNNEL := preload("res://assets/terrain/tunnel_entrance.png")
const ARCHER_NEST := preload("res://assets/objects/archer_nest.png")
## portal: 4 klatki wiru (tools/gen_undead.py)
const PORTAL := preload("res://assets/objects/portal.png")
const PORTAL_FRAME := Vector2(28, 18)
const PORTAL_FPS := 6.0

var _level: Dictionary = {}
var _paths: PathNetwork
var _bridges: BridgeSystem
var _spots: Array[BuildSpot] = []
## scena poziomu z edytora - rysowana pod wszystkim, co rysuje ta mapa
var _scene: LevelScene = null
## czas animacji portali (czas rzeczywisty)
var _anim := 0.0
## grafiki pixel art: osobna warstwa (ostre piksele), nad sceną, pod resztą mapy
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
func _process(delta: float) -> void:
	_anim += delta
	queue_redraw()
	_pixel_layer.queue_redraw()


## Napis na pustym miejscu na Statek (nad warstwą pixel artu).
func _draw() -> void:
	if _paths == null:
		return
	for p in _empty_ship_berths():
		UiDraw.text(self, p + Vector2(-40, -8), "Statek", 14, Color(1, 1, 1, 0.9), HORIZONTAL_ALIGNMENT_CENTER, 80.0)


## Warstwa pixel artu: mosty (zwodzone w klatce animacji podnoszenia, world/bridge_art.gd),
## wejścia do tuneli, gniazda Leśnych Łuczników i półprzezroczysty statek na pustym miejscu.
func _draw_pixel_art() -> void:
	if _paths == null:
		return
	for p in _empty_ship_berths():
		ShipTower.draw_ship(_pixel_layer, p, 0.0, Color(1, 1, 1, 0.45))
	for fb in _level.get("fixed_bridges", []):
		BridgeArt.draw_bridge(_pixel_layer, fb.a, fb.b, fb.get("vertical", false))
	for i in _bridges.defs.size():
		BridgeArt.draw_drawbridge(_pixel_layer, _bridges.defs[i].a, _bridges.defs[i].b, _bridges.anim[i])
	# wejście tunelu stoi na końcu drogi, która wchodzi w nie od dołu
	for t in _level.get("tunnels", []):
		_draw_pixel_sprite(TUNNEL, t.a + Vector2(0, 8), 1.0)
		_draw_pixel_sprite(TUNNEL, t.b + Vector2(0, 8), 1.0)
	for p in _level.get("archer_posts", []):
		_draw_pixel_sprite(ARCHER_NEST, p + Vector2(0, 4), 0.5)
	var frame := Rect2(Vector2(int(_anim * PORTAL_FPS) % 4 * PORTAL_FRAME.x, 0), PORTAL_FRAME)
	var size := PORTAL_FRAME * LevelScene.PIXEL
	for portal in _level.get("portals", []):
		for p: Vector2 in [portal.a, portal.b]:
			_pixel_layer.draw_texture_rect_region(PORTAL, Rect2(p - size / 2.0, size), frame)


## Ukryta droga poziomu pojawia się na mapie (otwiera ją Mumia, GameWorld.open_hidden_route).
func reveal_hidden_road(from: Vector2) -> void:
	if _scene != null:
		_scene.reveal_hidden_road(from)


## Grafika w skali pixel artu; anchor_y = która część wysokości jest nad punktem p (0,5 = środek, 1 = podstawa).
func _draw_pixel_sprite(tex: Texture2D, p: Vector2, anchor_y: float) -> void:
	var size := tex.get_size() * LevelScene.PIXEL
	_pixel_layer.draw_texture_rect(tex, Rect2(p - Vector2(size.x / 2.0, size.y * anchor_y), size), false)


## Miejsca na Statek, na których nic jeszcze nie stoi.
func _empty_ship_berths() -> Array[Vector2]:
	var berths: Array[Vector2] = []
	for s in _spots:
		if s.only_type == "ship" and s.is_empty():
			berths.append(s.position)
	return berths
