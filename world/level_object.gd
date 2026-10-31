@tool
class_name LevelObject
extends Node2D
## Obiekt poziomu ustawiany myszką w edytorze: dziecko węzła "Obiekty" w scenie poziomu (levels/).
## Rodzaj wybiera się w Inspektorze (pole Kind). Punkt węzła to:
##   most stały / zwodzony - lewy (albo górny, gdy pionowy) koniec mostu, długość w polu Length
##   tunel - wejście; dziecko "Wyjscie" (Marker2D) to wyjście. Oba końce przyciągają się
##       do najbliższego punktu trasy, więc muszą leżeć na kolejnych punktach jakiejś trasy
##   gniazdo łuczników, bohater - miejsce postaci (stopy)
##   statek - środek statku; dziecko "Cel" (Marker2D) to środek obszaru, w który strzela
##   palma - podstawa pnia; dziecko "Cel" to środek obszaru, na który spadają kokosy (Radius)
##   wieża wroga - podstawa wieży; dziecko "Cel" to środek obszaru, w którym co jakiś czas
##       wrogowie biegną szybciej (Radius)
##   wieża rycerska - darmowa wieża; trafia na najbliższe miejsce budowy
##   portal - wejście; dziecko "Wyjscie" to wyjście. Jak tunel: oba końce muszą leżeć na kolejnych
##       punktach trasy, a wróg z wejścia od razu pojawia się w wyjściu
## W grze obiekty nic nie rysują - zamienia je na dane poziomu LevelScene.get_objects(),
## a rysuje world/level_map.gd i jednostki. Podgląd poniżej widać tylko w edytorze.

enum Kind { BRIDGE, DRAWBRIDGE, TUNNEL, ARCHER_NEST, SHIP, HERO, PALM, KNIGHT_TOWER, WAR_TOWER, PORTAL }

const NAMES := {
	Kind.BRIDGE: "Most", Kind.DRAWBRIDGE: "Most zwodzony", Kind.TUNNEL: "Tunel",
	Kind.ARCHER_NEST: "Gniazdo łuczników", Kind.SHIP: "Statek", Kind.HERO: "Bohater: Rycerz",
	Kind.PALM: "Palma", Kind.KNIGHT_TOWER: "Wieża Rycerska", Kind.WAR_TOWER: "Wieża wroga", Kind.PORTAL: "Portal",
}
## rodzaje z dzieckiem-znacznikiem: rodzaj -> [nazwa dziecka, domyślne przesunięcie]
const MARKERS := {
	Kind.TUNNEL: ["Wyjscie", Vector2(160, 0)],
	Kind.SHIP: ["Cel", Vector2(-160, 160)],
	Kind.PALM: ["Cel", Vector2(60, 70)],
	Kind.WAR_TOWER: ["Cel", Vector2(0, 80)],
	Kind.PORTAL: ["Wyjscie", Vector2(300, 0)],
}
const BridgeArtScript := preload("res://world/bridge_art.gd")
const TUNNEL := preload("res://assets/terrain/tunnel_entrance.png")
const ARCHER_NEST := preload("res://assets/objects/archer_nest.png")
const SHIP := preload("res://assets/objects/ship_sway.png")
const PALM := preload("res://assets/objects/palm_sway.png")
const HERO := preload("res://assets/allies/hero_walk.png")
const KNIGHT_TOWER := preload("res://assets/towers/knight_1.png")
const WAR_TOWER := preload("res://assets/objects/war_tower.png")
const PORTAL := preload("res://assets/objects/portal.png")
## klatki grafik w pikselach obrazka (jak w ship_tower.gd, stun_palm.gd i unit_sprites.gd)
const SHIP_FRAME := Vector2(64, 32)
const PALM_FRAME := Vector2(24, 40)
const PALM_BASE := Vector2(9, 38)
const HERO_FRAME := Vector2(16, 22)
const WAR_TOWER_FRAME := Vector2(24, 44)
const PORTAL_FRAME := Vector2(28, 18)
## podstawa wieży poniżej jej punktu (Tower.BASE_Y)
const TOWER_BASE_Y := 22.0
## jednostek gry na piksel grafiki (LevelScene.PIXEL - bez odwołania, bo level_scene.gd ładuje ten skrypt)
const PIXEL := 2
const LABEL_COLOR := Color(1, 1, 0.6)

@export var kind := Kind.BRIDGE:
	set(value):
		kind = value
		notify_property_list_changed()
		_ensure_marker()
		queue_redraw()
## długość mostu (jednostki gry, 32 = kafelek)
@export var length := 160.0:
	set(value):
		length = value
		queue_redraw()
## most stały: pionowy (z góry na dół) zamiast poziomego
@export var vertical := false:
	set(value):
		vertical = value
		queue_redraw()
## most zwodzony: nazwa w komunikacie o zmianie mostu
@export var bridge_name := "Most 1"
## most zwodzony: trasa przez ten most (0 = pierwsza trasa w scenie)
@export var route := 0
## most zwodzony: strefa = punkty trasy od zone_from do zone_to; póki są w niej wrogowie, most się nie podniesie
@export var zone_from := 0
@export var zone_to := 0
## palma: promień obszaru kokosów; wieża wroga: promień obszaru przyspieszenia
@export var radius := 90.0:
	set(value):
		radius = value
		queue_redraw()


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	set_process(Engine.is_editor_hint())
	_ensure_marker()


## W edytorze odświeża podgląd (znaczniki i trasy mogą się przesuwać).
func _process(_delta: float) -> void:
	queue_redraw()


