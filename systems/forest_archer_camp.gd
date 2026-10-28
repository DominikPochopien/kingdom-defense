class_name ForestArcherCamp
extends RefCounted
## Gniazda Leśnych Łuczników (klucz poziomu "archer_posts"). Są FOREST_ARCHER_MAX "miejsca"
## na łuczników; każde co `period` s wypuszcza łucznika w losowym wolnym gnieździe.
## Miejsca są przesunięte w czasie, więc łucznicy pojawiają się na zmianę i czasem stoją razem.
## Na poziomach bez gniazd nic nie robi. Sam łucznik: entities/forest_archer.gd.

var posts: Array = []
## co ile sekund każde miejsce wypuszcza łucznika (klucz poziomu "archer_period")
var period := Balance.FOREST_ARCHER_PERIOD

## czas do pojawienia się kolejnego łucznika w każdym miejscu (s)
var _slot_timers: Array[float] = []


func _init(level: Dictionary) -> void:
	posts = level.get("archer_posts", [])
	period = float(level.get("archer_period", Balance.FOREST_ARCHER_PERIOD))
	reset()


func is_enabled() -> bool:
	return not posts.is_empty()


func reset() -> void:
	_slot_timers.clear()
	for k in Balance.FOREST_ARCHER_MAX:
		_slot_timers.append(Balance.FOREST_ARCHER_FIRST + k * period / Balance.FOREST_ARCHER_MAX)


## Zwraca indeks gniazda dla nowego łucznika albo -1 (najwyżej jeden na klatkę).
func update(dt: float, archers: Array[ForestArcher]) -> int:
	if not is_enabled():
		return -1
	var result := -1
	for k in _slot_timers.size():
		_slot_timers[k] -= dt
		if _slot_timers[k] <= 0 and result == -1:
			_slot_timers[k] += period
			if archers.size() < Balance.FOREST_ARCHER_MAX:
				result = _random_free_post(archers)
	return result


func _random_free_post(archers: Array[ForestArcher]) -> int:
	var free: Array[int] = []
	for i in posts.size():
		free.append(i)
	for a in archers:
		free.erase(a.post)
	if free.is_empty():
		return -1
	var picked: int = free.pick_random()
	return picked
