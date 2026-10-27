class_name GameWorld
extends Node2D
## Rozgrywka na jednym poziomie: stan (złoto, życia, fale), jednostki i zasady gry.
##
## Jednostki to węzły w warstwach-dzieciach (Towers, Soldiers, Enemies, ...). Kolejność
## warstw w main.tscn = kolejność rysowania. Logikę gry wykonuje _tick() - woła tick()
## każdej jednostki w stałej kolejności, tylko gdy gra trwa i nie jest zapauzowana.

signal won
signal lost

@onready var map: LevelMap = $Map
@onready var build_menu: BuildMenu = $BuildMenu
@onready var _towers_layer: Node2D = $Towers
@onready var _soldiers_layer: Node2D = $Soldiers
@onready var _enemies_layer: Node2D = $Enemies
@onready var _projectiles_layer: Node2D = $Projectiles
@onready var _strikes_layer: Node2D = $Strikes
@onready var _effects_layer: Node2D = $Effects
@onready var _texts_layer: Node2D = $FloatingTexts

## zapis checkpointów; ustawiany przez main.gd
var save: SaveManager

var level_index := 0
var level: Dictionary = {}
var paths: PathNetwork
var bridges: BridgeSystem
var spawner := WaveSpawner.new()
var abilities := Abilities.new()

var gold := 0
var lives := 0
## true w trakcie rozgrywki; false w menu, na ekranie wyboru poziomu i po końcu gry
var active := false
var paused := false
var game_speed := 1.0

var spots: Array[BuildSpot] = []
var enemies: Array[Enemy] = []
var soldiers: Array[Soldier] = []
var projectiles: Array[Projectile] = []
var strikes: Array[FireStrike] = []
var effects: Array[VisualEffect] = []
var texts: Array[FloatingText] = []

var selected_spot: BuildSpot = null
var selected_enemy: Enemy = null

var _hp_mult := 1.0
## czy w poprzedniej klatce trwała fala (do automatycznego zapisu po jej końcu)
var _was_busy := false


# ================= START POZIOMU =================
## Ładuje mapę poziomu bez rozpoczynania gry (tło menu głównego).
func show_level(index: int) -> void:
	_clear_units()
	level_index = index
	level = LevelData.get_level(index)
	paths = PathNetwork.new(LevelData.routes_of(level))
	bridges = BridgeSystem.new(level, paths)
	bridges.switched.connect(_on_bridge_switched)
	spots.clear()
	var positions: Array = level.spots
	for i in positions.size():
		spots.append(BuildSpot.new(i, positions[i]))
	_hp_mult = level.hp
	spawner.reset(level.waves, level.get("shamans", false))
	map.setup(level, index, paths, bridges, spots)


func start(index: int) -> void:
	show_level(index)
	gold = level.gold
	lives = level.lives
	paused = false
	game_speed = 1.0
	abilities.reset()
	_was_busy = false
	_place_special_tower()
	active = true


## Wznawia rozgrywkę z checkpointu zapisanego przez save_run().
func restore(index: int, data: Dictionary) -> void:
	start(index)
	gold = int(data.gold)
	lives = int(data.lives)
	spawner.wave = int(data.wave)
	abilities.fire_cooldown = float(data.get("fire_cd", 0.0))
	abilities.reinf_cooldown = float(data.get("reinf_cd", 0.0))
	for td in data.towers:
		var i := int(td.spot)
		if i >= 0 and i < spots.size():
			if not spots[i].is_empty():
				spots[i].tower.remove()   # darmowa wieża postawiona przez start()
			_place_tower(spots[i], td.type, int(td.level), td.branch, int(td.spent))
	bridges.active = int(data.get("bridge", 0))
	bridges.timer = float(data.get("bridge_timer", bridges.period))
	bridges.snap()


## Darmowa wieża poziomu (np. Wieża Rycerska na "Rozdrożach").
func _place_special_tower() -> void:
	if level.has("special_tower"):
		_place_tower(spots[level.special_tower], "knight_tower", 1, "", 0)


func _clear_units() -> void:
	for layer in [_towers_layer, _soldiers_layer, _enemies_layer, _projectiles_layer,
			_strikes_layer, _effects_layer, _texts_layer]:
		for child in layer.get_children():
			child.queue_free()
	for list in [enemies, soldiers, projectiles, strikes, effects, texts]:
		list.clear()
	selected_spot = null
	selected_enemy = null
	active = false


# ================= PĘTLA GRY =================
func _process(delta: float) -> void:
	if active and not paused:
		_tick(delta * game_speed)
	if bridges != null:
		bridges.animate(delta)


