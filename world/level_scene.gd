@tool
class_name LevelScene
extends Node2D
## Poziom zbudowany w edytorze Godota (scena w levels/, podpięta kluczem "scene" w danych poziomu).
## Węzły sceny:
##   Trawa, Piasek, Woda, Piana, Droga, DrogaSkos, Gory - kafelki (TileMapLayer, od spodu).
##       Piasek, wodę, drogi i góry maluje się pędzlem terenu (zakładka TileMap → Terrains),
##       skośną drogę - kafelkami z atlasu road_diagonal; można też generować przyciskami w Inspektorze.
##   MiejscaNaWieze - miejsca budowy (Sprite2D). Kolejność = numer miejsca w zapisie gry,
##       więc nowe dopisuj na końcu, a starych nie przestawiaj w drzewie sceny.
##   Ozdoby - drzewa, szczyty gór, krzaki, kamienie, lilie, muszelki (Sprite2D, punkt węzła = podstawa).
##   Obiekty - mosty, mosty zwodzone, tunele, gniazda łuczników, statek, bohater, palmy, wieże wroga
##       i darmowa Wieża Rycerska (LevelObject, world/level_object.gd; rodzaj w polu Kind). Nowy: zduplikuj
##       istniejący (Ctrl+D) albo dodaj węzeł Node2D ze skryptem level_object.gd.
##       Kolejność mostów zwodzonych w drzewie = kolejność w grze (pierwszy jest otwarty na starcie).
##   Trasa1, Trasa2, ... - trasy wrogów (Path2D, w kolejności z drzewa sceny). Dla ładnej drogi
##       punkty leżą na środkach kafelków (32k + 16), a skosy mają dokładnie 45°. Mosty zwodzone
##       zwodzone wskazują numery punktów trasy (strefa), a tunele leżą na punktach tras - po zmianie
##       trasy sprawdź je. Po zmianie tras kliknij w Inspektorze "Wygeneruj drogę z tras".
## Generator bierze wodę, piasek i góry z danych poziomu (data/levels/, klucze river, ponds,
## sea, beach, islands, mountains), a tunele z Obiektów. Przy otwarciu sceny wypełnia tylko puste warstwy.
## Droga malowana (klucz "road": "painted" w danych poziomu): zamiast kafelków droga jest obrazkiem
##   liczonym przy każdym otwarciu sceny z tekstur road_fill/road_edge/road_bits (assets/README_grafiki.md).
##   Trasa to gładkie łuki przez punkty Path2D (albo po ich uchwytach, jeśli je wyciągniesz), droga ma
##   prawie stałą szerokość (szersza na ciasnych zakrętach) i gładkie, miejscami poszarpane brzegi; wrogowie idą tym samym łukiem. Punkty trasy w grze to nie te
##   same punkty co w Path2D: strefy mostów zwodzonych nadal podaje się numerami punktów Path2D (kod
##   przelicza je na łuk), trasy z tym samym początkiem dzielą łuk aż do rozwidlenia, trasa dołączająca do
##   innej (te same punkty od złączenia do końca) dostaje od złączenia jej łuk, a tunel zostaje prostym,
##   niemalowanym odcinkiem między wejściem i wyjściem (łuki przed i za nim liczą się osobno).
##   W edytorze droga odświeża się sama po przeciągnięciu punktu trasy.
## Pixel art: 1 piksel obrazka = 2 jednostki gry, kafelek = 32 jednostki.

## przez preload, a nie class_name - scena ładuje się w edytorze, zanim Godot zarejestruje nazwy klas
const LevelObjectScript := preload("res://world/level_object.gd")

const TILE := 16
## jednostek gry na piksel grafiki
const PIXEL := 2
const CELL := TILE * PIXEL
## 1280 / 32 kolumn i 720 / 32 = 22,5 rzędu (ostatni wystaje poza ekran)
const COLS := 40
const ROWS := 23
## róg kafelka bliżej trasy niż tyle należy do drogi - droga ma 2 kafelki szerokości
const ROAD_REACH := CELL / 2.0 + 1.0
## szansa na losowy wariant pełnego kafelka
const VARIANT_CHANCE := 0.5
const WATER_FRAMES := 4
const WATER_FPS := 4.0
## warstwy kafelków od spodu
const LAYERS := ["Trawa", "Piasek", "Woda", "Piana", "Droga", "DrogaSkos", "Gory"]

const SRC_GRASS := 0
const SRC_ROAD := 1
const SRC_SAND_ROAD := 2
const SRC_SAND := 3
const SRC_WATER := 4
const SRC_SEA := 5
const SRC_FOAM := 6
const SRC_MOUNTAIN := 7
const SRC_DIAGONAL := 8
const SRC_SAND_DIAGONAL := 9
const GRASS_TEX := "res://assets/terrain/grass.png"
## atlasy skośnej drogi (bez opisu terenu - kafelki układa generator albo stawia się je ręcznie)
const DIAGONAL_TEX := {
	SRC_DIAGONAL: "res://assets/terrain/road_diagonal.png",
	SRC_SAND_DIAGONAL: "res://assets/terrain/sand_road_diagonal.png",
}
const DIAGONAL_COLUMNS := 8
const DIAGONAL_TILES := 30
## zestawy terenów dla pędzla: [nazwa zestawu, kolor w edytorze, nazwy terenów]
const TERRAIN_SETS := [
	["Drogi", Color(0.65, 0.5, 0.35), ["Droga", "Droga na piasku"]],
	["Piasek", Color(0.95, 0.75, 0.35), ["Piasek"]],
	["Woda", Color(0.3, 0.5, 0.95), ["Woda", "Morze"]],
	["Piana", Color(0.9, 0.95, 1.0), ["Piana"]],
	["Góry", Color(0.5, 0.45, 0.55), ["Góry"]],
]
## nakładki dopasowywane po rogach (assets/README_grafiki.md). Zwykłe: kafelek o masce m
## w kolumnie m % 4, wierszu m / 4, wiersz 4 = warianty pełnego. Animowane: wiersz m, klatki w kolumnach.
const OVERLAYS := [
	{"source": SRC_ROAD, "texture": "res://assets/terrain/road.png", "terrain_set": 0, "terrain": 0, "animated": false},
	{"source": SRC_SAND_ROAD, "texture": "res://assets/terrain/sand_road.png", "terrain_set": 0, "terrain": 1, "animated": false},
	{"source": SRC_SAND, "texture": "res://assets/terrain/beach.png", "terrain_set": 1, "terrain": 0, "animated": false},
	{"source": SRC_WATER, "texture": "res://assets/terrain/water.png", "terrain_set": 2, "terrain": 0, "animated": true},
	{"source": SRC_SEA, "texture": "res://assets/terrain/sea.png", "terrain_set": 2, "terrain": 1, "animated": true},
	{"source": SRC_FOAM, "texture": "res://assets/terrain/sea_foam.png", "terrain_set": 3, "terrain": 0, "animated": true},
	{"source": SRC_MOUNTAIN, "texture": "res://assets/terrain/mountain.png", "terrain_set": 4, "terrain": 0, "animated": false},
]
## rogi kafelka w kolejności bitów maski: NW=1, NE=2, SW=4, SE=8
const CORNERS := [
	TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER, TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER,
	TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER, TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER,
]
## Skos 45° z road_diagonal_layout.json. Klucz = kierunek w poziomie, gdy idziemy w dół skosu.
## Wiersz = [przesunięcie pierwszego kafelka względem kolumny środka drogi, indeksy kafelków].
## entry: 2 wiersze od górnego końca (nad nim prosta pionowa droga), middle: każdy kolejny,
## exit_*: 2-3 ostatnie wiersze, zależnie od tego, co jest pod dolnym końcem skosu
## (pionowa droga, pozioma w tę samą stronę albo skrzyżowanie z innymi drogami).
const DIAGONAL := {
	1: {
		"entry": [[-1, [3, 1, 4, 5]], [-2, [6, 7, 1, 8, 5]]],
		"middle": [-2, [9, 7, 1, 8, 5]],
		"exit_vertical": [[-2, [9, 7, 1, 8, 5]], [-2, [9, 25, 1, 26]]],
		"exit_horizontal": [[-2, [9, 7, 1, 10]], [-2, [9, 7, 1]], [-1, [12, 13]]],
		"exit_junction": [[-2, [9, 7, 1, 8, 5]], [-2, [9, 25, 1]]],
	},
	-1: {
		"entry": [[-2, [15, 16, 1, 17]], [-2, [15, 18, 1, 19, 20]]],
		"middle": [-2, [15, 18, 1, 19, 21]],
		"exit_vertical": [[-2, [27, 18, 1, 19, 21]], [-1, [28, 1, 29, 21]]],
		"exit_horizontal": [[-1, [22, 1, 19, 21]], [0, [1, 19, 21]], [0, [23, 24]]],
		"exit_junction": [[-2, [15, 18, 1, 19, 21]], [0, [1, 29, 21]]],
	},
}

