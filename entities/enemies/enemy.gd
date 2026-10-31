class_name Enemy
extends Node2D
## Bazowa klasa wroga: ruch po trasie, walka z blokującym żołnierzem, otrzymywanie obrażeń.
## Statystyki: data/enemy_data.gd. Wygląd: arkusze pixel artu assets/enemies/<typ>_<animacja>.png (UnitSprites);
## typy z umiejętnościami mają podklasę, która wybiera własne arkusze (_sheet_name) i dorysowuje
## efekty (_draw_under, _draw_over). Tworzenie: EnemyFactory.create().

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
## true, gdy wróg idzie tunelem - niewidzialny i nie można go trafić ani kliknąć
var in_tunnel := false
## żołnierz, który zatrzymał wroga (null = wróg idzie)
var blocked_by: Soldier = null
var slow_time := 0.0
## przyspieszenie (niebieska aura Magicznego Rycerza): czas i mnożnik prędkości
var haste_time := 0.0
var haste_mult := 1.0
## podpalenie (Ogniste pociski Statku): ile jeszcze trwa (s) i obrażenia na sekundę (bez pancerza)
var burn_time := 0.0
var burn_dps := 0.0
## ogłuszenie (kokosy Palmy): wróg stoi i nic nie robi
var stun_time := 0.0
var anim := 0.0
## obrazek postaci patrzy w lewo (ostatni ruch był w lewo)
var facing_left := false

var _attack_cd := 0.0
var _flash := 0.0


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


## Czy wróg istnieje i żyje (bezpieczne także dla zwolnionych obiektów).
static func is_alive(e) -> bool:
	return is_instance_valid(e) and not e.dead


## Czy wieże, żołnierze i umiejętności mogą teraz trafić wroga (żyje i nie jest w tunelu).
static func is_targetable(e) -> bool:
	return is_alive(e) and not e.in_tunnel


func setup(enemy_type: String, hp_mult: float, start_route: int) -> void:
	var info := EnemyData.get_info(enemy_type)
	type = enemy_type
	title = info.title
	hp = info.hp * (1.0 if info.get("fixed_hp", false) else hp_mult)
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
	_update_burn(dt)
	if dead:
		return
	if stun_time > 0:
		stun_time -= dt
		return
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
		# zabity Bohater sam zwalnia wroga (blocked_by jest wtedy już puste)
		if is_instance_valid(blocked_by) and not blocked_by.alive:
			blocked_by = null


func _move(dt: float) -> void:
	var spd := speed
	if slow_time > 0:
		slow_time -= dt
		spd *= SLOW_FACTOR
	if haste_time > 0:
		haste_time -= dt
		spd *= haste_mult
	var old_distance := distance
	distance += spd * dt
	var bridges := world.bridges
	if bridges.is_enabled() and not forked and distance >= bridges.fork_distance():
		forked = true
		route = bridges.active
	var old_x := position.x
	position = world.paths.position_at(distance, route)
	if absf(position.x - old_x) > 0.01:
		facing_left = position.x < old_x
	var portal := world.paths.portal_between(old_distance, distance, route)
	if not portal.is_empty():
		world.on_portal_used(portal[0], portal[1])
	in_tunnel = world.paths.is_hidden_at(distance, route)
	visible = not in_tunnel
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


func apply_burn(total_damage: float, duration: float) -> void:
	burn_time = duration
	burn_dps = total_damage / duration


func apply_stun(duration: float) -> void:
	stun_time = maxf(stun_time, duration)


func _update_burn(dt: float) -> void:
	if burn_time <= 0:
		return
	var step := minf(dt, burn_time)
	burn_time -= dt
	hp -= burn_dps * step
	if hp <= 0:
		_die()


func apply_haste(duration: float, mult: float) -> void:
	haste_time = maxf(haste_time, duration)
	haste_mult = mult


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
	if flying:
		draw_circle(Vector2(0, 4), radius * 0.6, Color(0, 0, 0, 0.2))
	_draw_under()
	var size := UnitSprites.size_of(type)
	var foot := _sprite_foot()
	var tint := Color(0.65, 0.8, 1.2) if slow_time > 0 else Color.WHITE
	UnitSprites.draw(self, "enemies/" + _sheet_name(), type, foot, _sheet_time(), _facing(), tint)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(_facing(), 1.0))
	_draw_over(foot, size)
	draw_set_transform(Vector2.ZERO)
	UiDraw.health_bar(self, foot - Vector2(0, size.y + 6), hp / max_hp, maxf(24.0, radius * 2.0), HEALTH_BAR_COLOR)
	_draw_status()


## 1 = patrzy w prawo, -1 = w lewo.
func _facing() -> float:
	return -1.0 if facing_left else 1.0


## Dolny środek klatki (stopy postaci). Latające unoszą klatkę nad ziemią.
func _sprite_foot() -> Vector2:
	return Vector2(0, radius * 0.6)


## Arkusz bieżącej animacji. Podklasy z własnymi stanami (lot, turlanie, aury) nadpisują.
func _sheet_name() -> String:
	return _standard_sheet(type)


## Trafiony: biała klatka "hit", walczy z żołnierzem: "attack", inaczej "walk".
func _standard_sheet(prefix: String) -> String:
	if _flash > 0:
		return prefix + "_hit"
	if is_instance_valid(blocked_by):
		return prefix + "_attack"
	return prefix + "_walk"


## Czas, według którego wybierana jest klatka animacji.
func _sheet_time() -> float:
	return anim


## Efekty pod postacią (np. aura). Nadpisywane w podklasach.
func _draw_under() -> void:
	pass


## Efekty nad postacią w jej układzie (odbitym, gdy idzie w lewo). Nadpisywane w podklasach.
func _draw_over(_foot: Vector2, _size: Vector2) -> void:
	pass


## Płomyki przy podpalonym wrogu i gwiazdki nad głową ogłuszonego.
func _draw_status() -> void:
	var body := _body_offset()
	if burn_time > 0:
		for k in 3:
			var p := body + Vector2(-radius * 0.6 + k * radius * 0.6, -radius * 0.3 + sin(anim * 12.0 + k) * 2.0)
			draw_circle(p, 4.0, Color(1, 0.45, 0.05, 0.75))
			draw_circle(p + Vector2(0, -2), 2.2, Color(1, 0.85, 0.3, 0.9))
	if stun_time > 0:
		var head := body + Vector2(0, -radius - 4)
		for k in 3:
			var a := anim * 5.0 + k * TAU / 3.0
			draw_circle(head + Vector2(cos(a) * 11.0, sin(a) * 4.0), 2.6, Color(1, 0.9, 0.2))
