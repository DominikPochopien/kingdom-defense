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

var world: GameWorld


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
	_draw_abilities()
	_draw_wave_info()
	if world.abilities.is_targeting():
		UiDraw.text(self, Vector2(0, 80), "Kliknij na mapie, aby użyć umiejętności (PPM - anuluj)", 18,
			Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, W)
	if world.paused:
		draw_rect(Rect2(0, GameConfig.TOP, W, H - GameConfig.TOP), Color(0, 0, 0, 0.35))
		UiDraw.text(self, Vector2(0, H / 2.0), "PAUZA", 48, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, W)
	_draw_selected_tower_line()


func _draw_top_bar() -> void:
	draw_rect(Rect2(0, 0, W, GameConfig.TOP), Color(0.1, 0.08, 0.06, 0.92))
	UiDraw.text(self, Vector2(14, 29), "Życia: %d" % world.lives, 20, Color(1, 0.45, 0.45))
	UiDraw.text(self, Vector2(150, 29), "Złoto: %d" % world.gold, 20, Color(1, 0.88, 0.3))
	UiDraw.text(self, Vector2(300, 29), "Fala: %d / %d" % [world.spawner.wave, world.spawner.total_waves], 20, Color(0.9, 0.95, 1))
	UiDraw.text(self, Vector2(440, 29), world.level.name, 16, Color(0.8, 0.9, 0.8))
	UiDraw.button(self, R_FULL, "Ekran F11", UiDraw.BUTTON_GRAY)
	UiDraw.button(self, R_MENU, "Poziomy", UiDraw.BUTTON_GRAY)
	UiDraw.button(self, R_MUTE, "Cisza" if Audio.muted else "Dźwięk", UiDraw.BUTTON_GRAY)
	UiDraw.button(self, R_PAUSE, "Start" if world.paused else "Pauza", UiDraw.BUTTON_GRAY)
	UiDraw.button(self, R_SPEED, "Tempo x%d" % int(world.game_speed), UiDraw.BUTTON_GRAY)


func _draw_abilities() -> void:
	_draw_ability(R_FIRE, Abilities.Kind.FIRE, "Deszcz ognia", Color(0.75, 0.3, 0.1), Color(0.95, 0.5, 0.1))
	_draw_ability(R_REINF, Abilities.Kind.REINFORCEMENTS, "Posiłki", Color(0.15, 0.5, 0.7), Color(0.2, 0.7, 0.9))


func _draw_ability(r: Rect2, kind: Abilities.Kind, label: String, color: Color, active_color: Color) -> void:
	var abilities := world.abilities
	var is_ready := abilities.is_ready(kind)
	var sub := "gotowe" if is_ready else "%ds" % int(ceil(abilities.cooldown_of(kind)))
	UiDraw.button(self, r, label, active_color if abilities.targeting == kind else color, is_ready, sub)


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