## --- droga malowana ---
## połowa szerokości drogi w pikselach grafiki: HALF_MID (38 px = 76 jednostek gry), lekko ±HALF_AMP
const HALF_MID := 19.0
const HALF_AMP := 0.8
## na ciasnych zakrętach droga jest szersza o HALF_BEND px z każdej strony
## (pełne poszerzenie przy promieniu łuku BEND_RADIUS px lub mniejszym)
const HALF_BEND := 3.0
const BEND_RADIUS := 45.0
const BEND_SPREAD := 20
## brzegi: zwykle gładkie (fale ±EDGE_SMOOTH px), miejscami poszarpane (dodatkowo ±EDGE_ROUGH px)
const EDGE_SMOOTH := 0.6
const EDGE_ROUGH := 1.5
## drganie brzegu o pojedyncze piksele (jak edge_noise w tools/gen_art.py)
const EDGE_JITTER := 0.5
## okresy fal (w pikselach wzdłuż trasy) i ich siła: [okres, waga]
const WIDTH_WAVES := [[97.0, 0.5], [151.0, 0.35], [233.0, 0.25]]
const EDGE_WAVES := [[41.0, 0.5], [67.0, 0.35], [113.0, 0.25]]
## gdzie brzeg jest poszarpany: tam, gdzie ta wolna fala przekracza ROUGH_FROM (ok. 1/8 długości drogi)
const ROUGH_WAVES := [[311.0, 0.6], [197.0, 0.4]]
const ROUGH_FROM := 0.55
const ROUGH_FULL := 0.8
## przy moście droga przechodzi w szerokość jego pokładu (40 px, world/bridge_art.gd) - prawie bez zwężenia
## na ostatnich BRIDGE_TAPER px przed mostem
const BRIDGE_HALF := 20.0
const BRIDGE_TAPER := 30.0
## co tyle jednostek gry punkt wygładzonej trasy
const ARC_STEP := 12.0
const PAINT_W := 640
## odsłanianie ukrytej drogi: w REVEAL_TIME s okrąg rośnie do REVEAL_REACH pikseli grafiki (dalej tym samym tempem)
const REVEAL_TIME := 3.0
const REVEAL_REACH := 380.0
const REVEAL_SHADER := """
shader_type canvas_item;
uniform vec2 center;
uniform float radius;
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float d = distance(UV * vec2(textureSize(TEXTURE, 0)), center);
	float glow = 1.0 - clamp(abs(radius - d) / 10.0, 0.0, 1.0);
	COLOR = vec4(mix(c.rgb, vec3(0.75, 0.4, 1.0), glow * 0.7), c.a * clamp((radius - d) / 4.0, 0.0, 1.0));
}
"""
const PAINT_H := 360
const FILL_SIZE := 32
## przy brzegu co tyle pikseli trasy średnio jeden drobiazg z road_bits
const BITS_EVERY := 14.0
## które drobiazgi losować (powtórzenia = częściej): kamyki, koleiny, kałuża, kępki, kwiatki, źdźbła
const BITS_PICK := [0, 1, 3, 3, 4, 6, 8, 9, 10, 8, 9, 13, 14, 15]
## drganie brzegu (jak edge_noise w tools/gen_art.py): [kx, ky, faza, amplituda], okres 16 px
const EDGE_TERMS := [[1, 0, 0.3, 0.5], [0, 1, 1.7, 0.5], [2, 1, 2.1, 0.35],
	[1, -2, 0.9, 0.35], [3, 0, 4.0, 0.2], [0, 3, 5.2, 0.2]]
const PAINT_TEX := {
	"grass": {"fill": "res://assets/terrain/road_fill.png", "edge": "res://assets/terrain/road_edge.png",
		"lit": "res://assets/terrain/road_edge_lit.png", "bits": "res://assets/terrain/road_bits.png"},
	"sand": {"fill": "res://assets/terrain/sand_road_fill.png", "edge": "res://assets/terrain/sand_road_edge.png",
		"lit": "res://assets/terrain/sand_road_edge_lit.png", "bits": "res://assets/terrain/sand_road_bits.png"},
}

@export_tool_button("Wygeneruj cały teren") var generate_terrain_button: Callable = generate_terrain
@export_tool_button("Wygeneruj drogę z tras") var generate_road_button: Callable = generate_road

## wspólny zestaw kafelków (budowany w kodzie, bo zawiera opis terenów dla pędzla)
static var _tileset: TileSet = null

## obrazek drogi malowanej (tworzony w kodzie, nie zapisuje się w scenie)
var _painted: Sprite2D = null
## w grze: obrazek z ukrytymi trasami ("hidden_routes"), niewidoczny do reveal_hidden_road()
var _painted_hidden: Sprite2D = null
var _repaint_queued := false


