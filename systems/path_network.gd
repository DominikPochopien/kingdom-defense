class_name PathNetwork
extends RefCounted
## Trasy wrogów na mapie. Wróg zna tylko przebyty dystans i numer trasy,
## a pozycję na ekranie liczy position_at().
## Tunel = odcinek trasy od punktu a do b; wróg idzie nim niewidzialny i nie można go trafić.
## Portal = odcinek od punktu a do b o zerowej długości: wróg znika w a i od razu wychodzi w b.

const SAMPLE_STEP := 8.0


class Route:
	var points: Array = []
	## cum[i] = dystans od początku trasy do punktu i
	var cum: Array[float] = []
	var length := 0.0
	## indeksy odcinków w tunelu (odcinek i = od punktu i do i+1)
	var tunnel_segments: Array[int] = []
	## indeksy odcinków-portali (zerowej długości)
	var portal_segments: Array[int] = []


var routes: Array[Route] = []
## gęsto rozmieszczone punkty wszystkich tras (do szukania najbliższego punktu drogi)
var _samples := PackedVector2Array()


## tunnels, portals: listy {"a", "b"} - końce tuneli i portali (muszą być kolejnymi punktami tras)
func _init(route_points: Array, tunnels: Array = [], portals: Array = []) -> void:
	for pts in route_points:
		var route := Route.new()
		route.points = pts.duplicate()
		route.cum = [0.0]
		for i in range(1, pts.size()):
			var is_portal := portals.any(func(p: Dictionary) -> bool: return pts[i - 1] == p.a and pts[i] == p.b)
			if is_portal:
				route.portal_segments.append(i - 1)
			route.cum.append(route.cum[i - 1] + (0.0 if is_portal else pts[i].distance_to(pts[i - 1])))
			for t in tunnels:
				if pts[i - 1] == t.a and pts[i] == t.b:
					route.tunnel_segments.append(i - 1)
		route.length = route.cum[route.cum.size() - 1]
		routes.append(route)
	for ri in routes.size():
		var d := 0.0
		while d <= routes[ri].length:
			if not is_hidden_at(d, ri):
				_samples.append(position_at(d, ri))
			d += SAMPLE_STEP


## Czy wróg w tym miejscu trasy jest w tunelu (niewidzialny).
func is_hidden_at(distance: float, route: int) -> bool:
	var r := routes[route]
	for i in r.tunnel_segments:
		if distance > r.cum[i] and distance < r.cum[i + 1]:
			return true
	return false


## Portal przekroczony przy przejściu od dystansu from do to: [wejście, wyjście] albo [], gdy żaden.
func portal_between(from: float, to: float, route: int) -> Array:
	var r := routes[route]
	for i in r.portal_segments:
		if from <= r.cum[i] and to > r.cum[i]:
			return [r.points[i], r.points[i + 1]]
	return []


## Czy na trasie za podanym dystansem jest jeszcze portal.
func has_portal_ahead(route: int, distance: float) -> bool:
	var r := routes[route]
	return r.portal_segments.any(func(i: int) -> bool: return r.cum[i] >= distance)


## Najbliższe miejsce trasy dla punktu p: Vector2(dystans od początku trasy, odległość od p).
func closest_on_route(route: int, p: Vector2) -> Vector2:
	var best := Vector2(0.0, INF)
	var d := 0.0
	while d <= routes[route].length:
		var gap := position_at(d, route).distance_to(p)
		if gap < best.y:
			best = Vector2(d, gap)
		d += SAMPLE_STEP
	return best


func route_count() -> int:
	return routes.size()


func length_of(route: int) -> float:
	return routes[route].length


## Dystans od początku trasy do jej punktu o podanym indeksie.
func distance_to_point(route: int, point_index: int) -> float:
	return routes[route].cum[point_index]


func position_at(distance: float, route := 0) -> Vector2:
	var r := routes[route]
	distance = clampf(distance, 0.0, r.length)
	for i in range(1, r.points.size()):
		if distance <= r.cum[i]:
			var seg := r.cum[i] - r.cum[i - 1]
			if seg <= 0.0:
				return r.points[i]
			return r.points[i - 1].lerp(r.points[i], (distance - r.cum[i - 1]) / seg)
	return r.points[r.points.size() - 1]


func nearest_point(p: Vector2) -> Vector2:
	var best := _samples[0]
	var best_dist := 1e12
	for q in _samples:
		var d := q.distance_squared_to(p)
		if d < best_dist:
			best_dist = d
			best = q
	return best
