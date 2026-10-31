class_name InfoPanel
extends Node2D
## Panele ze statystykami: podgląd przycisku menu budowy (nowa wieża / po ulepszeniu),
## wybrana wieża, wróg / żołnierz / wieża pod kursorem.

const COLOR_TOWER := Color(0.5, 0.8, 1.0)
const COLOR_UPGRADE := Color(0.5, 1.0, 0.5)
const COLOR_BRANCH := Color(0.75, 0.5, 0.95)
const COLOR_ENEMY := Color(1, 0.5, 0.45)
const COLOR_SOLDIER := Color(0.4, 0.75, 1.0)
const LIGHT := UiDraw.TEXT_LIGHT
const HP_COLOR := Color(1, 0.5, 0.5)
const DMG_COLOR := Color(1, 0.88, 0.5)
const GOLD_COLOR := Color(1, 0.88, 0.3)

var world: GameWorld


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if not world.active:
		return
	var mouse := get_global_mouse_position()
	var spot := world.selected_spot
	if spot != null:
		var hovered := world.build_menu.hovered_button()
		if hovered != null:
			_draw_button_preview(spot, hovered)
			return
		if not spot.is_empty():
			var t := spot.tower
			UiDraw.panel(self, _beside_spot(spot), t.stats.title(), tower_lines(t.stats, t), COLOR_TOWER)
	var enemy := world.enemy_at(mouse)
	if enemy == null and Enemy.is_alive(world.selected_enemy):
		enemy = world.selected_enemy
	if enemy != null:
		UiDraw.panel(self, enemy.body_position() + Vector2(28, -50), enemy.title, enemy_lines(enemy), COLOR_ENEMY)
		return
	var soldier := world.soldier_at(mouse)
	if soldier != null:
		UiDraw.panel(self, soldier.position + Vector2(24, -40), soldier.display_name(), soldier_lines(soldier), COLOR_SOLDIER)
		return
	var tower := world.tower_at(mouse)
	if tower != null and not (spot != null and spot.tower == tower):
		UiDraw.panel(self, tower.position + Vector2(40, -50), tower.stats.title(), tower_lines(tower.stats, tower), COLOR_TOWER)
		return
	var palm := world.palm_at(mouse)
	if palm != null:
		UiDraw.panel(self, palm.position + Vector2(40, -80), "Palma", palm_lines(palm), COLOR_SOLDIER)
		return
	var war_tower := world.war_tower_at(mouse)
	if war_tower != null:
		UiDraw.panel(self, _beside_point(war_tower.position + Vector2(0, -60)), "Wieża wroga", war_tower_lines(war_tower), COLOR_ENEMY)


## Panel obok miejsca budowy (z prawej, a przy prawej krawędzi ekranu - z lewej).
func _beside_spot(spot: BuildSpot) -> Vector2:
	var pos := spot.position + Vector2(150, -60)
	if pos.x + UiDraw.PANEL_WIDTH > GameConfig.W:
		pos.x = spot.position.x - 150 - UiDraw.PANEL_WIDTH
	return pos


## Panel obok punktu (z prawej, a przy prawej krawędzi ekranu - z lewej).
func _beside_point(p: Vector2) -> Vector2:
	var pos := p + Vector2(40, 0)
	if pos.x + UiDraw.PANEL_WIDTH > GameConfig.W:
		pos.x = p.x - 40 - UiDraw.PANEL_WIDTH
	return pos


func _draw_button_preview(spot: BuildSpot, b: UiButton) -> void:
	var pos := _beside_spot(spot)
	match b.action:
		"build":
			var stats := TowerStats.new(b.tower_type)
			UiDraw.panel(self, pos, stats.display_name() + " (nowa)", tower_lines(stats, null), COLOR_TOWER)
		"upgrade":
			var current := spot.tower.stats
			var stats := current.preview(current.level + 1, current.branch)
			UiDraw.panel(self, pos, "Po ulepszeniu: poz. %d" % stats.level, tower_lines(stats, null), COLOR_UPGRADE)
		"branch":
			var stats := spot.tower.stats.preview(TowerStats.BRANCH_LEVEL, b.branch_id)
			var lines := [[b.description, Color(0.8, 0.95, 1.0)], ["", Color.WHITE]]
			lines.append_array(tower_lines(stats, null))
			UiDraw.panel(self, pos, b.label, lines, COLOR_BRANCH)
		"rally":
			UiDraw.panel(self, pos, b.label, [
				["Kliknij drogę w zasięgu wieży, aby wskazać żołnierzom, gdzie mają stanąć.", Color(0.8, 0.95, 1.0)],
				["Prawy przycisk / Esc - anuluj", Color(0.7, 0.7, 0.75)],
			], COLOR_TOWER)


