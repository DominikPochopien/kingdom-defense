class_name Enemy
extends Node2D
## Bazowa klasa wroga: ruch po trasie, walka z blokującym żołnierzem, otrzymywanie obrażeń.
## Statystyki: data/enemy_data.gd. Wygląd konkretnego typu: nadpisz _draw_body()
## w jego pliku (goblin.gd, wolf.gd, ...). Tworzenie: EnemyFactory.create().

const SLOW_FACTOR := 0.6
const ATTACK_INTERVAL := 1.0
const HIT_FLASH_TIME := 0.1
const HEALTH_BAR_COLOR := Color(0.9, 0.2, 0.2)

var world: GameWorld

var type := ""
var title := ""
var hp := 0.0
var max_hp := 0.0
var speed := 0.0
var armor := 0.0
var magic_resist := 0.0
var reward := 0
var lives_cost := 1
var flying := false
var damage := 0.0
var radius := 10.0

## przebyty dystans na trasie
var distance := 0.0
var route := 0
## true, gdy wróg minął rozwidlenie tras (poziom z mostami)
var forked := false
var dead := false
## żołnierz, który zatrzymał wroga (null = wróg idzie)
var blocked_by: Soldier = null
var slow_time := 0.0
var anim := 0.0

var _attack_cd := 0.0
var _flash := 0.0


## Czy wróg istnieje i żyje (bezpieczne także dla zwolnionych obiektów).
static func is_alive(e) -> bool:
	return is_instance_valid(e) and not e.dead


func setup(enemy_type: String, hp_mult: float, start_route: int) -> void:
	var info := EnemyData.get_info(enemy_type)
	type = enemy_type
	title = info.title
	hp = info.hp * hp_mult
	max_hp = hp
	speed = info.speed
	armor = info.armor
	magic_resist = info.mr
	reward = info.reward
	lives_cost = info.lives
	flying = info.flying
	damage = info.dmg
	radius = info.r
	route = start_route


func is_finished() -> bool:
	return dead


func tick(dt: float) -> void:
	anim += dt
	if _flash > 0:
		_flash -= dt
	_update_ability(dt)
	if _is_blocked():
		_fight_blocker(dt)
		return
	_move(dt)


## Umiejętność specjalna (np. leczenie szamana) - nadpisywana w podklasach.
func _update_ability(_dt: float) -> void:
	pass


func _is_blocked() -> bool:
	if not is_instance_valid(blocked_by) or blocked_by.gone or not blocked_by.alive:
		blocked_by = null
	return blocked_by != null


## Czy wroga blokuje ktoś inny niż podany żołnierz.
func is_blocked_by_other(soldier: Soldier) -> bool:
	return is_instance_valid(blocked_by) and blocked_by != soldier


func _fight_blocker(dt: float) -> void:
	_attack_cd -= dt
	if _attack_cd <= 0:
		_attack_cd = ATTACK_INTERVAL
		blocked_by.take_hit(damage)
		if not blocked_by.alive:
			blocked_by = null


func _move(dt: float) -> void:
	var spd := speed
	if slow_time > 0:
		slow_time -= dt
		spd *= SLOW_FACTOR
	distance += spd * dt
	var bridges := world.bridges
	if bridges.is_enabled() and not forked and distance >= bridges.fork_distance():
		forked = true
		route = bridges.active
	position = world.paths.position_at(distance, route)
	if distance >= world.paths.length_of(route):
		dead = true
		world.lose_lives(lives_cost)


func take_damage(amount: float, magic: bool) -> void:
	if dead:
		return
	var reduction := magic_resist if magic else armor
	var dealt := amount * (1.0 - reduction)
	hp -= dealt
	_flash = HIT_FLASH_TIME
	world.add_float(position + Vector2(randf_range(-8, 8), -26), str(int(round(dealt))), Color(1, 0.95, 0.6))
	if hp <= 0:
		_die()


func heal(amount: float) -> void:
	hp = minf(max_hp, hp + amount)


func apply_slow(duration: float) -> void:
	slow_time = duration


func _die() -> void:
	dead = true
	world.add_gold(reward)
	world.add_float(position + Vector2(0, -40), "+%d" % reward, Color(1, 0.85, 0.2))
	world.add_effect(position, "death", 22.0)
	Audio.play("coin")


## Punkt, w którym wróg jest rysowany (latające unoszą się nad ziemią) - do klikania i paneli.
func body_position() -> Vector2:
	return position + _body_offset()


func _body_offset() -> Vector2:
	return Vector2.ZERO


# ---------------- rysowanie ----------------
func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var tint := Color(1, 1, 1) if _flash <= 0 else Color(1, 0.6, 0.6)
	if slow_time > 0:
		tint = tint * Color(0.65, 0.8, 1.2)
	draw_circle(Vector2(0, radius * 0.8), radius * 0.8, Color(0, 0, 0, 0.25))
	_draw_body(tint)
	_draw_face()
	_draw_health_bar()


## Ciało wroga w punkcie (0, 0). Nadpisywane w podklasach.
func _draw_body(tint: Color) -> void:
	draw_circle(Vector2.ZERO, radius, Color(0.8, 0.8, 0.8) * tint)


func _draw_face() -> void:
	draw_circle(Vector2(-4, -3), 2.5, Color.WHITE)
	draw_circle(Vector2(4, -3), 2.5, Color.WHITE)
	draw_circle(Vector2(-4, -3), 1.2, Color.BLACK)
	draw_circle(Vector2(4, -3), 1.2, Color.BLACK)


func _draw_health_bar() -> void:
	UiDraw.health_bar(self, Vector2(0, -radius - 10), hp / max_hp, maxf(24.0, radius * 2.0), HEALTH_BAR_COLOR)