func _ready() -> void:
	for layer_name in LAYERS:
		_layer(layer_name).tile_set = make_tileset()
	var level := _level_data()
	var painted := _is_painted(level)
	var generators := _generators()
	for layer_name in generators:
		if painted and layer_name == "Droga":
			continue
		if _layer(layer_name).get_used_cells().is_empty():
			generators[layer_name].call(level)
	if painted:
		_paint_road(level)
		if Engine.is_editor_hint():
			for child in get_children():
				if child is Path2D and (child as Path2D).curve != null:
					(child as Path2D).curve.changed.connect(_queue_repaint)


## Punkty tras wrogów w jednostkach gry (każdy Path2D sceny to jedna trasa).
## Przy drodze malowanej trasa jest wygładzona (łuki przez punkty Path2D).
func get_routes() -> Array:
	var smooth := _is_painted(LevelData.scene_data(scene_file_path))
	var tunnels := _tunnel_ends() if smooth else []
	var raw := []
	var routes := []
	for path in _paths():
		raw.append(_route_points(path))
		routes.append(_smooth_route(path, tunnels) if smooth else raw.back())
	if smooth:
		_share_prefixes(raw, routes)
		_share_suffixes(raw, routes)
	return routes


## Końce tuneli i portali z Obiektów: [wejście, wyjście] (prosto ze sceny - get_objects() sam korzysta z get_routes()).
func _tunnel_ends() -> Array:
	var res := []
	var holder := get_node_or_null("Obiekty") as Node2D
	if holder == null:
		return res
	for child in holder.get_children():
		var obj := child as LevelObjectScript
		if obj != null and obj.kind in [LevelObjectScript.Kind.TUNNEL, LevelObjectScript.Kind.PORTAL]:
			res.append([holder.transform * obj.position, holder.transform * obj.marker_position()])
	return res


func _paths() -> Array[Path2D]:
	var paths: Array[Path2D] = []
	for child in get_children():
		if child is Path2D:
			paths.append(child as Path2D)
	return paths


## Trasy z tym samym początkiem (rozwidlenie przy mostach zwodzonych): wygładzony łuk przed punktem
## rozwidlenia zależy też od dalszych punktów, więc bez tego trasy rozchodziłyby się trochę przed nim,
## a wróg zmieniający trasę na rozwidleniu przeskoczyłby w bok. Późniejsza trasa dostaje początek
## wcześniejszej aż do punktu rozwidlenia (ten punkt leży na obu łukach).
static func _share_prefixes(raw: Array, routes: Array) -> void:
	for r in range(1, routes.size()):
		for q in r:
			var shared := 0
			while shared < mini(raw[r].size(), raw[q].size()) and raw[r][shared] == raw[q][shared]:
				shared += 1
			if shared < 2:
				continue
			var fork: Vector2 = raw[r][shared - 1]
			var cut_q := _nearest_index(fork, routes[q])
			var cut_r := _nearest_index(fork, routes[r])
			routes[r] = routes[q].slice(0, cut_q + 1) + routes[r].slice(cut_r + 1)
			break


## Trasy z tym samym końcem (trasa dołącza do innej): łuk za punktem złączenia zależy też od wcześniejszych
## punktów, więc bez tego wspólny odcinek obu tras różniłby się trochę i malował podwójnie. Późniejsza trasa
## od punktu złączenia (pierwszego wspólnego punktu Path2D) dostaje dalszą część wcześniejszej.
## Gdy pasuje kilka wcześniejszych tras, bierze tę z najdłuższym wspólnym końcem (np. dwa wejścia i dwa mosty).
static func _share_suffixes(raw: Array, routes: Array) -> void:
	for r in range(1, routes.size()):
		var best_q := -1
		var best_shared := 1
		for q in r:
			var size_r: int = raw[r].size()
			var size_q: int = raw[q].size()
			var shared := 0
			while shared < mini(size_r, size_q) and raw[r][size_r - 1 - shared] == raw[q][size_q - 1 - shared]:
				shared += 1
			if shared > best_shared:
				best_q = q
				best_shared = shared
		if best_q < 0:
			continue
		var join: Vector2 = raw[r][raw[r].size() - best_shared]
		var cut_q := _nearest_index(join, routes[best_q])
		var cut_r := _nearest_index(join, routes[r])
		routes[r] = routes[r].slice(0, cut_r) + routes[best_q].slice(cut_q)


## Numer punktu trasy w grze dla numeru punktu Path2D (droga malowana ma gęstsze punkty,
## ale łuk przechodzi przez punkty Path2D).
func _game_point_index(route: int, path_point: int, routes: Array) -> int:
	if not _is_painted(LevelData.scene_data(scene_file_path)):
		return path_point
	return _nearest_index(_route_points(_paths()[route])[path_point], routes[route])


static func _route_points(path: Path2D) -> Array:
	var points := []
	for i in path.curve.point_count:
		points.append(path.transform * path.curve.get_point_position(i))
	return points


## Wygładzona trasa. Gdy w edytorze wyciągnięto uchwyty punktów Path2D, łuki idą po nich;
## bez uchwytów - spline Catmulla-Roma (dośrodkowy) przez punkty. Trzy punkty w linii = prosty odcinek
## (np. most: punkt przed, oba końce mostu i punkt za nim w jednej linii).
## Tunel (tunnels: [wejście, wyjście] na kolejnych punktach Path2D) zostaje prostym odcinkiem między
## dokładnymi punktami, a łuki przed i za nim liczą się osobno (bez uchwytów).
static func _smooth_route(path: Path2D, tunnels: Array) -> Array:
	var curve := path.curve
	var has_handles := false
	for i in curve.point_count:
		if curve.get_point_in(i) != Vector2.ZERO or curve.get_point_out(i) != Vector2.ZERO:
			has_handles = true
	if has_handles:
		var res := []
		for p in curve.tessellate_even_length(5, ARC_STEP):
			_append_distinct_or_first(res, path.transform * p)
		return res
	var smoothed := []
	for piece in _split_at_tunnels(_route_points(path), tunnels):
		smoothed.append_array(_catmull_rom(piece))
	return smoothed


## Trasa pocięta w miejscach tuneli: odcinek od wejścia do wyjścia (z dokładnością do 1 jednostki)
## rozdziela kawałki, a sam do żadnego nie należy. tunnels: lista [wejście, wyjście].
static func _split_at_tunnels(points: Array, tunnels: Array) -> Array:
	var pieces := []
	var piece := [points[0]]
	for i in range(1, points.size()):
		var a: Vector2 = points[i - 1]
		var b: Vector2 = points[i]
		if tunnels.any(func(t: Array) -> bool: return a.distance_to(t[0]) < 1.0 and b.distance_to(t[1]) < 1.0):
			pieces.append(piece)
			piece = []
		piece.append(b)
	pieces.append(piece)
	return pieces


