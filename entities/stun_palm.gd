class_name StunPalm
extends Node2D
## Palma (klucz poziomu "palms") - sprzymierzeniec na mapie. Co PALM_MIN_TIME-PALM_MAX_TIME s
## zrzuca kokosy na wszystkich wrogów w swoim obszarze: zadaje małe obrażenia i ogłusza ich.
## Gdy w obszarze nikogo nie ma, czeka naładowana na pierwszego wroga. Liczby: data/balance.gd (PALM_*).

const SWAY := preload("res://assets/objects/palm_sway.png")
const COCONUT_FALL := preload("res://assets/objects/palm_coconut_fall.png")
## klatka grafiki (piksele obrazka) i miejsce podstawy pnia w klatce
const FRAME := Vector2(24, 40)
const BASE := Vector2(9, 38)
const SWAY_FRAMES := 2
const SWAY_FPS := 2.0
const FALL_FRAMES := 4
## jak długo trwa zrzucanie kokosów (trzęsienie liśćmi i animacja spadania)
const SHAKE_TIME := 0.6
## korona palmy względem jej podstawy
const CROWN := Vector2(8, -48)

var world: GameWorld
## środek i promień obszaru, w który spadają kokosy (współrzędne świata)
var center := Vector2.ZERO
var radius := 90.0

var _cooldown := 0.0
var _shake := 0.0
var _anim := 0.0


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func setup(def: Dictionary) -> void:
	position = def.pos
	center = def.center
	radius = def.radius
	_cooldown = Balance.PALM_FIRST


func is_finished() -> bool:
	return false


func is_ready() -> bool:
	return _cooldown <= 0


func cooldown() -> float:
	return maxf(_cooldown, 0.0)


func tick(dt: float) -> void:
	_anim += dt
	_shake = maxf(_shake - dt, 0.0)
	_cooldown -= dt
	if _cooldown > 0:
		return
	var hit := false
	for e in world.enemies:
		if Enemy.is_targetable(e) and e.position.distance_to(center) <= radius:
			world.add_effect(position + CROWN, "coconut", 6.0, e.body_position(), 0.35)
			e.take_damage(Balance.PALM_DAMAGE, false)
			e.apply_stun(Balance.PALM_STUN)
			hit = true
	if not hit:
		return
	_cooldown = randf_range(Balance.PALM_MIN_TIME, Balance.PALM_MAX_TIME)
	_shake = SHAKE_TIME
	world.add_float(center + Vector2(-34, -50), "Kokosy!", Color(0.6, 1.0, 0.4))
	Audio.play("boom")


func contains(p: Vector2) -> bool:
	return p.distance_to(position + Vector2(0, -30)) < 34.0


# ---------------- rysowanie ----------------
func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	# obszar działania: przerywany okrąg, jaśniejszy, gdy palma jest gotowa
	var c := center - position
	var alpha := 0.55 if is_ready() else 0.25
	for k in 24:
		var a := k * TAU / 24.0
		draw_arc(c, radius, a, a + TAU / 48.0, 4, Color(0.3, 0.9, 0.35, alpha), 2.5)
	# palma: kołysze się, a przy zrzucaniu kokosów pokazuje ich spadanie
	var sheet := SWAY
	var frame := int(_anim * SWAY_FPS) % SWAY_FRAMES
	if _shake > 0:
		sheet = COCONUT_FALL
		frame = mini(int((1.0 - _shake / SHAKE_TIME) * FALL_FRAMES), FALL_FRAMES - 1)
	var px := float(LevelScene.PIXEL)
	draw_texture_rect_region(sheet, Rect2(-BASE * px, FRAME * px), Rect2(Vector2(frame * FRAME.x, 0), FRAME))
