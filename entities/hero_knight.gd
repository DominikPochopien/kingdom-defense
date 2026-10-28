class_name HeroKnight
extends Soldier
## Bohater: Rycerz - sprzymierzeniec stojący na posterunku poziomu (klucz "hero").
## Walczy wręcz jak żołnierz (blokuje, nie bije latających), leczy się poza walką,
## po śmierci odradza się na posterunku. Superumiejętność "Obrót": gdy wrogowie są blisko,
## kręci się z mieczem i co chwilę rani wszystkich naziemnych wrogów wokół.
## Liczby: data/balance.gd (HERO_*).

var _spin_cd := 3.0
## ile jeszcze trwa obrót (s)
var _spin_left := 0.0
var _spin_tick := 0.0
var _spin_angle := 0.0


func setup_hero(post: Vector2) -> void:
	position = post
	rally = post
	max_hp = Balance.HERO_HP
	hp = max_hp
	damage = Balance.HERO_DAMAGE
	radius = Balance.HERO_RANGE


func display_name() -> String:
	return "Bohater: Rycerz"


func is_spinning() -> bool:
	return _spin_left > 0


func spin_cooldown() -> float:
	return maxf(_spin_cd, 0.0)


func tick(dt: float) -> void:
	super.tick(dt)
	if not alive:
		_spin_left = 0.0
		return
	_spin_cd -= dt
	if is_spinning():
		_update_spin(dt)
	elif _spin_cd <= 0 and _ground_enemies_near() > 0:
		_spin_left = Balance.HERO_SPIN_TIME
		_spin_tick = 0.0
		_spin_cd = Balance.HERO_SPIN_COOLDOWN + Balance.HERO_SPIN_TIME
		world.add_float(position + Vector2(-24, -40), "Obrót!", Color(1, 0.85, 0.3))
	if target == null:
		hp = minf(max_hp, hp + Balance.HERO_REGEN * dt)


func _update_spin(dt: float) -> void:
	_spin_left -= dt
	_spin_angle += dt * 14.0
	_spin_tick -= dt
	if _spin_tick > 0:
		return
	_spin_tick = Balance.HERO_SPIN_TICK
	for e in world.enemies:
		if Enemy.is_targetable(e) and not e.flying and e.position.distance_to(position) <= Balance.HERO_SPIN_RADIUS:
			e.take_damage(Balance.HERO_SPIN_DAMAGE, false)
	Audio.play("shoot")


func _ground_enemies_near() -> int:
	var n := 0
	for e in world.enemies:
		if Enemy.is_targetable(e) and not e.flying and e.position.distance_to(position) <= Balance.HERO_SPIN_RADIUS:
			n += 1
	return n


func take_hit(amount: float) -> void:
	hp -= amount
	_flash = HIT_FLASH_TIME
	if hp > 0:
		return
	alive = false
	_release_target()
	respawn = Balance.HERO_RESPAWN


## Odradza się na swoim posterunku (nie ma wieży).
func _wait_for_respawn(dt: float) -> void:
	respawn -= dt
	if respawn <= 0:
		alive = true
		hp = max_hp
		_spin_cd = 2.0
		position = rally


# ---------------- rysowanie ----------------
func _draw() -> void:
	if gone:
		return
	if not alive:
		# znacznik posterunku i odliczanie do powrotu
		draw_arc(Vector2.ZERO, 12.0, 0, TAU, 24, Color(1, 0.85, 0.3, 0.6), 2.0)
		UiDraw.text(self, Vector2(-30, -16), "%d s" % int(ceil(respawn)), 14, Color(1, 0.85, 0.3), HORIZONTAL_ALIGNMENT_CENTER, 60.0)
		return
	if is_spinning():
		draw_circle(Vector2.ZERO, Balance.HERO_SPIN_RADIUS, Color(1, 0.9, 0.5, 0.12))
		for k in 3:
			var a := _spin_angle + k * TAU / 3.0
			draw_arc(Vector2.ZERO, Balance.HERO_SPIN_RADIUS * 0.8, a, a + 1.2, 12, Color(1, 1, 1, 0.5), 3.0)
	var top := _draw_unit()
	UiDraw.health_bar(self, Vector2(0, top - 6.0), hp / max_hp, 28.0, Color(1, 0.85, 0.3))


func _unit() -> String:
	return "hero"


func _anim_time() -> float:
	return _anim if is_spinning() else super._anim_time()


func _sheet_name() -> String:
	if is_spinning():
		return "hero_spin"
	return super._sheet_name()