## Linie [tekst, kolor] opisujące wieżę. tower = null oznacza podgląd (wieża jeszcze nie istnieje).
func tower_lines(stats: TowerStats, tower: Tower) -> Array:
	var lines := []
	if stats.uses_soldiers():
		if tower == null:
			lines.append(["Żołnierze: %d" % stats.soldier_count(), LIGHT])
		else:
			var st := tower as SoldierTower
			lines.append(["Żołnierze: %d / %d żywych" % [st.alive_soldiers(), st.soldiers.size()], LIGHT])
		lines.append(["HP żołnierza: %d" % int(stats.soldier_hp()), HP_COLOR])
		lines.append(["Obrażenia: %d / s (fizyczne)" % int(stats.damage()), DMG_COLOR])
		lines.append(["Zasięg walki: %d" % int(stats.attack_range()), LIGHT])
		lines.append(["Odradzanie: %d s" % int(stats.respawn_time()), LIGHT])
		lines.append(["Cele: " + stats.targets_description(), Color(0.4, 0.9, 0.5) if stats.has_knights() else LIGHT])
	else:
		var dmg_type := "magiczne" if stats.is_magic() else "fizyczne"
		lines.append(["Obrażenia: %d (%s)" % [int(stats.damage()), dmg_type], DMG_COLOR])
		lines.append(["Szybkość: %.1f strzału / s" % (1.0 / stats.reload_time()), LIGHT])
		lines.append(["DPS (bez pancerza): %d" % int(stats.damage() * stats.shots() / stats.reload_time()), Color(1, 0.7, 0.4)])
		lines.append(["Zasięg: %d" % int(stats.attack_range()), LIGHT])
		if stats.has_cannons():
			lines.append(["Armaty: %d" % stats.shots(), LIGHT])
		if stats.burn_damage() > 0:
			lines.append(["Podpalenie: %d obrażeń przez %d s" % [int(stats.burn_damage()), int(stats.burn_time())],
				Color(1, 0.6, 0.3)])
		if stats.volley_shots() > 0:
			lines.append(["Salwa: %d pocisków co %d s w losowe cele" % [stats.volley_shots(), int(stats.volley_period())],
				Color(1, 0.85, 0.4)])
		if stats.splash_radius() > 0:
			lines.append(["Promień wybuchu: %d" % int(stats.splash_radius()), LIGHT])
		lines.append(["Cele: " + stats.targets_description(), LIGHT])
	var branch := stats.branch_info()
	if not branch.is_empty():
		lines.append(["Ulepszenie: " + branch.name, Color(0.4, 0.95, 1.0)])
		lines.append([branch.desc, Color(0.7, 0.9, 1.0)])
	if tower != null and stats.is_sellable():
		lines.append(["Sprzedaż: +%d zł" % tower.sell_value(), Color(0.7, 0.7, 0.7)])
	return lines


func enemy_lines(e: Enemy) -> Array:
	var lines := []
	lines.append(["HP: %d / %d" % [int(ceil(e.hp)), int(e.max_hp)], HP_COLOR])
	lines.append(["Pancerz (fizyczny): " + UiDraw.percent(e.armor), LIGHT])
	lines.append(["Odporność na magię: " + UiDraw.percent(e.magic_resist), LIGHT])
	var speed_line := "Prędkość: %d" % int(e.speed)
	if e.haste_time > 0:
		speed_line += " (przyspieszony +%d%%)" % roundi((e.haste_mult - 1.0) * 100.0)
	if e.slow_time > 0:
		speed_line += " (spowolniony)"
	lines.append([speed_line, Color(0.6, 0.85, 1.0) if e.slow_time > 0 or e.haste_time > 0 else LIGHT])
	lines.append(["Typ: " + ("latający (omija blokadę)" if e.flying else "naziemny"), LIGHT])
	if e.damage > 0:
		lines.append(["Obrażenia vs żołnierz: %d / s" % int(e.damage), LIGHT])
	lines.append(["Odbiera żyć: %d" % e.lives_cost, Color(1, 0.6, 0.5)])
	lines.append(["Nagroda: %d zł" % e.reward, GOLD_COLOR])
	var info := EnemyData.get_info(e.type)
	if info.get("ability", "") == "heal":
		lines.append(["Umiejętność - Rytuał: co %d s leczy wrogów w promieniu %d o %s ich max HP"
			% [int(info.heal_interval), int(info.heal_radius), UiDraw.percent(info.heal_pct)], Color(0.5, 1.0, 0.6)])
	elif info.get("ability", "") == "breath":
		lines.append(["Zionięcie ogniem: co %d s pali %d najbliższych żołnierzy (%d obrażeń, zasięg %d)"
			% [int(info.breath_interval), int(info.breath_targets), int(info.breath_damage), int(info.breath_range)],
			Color(1, 0.6, 0.3)])
	elif info.get("ability", "") == "magic_knight":
		lines.append(["Pieczęć: co %d s wyłącza wieże w promieniu %d na %d s"
			% [int(info.seal_interval), int(info.seal_radius), int(info.seal_time)], Color(0.85, 0.6, 1.0)])
		lines.append(["Pośpiech: co %d s przez %d s wrogowie w promieniu %d są %d razy szybsi"
			% [int(info.haste_interval), int(info.haste_time), int(info.haste_radius), int(info.haste_mult)], Color(0.5, 0.75, 1.0)])
	elif info.get("ability", "") == "hedgehog":
		lines.append(["Kolce: co %d s rzuca w żołnierza (%d obrażeń, zasięg %d)"
			% [int(info.spike_interval), int(info.spike_damage), int(info.spike_range)], Color(0.85, 0.7, 0.5)])
		lines.append(["Turlanie: co %d s turla się coraz szybciej, nie da się go zatrzymać i taranuje żołnierzy (%d obrażeń)"
			% [int(info.roll_interval), int(info.roll_damage)], Color(1, 0.7, 0.4)])
	elif info.get("ability", "") == "archer":
		lines.append(["Łuk: co %.1f s strzela w żołnierza (%d obrażeń, zasięg %d)"
			% [float(info.arrow_interval), int(info.arrow_damage), int(info.arrow_range)], Color(0.85, 0.75, 0.6)])
	elif info.get("ability", "") == "mummy":
		lines.append(["Przywołanie: co %d s wskrzesza %d Szkieletów, %d łucznika i %d pancernego"
			% [int(info.summon_interval), int(info.summon_skeletons), int(info.summon_archers), int(info.summon_armored)],
			Color(0.55, 1.0, 0.85)])
		lines.append(["Droga umarłych: na środku mapy otwiera nową drogę dla wrogów", Color(0.85, 0.6, 1.0)])
	if e.burn_time > 0:
		lines.append(["Podpalony!", Color(1, 0.55, 0.2)])
	if e.stun_time > 0:
		lines.append(["Ogłuszony: %d s" % int(ceil(e.stun_time)), Color(1, 0.9, 0.3)])
	if is_instance_valid(e.blocked_by):
		lines.append(["Zablokowany przez żołnierza", Color(0.5, 0.9, 1.0)])
	return lines


