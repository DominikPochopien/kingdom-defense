class_name Hud
extends Node2D
## Pasek interfejsu w trakcie gry: życia, złoto, fala, przyciski na górze,
## umiejętności i "Następna fala" na dole, napis PAUZA i podpowiedzi.

signal levels_requested
signal fullscreen_requested

const H := GameConfig.H
const W := GameConfig.W
const R_FULL := Rect2(830, 6, 80, 32)
const R_MENU := Rect2(920, 6, 80, 32)
const R_MUTE := Rect2(1010, 6, 80, 32)
const R_PAUSE := Rect2(1100, 6, 80, 32)
const R_SPEED := Rect2(1190, 6, 80, 32)
const R_FIRE := Rect2(10, H - 66, 130, 56)
const R_REINF := Rect2(150, H - 66, 130, 56)
const R_NEXT := Rect2(W - 210, H - 62, 200, 52)
## duży pasek HP bossa pod górnym paskiem (wrogowie z "boss_bar" w data/enemy_data.gd)
const BOSS_BAR := Rect2(W / 2.0 - 280, GameConfig.TOP + 26, 560, 14)
const BOSS_BAR_SEGMENTS := 20
const ICON_GOLD := preload("res://assets/ui/icon_gold.png")
const ICON_LIFE := preload("res://assets/ui/icon_life.png")
const ICON_WAVE := preload("res://assets/ui/icon_wave.png")
const ICON_FIRE := preload("res://assets/ui/icon_skill_fire_rain.png")
const ICON_REINF := preload("res://assets/ui/icon_skill_reinforcements.png")
## ikony paska 12 px rysowane w skali 2x
const BAR_ICON := 24.0

var world: GameWorld


func _ready() -> void:
	# ikony to pixel art - ostre piksele
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


## Obsługa kliknięcia; zwraca true, jeśli kliknięto w element interfejsu.
func handle_click(p: Vector2) -> bool:
	if R_FULL.has_point(p):
		fullscreen_requested.emit()
	elif R_MENU.has_point(p):
		levels_requested.emit()
	elif R_PAUSE.has_point(p):
		world.paused = not world.paused
	elif R_SPEED.has_point(p):
		world.game_speed = 2.0 if world.game_speed == 1.0 else 1.0
	elif R_MUTE.has_point(p):
		Audio.toggle_mute()
	elif R_NEXT.has_point(p):
		world.start_next_wave()
	elif R_FIRE.has_point(p):
		_toggle_ability(Abilities.Kind.FIRE)
	elif R_REINF.has_point(p):
		_toggle_ability(Abilities.Kind.REINFORCEMENTS)
	else:
		return false
	return true


func _toggle_ability(kind: Abilities.Kind) -> void:
	if world.abilities.is_ready(kind):
		world.abilities.toggle_targeting(kind)
		world.selected_spot = null


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	_draw_top_bar()
	_draw_boss_bar()
	_draw_abilities()
	_draw_wave_info()
	if world.abilities.is_targeting():
		# pod paskiem bossa, gdy jest widoczny
		UiDraw.text(self, Vector2(0, 80 if _boss() == null else 124), "Kliknij na mapie, aby użyć umiejętności (PPM - anuluj)", 18,
			Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, W)
	if world.paused:
		draw_rect(Rect2(0, GameConfig.TOP, W, H - GameConfig.TOP), Color(0, 0, 0, 0.35))
		UiDraw.text(self, Vector2(0, H / 2.0), "PAUZA", 48, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, W)
	_draw_selected_tower_line()


func _draw_top_bar() -> void:
	draw_rect(Rect2(0, 0, W, GameConfig.TOP), Color(0.1, 0.08, 0.06, 0.92))
	_draw_counter(14, ICON_LIFE, str(world.lives), Color(1, 0.45, 0.45))
	_draw_counter(150, ICON_GOLD, str(world.gold), Color(1, 0.88, 0.3))
	_draw_counter(300, ICON_WAVE, "%d / %d" % [world.spawner.wave, world.spawner.total_waves], Color(0.9, 0.95, 1))
	UiDraw.text(self, Vector2(440, 29), world.level.name, 16, Color(0.8, 0.9, 0.8))
	UiDraw.button(self, R_FULL, "Ekran F11", UiDraw.BUTTON_GRAY)
	UiDraw.button(self, R_MENU, "Poziomy", UiDraw.BUTTON_GRAY)
	UiDraw.button(self, R_MUTE, "Cisza" if Audio.muted else "Dźwięk", UiDraw.BUTTON_GRAY)
	UiDraw.button(self, R_PAUSE, "Start" if world.paused else "Pauza", UiDraw.BUTTON_GRAY)
	UiDraw.button(self, R_SPEED, "Tempo x%d" % int(world.game_speed), UiDraw.BUTTON_GRAY)


