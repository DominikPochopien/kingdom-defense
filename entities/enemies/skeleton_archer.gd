extends Enemy
## Szkielet łucznik (poziom 9) - gdy żołnierz jest w dużym zasięgu łuku, staje i co chwilę do niego
## strzela (liczby: data/enemy_data.gd, "arrow_*"). Zablokowany walczy wręcz jak zwykły wróg.

## jak długo po strzale widać klatki napinania łuku (s)
const SHOT_ANIM_TIME := 0.4

var _info: Dictionary
var _arrow_cd := 0.0
var _shot_anim := 0.0
## żołnierz, w którego celuje (null = idzie dalej)
var _target: Soldier = null


func setup(enemy_type: String, hp_mult: float, start_route: int) -> void:
	super.setup(enemy_type, hp_mult, start_route)
	_info = EnemyData.get_info(enemy_type)
	_arrow_cd = _info.arrow_first


func _update_ability(dt: float) -> void:
	_arrow_cd -= dt
	_shot_anim -= dt
	_target = null if in_tunnel else _nearest_soldier(_info.arrow_range)
	if _target == null:
		return
	facing_left = _target.position.x < position.x
	if _arrow_cd > 0:
		return
	_arrow_cd = _info.arrow_interval
	_shot_anim = SHOT_ANIM_TIME
	_target.take_hit(_info.arrow_damage)
	world.add_effect(position + Vector2(0, -14), "arrow", 0.0, _target.position + Vector2(0, -10), 0.35)
	Audio.play("shoot")


## Celując w żołnierza, łucznik stoi w miejscu.
func _move(dt: float) -> void:
	if _target != null:
		return
	super._move(dt)


func _nearest_soldier(max_range: float) -> Soldier:
	var best: Soldier = null
	var best_dist := max_range
	for s in world.soldiers:
		if not s.is_active():
			continue
		var d := s.position.distance_to(position)
		if d <= best_dist:
			best_dist = d
			best = s
	return best


# ---------------- rysowanie ----------------
func _sheet_name() -> String:
	if _flash <= 0 and (_shot_anim > 0 or _target != null):
		return "skeleton_archer_attack"
	return _standard_sheet(type)


func _sheet_time() -> float:
	if _shot_anim > 0:
		return SHOT_ANIM_TIME - _shot_anim
	# czeka na kolejny strzał z napiętym łukiem (klatka 0)
	return 0.0 if _target != null else anim
