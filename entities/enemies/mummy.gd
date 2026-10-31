extends Enemy
## Mumia - boss poziomu 9 (liczby: data/enemy_data.gd, "summon_*"). Wychodzi z piramidy,
## idzie w lewo do portalu i przez niego do wyjścia. Dwie umiejętności:
##  - Przywołanie: co jakiś czas staje i wskrzesza wokół siebie Szkielety (zwykłe, łucznika i pancernego);
##    przywołani idą prosto do wyjścia - trasą Mumii, gdy nie ma już na niej portalu, a wcześniej
##    najbliższą trasą z klucza poziomu "minion_routes",
##  - Ukryta droga: gdy dojdzie do punktu "gate" klucza poziomu "hidden_route", otwiera nową drogę,
##    z której wychodzą zwykli wrogowie (GameWorld.open_hidden_route).

## zasięg rozstawienia przywołanych wzdłuż trasy (przed i za Mumią)
const SUMMON_BEHIND := 70.0
const SUMMON_AHEAD := 40.0
## jak blisko punktu otwarcia drogi musi przejść Mumia
const GATE_REACH := 14.0

var _info: Dictionary
var _summon_cd := 0.0
## ile jeszcze trwa przywoływanie (Mumia stoi)
var _cast_left := 0.0


func setup(enemy_type: String, hp_mult: float, start_route: int) -> void:
	super.setup(enemy_type, hp_mult, start_route)
	_info = EnemyData.get_info(enemy_type)
	_summon_cd = _info.summon_first


func is_casting() -> bool:
	return _cast_left > 0


func _update_ability(dt: float) -> void:
	_check_gate()
	if is_casting():
		_cast_left -= dt
		if _cast_left <= 0:
			_summon()
		return
	_summon_cd -= dt
	if _summon_cd <= 0 and not in_tunnel:
		_summon_cd = _info.summon_interval
		_cast_left = _info.summon_time
		world.add_float(position + Vector2(-50, -70), "Przywołanie!", Color(0.55, 1.0, 0.85))
		Audio.play("magic")


func _summon() -> void:
	var kinds := []
	for _i in int(_info.summon_skeletons):
		kinds.append("skeleton")
	for _i in int(_info.summon_archers):
		kinds.append("skeleton_archer")
	for _i in int(_info.summon_armored):
		kinds.insert(0, "skeleton_armored")
	var spot := _minion_spot()
	for i in kinds.size():
		var offset := lerpf(SUMMON_AHEAD, -SUMMON_BEHIND, float(i) / maxf(1.0, kinds.size() - 1.0))
		world.spawn_minion(kinds[i], int(spot.x), spot.y + offset + randf_range(-6.0, 6.0))
	world.add_effect(position, "portal", 90.0, Vector2.ZERO, 0.7)


## Trasa i dystans dla przywołanych: Vector2(trasa, dystans). Bez portalu przed sobą - trasa Mumii,
## inaczej najbliższe miejsce tras "minion_routes" (prowadzą do wyjścia bez portalu).
func _minion_spot() -> Vector2:
	var routes: Array = world.level.get("minion_routes", [])
	if routes.is_empty() or not world.paths.has_portal_ahead(route, distance):
		return Vector2(route, distance)
	var best := Vector2(route, distance)
	var best_gap := INF
	for r: int in routes:
		var c := world.paths.closest_on_route(r, position)
		if c.y < best_gap:
			best_gap = c.y
			best = Vector2(r, c.x)
	return best


func _check_gate() -> void:
	var hidden: Dictionary = world.level.get("hidden_route", {})
	if hidden.is_empty() or world.hidden_route_open:
		return
	if position.distance_to(hidden.gate) <= GATE_REACH:
		world.open_hidden_route()


## Podczas przywoływania Mumia stoi w miejscu.
func _move(dt: float) -> void:
	if is_casting():
		return
	super._move(dt)


# ---------------- rysowanie ----------------
func _sheet_name() -> String:
	if _flash <= 0 and is_casting():
		return "mummy_cast"
	return _standard_sheet(type)


func _draw_under() -> void:
	if is_casting():
		var k := 1.0 - _cast_left / float(_info.summon_time)
		draw_circle(Vector2.ZERO, 30.0 + 50.0 * k, Color(0.2, 0.9, 0.75, 0.12))
		draw_arc(Vector2.ZERO, 30.0 + 50.0 * k, 0, TAU, 40, Color(0.3, 1.0, 0.8, 0.7), 3.0)
