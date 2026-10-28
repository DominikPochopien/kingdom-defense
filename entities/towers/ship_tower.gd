extends ShooterTower
## Statek - kupowany na specjalnym miejscu na morzu (klucz poziomu "ship").
## Strzela z armat (1 / 2 / 3 na poziomach 1-3) do wrogów w swoim obszarze: okrąg wokół
## aim_center, a nie wokół samego statku. Gałęzie: "Ogniste pociski" (podpalenie)
## i "Szybka lanca" (co jakiś czas salwa wielu pocisków w losowych wrogów).

const SWAY := preload("res://assets/objects/ship_sway.png")
## klatka statku (piksele obrazka): dziób w prawo, linia wody na dole
const FRAME := Vector2(64, 32)
const SWAY_FPS := 1.5

var _volley_cd := 0.0


func _on_stats_changed() -> void:
	_volley_cd = stats.volley_period()


func tick(dt: float) -> void:
	super.tick(dt)
	if stats.volley_shots() <= 0:
		return
	_volley_cd -= dt
	if _volley_cd > 0:
		return
	var targets := _enemies_in_range()
	if targets.is_empty():
		return
	_volley_cd = stats.volley_period()
	for k in stats.volley_shots():
		var target: Enemy = targets.pick_random()
		var p := Projectile.new()
		p.setup(position + Vector2(randf_range(-24, 24), randf_range(-10, 6)), stats, target)
		world.add_projectile(p)
	world.add_float(position + Vector2(-30, -60), "Salwa!", Color(1, 0.85, 0.3))
	Audio.play("boom")


func _enemies_in_range() -> Array[Enemy]:
	var res: Array[Enemy] = []
	for e in world.enemies:
		if Enemy.is_targetable(e) and e.position.distance_to(aim_center) <= stats.attack_range():
			res.append(e)
	return res


# ---------------- rysowanie ----------------
## Statek nie zmienia wyglądu z poziomem, więc poziom pokazują znaczniki pod nim.
func _draw() -> void:
	draw_ship(self, Vector2.ZERO, Time.get_ticks_msec() / 1000.0, Color.WHITE)
	_draw_level_marks()
	if is_disabled():
		_draw_sealed()


## Kołyszący się statek wyśrodkowany w punkcie p (używa go też mapa dla pustego miejsca na statek).
static func draw_ship(canvas: CanvasItem, p: Vector2, t: float, tint: Color) -> void:
	var size := FRAME * LevelScene.PIXEL
	var frame := int(t * SWAY_FPS) % 2
	canvas.draw_texture_rect_region(SWAY, Rect2(p - size / 2.0, size), Rect2(Vector2(frame * FRAME.x, 0), FRAME), tint)


## Kropki poziomu (1-3) i obwódka po wyborze ulepszenia 4. poziomu.
func _draw_level_marks() -> void:
	for i in stats.level:
		var col := Color(1, 0.85, 0.2) if i < TowerStats.MAX_LEVEL else Color(0.3, 0.95, 1.0)
		draw_circle(Vector2(-12 + i * 8, 40), 3.2, col)
	if stats.level == TowerStats.BRANCH_LEVEL:
		draw_arc(Vector2.ZERO, 60.0, 0, TAU, 40, Color(0.3, 0.95, 1.0, 0.8), 2.0)