static func _catmull_rom(points: Array) -> Array:
	if points.size() < 3:
		return points.duplicate()
	var first: Vector2 = points[0]
	var last: Vector2 = points[points.size() - 1]
	# dopisane punkty za końcami, żeby trasa wchodziła i wychodziła prosto
	var pts := [2.0 * first - points[1]]
	pts.append_array(points)
	pts.append(2.0 * last - points[points.size() - 2])
	var res := [first]
	for i in range(1, pts.size() - 2):
		var p0: Vector2 = pts[i - 1]
		var p1: Vector2 = pts[i]
		var p2: Vector2 = pts[i + 1]
		var p3: Vector2 = pts[i + 2]
		var t1 := sqrt(maxf(p0.distance_to(p1), 0.001))
		var t2 := t1 + sqrt(maxf(p1.distance_to(p2), 0.001))
		var t3 := t2 + sqrt(maxf(p2.distance_to(p3), 0.001))
		var steps := maxi(1, ceili(p1.distance_to(p2) / ARC_STEP))
		for s in range(1, steps + 1):
			var t := lerpf(t1, t2, float(s) / steps)
			var a1 := p0.lerp(p1, t / t1)
			var a2 := p1.lerp(p2, (t - t1) / (t2 - t1))
			var a3 := p2.lerp(p3, (t - t2) / (t3 - t2))
			var b1 := a1.lerp(a2, t / t2)
			var b2 := a2.lerp(a3, (t - t1) / (t3 - t1))
			_append_distinct(res, b1.lerp(b2, (t - t1) / (t2 - t1)))
	# dokładnie ostatni punkt (koniec tunelu musi być punktem trasy)
	res[res.size() - 1] = last
	return res


static func _append_distinct_or_first(points: Array, p: Vector2) -> void:
	if points.is_empty():
		points.append(p)
	else:
		_append_distinct(points, p)


## Bez powtórzonych punktów - odcinek zerowej długości psułby liczenie pozycji na trasie.
static func _append_distinct(points: Array, p: Vector2) -> void:
	if (points.back() as Vector2).distance_to(p) > 0.01:
		points.append(p)


static func _is_painted(level: Dictionary) -> bool:
	return level.get("road", "") == "painted"


## Środki miejsc budowy w kolejności z drzewa sceny.
func get_spots() -> Array:
	var holder: Node2D = $MiejscaNaWieze
	var positions := []
	for child in holder.get_children():
		if child is Node2D:
			positions.append(holder.transform * (child as Node2D).position)
	return positions


## Obiekty z węzła "Obiekty" jako klucze danych poziomu (opis w data/level_data.gd):
## fixed_bridges, bridges, tunnels, portals, archer_posts, ship, hero, palms, war_towers, special_tower.
func get_objects() -> Dictionary:
	var res := {}
	var holder := get_node_or_null("Obiekty") as Node2D
	if holder == null:
		return res
	var routes := get_routes()
	for child in holder.get_children():
		var obj := child as LevelObjectScript
		if obj == null:
			continue
		var pos := holder.transform * obj.position
		var marker := holder.transform * obj.marker_position()
		match obj.kind:
			LevelObjectScript.Kind.BRIDGE:
				_append(res, "fixed_bridges",
					{"a": pos, "b": holder.transform * obj.bridge_end(), "vertical": obj.vertical})
			LevelObjectScript.Kind.DRAWBRIDGE:
				_append(res, "bridges", {"a": pos, "b": holder.transform * obj.bridge_end(), "name": obj.bridge_name,
					"route": obj.route, "zone_from": _game_point_index(obj.route, obj.zone_from, routes),
					"zone_to": _game_point_index(obj.route, obj.zone_to, routes)})
			LevelObjectScript.Kind.TUNNEL:
				_append(res, "tunnels", {"a": _nearest_route_point(pos, routes), "b": _nearest_route_point(marker, routes)})
			LevelObjectScript.Kind.PORTAL:
				_append(res, "portals", {"a": _nearest_route_point(pos, routes), "b": _nearest_route_point(marker, routes)})
			LevelObjectScript.Kind.ARCHER_NEST:
				_append(res, "archer_posts", pos)
			LevelObjectScript.Kind.SHIP:
				res["ship"] = {"pos": pos, "aim": marker}
			LevelObjectScript.Kind.HERO:
				res["hero"] = pos
			LevelObjectScript.Kind.PALM:
				_append(res, "palms", {"pos": pos, "center": marker, "radius": obj.radius})
			LevelObjectScript.Kind.WAR_TOWER:
				_append(res, "war_towers", {"pos": pos, "center": marker, "radius": obj.radius})
			LevelObjectScript.Kind.KNIGHT_TOWER:
				res["special_tower"] = _nearest_index(pos, get_spots())
	return res


static func _append(res: Dictionary, key: String, value: Variant) -> void:
	if not res.has(key):
		res[key] = []
	res[key].append(value)


## Najbliższy punkt którejkolwiek trasy (końce tuneli muszą być dokładnie punktami tras).
static func _nearest_route_point(p: Vector2, routes: Array) -> Vector2:
	var all := []
	for route in routes:
		all.append_array(route)
	var i := _nearest_index(p, all)
	return all[i] if i >= 0 else p


static func _nearest_index(p: Vector2, points: Array) -> int:
	var best := -1
	for i in points.size():
		if best < 0 or p.distance_squared_to(points[i]) < p.distance_squared_to(points[best]):
			best = i
	return best


## Układa od nowa wszystkie warstwy. Nadpisuje ręczne zmiany kafelków.
func generate_terrain() -> void:
	var level := _level_data()
	for generator in _generators().values():
		generator.call(level)


## Układa od nowa drogi wzdłuż tras (także skosy). Nadpisuje ręcznie malowane drogi.
func generate_road() -> void:
	_generate_road(_level_data())


## Dane poziomu (data/levels/) uzupełnione o obiekty ze sceny (dla generatora).
func _level_data() -> Dictionary:
	var level := LevelData.scene_data(scene_file_path).duplicate()
	level.merge(get_objects(), true)
	return level


## Warstwa -> funkcja, która ją wypełnia (DrogaSkos wypełnia się razem z Drogą).
func _generators() -> Dictionary:
	return {
		"Trawa": _generate_grass, "Piasek": _generate_sand, "Woda": _generate_water,
		"Piana": _generate_foam, "Droga": _generate_road, "Gory": _generate_mountains,
	}


func _layer(layer_name: String) -> TileMapLayer:
	return get_node(layer_name) as TileMapLayer


func _generate_grass(_level: Dictionary) -> void:
	var grass := _layer("Trawa")
	var rng := _new_rng()
	grass.clear()
	for y in ROWS:
		for x in COLS:
			grass.set_cell(Vector2i(x, y), SRC_GRASS, Vector2i(rng.randi_range(0, 3), 0))


func _generate_sand(level: Dictionary) -> void:
	_paint_corners(_layer("Piasek"), func(p: Vector2) -> bool: return _on_sand(p, level),
		func(_center: Vector2) -> int: return SRC_SAND)


