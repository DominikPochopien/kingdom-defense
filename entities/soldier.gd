class_name Soldier
extends Node2D
## Żołnierz walczący wręcz. Trzy odmiany:
##  - żołnierz z Koszar (odradza się po śmierci),
##  - rycerz z Wieży Rycerskiej (dłuższy zasięg ciosu, bije też latających),
##  - posiłki z umiejętności (bez wieży, znikają po czasie, nie odradzają się).
## Żołnierz zatrzymuje (blokuje) naziemnego wroga, z którym walczy.

const MOVE_SPEED := 90.0
const ATTACK_INTERVAL := 1.0
const REACH := 20.0
const KNIGHT_REACH := 40.0
## cel oddalony od punktu zbiórki o więcej niż radius * LEASH jest porzucany
const LEASH := 1.5

var world: GameWorld

## wieża-matka (null dla posiłków)
var tower: SoldierTower = null
var is_reinforcement := false
var is_knight := false
var rally := Vector2.ZERO
var hp := 50.0
var max_hp := 50.0
var damage := 4.0
## promień, w którym żołnierz szuka wrogów (od punktu zbiórki)
var radius := 120.0
var target: Enemy = null
var alive := true
var gone := false
var respawn := 0.0
## czas do zniknięcia (tylko posiłki), -1 = bez limitu
var lifetime := -1.0

var _attack_cd := 0.0


func setup_for_tower(owner_tower: SoldierTower) -> void:
	tower = owner_tower
	position = owner_tower.position
	is_knight = owner_tower.stats.has_knights()
	apply_stats(owner_tower.stats)


func setup_reinforcement(at: Vector2, rally_point: Vector2) -> void:
	is_reinforcement = true
	position = at
	rally = rally_point
	hp = Balance.REINF_HP
	max_hp = Balance.REINF_HP
	damage = Balance.REINF_DAMAGE
	radius = Balance.REINF_RADIUS
	lifetime = Balance.REINF_LIFETIME


## Ustawia statystyki z wieży i leczy do pełna (po budowie i każdym ulepszeniu).
func apply_stats(stats: TowerStats) -> void:
	max_hp = stats.soldier_hp()
	hp = max_hp
	damage = stats.damage()
	radius = stats.attack_range()


func is_finished() -> bool:
	return gone


func is_active() -> bool:
	return alive and not gone


func despawn() -> void:
	gone = true


func take_hit(amount: float) -> void:
	hp -= amount
	if hp > 0:
		return
	alive = false
	target = null
	if is_reinforcement:
		gone = true
	else:
		respawn = tower.stats.respawn_time()


func tick(dt: float) -> void:
	if gone:
		return
	if not alive:
		_wait_for_respawn(dt)
		return
	if lifetime > 0:
		lifetime -= dt
		if lifetime <= 0:
			gone = true
			return
	_update_target()
	_act(dt)


func _wait_for_respawn(dt: float) -> void:
	respawn -= dt
	if respawn <= 0:
		alive = true
		hp = max_hp
		position = tower.position


func _update_target() -> void:
	if not Enemy.is_alive(target) or target.is_blocked_by_other(self) \
			or target.position.distance_to(rally) > radius * LEASH:
		_release_target()
	if target == null:
		target = _find_target()


## Porzuca cel; wróg zablokowany przez tego żołnierza może iść dalej.
func _release_target() -> void:
	if is_instance_valid(target) and target.blocked_by == self:
		target.blocked_by = null
	target = null


func _find_target() -> Enemy:
	var best: Enemy = null
	var best_dist := 1e9
	for e in world.enemies:
		if e.dead or (e.flying and not is_knight):
			continue
		if e.is_blocked_by_other(self):
			continue
		var d := e.position.distance_to(rally)
		if d < radius and d < best_dist:
			best_dist = d
			best = e
	return best


func _act(dt: float) -> void:
	var dest := rally if target == null else target.position
	var to := dest - position
	var dist := to.length()
	var reach := KNIGHT_REACH if is_knight else REACH
	if target != null and dist <= reach:
		if not target.flying:
			target.blocked_by = self
		_attack_cd -= dt
		if _attack_cd <= 0:
			_attack_cd = ATTACK_INTERVAL
			target.take_damage(damage, false)
	elif dist > 3.0:
		position += to.normalized() * minf(MOVE_SPEED * dt, dist)


func display_name() -> String:
	if is_knight:
		return "Rycerz z Włócznią"
	if is_reinforcement:
		return "Posiłki"
	return "Żołnierz"


# ---------------- rysowanie ----------------
func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if not is_active():
		return
	draw_circle(Vector2(0, 8), 7.0, Color(0, 0, 0, 0.25))
	var col := Color(0.3, 0.85, 0.9) if is_reinforcement else Color(0.3, 0.5, 0.9)
	if is_knight:
		col = Color(0.9, 0.55, 0.1)
	draw_circle(Vector2.ZERO, 8.0, col)
	draw_circle(Vector2(0, -9), 5.0, Color(0.95, 0.8, 0.65))
	if is_knight:
		draw_line(Vector2(-5, -2), Vector2(16, -16), Color(0.8, 0.8, 0.8), 2.0)   # włócznia
	else:
		draw_line(Vector2(8, 0), Vector2(14, -10), Color(0.85, 0.85, 0.9), 2.5)   # miecz
	UiDraw.health_bar(self, Vector2(0, -20), hp / max_hp, 20.0, Color(0.3, 0.8, 1))
