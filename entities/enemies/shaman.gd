extends Enemy
## Szaman Wojenny - co kilka sekund odprawia Rytuał leczący wrogów wokół siebie.

var heal_interval := 6.0
var heal_radius := 140.0
var heal_pct := 0.12

var _heal_cd := 3.0


func setup(enemy_type: String, hp_mult: float, start_route: int) -> void:
	super.setup(enemy_type, hp_mult, start_route)
	var info := EnemyData.get_info(enemy_type)
	_heal_cd = info.heal_first
	heal_interval = info.heal_interval
	heal_radius = info.heal_radius
	heal_pct = info.heal_pct


func _update_ability(dt: float) -> void:
	_heal_cd -= dt
	if _heal_cd > 0:
		return
	_heal_cd = heal_interval
	for other in world.enemies:
		if not other.dead and other.position.distance_to(position) <= heal_radius:
			other.heal(other.max_hp * heal_pct)
	world.add_effect(position, "heal", heal_radius)
	world.add_float(position + Vector2(0, -44), "Rytuał!", Color(0.5, 1, 0.5))