## Rzeki i kałuże ze zwykłym brzegiem, morze (i woda przy piasku) z brzegiem pod plażę.
func _generate_water(level: Dictionary) -> void:
	_paint_corners(_layer("Woda"), func(p: Vector2) -> bool: return _in_water(p, level),
		func(center: Vector2) -> int: return SRC_SEA if _on_sand(center, level) or _in_sea(center, level) else SRC_WATER)


func _generate_foam(level: Dictionary) -> void:
	_paint_corners(_layer("Piana"), func(p: Vector2) -> bool: return _in_sea(p, level) and not _on_island(p, level),
		func(_center: Vector2) -> int: return SRC_FOAM)


func _generate_mountains(level: Dictionary) -> void:
	_paint_corners(_layer("Gory"), func(p: Vector2) -> bool: return _in_any(p, level.get("mountains", [])),
		func(_center: Vector2) -> int: return SRC_MOUNTAIN)


## Proste odcinki tras: kafelki po rogach (bez tuneli i wody). Skosy 45°: gotowe układy kafelków
## na warstwie DrogaSkos. Poziom z plażą ma w całości drogę na piasku (bez szwów na granicy plaży).
func _generate_road(level: Dictionary) -> void:
	if _is_painted(level):
		_layer("Droga").clear()
		_layer("DrogaSkos").clear()
		_paint_road(level)
		return
	var sandy := level.has("beach")
	var straight := []
	var diagonal := []
	var tunnels: Array = level.get("tunnels", [])
	for route in get_routes():
		for i in range(1, route.size()):
			var a: Vector2 = route[i - 1]
			var b: Vector2 = route[i]
			if tunnels.any(func(t: Dictionary) -> bool: return a == t.a and b == t.b):
				continue
			var d := b - a
			if d.x != 0 and absf(d.x) == absf(d.y):
				diagonal.append([route, i])
			else:
				straight.append([a, b])
	_paint_corners(_layer("Droga"),
		func(p: Vector2) -> bool: return _distance_to_segments(p, straight) <= ROAD_REACH and not _in_water(p, level),
		func(_center: Vector2) -> int: return SRC_SAND_ROAD if sandy else SRC_ROAD)
	var diagonal_layer := _layer("DrogaSkos")
	diagonal_layer.clear()
	for item in diagonal:
		_stamp_diagonal(diagonal_layer, item[0], item[1], straight, SRC_SAND_DIAGONAL if sandy else SRC_DIAGONAL)


## W edytorze: przemalowanie drogi chwilę po zmianie trasy (nie przy każdym ruchu myszy).
func _queue_repaint() -> void:
	if _repaint_queued or not is_inside_tree():
		return
	_repaint_queued = true
	await get_tree().create_timer(0.3).timeout
	_repaint_queued = false
	_paint_road(_level_data())


## Droga malowana wzdłuż tras (opis w assets/README_grafiki.md, "Droga malowana wzdłuż trasy"):
## k = odległość piksela od trasy minus granica drogi w tym miejscu (_edge_table);
## brzeg dostaje kolor road_edge[floor(-k)], a głębiej road_fill.
func _paint_road(level: Dictionary) -> void:
	var tex: Dictionary = PAINT_TEX["sand" if level.has("beach") else "grass"]
	var fill := _load_image(tex.fill)
	var edge := _load_image(tex.edge)
	var lit := _load_image(tex.lit)
	var bits := _load_image(tex.bits)
	if fill == null or edge == null or bits == null:
		return
	if lit == null:
		lit = edge
	# odcinki tras w pikselach grafiki: [a, b, dystans od początku trasy do a, numer trasy]
	var segments := []
	var edges := []
	var routes := get_routes()
	var bridges := []
	for br in level.get("fixed_bridges", []) + level.get("bridges", []):
		bridges.append([br.a / PIXEL, br.b / PIXEL])
	# portale też się nie malują (wróg przeskakuje z wejścia do wyjścia)
	var tunnels := []
	for t in level.get("tunnels", []) + level.get("portals", []):
		tunnels.append([t.a, t.b])
	var unpainted: Array = level.get("unpainted_routes", [])
	# w edytorze widać wszystkie drogi, w grze ukryte trasy są na osobnym obrazku
	var hidden_routes: Array = [] if Engine.is_editor_hint() else level.get("hidden_routes", [])
	var painted_routes := []
	for r in routes.size():
		# do malowania wystarczy mniej punktów (łuki zostają gładkie z dokładnością do 0,3 px);
		# tunele się nie malują - kawałki trasy między nimi upraszcza się osobno
		var route := []
		var jump_at := {}
		var pieces := []
		for piece in _split_at_tunnels(routes[r], tunnels):
			if not route.is_empty():
				jump_at[route.size()] = true
			var simple := []
			for q in _simplify(piece, 0.3 * PIXEL):
				simple.append(q / PIXEL)
			route.append_array(simple)
			pieces.append(simple)
		var length := 0.0
		for i in range(1, route.size()):
			var a: Vector2 = route[i - 1]
			var b: Vector2 = route[i]
			# odcinek wspólny z wcześniejszą trasą maluje tylko ona (inaczej brzegi obu tras by się nakładały)
			if not jump_at.has(i) and not unpainted.has(r) \
					and not (_near_routes(a, painted_routes) and _near_routes(b, painted_routes)):
				segments.append([a, b, length, r])
			length += a.distance_to(b)
		if not unpainted.has(r):
			painted_routes.append_array(pieces)
		var bend := _bend_table(routes[r], length)
		var taper := _bridge_table(route, length, bridges)
		edges.append([_edge_table(length, r, 0, bend, taper), _edge_table(length, r, 1, bend, taper)])
	var visible_segments := segments.filter(func(seg: Array) -> bool: return not hidden_routes.has(seg[3]))
	var water := _water_lookup(level)
	_painted = _road_sprite(_painted, "DrogaMalowana",
		_road_image(visible_segments, edges, fill, edge, lit, bits, water), _layer("DrogaSkos").get_index() + 1)
	if visible_segments.size() < segments.size():
		_painted_hidden = _road_sprite(_painted_hidden, "DrogaUkryta",
			_road_image(segments, edges, fill, edge, lit, bits, water), _painted.get_index() + 1)
		_painted_hidden.visible = false


## Pokazuje drogę ukrytych tras poziomu ("hidden_routes"): rozlewa się okręgiem z punktu from
## (współrzędne gry) z fioletową poświatą na brzegu; trwa REVEAL_TIME s.
func reveal_hidden_road(from: Vector2) -> void:
	if _painted_hidden == null:
		return
	var mat := ShaderMaterial.new()
	mat.shader = Shader.new()
	mat.shader.code = REVEAL_SHADER
	mat.set_shader_parameter("center", from / PIXEL)
	mat.set_shader_parameter("radius", 0.0)
	_painted_hidden.material = mat
	_painted_hidden.visible = true
	var reach := Vector2(PAINT_W, PAINT_H).length()
	create_tween().tween_method(func(r: float) -> void: mat.set_shader_parameter("radius", r),
		0.0, reach, REVEAL_TIME * reach / REVEAL_REACH)


