class_name SoldierTower
extends Tower
## Wieża wystawiająca żołnierzy na najbliższy punkt drogi (koszary, Wieża Rycerska).
## Liczba żołnierzy wynika z TowerStats.soldier_count() i rośnie przy ulepszeniach.

## odległość żołnierzy od punktu zbiórki
const FORMATION_RADIUS := 16.0

var soldiers: Array[Soldier] = []
var rally := Vector2.ZERO


func _on_placed() -> void:
	rally = world.paths.nearest_point(position)
	_fill_soldiers()


func _on_stats_changed() -> void:
	_fill_soldiers()
	for s in soldiers:
		s.apply_stats(stats)


## Nowy punkt zbiórki wybrany przez gracza; żołnierze od razu tam idą.
func set_rally(point: Vector2) -> void:
	rally = point
	_layout_formation()


## Jak daleko od wieży można postawić punkt zbiórki.
func rally_range() -> float:
	return stats.attack_range()


func can_rally_to(point: Vector2) -> bool:
	return position.distance_to(point) <= rally_range()


func to_save_data(spot_index: int) -> Dictionary:
	var data := super.to_save_data(spot_index)
	data["rally_x"] = rally.x
	data["rally_y"] = rally.y
	return data


func remove() -> void:
	for s in soldiers:
		s.despawn()
	super.remove()


func alive_soldiers() -> int:
	var n := 0
	for s in soldiers:
		if s.alive:
			n += 1
	return n


func _fill_soldiers() -> void:
	while soldiers.size() < stats.soldier_count():
		var s := Soldier.new()
		s.setup_for_tower(self)
		world.add_soldier(s)
		soldiers.append(s)
	_layout_formation()


## Rozstawia żołnierzy w kółku wokół punktu zbiórki.
func _layout_formation() -> void:
	var n := soldiers.size()
	for i in n:
		var a := i * TAU / float(n)
		soldiers[i].rally = rally + Vector2(cos(a), sin(a)) * FORMATION_RADIUS
