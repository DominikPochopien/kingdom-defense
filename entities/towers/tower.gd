class_name Tower
extends Node2D
## Bazowa klasa wieży: poziom, ulepszenia i wygląd (grafika z assets/towers/ według poziomu i gałęzi,
## nazwy w TowerData). Statystyki liczy TowerStats. Zachowanie: ShooterTower / SoldierTower.
## Tworzenie: TowerFactory.create().

const ART_PATH := "res://assets/towers/%s.png"
## dolna krawędź grafiki wieży względem środka miejsca budowy (dół kamiennego kręgu)
const BASE_Y := 22.0

var world: GameWorld
var stats: TowerStats
## środek obszaru, w którym wieża szuka celów (zwykle jej pozycja; Statek - punkt na lądzie)
var aim_center := Vector2.ZERO
## złoto wydane na budowę i ulepszenia (podstawa ceny sprzedaży)
var spent := 0
## czas wyłączenia wieży (fioletowa aura Magicznego Rycerza); > 0 = wieża nie działa
var disabled_time := 0.0
## grafika dla bieżącego poziomu i gałęzi
var _art: Texture2D = null


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func setup(game_world: GameWorld, tower_type: String, level: int, branch: String, gold_spent: int) -> void:
	world = game_world
	stats = TowerStats.new(tower_type, level, branch)
	spent = gold_spent
	_refresh_art()
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


func disable(duration: float) -> void:
	disabled_time = maxf(disabled_time, duration)


func is_disabled() -> bool:
	return disabled_time > 0.0


## Odlicza czas wyłączenia; zwraca true, gdy wieża jest wyłączona i nie powinna działać.
func update_disabled(dt: float) -> bool:
	if disabled_time <= 0.0:
		return false
	disabled_time -= dt
	return true


func upgrade(cost: int) -> void:
	spent += cost
	stats.level += 1
	_refresh_art()
	_on_stats_changed()


func choose_branch(branch_id: String, cost: int) -> void:
	spent += cost
	stats.level = TowerStats.BRANCH_LEVEL
	stats.branch = branch_id
	_refresh_art()
	_on_stats_changed()


func sell_value() -> int:
	return TowerStats.sell_value(spent)


## Dane do zapisu gry (format zgodny z SaveManager).
func to_save_data(spot_index: int) -> Dictionary:
	return {"spot": spot_index, "type": stats.type, "level": stats.level, "branch": stats.branch, "spent": spent}


## Grafika według poziomu (1-3) albo wybranej gałęzi (4). Typ bez "art" w TowerData rysuje się sam.
func _refresh_art() -> void:
	var info: Dictionary = TowerData.TOWERS[stats.type]
	if not info.has("art"):
		return
	var art_name: String = "%s_%d" % [info.art, stats.level]
	if stats.level == TowerStats.BRANCH_LEVEL:
		art_name = stats.branch_info().art
	_art = load(ART_PATH % art_name)


# ---------------- rysowanie ----------------
func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	_draw_body()
	if is_disabled():
		_draw_sealed()


## Grafika wieży stojąca na kamiennym kręgu miejsca budowy. Nadpisywane przez wieże bez grafiki w TowerData.
func _draw_body() -> void:
	var size := _art.get_size() * LevelScene.PIXEL
	draw_texture_rect(_art, Rect2(Vector2(-size.x / 2.0, BASE_Y - size.y), size), false)


## Fioletowa pieczęć na wyłączonej wieży i licznik sekund.
func _draw_sealed() -> void:
	var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 150.0)
	draw_circle(Vector2(0, -16), 38.0, Color(0.6, 0.2, 0.95, 0.3 + 0.15 * pulse))
	draw_arc(Vector2(0, -16), 38.0, 0, TAU, 32, Color(0.8, 0.5, 1.0, 0.9), 3.0)
	UiDraw.text(self, Vector2(-30, -62), "%d s" % int(ceil(disabled_time)), 14, Color(0.9, 0.75, 1.0),
		HORIZONTAL_ALIGNMENT_CENTER, 60.0)
