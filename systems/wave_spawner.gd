class_name WaveSpawner
extends RefCounted
## Numer fali i kolejka wrogów, którzy mają się jeszcze pojawić. Skład fal: data/wave_data.gd.

var wave := 0
var total_waves := 10
var with_shamans := false

## elementy: [typ wroga, opóźnienie przed jego pojawieniem (s)]
var _queue: Array = []
var _timer := 0.0


func reset(waves: int, shamans: bool) -> void:
	wave = 0
	total_waves = waves
	with_shamans = shamans
	_queue.clear()
	_timer = 0.0


func is_spawning() -> bool:
	return not _queue.is_empty()


func has_more_waves() -> bool:
	return wave < total_waves


func next_composition() -> Array:
	return WaveData.composition(wave + 1, total_waves, with_shamans)


func start_next_wave() -> void:
	wave += 1
	var shamans := 0
	for group in WaveData.composition(wave, total_waves, with_shamans):
		var type: String = group[0]
		var amount: int = group[1]
		if type == "shaman":
			shamans = amount
			continue
		var gap := WaveData.spawn_gap(type)
		for i in amount:
			_queue.append([type, WaveData.GROUP_GAP if i == 0 else gap])
	# szamani rozłożeni równomiernie w środku fali
	var base_count := _queue.size()
	for k in shamans:
		var at := int(float(k + 1) * base_count / float(shamans + 1)) + k
		_queue.insert(at, ["shaman", WaveData.SHAMAN_GAP])
	_timer = WaveData.FIRST_SPAWN_DELAY


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
