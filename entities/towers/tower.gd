class_name Tower
extends Node2D
## Bazowa klasa wieży: poziom, ulepszenia i wspólny wygląd (cień, znaczniki poziomu).
## Statystyki liczy TowerStats. Zachowanie: ShooterTower / SoldierTower,
## wygląd konkretnego typu: <typ>_tower.gd. Tworzenie: TowerFactory.create().

var world: GameWorld
var stats: TowerStats
## złoto wydane na budowę i ulepszenia (podstawa ceny sprzedaży)
var spent := 0


func setup(game_world: GameWorld, tower_type: String, level: int, branch: String, gold_spent: int) -> void:
	world = game_world
	stats = TowerStats.new(tower_type, level, branch)
	spent = gold_spent
	_on_placed()


## Wywoływane po postawieniu wieży (np. koszary tworzą żołnierzy).
func _on_placed() -> void:
	pass


## Wywoływane po ulepszeniu albo wyborze gałęzi.
func _on_stats_changed() -> void:
	pass


## Sprzątanie przed usunięciem wieży (np. żołnierze znikają).
func remove() -> void:
	queue_free()


func tick(_dt: float) -> void:
	pass


func upgrade(cost: int) -> void:
	spent += cost
	stats.level += 1
	_on_stats_changed()


func choose_branch(branch_id: String, cost: int) -> void:
	spent += cost
	stats.level = TowerStats.BRANCH_LEVEL
	stats.branch = branch_id
	_on_stats_changed()


func sell_value() -> int:
	return TowerStats.sell_value(spent)


## Dane do zapisu gry (format zgodny z SaveManager).
func to_save_data(spot_index: int) -> Dictionary:
	return {"spot": spot_index, "type": stats.type, "level": stats.level, "branch": stats.branch, "spent": spent}


# ---------------- rysowanie ----------------
func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2(0, 18), 18.0, Color(0, 0, 0, 0.25))
	_draw_body()
	_draw_level_marks()


## Budynek wieży w punkcie (0, 0). Nadpisywane w podklasach.
func _draw_body() -> void:
	pass


func _draw_level_marks() -> void:
	for i in stats.level:
		var col := Color(1, 0.85, 0.2) if i < TowerStats.MAX_LEVEL else Color(0.3, 0.95, 1.0)
		draw_circle(Vector2(-12 + i * 8, 28), 3.2, col)
	if stats.level == TowerStats.BRANCH_LEVEL:
		draw_arc(Vector2.ZERO, 30.0, 0, TAU, 32, Color(0.3, 0.95, 1.0, 0.8), 2.0)
