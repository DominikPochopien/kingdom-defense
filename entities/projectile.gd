class_name Projectile
extends Node2D
## Pocisk wieży (strzała, kula magii, kula armatnia). Leci za celem;
## jeśli cel zginie - leci do jego ostatniej pozycji.

const HIT_DISTANCE := 4.0

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
var done := false

var _aim := Vector2.ZERO


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


func is_finished() -> bool:
	return done


func tick(dt: float) -> void:
	if Enemy.is_alive(target):
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
	if not Enemy.is_alive(target):
		return
	target.take_damage(damage, magic)
	if slow_time > 0 and not target.dead:
		target.apply_slow(slow_time)
	if chain_damage > 0:
		_chain()


## Błyskawica: przeskok na najbliższego innego wroga.
func _chain() -> void:
	var best: Enemy = null
	var best_dist := chain_range
	for e in world.enemies:
		if e.dead or e == target:
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
	match kind:
		"archer":
			var dir := (_aim - position).normalized()
			draw_line(Vector2.ZERO, -dir * 12.0, Color(0.9, 0.8, 0.5), 2.5)
		"mage":
			draw_circle(Vector2.ZERO, 7.0, Color(0.6, 0.4, 1.0, 0.4))
			draw_circle(Vector2.ZERO, 4.0, Color(0.8, 0.7, 1.0))
		_:
			draw_circle(Vector2.ZERO, 6.0, Color(0.15, 0.15, 0.15))