## Obrazek drogi z podanych odcinków (opis w _paint_road).
func _road_image(segments: Array, edges: Array, fill: Image, edge: Image, lit: Image, bits: Image,
		water: Callable) -> Image:
	# dla każdego piksela najbliższa droga, liczona tylko w otoczeniu odcinków
	var count := PAINT_W * PAINT_H
	var key := PackedFloat32Array()
	key.resize(count)
	key.fill(1e9)
	var off_x := PackedFloat32Array()
	off_x.resize(count)
	var off_y := PackedFloat32Array()
	off_y.resize(count)
	var reach := HALF_MID + HALF_AMP + HALF_BEND + EDGE_SMOOTH + EDGE_ROUGH + 2.0
	var reach_sq := reach * reach
	for seg in segments:
		var a: Vector2 = seg[0]
		var b: Vector2 = seg[1]
		var start: float = seg[2]
		var tables: Array = edges[seg[3]]
		var dir := b - a
		var len_sq := dir.length_squared()
		var length := sqrt(len_sq)
		var x0 := maxi(0, floori(minf(a.x, b.x) - reach))
		var x1 := mini(PAINT_W - 1, ceili(maxf(a.x, b.x) + reach))
		var y0 := maxi(0, floori(minf(a.y, b.y) - reach))
		var y1 := mini(PAINT_H - 1, ceili(maxf(a.y, b.y) + reach))
		for y in range(y0, y1 + 1):
			for x in range(x0, x1 + 1):
				var p := Vector2(x + 0.5, y + 0.5)
				var t := 0.0 if len_sq < 0.000001 else clampf((p - a).dot(dir) / len_sq, 0.0, 1.0)
				var off := p - (a + dir * t)
				if off.length_squared() > reach_sq:
					continue
				# lewa i prawa strona drogi falują niezależnie
				var table: PackedFloat32Array = tables[1 if dir.cross(off) >= 0.0 else 0]
				var k := y * PAINT_W + x
				var v := off.length() - table[mini(floori(start + t * length), table.size() - 1)]
				if v < key[k]:
					key[k] = v
					off_x[k] = off.x
					off_y[k] = off.y
	var jitter := _edge_noise_table()
	var inner := edge.get_pixel(7, 0)
	var img := Image.create_empty(PAINT_W, PAINT_H, false, Image.FORMAT_RGBA8)
	for y in PAINT_H:
		for x in PAINT_W:
			var k := y * PAINT_W + x
			if key[k] > 1.0:
				continue
			var i := floori(jitter[(y % 16) * 16 + x % 16] - key[k])
			if i < 0 or water.call(Vector2(x + 0.5, y + 0.5) * PIXEL):
				continue
			var color := fill.get_pixel(x % FILL_SIZE, y % FILL_SIZE)
			if i < 8:
				# strona światła: brzeg, którego normalna wskazuje w prawo-dół
				var d := Vector2(off_x[k], off_y[k]).length()
				var on_lit := d > 0.000001 and (off_x[k] + off_y[k]) / d > 0.35
				var c := (lit if on_lit else edge).get_pixel(i, 0)
				if c != inner:
					color = c
			img.set_pixel(x, y, color)
	_scatter_bits(img, bits, segments, edges, water)
	return img


## Sprite2D z obrazkiem drogi (tworzony przy pierwszym malowaniu, potem tylko podmiana tekstury).
func _road_sprite(sprite: Sprite2D, sprite_name: String, img: Image, index: int) -> Sprite2D:
	if sprite == null:
		sprite = Sprite2D.new()
		sprite.name = sprite_name
		sprite.centered = false
		sprite.scale = Vector2(PIXEL, PIXEL)
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(sprite)
		move_child(sprite, index)
	sprite.texture = ImageTexture.create_from_image(img)
	return sprite


## Czy punkt leży (z dokładnością do 1 px) na którejś z tras (w pikselach grafiki).
static func _near_routes(p: Vector2, routes: Array) -> bool:
	for route in routes:
		for i in range(1, route.size()):
			if p.distance_to(Geometry2D.get_closest_point_to_segment(p, route[i - 1], route[i])) < 1.0:
				return true
	return false


## Linia uproszczona algorytmem Douglasa-Peuckera: zostają punkty odstające o więcej niż tolerance.
static func _simplify(points: Array, tolerance: float) -> Array:
	if points.size() < 3:
		return points.duplicate()
	var keep := []
	keep.resize(points.size())
	keep.fill(false)
	keep[0] = true
	keep[points.size() - 1] = true
	var stack := [[0, points.size() - 1]]
	while not stack.is_empty():
		var range_ij: Array = stack.pop_back()
		var i: int = range_ij[0]
		var j: int = range_ij[1]
		var best := tolerance
		var best_k := -1
		for k in range(i + 1, j):
			var q: Vector2 = Geometry2D.get_closest_point_to_segment(points[k], points[i], points[j])
			var d := q.distance_to(points[k])
			if d > best:
				best = d
				best_k = k
		if best_k >= 0:
			keep[best_k] = true
			stack.append([i, best_k])
			stack.append([best_k, j])
	var res := []
	for k in points.size():
		if keep[k]:
			res.append(points[k])
	return res


## Granica drogi (połowa szerokości + fale brzegu) dla każdego piksela długości trasy.
## side: 0 = lewa, 1 = prawa strona; szerokość jest wspólna, fale brzegu osobne.
## bend: 0..1 - jak ciasny jest zakręt w danym miejscu (_bend_table);
## taper: 0..1 - jak blisko mostu (_bridge_table), tam droga ma szerokość mostu i równe brzegi.
static func _edge_table(length: float, route: int, side: int, bend: PackedFloat32Array,
		taper: PackedFloat32Array) -> PackedFloat32Array:
	var table := PackedFloat32Array()
	table.resize(ceili(length) + 1)
	var phase := route * 1.9
	for s in table.size():
		var rough := clampf((_wave(s, ROUGH_WAVES, phase + 4.4) - ROUGH_FROM) / (ROUGH_FULL - ROUGH_FROM), 0.0, 1.0)
		var half := HALF_MID + HALF_AMP * _wave(s, WIDTH_WAVES, phase + 0.7) 			+ HALF_BEND * bend[mini(s, bend.size() - 1)] 			+ (EDGE_SMOOTH + EDGE_ROUGH * rough) * _wave(s, EDGE_WAVES, phase + 2.1 + side * 3.7)
		table[s] = lerpf(half, BRIDGE_HALF, taper[mini(s, taper.size() - 1)])
	return table


