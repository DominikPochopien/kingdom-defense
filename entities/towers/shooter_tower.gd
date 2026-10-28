class_name ShooterTower
extends Tower
## Wieża strzelająca pociskami (łucznicy, magowie, artyleria).
## Celuje we wroga najdalej na trasie w swoim zasięgu (okrąg wokół aim_center).

## pociski wylatują z czubka wieży
const MUZZLE := Vector2(-4, -20)
const MUZZLE_SPACING := 8.0

var _cooldown := 0.0


func tick(dt: float) -> void:
	_cooldown -= dt
	if _cooldown > 0:
		return
	var targets := _pick_targets()
	if targets.is_empty():
		return
	_cooldown = stats.reload_time()
	for k in targets.size():
		var p := Projectile.new()
		p.setup(position + MUZZLE + Vector2(k * MUZZLE_SPACING, 0), stats, targets[k])
		world.add_projectile(p)
	Audio.play(stats.info.shot_sound)


## Cele dla wszystkich pocisków salwy; gdy celów jest mniej - drugi pocisk leci w pierwszy cel.
func _pick_targets() -> Array[Enemy]:
	var chosen: Array[Enemy] = []
	for k in stats.shots():
		var best := _pick_target(chosen)
		if best == null:
			if k == 0:
				return chosen
			best = chosen[0]
		chosen.append(best)
	return chosen


func _pick_target(exclude: Array[Enemy]) -> Enemy:
	var reach := stats.attack_range()
	var best: Enemy = null
	var best_progress := -1.0
	for e in world.enemies:
		if not Enemy.is_targetable(e) or exclude.has(e):
			continue
		if stats.is_ground_only() and e.flying:
			continue
		if e.position.distance_to(aim_center) > reach:
			continue
		if e.distance > best_progress:
			best_progress = e.distance
			best = e
	return best
