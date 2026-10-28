extends Enemy
## Magiczny Rycerz - odporny na obrażenia fizyczne. Dwie umiejętności:
##  - Pieczęć: fioletowa aura wyłącza wieże w zasięgu na kilka sekund,
##  - Pośpiech: niebieska aura przez kilka sekund przyspiesza wrogów, którzy są w niej.
## Liczby: data/enemy_data.gd ("seal_*", "haste_*").

const HASTE_COLOR := Color(0.3, 0.6, 1.0)
## na tyle sekund przed Pieczęcią rycerz świeci fioletową aurą (ostrzeżenie dla gracza)
const SEAL_WARNING := 1.5

var seal_interval := 12.0
var seal_radius := 184.0
var seal_time := 4.0
var haste_interval := 12.0
var haste_time_total := 5.0
var haste_radius := 130.0
var haste_power := 2.0

var _seal_cd := 4.0
var _haste_cd := 8.0
## ile jeszcze trwa niebieska aura (s)
var _haste_left := 0.0


func setup(enemy_type: String, hp_mult: float, start_route: int) -> void:
	super.setup(enemy_type, hp_mult, start_route)
	var info := EnemyData.get_info(enemy_type)
	_seal_cd = info.seal_first
	seal_interval = info.seal_interval
	seal_radius = info.seal_radius
	seal_time = info.seal_time
	_haste_cd = info.haste_first
	haste_interval = info.haste_interval
	haste_time_total = info.haste_time
	haste_radius = info.haste_radius
	haste_power = info.haste_mult


func _update_ability(dt: float) -> void:
	# w tunelu nie używa umiejętności
	if in_tunnel:
		return
	_seal_cd -= dt
	if _seal_cd <= 0:
		_seal_cd = seal_interval
		_cast_seal()
	_haste_cd -= dt
	if _haste_cd <= 0:
		_haste_cd = haste_interval
		_haste_left = haste_time_total
		world.add_float(position + Vector2(-30, -48), "Pośpiech!", Color(0.5, 0.75, 1.0))
	if _haste_left > 0:
		_haste_left -= dt
		for other in world.enemies:
			if Enemy.is_targetable(other) and other.position.distance_to(position) <= haste_radius:
				other.apply_haste(0.2, haste_power)


## Wyłącza wszystkie wieże w zasięgu.
func _cast_seal() -> void:
	var hit := false
	for spot in world.spots:
		if not spot.is_empty() and spot.position.distance_to(position) <= seal_radius:
			spot.tower.disable(seal_time)
			hit = true
	world.add_effect(position, "seal", seal_radius, Vector2.ZERO, 0.7)
	if hit:
		world.add_float(position + Vector2(-30, -48), "Pieczęć!", Color(0.85, 0.6, 1.0))
		Audio.play("magic")


# ---------------- rysowanie ----------------
## Zasięg Pośpiechu na ziemi, póki działa.
func _draw_under() -> void:
	if _haste_left > 0:
		draw_circle(Vector2.ZERO, haste_radius, Color(HASTE_COLOR, 0.12))
		draw_arc(Vector2.ZERO, haste_radius, 0, TAU, 48, Color(HASTE_COLOR, 0.6), 2.5)


## Niebieska aura w czasie Pośpiechu, fioletowa tuż przed Pieczęcią, inaczej bez aury.
func _sheet_name() -> String:
	if _haste_left > 0:
		return _standard_sheet("magic_knight_blue")
	if _seal_cd <= SEAL_WARNING and not in_tunnel:
		return _standard_sheet("magic_knight_purple")
	return _standard_sheet("magic_knight")
