class_name SeaBird
extends Node2D
## Ptak przelatujący nad mapą (klucz poziomu "birds", grafika assets/enemies/desert_bird_fly.png). Leci prosto od krawędzi do krawędzi
## i co chwilę zrzuca jajko na wroga pod sobą (symboliczne obrażenia). Liczby: data/balance.gd (BIRD_*).

var world: GameWorld

var _velocity := Vector2.ZERO
var _egg_cd := 0.5
var _flap := 0.0


## Startuje za lewą albo prawą krawędzią ekranu na losowej wysokości.
func setup_random() -> void:
	var from_left := randf() < 0.5
	var y := randf_range(GameConfig.TOP + 60, GameConfig.H - 120)
	position = Vector2(-40 if from_left else GameConfig.W + 40, y)
	var target_y := clampf(y + randf_range(-120, 120), GameConfig.TOP + 40, GameConfig.H - 100)
	var to := Vector2(GameConfig.W + 50 if from_left else -50, target_y)
	_velocity = (to - position).normalized() * Balance.BIRD_SPEED


func is_finished() -> bool:
	return position.x < -60 or position.x > GameConfig.W + 60


func tick(dt: float) -> void:
	position += _velocity * dt
	_flap += dt
	_egg_cd -= dt
	if _egg_cd > 0:
		return
	var target := _nearest_enemy()
	if target == null:
		return
	_egg_cd = Balance.BIRD_EGG_RELOAD
	var egg := Projectile.new()
	egg.setup_dart(position + Vector2(0, 4), target, Balance.BIRD_EGG_DAMAGE, Balance.BIRD_EGG_SPEED, "egg")
	world.add_projectile(egg)


func _nearest_enemy() -> Enemy:
	var best: Enemy = null
	var best_dist := Balance.BIRD_RANGE
	for e in world.enemies:
		if not Enemy.is_targetable(e):
			continue
		var d := e.position.distance_to(position)
		if d < best_dist:
			best_dist = d
			best = e
	return best


# ---------------- rysowanie ----------------
func _process(_delta: float) -> void:
	queue_redraw()


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _draw() -> void:
	# cień daleko na ziemi i ptak lecący w stronę ruchu
	draw_circle(Vector2(0, 40), 5.0, Color(0, 0, 0, 0.15))
	UnitSprites.draw(self, "enemies/desert_bird_fly", "desert_bird", Vector2(0, 12), _flap, -1.0 if _velocity.x < 0 else 1.0)