func palm_lines(palm: StunPalm) -> Array:
	return [
		["Co %d-%d s zrzuca kokosy na wszystkich wrogów w zielonym okręgu" % [int(Balance.PALM_MIN_TIME), int(Balance.PALM_MAX_TIME)], LIGHT],
		["Obrażenia: %d, ogłuszenie: %d s" % [int(Balance.PALM_DAMAGE), int(Balance.PALM_STUN)], DMG_COLOR],
		["Gotowa - czeka na wrogów!" if palm.is_ready() else "Kokosy za: %d s" % int(ceil(palm.cooldown())), Color(0.6, 1.0, 0.4)],
	]


func war_tower_lines(wt: WarTower) -> Array:
	var state := ""
	if wt.is_active():
		state = "Płonie! Jeszcze %d s" % int(ceil(wt.active_left()))
	elif wt.is_ready():
		state = "Gotowa - czeka na wrogów!"
	else:
		state = "Ogień za: %d s" % int(ceil(wt.cooldown()))
	return [
		["Co %d-%d s rozpala ogień: przez %d s wrogowie w czerwonym okręgu biegną o %d%% szybciej"
			% [int(Balance.WAR_TOWER_MIN_TIME), int(Balance.WAR_TOWER_MAX_TIME), int(Balance.WAR_TOWER_ACTIVE),
			roundi((Balance.WAR_TOWER_HASTE - 1.0) * 100.0)], LIGHT],
		["Nie da się jej zniszczyć", Color(0.7, 0.7, 0.7)],
		[state, Color(1, 0.5, 0.4)],
	]


func soldier_lines(s: Soldier) -> Array:
	var lines := [
		["HP: %d / %d" % [int(ceil(s.hp)), int(s.max_hp)], HP_COLOR],
		["Obrażenia: %d / s" % int(s.damage), DMG_COLOR],
		["Zasięg walki: %d" % int(s.radius), LIGHT],
	]
	if s.lifetime > 0:
		lines.append(["Znika za: %d s" % int(ceil(s.lifetime)), Color(0.7, 0.9, 1.0)])
	if s is HeroKnight:
		var hero := s as HeroKnight
		lines.append(["Obrót: przez %d s rani wrogów wokół (%d co %s s)"
			% [int(Balance.HERO_SPIN_TIME), int(Balance.HERO_SPIN_DAMAGE), str(Balance.HERO_SPIN_TICK)], Color(1, 0.85, 0.3)])
		lines.append(["Obrót TRWA!" if hero.is_spinning() else "Obrót gotowy za: %d s" % int(ceil(hero.spin_cooldown())),
			Color(1, 0.85, 0.3)])
		lines.append(["Tylko wręcz - nie bije latających", LIGHT])
	return lines