func _tick(dt: float) -> void:
	bridges.update(dt, enemies)
	abilities.update(dt)
	var spawn_type := spawner.update(dt)
	if spawn_type != "":
		_spawn_enemy(spawn_type)
	for e in enemies:
		e.tick(dt)
	for s in soldiers:
		s.tick(dt)
	for spot in spots:
		if not spot.is_empty():
			spot.tower.tick(dt)
	for p in projectiles:
		p.tick(dt)
	for st in strikes:
		st.tick(dt)
	for f in effects:
		f.tick(dt)
	for t in texts:
		t.tick(dt)
	for list in [enemies, soldiers, projectiles, strikes, effects, texts]:
		_remove_finished(list)
	if not Enemy.is_alive(selected_enemy):
		selected_enemy = null
	_autosave_after_wave()
	_check_game_over()


func _remove_finished(list: Array) -> void:
	for i in range(list.size() - 1, -1, -1):
		if list[i].is_finished():
			list[i].queue_free()
			list.remove_at(i)


func _autosave_after_wave() -> void:
	var busy := spawner.is_spawning() or not enemies.is_empty()
	if _was_busy and not busy and spawner.has_more_waves() and lives > 0:
		_was_busy = false
		save_run()
	_was_busy = busy


func _check_game_over() -> void:
	if lives <= 0:
		lives = 0
		active = false
		lost.emit()
	elif not spawner.has_more_waves() and not spawner.is_spawning() and enemies.is_empty():
		active = false
		won.emit()


func _on_bridge_switched(bridge_name: String) -> void:
	add_float(Vector2(GameConfig.W / 2.0 - 60.0, 90.0), bridge_name + " otwarty!", Color(0.5, 1.0, 0.5))
	Audio.play("wave")


# ================= FALE =================
func can_call_wave() -> bool:
	return active and spawner.has_more_waves() and not spawner.is_spawning()


func start_next_wave() -> void:
	if not can_call_wave():
		return
	if not enemies.is_empty():
		gold += Balance.EARLY_BONUS
		add_float(Vector2(GameConfig.W - 110, GameConfig.H - 80), "+%d bonus" % Balance.EARLY_BONUS, Color(1, 0.85, 0.3))
	spawner.start_next_wave()
	Audio.play("wave")


func _spawn_enemy(type: String) -> void:
	var route := 0
	if bridges.is_enabled():
		route = bridges.active
	elif level.has("random_routes_from") and spawner.wave >= level.random_routes_from:
		route = randi() % paths.route_count()
	var enemy := EnemyFactory.create(type, _hp_mult, route)
	enemy.position = paths.position_at(0.0, route)
	_add_unit(enemy, _enemies_layer, enemies)


# ================= DODAWANIE JEDNOSTEK I EFEKTÓW =================
## node: dowolna jednostka lub efekt z polem `world`.
func _add_unit(node, layer: Node2D, list: Array) -> void:
	node.world = self
	list.append(node)
	layer.add_child(node)


func add_soldier(soldier: Soldier) -> void:
	_add_unit(soldier, _soldiers_layer, soldiers)


func add_projectile(projectile: Projectile) -> void:
	_add_unit(projectile, _projectiles_layer, projectiles)


func add_effect(pos: Vector2, kind: String, radius: float, to := Vector2.ZERO, duration := 0.4) -> void:
	var fx := VisualEffect.new()
	fx.setup(pos, kind, radius, to, duration)
	_add_unit(fx, _effects_layer, effects)


func add_float(pos: Vector2, text: String, color: Color) -> void:
	var label := FloatingText.new()
	label.setup(pos, text, color)
	_add_unit(label, _texts_layer, texts)


# ================= WALKA I EKONOMIA =================
func explode(pos: Vector2, radius: float, damage: float, magic: bool, ground_only: bool) -> void:
	for e in enemies:
		if e.dead or (ground_only and e.flying):
			continue
		if e.position.distance_to(pos) <= radius:
			e.take_damage(damage, magic)
	add_effect(pos, "boom", radius)
	Audio.play("boom")


func add_gold(amount: int) -> void:
	gold += amount


func lose_lives(amount: int) -> void:
	lives -= amount
	add_float(Vector2(GameConfig.W - 120, 90), "-%d życie" % amount, Color(1, 0.3, 0.3))
	Audio.play("hurt")


