extends Enemy
## Smok - latający (omija blokadę żołnierzy). Co kilka sekund zieje ogniem naraz
## w kilku najbliższych żołnierzy (koszary, rycerze, posiłki, bohater).
## Liczby: data/enemy_data.gd ("breath_*").

const HOVER_HEIGHT := 28.0
## jak długo trwa animacja zionięcia (3 klatki) i gdzie w klatce smoka jest pysk (piksele obrazka)
const BREATH_TIME := 0.375
const MOUTH := Vector2(46, 14)
## klatka płomienia z pyska (arkusz dragon_fire, doklejany lewą krawędzią do pyska)
const FIRE_FRAME := Vector2(32, 12)

var breath_interval := 3.0
var breath_range := 140.0
var breath_damage := 30.0
var breath_targets := 2

var _breath_cd := 2.0
## ile jeszcze trwa animacja zionięcia (s)
var _breathing := 0.0


func setup(enemy_type: String, hp_mult: float, start_route: int) -> void:
	super.setup(enemy_type, hp_mult, start_route)
	var info := EnemyData.get_info(enemy_type)
	_breath_cd = info.breath_first
	breath_interval = info.breath_interval
	breath_range = info.breath_range
	breath_damage = info.breath_damage
	breath_targets = info.breath_targets


func _update_ability(dt: float) -> void:
	_breathing = maxf(_breathing - dt, 0.0)
	if in_tunnel:
		return
	_breath_cd -= dt
	if _breath_cd > 0:
		return
	var victims := _nearest_soldiers()
	if victims.is_empty():
		return
	_breath_cd = breath_interval
	_breathing = BREATH_TIME
	for s in victims:
		s.take_hit(breath_damage)
		world.add_effect(body_position(), "flame", 14.0, s.position, 0.45)
	Audio.play("boom")


## Najbliżsi aktywni żołnierze w zasięgu (najwyżej breath_targets).
func _nearest_soldiers() -> Array[Soldier]:
	var near: Array[Soldier] = []
	for s in world.soldiers:
		if s.is_active() and s.position.distance_to(position) <= breath_range:
			near.append(s)
	near.sort_custom(func(a: Soldier, b: Soldier) -> bool:
		return a.position.distance_to(position) < b.position.distance_to(position))
	return near.slice(0, breath_targets)


func _body_offset() -> Vector2:
	return Vector2(0, -HOVER_HEIGHT)


## Klatka nad ziemią, z lekkim bujaniem w locie.
func _sprite_foot() -> Vector2:
	return Vector2(0, -HOVER_HEIGHT + 20.0 + sin(anim * 4.0) * 3.0)


func _sheet_name() -> String:
	if _flash > 0:
		return "dragon_hit"
	return "dragon_breathe" if _breathing > 0 else "dragon_fly"


## Zionięcie zawsze zaczyna się od pierwszej klatki.
func _sheet_time() -> float:
	return BREATH_TIME - _breathing if _breathing > 0 else anim


## Płomień z pyska w czasie zionięcia.
func _draw_over(foot: Vector2, size: Vector2) -> void:
	if _breathing <= 0:
		return
	var px := float(LevelScene.PIXEL)
	var mouth := foot - Vector2(size.x / 2.0, size.y) + MOUTH * px
	var tex := UnitSprites.sheet("enemies/dragon_fire")
	var region := UnitSprites.frame_region(tex, FIRE_FRAME, BREATH_TIME - _breathing)
	draw_texture_rect_region(tex, Rect2(mouth - Vector2(0, FIRE_FRAME.y * px / 2.0), FIRE_FRAME * px), region)
