class_name WaveSpawner
extends RefCounted
## Numer fali i kolejka wrogów, którzy mają się jeszcze pojawić. Skład fal: data/wave_data.gd.

var wave := 0
var total_waves := 10
var with_shamans := false
var with_magic_knights := false
var with_dragons := false
var with_hedgehogs := false
var with_undead := false

## elementy: [typ wroga, opóźnienie przed jego pojawieniem (s)]
var _queue: Array = []
var _timer := 0.0
## wrogowie o ustalonych porach (fala specjalna, ukryta droga): [czas na zegarze _clock, typ, trasa],
## posortowani po czasie
var _timed: Array = []
## zegar kolejki _timed (s); stoi, gdy kolejka jest pusta
var _clock := 0.0
## fala specjalna poziomu (klucz "special_wave"): {"wave", "routes": {trasa: grupy}}, grupy jak w add_timed()
var special_wave: Dictionary = {}


func reset(waves: int, shamans: bool, magic_knights := false, dragons := false, hedgehogs := false,
		undead := false) -> void:
	wave = 0
	total_waves = waves
	with_shamans = shamans
	with_magic_knights = magic_knights
	with_dragons = dragons
	with_hedgehogs = hedgehogs
	with_undead = undead
	_queue.clear()
	_timer = 0.0
	_timed.clear()
	_clock = 0.0
	special_wave = {}


func is_spawning() -> bool:
	return not _queue.is_empty() or not _timed.is_empty()


func has_more_waves() -> bool:
	return wave < total_waves


func next_composition() -> Array:
	if _is_special(wave + 1):
		var counts := {}
		for groups: Array in special_wave.routes.values():
			for g: Array in groups:
				counts[g[0]] = int(counts.get(g[0], 0)) + int(g[1])
		var res := []
		for type in counts:
			res.append([type, counts[type]])
		return res
	return WaveData.composition(wave + 1, total_waves, with_shamans, with_magic_knights, with_dragons, with_hedgehogs,
		with_undead)


func _is_special(n: int) -> bool:
	return int(special_wave.get("wave", -1)) == n


func start_next_wave() -> void:
	wave += 1
	if _is_special(wave):
		for r in special_wave.routes:
			add_timed(special_wave.routes[r], int(r))
		return
	var shamans := 0
	var knights := 0
	var mummies := 0
	for group in WaveData.composition(wave, total_waves, with_shamans, with_magic_knights, with_dragons, with_hedgehogs,
			with_undead):
		var type: String = group[0]
		var amount: int = group[1]
		if type == "mummy":
			mummies = amount
			continue
		if type == "shaman":
			shamans = amount
			continue
		if type == "magic_knight":
			knights = amount
			continue
		var gap := WaveData.spawn_gap(type)
		for i in amount:
			_queue.append([type, WaveData.GROUP_GAP if i == 0 else gap])
	# szamani rozłożeni równomiernie w środku fali
	var base_count := _queue.size()
	for k in shamans:
		var at := int(float(k + 1) * base_count / float(shamans + 1)) + k
		_queue.insert(at, ["shaman", WaveData.SHAMAN_GAP])
	# Magiczni Rycerze: pierwszy zaczyna falę, ostatni ją kończy, reszta równo pomiędzy
	base_count = _queue.size()
	for k in knights:
		var at := 0 if knights == 1 else int(round(float(k) * base_count / float(knights - 1))) + k
		_queue.insert(at, ["magic_knight", WaveData.SHAMAN_GAP])
	# Mumia zaczyna falę - ma najdłuższą drogę i po drodze otwiera ukrytą drogę
	for _k in mummies:
		_queue.insert(0, ["mummy", WaveData.SHAMAN_GAP])
	_timer = WaveData.FIRST_SPAWN_DELAY


## Dokłada wrogów o ustalonych porach (licząc od teraz) na podaną trasę.
## groups: lista [typ, liczba, start (s), odstęp między kolejnymi (s)].
func add_timed(groups: Array, route: int) -> void:
	for g: Array in groups:
		for i in int(g[1]):
			_timed.append([_clock + float(g[2]) + i * float(g[3]), g[0], route])
	_timed.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])


## Wróg z kolejki o ustalonych porach do pojawienia się w tej klatce: [typ, trasa] albo [].
func update_timed(dt: float) -> Array:
	if _timed.is_empty():
		return []
	_clock += dt
	if _clock < _timed[0][0]:
		return []
	var item: Array = _timed.pop_front()
	return [item[1], item[2]]


## Zwraca typ wroga do pojawienia się w tej klatce albo "" (najwyżej jeden na klatkę).
func update(dt: float) -> String:
	if _queue.is_empty():
		return ""
	_timer -= dt
	if _timer > 0:
		return ""
	var item: Array = _queue.pop_front()
	if not _queue.is_empty():
		_timer = _queue[0][1]
	return item[0]