# ================= WIEŻE =================
func _place_tower(spot: BuildSpot, type: String, tower_level: int, branch: String, spent: int) -> Tower:
	var tower := TowerFactory.create(type)
	tower.position = spot.position
	tower.setup(self, type, tower_level, branch, spent)
	_towers_layer.add_child(tower)
	spot.tower = tower
	return tower


func build_tower(spot: BuildSpot, type: String) -> void:
	var cost: int = TowerData.TOWERS[type].cost
	if gold < cost:
		return
	gold -= cost
	_place_tower(spot, type, 1, "", cost)
	Audio.play("build")
	selected_spot = null
	save_run()


func upgrade_tower(spot: BuildSpot) -> void:
	var tower := spot.tower
	var cost := tower.stats.upgrade_cost()
	if not tower.stats.can_upgrade() or gold < cost:
		return
	gold -= cost
	tower.upgrade(cost)
	Audio.play("build")
	save_run()


func choose_branch(spot: BuildSpot, branch_id: String) -> void:
	var tower := spot.tower
	var cost := tower.stats.branch_cost()
	if not tower.stats.can_choose_branch() or gold < cost:
		return
	gold -= cost
	tower.choose_branch(branch_id, cost)
	add_effect(tower.position, "ring", 40.0)
	Audio.play("build")
	save_run()


func sell_tower(spot: BuildSpot) -> void:
	gold += spot.tower.sell_value()
	spot.tower.remove()
	spot.tower = null
	selected_spot = null
	Audio.play("coin")
	save_run()


# ================= UMIEJĘTNOŚCI =================
## Używa wybranej umiejętności w punkcie p (gdy gracz celuje).
func cast_ability_at(p: Vector2) -> void:
	match abilities.consume_targeting():
		Abilities.Kind.FIRE:
			_cast_fire(p)
		Abilities.Kind.REINFORCEMENTS:
			_cast_reinforcements(p)


func _cast_fire(p: Vector2) -> void:
	for i in Balance.FIRE_STRIKES:
		var offset := Vector2.from_angle(randf() * TAU) * randf_range(0, Balance.FIRE_SPREAD)
		var strike := FireStrike.new()
		strike.setup(p + offset, Balance.FIRE_FIRST_DELAY + i * Balance.FIRE_DELAY_STEP)
		_add_unit(strike, _strikes_layer, strikes)


func _cast_reinforcements(p: Vector2) -> void:
	var c := paths.nearest_point(p)
	for i in Balance.REINF_COUNT:
		var s := Soldier.new()
		s.setup_reinforcement(c, c + Vector2(-14 + i * 28, 0))
		add_soldier(s)
	add_effect(c, "ring", 30.0)
	Audio.play("build")


# ================= WYBÓR I OBIEKTY POD KURSOREM =================
## Kliknięcie na mapie: wybór miejsca budowy albo wroga.
func select_at(p: Vector2) -> void:
	for spot in spots:
		if spot.contains(p):
			selected_spot = spot if selected_spot != spot else null
			selected_enemy = null
			return
	selected_spot = null
	var e := enemy_at(p)
	selected_enemy = e if e != selected_enemy else null


func clear_selection() -> void:
	selected_spot = null
	selected_enemy = null


func enemy_at(p: Vector2) -> Enemy:
	var best: Enemy = null
	var best_dist := 1e9
	for e in enemies:
		if e.dead:
			continue
		var d := e.body_position().distance_to(p)
		if d <= e.radius + 10.0 and d < best_dist:
			best_dist = d
			best = e
	return best


func soldier_at(p: Vector2) -> Soldier:
	for s in soldiers:
		if s.is_active() and s.position.distance_to(p) < 14.0:
			return s
	return null


func tower_at(p: Vector2) -> Tower:
	for spot in spots:
		if not spot.is_empty() and spot.contains(p, BuildSpot.HOVER_RADIUS):
			return spot.tower
	return null


# ================= ZAPIS =================
## Checkpoint zapisuje się tylko między falami (gdy na mapie nie ma wrogów).
func is_quiet() -> bool:
	return active and not spawner.is_spawning() and enemies.is_empty()


func save_run() -> void:
	if not is_quiet():
		return
	var towers := []
	for spot in spots:
		if not spot.is_empty():
			towers.append(spot.tower.to_save_data(spot.index))
	save.save_run(level_index, {
		"gold": gold, "lives": lives, "wave": spawner.wave,
		"fire_cd": abilities.fire_cooldown, "reinf_cd": abilities.reinf_cooldown,
		"towers": towers, "bridge": bridges.active, "bridge_timer": bridges.timer,
	})