## Bliskość mostu dla każdego piksela długości trasy: 1 = na moście, 0 = dalej niż BRIDGE_TAPER px.
## route i bridges ([a, b]) w pikselach grafiki.
static func _bridge_table(route: Array, length: float, bridges: Array) -> PackedFloat32Array:
	var table := PackedFloat32Array()
	table.resize(ceili(length) + 1)
	if bridges.is_empty():
		return table
	var s := 0.0
	for i in range(1, route.size()):
		var a: Vector2 = route[i - 1]
		var b: Vector2 = route[i]
		var seg_len := a.distance_to(b)
		var n := maxi(1, ceili(seg_len))
		for j in n + 1:
			var p := a.lerp(b, float(j) / n)
			var d := INF
			for br in bridges:
				d = minf(d, p.distance_to(Geometry2D.get_closest_point_to_segment(p, br[0], br[1])))
			var idx := mini(floori(s + seg_len * j / n), table.size() - 1)
			table[idx] = maxf(table[idx], 1.0 - smoothstep(0.0, BRIDGE_TAPER, d))
		s += seg_len
	return table


## Ciasność zakrętów wzdłuż trasy (0 = prosto, 1 = łuk o promieniu BEND_RADIUS lub ciaśniejszy),
## rozmyta na ±BEND_SPREAD px, żeby poszerzenie narastało łagodnie. route w jednostkach gry.
static func _bend_table(route: Array, length: float) -> PackedFloat32Array:
	var table := PackedFloat32Array()
	table.resize(ceili(length) + 1)
	var s := 0.0
	for i in range(1, route.size() - 1):
		var a: Vector2 = route[i - 1] / PIXEL
		var v: Vector2 = route[i] / PIXEL
		var b: Vector2 = route[i + 1] / PIXEL
		s += a.distance_to(v)
		var angle := absf((v - a).angle_to(b - v))
		var k := clampf(angle / ((a.distance_to(v) + v.distance_to(b)) / 2.0) * BEND_RADIUS, 0.0, 1.0)
		for d in range(-BEND_SPREAD, BEND_SPREAD + 1):
			var idx := floori(s) + d
			if idx >= 0 and idx < table.size():
				table[idx] = maxf(table[idx], k * (1.0 - absf(d) / (BEND_SPREAD + 1.0)))
	return table


## Suma kilku sinusów o różnych okresach: łagodna, nieregularna fala w zakresie ok. -1..1.
static func _wave(s: float, waves: Array, phase: float) -> float:
	var sum := 0.0
	for k in waves.size():
		sum += waves[k][1] * sin(TAU * s / waves[k][0] + phase * (k + 1.3))
	return sum / 1.1


## Drobiazgi (kamyki, kępki trawy) rozrzucone wzdłuż brzegów drogi, zawsze w tych samych miejscach.
func _scatter_bits(img: Image, bits: Image, segments: Array, edges: Array, water: Callable) -> void:
	var total := 0.0
	for seg in segments:
		total += (seg[0] as Vector2).distance_to(seg[1])
	if total <= 0.0:
		return
	var rng := _new_rng()
	for n in int(total / BITS_EVERY):
		var seg: Array = segments[rng.randi_range(0, segments.size() - 1)]
		var a: Vector2 = seg[0]
		var b: Vector2 = seg[1]
		var t := rng.randf()
		var side := rng.randi_range(0, 1)
		var table: PackedFloat32Array = edges[seg[3]][side]
		var length := a.distance_to(b)
		if length < 0.001:
			continue
		var boundary := table[mini(floori(seg[2] + t * length), table.size() - 1)]
		# normalna w stronę danej strony drogi (prawa = obrót kierunku o 90° zgodnie z dir.cross > 0)
		var normal := Vector2(-(b - a).y, (b - a).x) / length * (1.0 if side == 1 else -1.0)
		var center := a.lerp(b, t) + normal * (boundary + rng.randf_range(-6.0, 1.0))
		if water.call(center * PIXEL):
			continue
		var idx: int = BITS_PICK[rng.randi_range(0, BITS_PICK.size() - 1)]
		var src := Rect2i((idx % 8) * 8, floori(idx / 8.0) * 8, 8, 8)
		img.blend_rect(bits, src, Vector2i(floori(center.x) - 4, floori(center.y) - 4))


## Szybsze _in_water dla wielu punktów: wielokąty przygotowane raz.
static func _water_lookup(level: Dictionary) -> Callable:
	var water: Array[PackedVector2Array] = []
	for poly in level.get("ponds", []):
		water.append(PackedVector2Array(poly))
	for key in ["river", "sea"]:
		if level.has(key):
			water.append(PackedVector2Array(level[key]))
	var islands: Array[PackedVector2Array] = []
	for poly in level.get("islands", []):
		islands.append(PackedVector2Array(poly))
	# prostokąt obejmujący całą wodę - większość punktów odpada od razu
	var bounds := Rect2()
	for i in water.size():
		var rect := Rect2(water[i][0], Vector2.ZERO)
		for q in water[i]:
			rect = rect.expand(q)
		bounds = rect if i == 0 else bounds.merge(rect)
	return func(p: Vector2) -> bool:
		if water.is_empty() or not bounds.has_point(p):
			return false
		if not water.any(func(poly: PackedVector2Array) -> bool: return Geometry2D.is_point_in_polygon(p, poly)):
			return false
		return not islands.any(func(poly: PackedVector2Array) -> bool: return Geometry2D.is_point_in_polygon(p, poly))


## Drganie brzegu ±1 px dla każdego piksela kafelka 16×16 (powtarza się bez szwów).
static func _edge_noise_table() -> PackedFloat32Array:
	var table := PackedFloat32Array()
	table.resize(256)
	for y in 16:
		for x in 16:
			var s := 0.0
			for term in EDGE_TERMS:
				s += term[3] * sin(TAU * (term[0] * (x + 0.5) + term[1] * (y + 0.5)) / 16.0 + term[2])
			table[y * 16 + x] = EDGE_JITTER * s / 2.1
	return table


## Obrazek z tekstury projektu; świeżo dodany plik (jeszcze bez importu) czyta prosto z dysku.
static func _load_image(path: String) -> Image:
	var img: Image = null
	if ResourceLoader.exists(path):
		img = (load(path) as Texture2D).get_image()
	elif FileAccess.file_exists(path):
		img = Image.load_from_file(ProjectSettings.globalize_path(path))
	if img == null:
		return null
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	return img