## Pola Inspektora tylko dla bieżącego rodzaju.
func _validate_property(property: Dictionary) -> void:
	var used := {
		"length": kind in [Kind.BRIDGE, Kind.DRAWBRIDGE],
		"vertical": kind == Kind.BRIDGE,
		"bridge_name": kind == Kind.DRAWBRIDGE, "route": kind == Kind.DRAWBRIDGE,
		"zone_from": kind == Kind.DRAWBRIDGE, "zone_to": kind == Kind.DRAWBRIDGE,
		"radius": kind in [Kind.PALM, Kind.WAR_TOWER],
	}
	var prop := String(property.name)
	if used.has(prop) and not used[prop]:
		property.usage = PROPERTY_USAGE_NO_EDITOR


## Drugi koniec mostu (współrzędne sceny).
func bridge_end() -> Vector2:
	return position + (Vector2(0, length) if vertical and kind == Kind.BRIDGE else Vector2(length, 0))


## Położenie dziecka-znacznika (wyjście tunelu, cel statku lub palmy) we współrzędnych sceny.
func marker_position() -> Vector2:
	return transform * _marker_local()


func _marker_local() -> Vector2:
	if not MARKERS.has(kind):
		return Vector2.ZERO
	var marker := get_node_or_null(MARKERS[kind][0]) as Node2D
	return marker.position if marker != null else MARKERS[kind][1]


## W edytorze dodaje brakujące dziecko-znacznik (np. po zmianie rodzaju na Statek).
func _ensure_marker() -> void:
	if not Engine.is_editor_hint() or not is_inside_tree() or not MARKERS.has(kind):
		return
	var marker_name: String = MARKERS[kind][0]
	if has_node(marker_name):
		return
	var marker := Marker2D.new()
	marker.name = marker_name
	marker.position = MARKERS[kind][1]
	add_child(marker)
	var root := get_tree().edited_scene_root
	if root != null and (root == self or root.is_ancestor_of(self)):
		marker.owner = root


# ---------------- podgląd w edytorze ----------------
func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var px := float(PIXEL)
	match kind:
		Kind.BRIDGE, Kind.DRAWBRIDGE:
			_draw_bridge()
		Kind.TUNNEL:
			var exit := _marker_local()
			_dashed_line(Vector2.ZERO, exit, Color(0.2, 0.2, 0.2, 0.8))
			_sprite(TUNNEL, Vector2(0, 8), 1.0)
			_sprite(TUNNEL, exit + Vector2(0, 8), 1.0)
		Kind.ARCHER_NEST:
			_sprite(ARCHER_NEST, Vector2(0, 4), 0.5)
		Kind.SHIP:
			var size := SHIP_FRAME * px
			draw_texture_rect_region(SHIP, Rect2(-size / 2.0, size), Rect2(Vector2.ZERO, SHIP_FRAME))
			_dashed_line(Vector2.ZERO, _marker_local(), Color(1, 0.5, 0.2, 0.8))
		Kind.HERO:
			var size := HERO_FRAME * px
			draw_texture_rect_region(HERO, Rect2(Vector2(-size.x / 2.0, -size.y), size), Rect2(Vector2.ZERO, HERO_FRAME))
		Kind.PALM:
			draw_texture_rect_region(PALM, Rect2(-PALM_BASE * px, PALM_FRAME * px), Rect2(Vector2.ZERO, PALM_FRAME))
			draw_arc(_marker_local(), radius, 0, TAU, 48, Color(0.3, 0.9, 0.35, 0.8), 2.0)
		Kind.KNIGHT_TOWER:
			var size := KNIGHT_TOWER.get_size() * px
			draw_texture_rect(KNIGHT_TOWER, Rect2(Vector2(-size.x / 2.0, TOWER_BASE_Y - size.y), size), false)
		Kind.WAR_TOWER:
			var size := WAR_TOWER_FRAME * px
			draw_texture_rect_region(WAR_TOWER, Rect2(Vector2(-size.x / 2.0, -size.y), size), Rect2(Vector2.ZERO, WAR_TOWER_FRAME))
			draw_arc(_marker_local(), radius, 0, TAU, 64, Color(0.95, 0.3, 0.2, 0.8), 2.0)
		Kind.PORTAL:
			var exit := _marker_local()
			_dashed_line(Vector2.ZERO, exit, Color(0.7, 0.4, 1.0, 0.8))
			var size := PORTAL_FRAME * px
			for p: Vector2 in [Vector2.ZERO, exit]:
				draw_texture_rect_region(PORTAL, Rect2(p - size / 2.0, size), Rect2(Vector2.ZERO, PORTAL_FRAME))
	var label: String = NAMES[kind]
	if kind == Kind.DRAWBRIDGE:
		label += " (%s)" % bridge_name
	draw_string(ThemeDB.fallback_font, Vector2(-60, -40), label, HORIZONTAL_ALIGNMENT_CENTER, 120, 12, LABEL_COLOR)


## Most jak w grze (world/bridge_art.gd); zwodzony opuszczony.
func _draw_bridge() -> void:
	var end := bridge_end() - position
	if kind == Kind.DRAWBRIDGE:
		BridgeArtScript.draw_drawbridge(self, Vector2.ZERO, end, 1.0)
	else:
		BridgeArtScript.draw_bridge(self, Vector2.ZERO, end, vertical)


## Grafika w skali pixel artu; anchor_y = która część wysokości jest nad punktem p.
func _sprite(tex: Texture2D, p: Vector2, anchor_y: float) -> void:
	var size := tex.get_size() * PIXEL
	draw_texture_rect(tex, Rect2(p - Vector2(size.x / 2.0, size.y * anchor_y), size), false)


func _dashed_line(a: Vector2, b: Vector2, color: Color) -> void:
	draw_dashed_line(a, b, color, 2.0, 8.0)
