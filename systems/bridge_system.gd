class_name BridgeSystem
extends RefCounted
## Zwodzone mosty (poziom "Rzeka Mostów"). Zawsze otwarty jest dokładnie jeden most;
## co `period` sekund czasu gry otwiera się drugi - ale nie wtedy, gdy wrogowie są
## w strefie któregoś mostu (od rozwidlenia tras do końca przeprawy).
## Na poziomach bez mostów wszystkie metody nic nie robią.
## Rysowanie mostów: world/level_map.gd.

signal switched(bridge_name: String)

const ANIM_SPEED := 1.5

var defs: Array = []
## indeks otwartego mostu
var active := 0
## czas do następnej zmiany (s); 0 = czeka, aż strefa mostów się opróżni
var timer := 0.0
var period := 20.0
## stan animacji opuszczenia każdego mostu (0 = podniesiony, 1 = opuszczony)
var anim: Array[float] = [1.0, 0.0]

var _paths: PathNetwork


func _init(level: Dictionary, paths: PathNetwork) -> void:
	defs = level.get("bridges", [])
	period = float(level.get("bridge_period", 20.0))
	_paths = paths
	reset()


func is_enabled() -> bool:
	return not defs.is_empty()


func reset() -> void:
	active = 0
	timer = period
	anim = [1.0, 0.0]


func is_waiting() -> bool:
	return timer <= 0.0


## Dystans na trasie, w którym trasy się rozwidlają (wspólny początek obu tras).
func fork_distance() -> float:
	var br: Dictionary = defs[0]
	return _paths.distance_to_point(br.route, br.zone_from)


## Logika zmiany mostu - liczona w czasie gry (stoi na pauzie).
func update(dt: float, enemies: Array) -> void:
	if not is_enabled():
		return
	if timer > 0.0:
		timer = maxf(0.0, timer - dt)
		if timer > 0.0:
			return
	if _is_zone_busy(0, enemies) or _is_zone_busy(1, enemies):
		return
	active = 1 - active
	timer = period
	switched.emit(defs[active].name)


## Animacja opuszczania/podnoszenia - liczona w czasie rzeczywistym.
func animate(dt: float) -> void:
	if not is_enabled():
		return
	for i in 2:
		anim[i] = move_toward(anim[i], 1.0 if active == i else 0.0, dt * ANIM_SPEED)


## Natychmiast ustawia animację w stan końcowy (po wczytaniu zapisu).
func snap() -> void:
	if not is_enabled():
		return
	for i in 2:
		anim[i] = 1.0 if active == i else 0.0


func _is_zone_busy(i: int, enemies: Array) -> bool:
	var br: Dictionary = defs[i]
	var zone_start := _paths.distance_to_point(i, br.zone_from)
	var zone_end := _paths.distance_to_point(i, br.zone_to)
	for e in enemies:
		if not e.dead and e.route == i and e.forked and e.distance >= zone_start and e.distance <= zone_end:
			return true
	return false
