class_name SaveManager
extends RefCounted
## Zapis postępu (odblokowane i ukończone poziomy) oraz checkpointów rozgrywki.
## Plik: user://save.cfg
##   [progress] unlocked, completed
##   [runs] level_N = {gold, lives, wave, fire_cd, reinf_cd, towers, bridge, bridge_timer}

const SAVE_PATH := "user://save.cfg"

## Liczba odblokowanych poziomów (poziomy 0..unlocked-1 są dostępne).
var unlocked := 1
var completed: Array = []
## poziom -> liczba ukończonych fal w zapisanym checkpoincie
var run_waves := {}

var _level_count := 0


func _init(level_count: int) -> void:
	_level_count = level_count


func load_progress() -> void:
	var cf := ConfigFile.new()
	if cf.load(SAVE_PATH) == OK:
		unlocked = int(cf.get_value("progress", "unlocked", 1))
		completed = cf.get_value("progress", "completed", [])
		run_waves.clear()
		for i in _level_count:
			var key := _run_key(i)
			if cf.has_section_key("runs", key):
				run_waves[i] = int(cf.get_value("runs", key).get("wave", 0))
	while completed.size() < _level_count:
		completed.append(false)
	# naprawa starszych zapisów: ukończony poziom zawsze odblokowuje następny
	var before := unlocked
	for i in _level_count:
		if completed[i]:
			unlocked = maxi(unlocked, i + 2)
	unlocked = clampi(unlocked, 1, _level_count)
	if unlocked != before:
		save_progress()


func save_progress() -> void:
	var cf := ConfigFile.new()
	cf.load(SAVE_PATH)
	cf.set_value("progress", "unlocked", unlocked)
	cf.set_value("progress", "completed", completed)
	cf.save(SAVE_PATH)


## TESTY: true = wszystkie poziomy odblokowane (przed wydaniem ustaw z powrotem false).
const UNLOCK_ALL := true


func is_unlocked(level: int) -> bool:
	return UNLOCK_ALL or level < unlocked


func is_completed(level: int) -> bool:
	return level < completed.size() and completed[level]


func mark_completed(level: int) -> void:
	completed[level] = true
	if level + 1 < _level_count:
		unlocked = maxi(unlocked, level + 2)
	save_progress()


func has_run(level: int) -> bool:
	return run_waves.has(level)


func save_run(level: int, data: Dictionary) -> void:
	var cf := ConfigFile.new()
	cf.load(SAVE_PATH)
	cf.set_value("runs", _run_key(level), data)
	cf.save(SAVE_PATH)
	run_waves[level] = int(data.wave)


## Zwraca zapisany checkpoint albo pusty słownik.
func load_run(level: int) -> Dictionary:
	var cf := ConfigFile.new()
	if cf.load(SAVE_PATH) != OK or not cf.has_section_key("runs", _run_key(level)):
		return {}
	return cf.get_value("runs", _run_key(level))


func delete_run(level: int) -> void:
	var cf := ConfigFile.new()
	if cf.load(SAVE_PATH) == OK and cf.has_section_key("runs", _run_key(level)):
		cf.erase_section_key("runs", _run_key(level))
		cf.save(SAVE_PATH)
	run_waves.erase(level)


static func _run_key(level: int) -> String:
	return "level_%d" % level