## Żyjący wróg z "boss_bar" (np. Mumia) albo null.
func _boss() -> Enemy:
	for e in world.enemies:
		if Enemy.is_alive(e) and EnemyData.get_info(e.type).get("boss_bar", false):
			return e
	return null


## Nazwa i HP żyjącego bossa z "boss_bar" (np. Mumii) - pasek na środku pod górnym paskiem.
func _draw_boss_bar() -> void:
	var boss := _boss()
	if boss == null:
		return
	var r := BOSS_BAR
	var frac := clampf(boss.hp / boss.max_hp, 0.0, 1.0)
	draw_rect(Rect2(r.position - Vector2(10, 26), r.size + Vector2(20, 34)), Color(0.05, 0.03, 0.06, 0.7))
	UiDraw.text(self, Vector2(r.position.x, r.position.y - 7), boss.title, 18, Color(1, 0.85, 1),
		HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	draw_rect(r, Color(0.25, 0.08, 0.22))
	draw_rect(Rect2(r.position, Vector2(r.size.x * frac, r.size.y)), Color(0.85, 0.25, 0.75))
	draw_rect(Rect2(r.position, Vector2(r.size.x * frac, 4)), Color(0.98, 0.55, 0.92))
	for k in range(1, BOSS_BAR_SEGMENTS):
		var x := r.position.x + r.size.x * k / BOSS_BAR_SEGMENTS
		draw_line(Vector2(x, r.position.y), Vector2(x, r.end.y), Color(0.1, 0.02, 0.1, 0.6), 1.0)
	draw_rect(r, Color(0.1, 0.02, 0.1), false, 2.0)
	UiDraw.text(self, Vector2(r.position.x, r.end.y - 2), "%d / %d" % [ceili(boss.hp), roundi(boss.max_hp)], 12,
		Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)


## Ikona w górnym pasku i liczba obok niej.
func _draw_counter(x: float, icon: Texture2D, value: String, color: Color) -> void:
	draw_texture_rect(icon, Rect2(x, (GameConfig.TOP - BAR_ICON) / 2.0, BAR_ICON, BAR_ICON), false)
	UiDraw.text(self, Vector2(x + BAR_ICON + 6, 29), value, 20, color)


func _draw_abilities() -> void:
	_draw_ability(R_FIRE, Abilities.Kind.FIRE, "Deszcz ognia", ICON_FIRE, Color(0.75, 0.3, 0.1), Color(0.95, 0.5, 0.1))
	_draw_ability(R_REINF, Abilities.Kind.REINFORCEMENTS, "Posiłki", ICON_REINF, Color(0.15, 0.5, 0.7), Color(0.2, 0.7, 0.9))


func _draw_ability(r: Rect2, kind: Abilities.Kind, label: String, icon: Texture2D, color: Color, active_color: Color) -> void:
	var abilities := world.abilities
	var is_ready := abilities.is_ready(kind)
	var sub := "gotowe" if is_ready else "%ds" % int(ceil(abilities.cooldown_of(kind)))
	UiDraw.button(self, r, label, active_color if abilities.targeting == kind else color, is_ready, sub, true, icon)


func _draw_wave_info() -> void:
	var spawner := world.spawner
	if not spawner.has_more_waves():
		return
	var can_call := not spawner.is_spawning()
	var sub := ""
	if can_call and not world.enemies.is_empty():
		sub = "+%d zł bonus" % Balance.EARLY_BONUS
	UiDraw.button(self, R_NEXT, "Następna fala", UiDraw.BUTTON_GREEN, can_call, sub)
	var parts := []
	for group in spawner.next_composition():
		parts.append("%d %s" % [group[1], EnemyData.get_info(group[0]).name])
	var line := "Fala %d: %s" % [spawner.wave + 1, ", ".join(parts)]
	UiDraw.text(self, Vector2(R_NEXT.position.x - 440, H - 20), line, 14, Color(1, 1, 1, 0.9),
		HORIZONTAL_ALIGNMENT_RIGHT, 430.0)


func _draw_selected_tower_line() -> void:
	var spot := world.selected_spot
	if spot == null or spot.is_empty():
		return
	var stats := spot.tower.stats
	var line := "%s  (poz. %d)" % [stats.display_name(), stats.level]
	if stats.uses_soldiers():
		line += "   Żołnierze: %d HP" % int(stats.soldier_hp())
	else:
		line += "   Obrażenia: %d" % int(stats.damage())
	UiDraw.text(self, Vector2(300, H - 22), line, 16, Color.WHITE)
