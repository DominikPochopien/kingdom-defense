class_name Projectile
extends Node2D
## Pocisk wieży (strzała, kula magii, kula armatnia). Leci za celem;
## jeśli cel zginie - leci do jego ostatniej pozycji. Grafiki: assets/projectiles/ (lecą w prawo).

const HIT_DISTANCE := 4.0
const CANNONBALL := preload("res://assets/projectiles/cannonball.png")
## rodzaj pocisku -> grafika; "dart" (strzałka z dmuchawki) rysowany kodem
const ART := {
	"archer": preload("res://assets/projectiles/arrow.png"), "mage": preload("res://assets/projectiles/magic_ball.png"),
	"artillery": CANNONBALL, "ship": CANNONBALL, "egg": preload("res://assets/projectiles/egg.png"),
}
## pociski z kilkoma klatkami animacji (pozostałe mają jedną)
const ART_FRAMES := {"mage": 2}
const ART_FPS := 10.0

var world: GameWorld

## typ wieży, która wystrzeliła pocisk (decyduje o wyglądzie)
var kind := ""
var target: Enemy = null
var speed := 400.0
var damage := 0.0
var magic := false
var splash := 0.0
var ground_only := false
var slow_time := 0.0
var chain_damage := 0.0
var chain_range := 0.0
## podpalenie trafionego wroga (Ogniste pociski Statku)
var burn_damage := 0.0
var burn_time := 0.0
var done := false

var _aim := Vector2.ZERO


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func setup(from: Vector2, tower_stats: TowerStats, enemy: Enemy) -> void:
	position = from
	target = enemy
	_aim = enemy.position
	kind = tower_stats.type
	speed = tower_stats.projectile_speed()
	damage = tower_stats.damage()
	magic = tower_stats.is_magic()
	splash = tower_stats.splash_radius()
	ground_only = tower_stats.is_ground_only()
	slow_time = tower_stats.slow_time()
	chain_damage = tower_stats.chain_damage()
	chain_range = tower_stats.chain_range()
	burn_damage = tower_stats.burn_damage()
	burn_time = tower_stats.burn_time()


## Pocisk bez wieży i bez TowerStats: strzałka z dmuchawki Leśnego Łucznika ("dart")
## albo jajko ptaka ("egg").
func setup_dart(from: Vector2, enemy: Enemy, dart_damage: float, dart_speed: float, dart_kind := "dart") -> void:
	position = from
	target = enemy
	_aim = enemy.position
	kind = dart_kind
	speed = dart_speed
	damage = dart_damage


func is_finished() -> bool:
	return done


func tick(dt: float) -> void:
	if Enemy.is_targetable(target):
		_aim = target.position
	var to := _aim - position
	var step := speed * dt
	if to.length() <= step + HIT_DISTANCE:
		done = true
		_hit()
	else:
		position += to.normalized() * step


func _hit() -> void:
	if splash > 0:
		world.explode(_aim, splash, damage, magic, ground_only)
		return
	if not Enemy.is_targetable(target):
		return
	target.take_damage(damage, magic)
	if slow_time > 0 and not target.dead:
		target.apply_slow(slow_time)
	if burn_time > 0 and not target.dead:
		target.apply_burn(burn_damage, burn_time)
	if chain_damage > 0:
		_chain()


## Błyskawica: przeskok na najbliższego innego wroga.
func _chain() -> void:
	var best: Enemy = null
	var best_dist := chain_range
	for e in world.enemies:
		if not Enemy.is_targetable(e) or e == target:
			continue
		var d := e.position.distance_to(target.position)
		if d < best_dist:
			best_dist = d
			best = e
	if best != null:
		world.add_effect(target.position, "zap", 0.0, best.position, 0.2)
		best.take_damage(damage * chain_damage, true)


# ---------------- rysowanie ----------------
func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var dir := (_aim - position).normalized()
	if kind == "dart":
		draw_line(Vector2.ZERO, -dir * 8.0, Color(0.85, 0.9, 0.7), 1.5)
		draw_circle(-dir * 8.0, 2.0, Color(0.9, 0.3, 0.6))
		return
	# ogniste pociski Statku żarzą się
	if burn_damage > 0:
		draw_circle(Vector2.ZERO, 8.0, Color(1, 0.45, 0.05, 0.45))
	var tex: Texture2D = ART[kind]
	var frames: int = ART_FRAMES.get(kind, 1)
	var frame := Vector2(tex.get_width() / float(frames), tex.get_height())
	var index := int(Time.get_ticks_msec() / 1000.0 * ART_FPS) % frames
	# strzała obraca się w stronę lotu, okrągłe pociski nie
	draw_set_transform(Vector2.ZERO, dir.angle() if kind == "archer" else 0.0, Vector2.ONE * LevelScene.PIXEL)
	draw_texture_rect_region(tex, Rect2(-frame / 2.0, frame), Rect2(Vector2(index * frame.x, 0), frame))
	draw_set_transform(Vector2.ZERO)
