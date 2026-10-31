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
		# ręcznie zepsuty plik nie może wywalić gry - złe wartości zastępujemy domyślnymi
		var saved_unlocked: Variant = cf.get_value("progress", "unlocked", 1)
		unlocked = int(saved_unlocked) if saved_unlocked is int or saved_unlocked is float else 1
		completed = []
		var saved_completed: Variant = cf.get_value("progress", "completed", [])
		if saved_completed is Array:
			for c: Variant in saved_completed:
				completed.append(c is bool and c)
		run_waves.clear()
		for i in _level_count:
			var key := _run_key(i)
			if cf.has_section_key("runs", key):
				var run: Variant = cf.get_value("runs", key)
				if _is_valid_run(run):
					run_waves[i] = int(run.wave)
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


## TESTY: true = wszystkie poziomy odblokowane (przed wydaniem musi być false).
const UNLOCK_ALL := false


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
	var run: Variant = cf.get_value("runs", _run_key(level))
	return run if _is_valid_run(run) else {}


## Czy checkpoint ma poprawny format (typy liczb, znane wieże i gałęzie). Zły checkpoint jest pomijany.
static func _is_valid_run(run: Variant) -> bool:
	if not run is Dictionary:
		return false
	for key in ["gold", "lives", "wave"]:
		if not _is_number(run.get(key)):
			return false
	for key in ["fire_cd", "reinf_cd", "bridge", "bridge_timer"]:
		if run.has(key) and not _is_number(run[key]):
			return false
	if int(run.get("bridge", 0)) not in [0, 1] or not run.get("towers") is Array:
		return false
	for td: Variant in run.towers:
		if not td is Dictionary or not _is_valid_tower(td):
			return false
	return true


static func _is_valid_tower(td: Dictionary) -> bool:
	for key in ["spot", "level", "spent"]:
		if not _is_number(td.get(key)):
			return false
	var type: Variant = td.get("type")
	var branch: Variant = td.get("branch")
	if not type is String or not TowerData.TOWERS.has(type) or not branch is String:
		return false
	if int(td.level) < 1 or int(td.level) > TowerStats.BRANCH_LEVEL:
		return false
	if branch == "":
		return true
	for b: Dictionary in TowerData.BRANCHES.get(type, []):
		if b.id == branch:
			return true
	return false


static func _is_number(v: Variant) -> bool:
	return v is int or v is float


func delete_run(level: int) -> void:
	var cf := ConfigFile.new()
	if cf.load(SAVE_PATH) == OK and cf.has_section_key("runs", _run_key(level)):
		cf.erase_section_key("runs", _run_key(level))
		cf.save(SAVE_PATH)
	run_waves.erase(level)


static func _run_key(level: int) -> String:
	return "level_%d" % level