## Kafelki skosu od punktu route[i - 1] do route[i] (kolejność dowolna) według DIAGONAL.
func _stamp_diagonal(layer: TileMapLayer, route: Array, i: int, straight: Array, source: int) -> void:
	var top: Vector2 = route[i - 1]
	var bottom: Vector2 = route[i]
	var beyond: Variant = route[i + 1] if i + 1 < route.size() else null
	if top.y > bottom.y:
		top = route[i]
		bottom = route[i - 1]
		beyond = route[i - 2] if i >= 2 else null
	var dir := 1 if bottom.x > top.x else -1
	var shape: Dictionary = DIAGONAL[dir]
	var c0 := floori(top.x / CELL)
	var r0 := floori(top.y / CELL)
	var r1 := floori(bottom.y / CELL)
	var rows := {r0: shape.entry[0], r0 + 1: shape.entry[1]}
	for r in range(r0 + 2, r1 - 1):
		rows[r] = shape.middle
	var exit: Array = _diagonal_exit(shape, dir, bottom, beyond, straight)
	for k in exit.size():
		rows[r1 - 1 + k] = exit[k]
	for r: int in rows:
		# kolumna środka drogi przesuwa się o 1 na wiersz aż do dolnego końca skosu
		var center: int = c0 + dir * mini(r - r0, r1 - r0)
		var first: int = rows[r][0]
		var ids: Array = rows[r][1]
		for k in ids.size():
			var cell := Vector2i(center + first + k, r)
			if cell.x >= 0 and cell.x < COLS and cell.y >= 0 and cell.y < ROWS:
				layer.set_cell(cell, source, _diagonal_coords(ids[k]))


## Położenie kafelka o numerze i w atlasie skośnej drogi.
static func _diagonal_coords(i: int) -> Vector2i:
	return Vector2i(i % DIAGONAL_COLUMNS, floori(i / float(DIAGONAL_COLUMNS)))


## Zakończenie skosu: skrzyżowanie, gdy w dolnym końcu spotykają się co najmniej 2 proste odcinki;
## inaczej pionowe lub poziome, zależnie od dalszego przebiegu trasy.
static func _diagonal_exit(shape: Dictionary, dir: int, bottom: Vector2, beyond: Variant, straight: Array) -> Array:
	var touching := {}
	for s in straight:
		if s[0] == bottom or s[1] == bottom:
			touching[s] = true
	if touching.size() >= 2 or beyond == null:
		return shape.exit_junction
	var next: Vector2 = beyond
	if next.x == bottom.x:
		return shape.exit_vertical
	if signf(next.x - bottom.x) == dir:
		return shape.exit_horizontal
	return shape.exit_junction


## Kafelki dopasowane po rogach: róg (punkt siatki co CELL) należy do terenu, gdy inside(róg) == true,
## a kafelek wybierany jest z maski swoich 4 rogów. source_at(środek kafelka) wybiera atlas.
func _paint_corners(layer: TileMapLayer, inside: Callable, source_at: Callable) -> void:
	var rng := _new_rng()
	var corners := {}
	for y in ROWS + 1:
		for x in COLS + 1:
			corners[Vector2i(x, y)] = inside.call(Vector2(x, y) * CELL)
	layer.clear()
	for y in ROWS:
		for x in COLS:
			var mask := 0
			for k in 4:
				if corners[Vector2i(x + (k & 1), y + (k >> 1))]:
					mask |= 1 << k
			if mask == 0:
				continue
			var source: int = source_at.call((Vector2(x, y) + Vector2(0.5, 0.5)) * CELL)
			layer.set_cell(Vector2i(x, y), source, _corner_tile(source, mask, rng))


static func _corner_tile(source: int, mask: int, rng: RandomNumberGenerator) -> Vector2i:
	if source in [SRC_WATER, SRC_SEA, SRC_FOAM]:
		return Vector2i(0, mask)
	if mask == 15 and rng.randf() < VARIANT_CHANCE:
		return Vector2i(rng.randi_range(0, 3), 4)
	return Vector2i(mask & 3, mask >> 2)


static func _distance_to_segments(p: Vector2, segments: Array) -> float:
	var best := INF
	for s in segments:
		best = minf(best, p.distance_to(Geometry2D.get_closest_point_to_segment(p, s[0], s[1])))
	return best


static func _on_sand(p: Vector2, level: Dictionary) -> bool:
	return _on_island(p, level) or (level.has("beach") and _in_any(p, [level.beach]))


static func _on_island(p: Vector2, level: Dictionary) -> bool:
	return _in_any(p, level.get("islands", []))


static func _in_sea(p: Vector2, level: Dictionary) -> bool:
	return level.has("sea") and _in_any(p, [level.sea])


## Rzeka, kałuże albo morze (poza wysepkami).
static func _in_water(p: Vector2, level: Dictionary) -> bool:
	var polygons: Array = level.get("ponds", []).duplicate()
	for key in ["river", "sea"]:
		if level.has(key):
			polygons.append(level[key])
	return _in_any(p, polygons) and not _on_island(p, level)


static func _in_any(p: Vector2, polygons: Array) -> bool:
	return polygons.any(func(poly: Array) -> bool: return Geometry2D.is_point_in_polygon(p, PackedVector2Array(poly)))


## Stałe ziarno - ten sam poziom zawsze wygeneruje się tak samo.
static func _new_rng() -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	return rng


static func make_tileset() -> TileSet:
	if _tileset != null:
		return _tileset
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)
	var grass := _add_source(ts, SRC_GRASS, GRASS_TEX)
	for i in 4:
		grass.create_tile(Vector2i(i, 0))
	for s in TERRAIN_SETS.size():
		ts.add_terrain_set()
		ts.set_terrain_set_mode(s, TileSet.TERRAIN_MODE_MATCH_CORNERS)
		var names: Array = TERRAIN_SETS[s][2]
		for t in names.size():
			ts.add_terrain(s)
			ts.set_terrain_name(s, t, names[t])
			ts.set_terrain_color(s, t, (TERRAIN_SETS[s][1] as Color).darkened(0.3 * t))
	for o in OVERLAYS:
		var source := _add_source(ts, o.source, o.texture)
		for mask in range(1, 16):
			var coords := Vector2i(0, mask) if o.animated else Vector2i(mask & 3, mask >> 2)
			_add_corner_tile(source, coords, o, mask, 1.0)
			if o.animated:
				source.set_tile_animation_frames_count(coords, WATER_FRAMES)
				source.set_tile_animation_speed(coords, WATER_FPS)
		if not o.animated:
			for i in 4:
				_add_corner_tile(source, Vector2i(i, 4), o, 15, 0.25)
	for id: int in DIAGONAL_TEX:
		var source := _add_source(ts, id, DIAGONAL_TEX[id])
		for i in DIAGONAL_TILES:
			source.create_tile(_diagonal_coords(i))
	_tileset = ts
	return ts


static func _add_source(ts: TileSet, id: int, texture_path: String) -> TileSetAtlasSource:
	var source := TileSetAtlasSource.new()
	source.texture = load(texture_path)
	source.texture_region_size = Vector2i(TILE, TILE)
	ts.add_source(source, id)
	return source


## Kafelek nakładki o z rogami według maski (róg poza terenem = -1, czyli pusto).
static func _add_corner_tile(source: TileSetAtlasSource, coords: Vector2i, o: Dictionary, mask: int, probability: float) -> void:
	source.create_tile(coords)
	var data := source.get_tile_data(coords, 0)
	data.terrain_set = o.terrain_set
	data.terrain = o.terrain
	data.probability = probability
	for k in 4:
		data.set_terrain_peering_bit(CORNERS[k], o.terrain if mask & (1 << k) else -1)
