class_name ForestArcher
extends Node2D
## Leśny Łucznik - sprzymierzeniec, który na kilka sekund wychodzi z gniazda w górach
## i strzela z dmuchawki do wroga najdalej na trasie (także do latających).
## Kiedy i gdzie się pojawia: systems/forest_archer_camp.gd. Statystyki: data/balance.gd.

const FADE_TIME := 0.5
## jak długo trwa animacja strzału z dmuchawki (3 klatki)
const SHOT_TIME := 0.375
const FOOT := Vector2(0, 10)

var world: GameWorld
## indeks gniazda (archer_posts), które zajmuje łucznik
var post := 0

var _time_left := 0.0
var _age := 0.0
var _cooldown := 0.3
var _aim_dir := Vector2.DOWN
## czas od ostatniego strzału (do animacji dmuchawki)
var _since_shot := SHOT_TIME


func setup(post_index: int, pos: Vector2, duration: float) -> void:
	post = post_index
	position = pos
	_time_left = duration


func is_finished() -> bool:
	return _time_left <= 0.0


func tick(dt: float) -> void:
	_age += dt
	_since_shot += dt
	_time_left -= dt
	_cooldown -= dt
	# nie strzela, gdy dopiero wychodzi z kryjówki albo już się chowa
	if _cooldown > 0 or _age < FADE_TIME or _time_left < FADE_TIME:
		return
	var target := _pick_target()
	if target == null:
		return
	_cooldown = Balance.FOREST_ARCHER_RELOAD
	_aim_dir = (target.position - position).normalized()
	_since_shot = 0.0
	var p := Projectile.new()
	p.setup_dart(_mouth() + _aim_dir * 18.0, target, Balance.FOREST_ARCHER_DAMAGE, Balance.FOREST_ARCHER_DART_SPEED)
	world.add_projectile(p)
	Audio.play("shoot")


## Wróg najdalej na trasie w zasięgu.
func _pick_target() -> Enemy:
	var best: Enemy = null
	var best_progress := -1.0
	for e in world.enemies:
		if not Enemy.is_targetable(e):
			continue
		if e.position.distance_to(position) > Balance.FOREST_ARCHER_RANGE:
			continue
		if e.distance > best_progress:
			best_progress = e.distance
			best = e
	return best


func _mouth() -> Vector2:
	return position + Vector2(0, -13)


# ---------------- rysowanie ----------------
## 0..1 - pojawianie się i znikanie
func _alpha() -> float:
	return clampf(minf(_age, _time_left) / FADE_TIME, 0.0, 1.0)


func _process(_delta: float) -> void:
	modulate.a = _alpha()
	queue_redraw()


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _draw() -> void:
	# wynurza się zza krzaka
	var foot := FOOT + Vector2(0, (1.0 - _alpha()) * 10.0)
	draw_circle(FOOT, 9.0, Color(0, 0, 0, 0.25))
	var shooting := _since_shot < SHOT_TIME
	UnitSprites.draw(self, "allies/forest_ranger_" + ("attack" if shooting else "walk"), "forest_ranger", foot,
		_since_shot if shooting else 0.0, -1.0 if _aim_dir.x < 0 else 1.0)
	# pasek pozostałego czasu
	var frac := clampf(_time_left / Balance.FOREST_ARCHER_MAX_TIME, 0.0, 1.0)
	draw_rect(Rect2(-12, 14, 24, 3), Color(0, 0, 0, 0.5))
	draw_rect(Rect2(-12, 14, 24 * frac, 3), Color(0.55, 0.95, 0.4))
