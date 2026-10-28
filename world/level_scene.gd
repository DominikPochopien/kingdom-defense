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
##   Trasa1, Trasa2, ... - trasy wrogów (Path2D, w kolejności z drzewa sceny). Dla ładnej drogi
##       punkty leżą na środkach kafelków (32k + 16), a skosy mają dokładnie 45°. Mosty zwodzone
##       i tunele z danych poziomu wskazują punkty tras, więc tam punktów nie przestawiaj.
## Generator bierze wodę, piasek, góry i tunele z danych poziomu (data/levels/, klucze river, ponds,
## sea, beach, islands, mountains, tunnels). Przy otwarciu sceny wypełnia tylko puste warstwy.
## Pixel art: 1 piksel obrazka = 2 jednostki gry, kafelek = 32 jednostki.

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

@export_tool_button("Wygeneruj cały teren") var generate_terrain_button: Callable = generate_terrain
@export_tool_button("Wygeneruj drogę z tras") var generate_road_button: Callable = generate_road

## wspólny zestaw kafelków (budowany w kodzie, bo zawiera opis terenów dla pędzla)
static var _tileset: TileSet = null


func _ready() -> void:
	for layer_name in LAYERS:
		_layer(layer_name).tile_set = make_tileset()
	var level := LevelData.scene_data(scene_file_path)
	var generators := _generators()
	for layer_name in generators:
		if _layer(layer_name).get_used_cells().is_empty():
			generators[layer_name].call(level)


## Punkty tras wrogów w jednostkach gry (każdy Path2D sceny to jedna trasa).
func get_routes() -> Array:
	var routes := []
	for child in get_children():
		if child is Path2D:
			var path := child as Path2D
			var points := []
			for i in path.curve.point_count:
				points.append(path.transform * path.curve.get_point_position(i))
			routes.append(points)
	return routes


## Środki miejsc budowy w kolejności z drzewa sceny.
func get_spots() -> Array:
	var holder: Node2D = $MiejscaNaWieze
	var positions := []
	for child in holder.get_children():
		if child is Node2D:
			positions.append(holder.transform * (child as Node2D).position)
	return positions


## Układa od nowa wszystkie warstwy. Nadpisuje ręczne zmiany kafelków.
func generate_terrain() -> void:
	var level := LevelData.scene_data(scene_file_path)
	for generator in _generators().values():
		generator.call(level)


## Układa od nowa drogi wzdłuż tras (także skosy). Nadpisuje ręcznie malowane drogi.
func generate_road() -> void:
	_generate_road(LevelData.scene_data(scene_file_path))


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
