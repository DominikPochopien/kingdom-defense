extends Enemy
## Jeżowiec - naziemny wróg z dwiema umiejętnościami (liczby: data/enemy_data.gd, "spike_*" i "roll_*"):
##  - Kolce: co kilka sekund rzuca kolcami w najbliższego żołnierza w zasięgu,
##  - Turlanie: gdy ktoś go blokuje albo żołnierz jest blisko, przewraca się na plecy i turla
##    coraz szybciej; nie da się go wtedy zatrzymać, a żołnierzy na swojej drodze taranuje (rani).

## jak blisko musi być żołnierz, żeby Jeżowiec zaczął się turlać
const ROLL_TRIGGER_RANGE := 90.0
const RAM_REACH := 12.0

var _info: Dictionary
var _base_speed := 0.0
var _spike_cd := 0.0
var _roll_cd := 0.0
## ile jeszcze trwa turlanie (s)
var _roll_left := 0.0
## żołnierze już staranowani w tym turlaniu (każdy obrywa raz)
var _rammed: Array[Soldier] = []


func setup(enemy_type: String, hp_mult: float, start_route: int) -> void:
	super.setup(enemy_type, hp_mult, start_route)
	_info = EnemyData.get_info(enemy_type)
	_base_speed = speed
	_spike_cd = _info.spike_first
	_roll_cd = _info.roll_first


func is_rolling() -> bool:
	return _roll_left > 0


func _update_ability(dt: float) -> void:
	_spike_cd -= dt
	_roll_cd -= dt
	if is_rolling():
		_update_roll(dt)
		return
	if _roll_cd <= 0 and (is_instance_valid(blocked_by) or _nearest_soldier(ROLL_TRIGGER_RANGE) != null):
		_start_roll()
		return
	if _spike_cd <= 0:
		var s := _nearest_soldier(_info.spike_range)
		if s != null:
			_spike_cd = _info.spike_interval
			s.take_hit(_info.spike_damage)
			world.add_effect(position, "spike", 0.0, s.position, 0.3)
			Audio.play("shoot")


func _start_roll() -> void:
	_roll_left = _info.roll_time
	_roll_cd = _info.roll_interval + _info.roll_time
	_rammed.clear()
	blocked_by = null
	world.add_float(position + Vector2(-30, -36), "Turla się!", Color(1, 0.7, 0.4))


## Przyspiesza od 1,5x do roll_max_mult x i rani żołnierzy, przez których przejeżdża.
func _update_roll(dt: float) -> void:
	_roll_left -= dt
	var k := clampf(1.0 - _roll_left / float(_info.roll_time), 0.0, 1.0)
	speed = _base_speed * lerpf(1.5, _info.roll_max_mult, k)
	for s in world.soldiers:
		if s.is_active() and not _rammed.has(s) and s.position.distance_to(position) <= radius + RAM_REACH:
			_rammed.append(s)
			s.take_hit(_info.roll_damage)
			world.add_effect(s.position, "boom", 16.0)
	if _roll_left <= 0:
		speed = _base_speed


## Turlającego się Jeżowca nikt nie zatrzyma.
func _is_blocked() -> bool:
	if is_rolling():
		blocked_by = null
		return false
	return super._is_blocked()


func _nearest_soldier(max_range: float) -> Soldier:
	var best: Soldier = null
	var best_dist := max_range
	for s in world.soldiers:
		if not s.is_active():
			continue
		var d := s.position.distance_to(position)
		if d <= best_dist:
			best_dist = d
			best = s
	return best


# ---------------- rysowanie ----------------
func _sheet_name() -> String:
	if _flash > 0:
		return "hedgehog_hit"
	return "hedgehog_roll" if is_rolling() else "hedgehog_walk"
