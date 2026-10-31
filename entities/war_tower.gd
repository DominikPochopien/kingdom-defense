class_name WarTower
extends Node2D
## Wieża wroga (klucz poziomu "war_towers") - przeszkoda na mapie, nie da się jej zniszczyć.
## Co WAR_TOWER_MIN_TIME-WAR_TOWER_MAX_TIME s rozpala ogień i przez WAR_TOWER_ACTIVE s wszyscy wrogowie
## w jej okręgu biegną WAR_TOWER_HASTE razy szybciej. Gdy w okręgu nikogo nie ma, czeka na pierwszego wroga.
## Liczby: data/balance.gd (WAR_TOWER_*). Grafika: assets/objects/war_tower.png (tools/gen_war_tower.py).

const SHEET := preload("res://assets/objects/war_tower.png")
## klatka grafiki (piksele obrazka): 0 - spokojna, 1-2 - płonie (migocze)
const FRAME := Vector2(24, 44)
const FIRE_FPS := 6.0
const COLOR := Color(0.95, 0.3, 0.2)

var world: GameWorld
## środek i promień obszaru przyspieszenia (współrzędne świata)
var center := Vector2.ZERO
var radius := 250.0

var _cooldown := 0.0
var _active := 0.0
var _anim := 0.0


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func setup(def: Dictionary) -> void:
	position = def.pos
	center = def.center
	radius = def.radius
	_cooldown = Balance.WAR_TOWER_FIRST


func is_finished() -> bool:
	return false


func is_active() -> bool:
	return _active > 0


func is_ready() -> bool:
	return _active <= 0 and _cooldown <= 0


func cooldown() -> float:
	return maxf(_cooldown, 0.0)


func active_left() -> float:
	return maxf(_active, 0.0)


func tick(dt: float) -> void:
	_anim += dt
	if _active > 0:
		_active -= dt
		_hasten_enemies()
		if _active <= 0:
			_cooldown = randf_range(Balance.WAR_TOWER_MIN_TIME, Balance.WAR_TOWER_MAX_TIME)
		return
	_cooldown -= dt
	if _cooldown > 0 or not _enemy_inside():
		return
	_active = Balance.WAR_TOWER_ACTIVE
	_hasten_enemies()
	world.add_float(position + Vector2(-60, -110), "Okrzyk wojenny!", COLOR)
	Audio.play("wave")


func _enemy_inside() -> bool:
	for e in world.enemies:
		if Enemy.is_alive(e) and e.position.distance_to(center) <= radius:
			return true
	return false


## Krótkie przyspieszenie odnawiane co klatkę - po wyjściu z okręgu szybko mija.
## Silniejszego przyspieszenia (aura Magicznego Rycerza) nie osłabia.
func _hasten_enemies() -> void:
	for e in world.enemies:
		if not Enemy.is_alive(e) or e.position.distance_to(center) > radius:
			continue
		if e.haste_time > 0 and e.haste_mult > Balance.WAR_TOWER_HASTE:
			continue
		e.apply_haste(0.2, Balance.WAR_TOWER_HASTE)


func contains(p: Vector2) -> bool:
	return p.distance_to(position + Vector2(0, -FRAME.y)) < 34.0


# ---------------- rysowanie ----------------
func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	# obszar działania: przerywany okrąg; gdy wieża płonie - czerwona poświata i pełny, pulsujący okrąg
	var c := center - position
	if is_active():
		var pulse := 0.5 + 0.5 * sin(_anim * 6.0)
		draw_circle(c, radius, Color(COLOR, 0.08 + 0.04 * pulse))
		draw_arc(c, radius, 0, TAU, 96, Color(COLOR, 0.55 + 0.3 * pulse), 3.0)
	else:
		var alpha := 0.5 if is_ready() else 0.25
		for k in 40:
			var a := k * TAU / 40.0
			draw_arc(c, radius, a, a + TAU / 80.0, 4, Color(COLOR, alpha), 2.5)
	var frame := 0
	if is_active():
		frame = 1 + int(_anim * FIRE_FPS) % 2
	var px := float(LevelScene.PIXEL)
	var size := FRAME * px
	draw_texture_rect_region(SHEET, Rect2(Vector2(-size.x / 2.0, -size.y), size), Rect2(Vector2(frame * FRAME.x, 0), FRAME))
