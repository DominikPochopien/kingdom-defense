class_name VisualEffect
extends Effect
## Animacja bez wpływu na grę: "boom" (wybuch), "death" (śmierć wroga), "heal" (rytuał szamana),
## "zap" (błyskawica między dwoma punktami), "ring" (budowa/ulepszenie),
## "seal" (fioletowa aura Magicznego Rycerza wyłączająca wieże),
## "flame" (ogień smoka od punktu do celu; radius = grubość płomienia),
## "spike" (kolce Jeżowca lecące do celu), "coconut" (kokos spadający łukiem z palmy na cel).
## Wybuch, śmierć, kolce i kokos to grafiki z assets/effects/ i assets/projectiles/, reszta - kod.

const EXPLOSION := preload("res://assets/effects/explosion.png")
const DEATH_PUFF := preload("res://assets/effects/death_puff.png")
const SPIKE := preload("res://assets/projectiles/hedgehog_spike.png")
const COCONUT := preload("res://assets/projectiles/coconut.png")

var kind := ""
var radius := 0.0
var duration := 0.4
## punkt końcowy błyskawicy (współrzędne świata)
var target_pos := Vector2.ZERO

var _t := 0.0


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func setup(at: Vector2, effect_kind: String, effect_radius: float, to: Vector2, effect_duration: float) -> void:
	position = at
	kind = effect_kind
	radius = effect_radius
	target_pos = to
	duration = effect_duration


func tick(dt: float) -> void:
	_t += dt
	if _t >= duration:
		done = true


func _draw() -> void:
	var k := _t / duration
	match kind:
		"boom":
			# wybuch 32 px rośnie z promieniem, ale zawsze w całkowitej skali (równe piksele)
			_draw_frames(EXPLOSION, 5, k, Vector2.ZERO, clampi(roundi(radius / 16.0), 1, 4))
		"death":
			_draw_frames(DEATH_PUFF, 4, k, Vector2.ZERO, LevelScene.PIXEL)
		"heal":
			draw_arc(Vector2.ZERO, radius * k, 0, TAU, 40, Color(0.4, 1, 0.5, 1.0 - k), 4.0)
			draw_circle(Vector2.ZERO, radius * k, Color(0.3, 1, 0.4, 0.15 * (1.0 - k)))
		"zap":
			var to := target_pos - position
			var mid := to / 2.0 + Vector2(randf_range(-8, 8), randf_range(-8, 8))
			draw_line(Vector2.ZERO, mid, Color(0.85, 0.95, 1.0), 3.0)
			draw_line(mid, to, Color(0.85, 0.95, 1.0), 3.0)
		"seal":
			draw_circle(Vector2.ZERO, radius * k, Color(0.6, 0.2, 0.95, 0.25 * (1.0 - k)))
			draw_arc(Vector2.ZERO, radius * k, 0, TAU, 48, Color(0.8, 0.45, 1.0, 1.0 - k), 4.0)
		"flame":
			var to := target_pos - position
			draw_line(Vector2.ZERO, to, Color(1, 0.45, 0.05, 0.8 * (1.0 - k)), radius)
			draw_line(Vector2.ZERO, to, Color(1, 0.9, 0.3, 1.0 - k), radius * 0.4)
			draw_circle(to, radius * (0.8 + k), Color(1, 0.5, 0.1, 0.6 * (1.0 - k)))
		"spike":
			var to := target_pos - position
			var dir := to.normalized()
			for o: float in [-6.0, 0.0, 6.0]:
				_draw_sprite(SPIKE, to * k + dir.orthogonal() * o, dir.angle())
		"coconut":
			var to := target_pos - position
			_draw_sprite(COCONUT, to * k + Vector2(0, -40.0 * sin(PI * k)), 0.0)
		"ring":
			draw_arc(Vector2.ZERO, radius * (0.3 + k), 0, TAU, 32, Color(0.4, 0.8, 1, 1.0 - k), 3.0)


## Klatka poziomego paska `frames` klatek dla postępu k (0..1), wyśrodkowana w punkcie p, w skali px.
func _draw_frames(tex: Texture2D, frames: int, k: float, p: Vector2, px: int) -> void:
	var frame := Vector2(tex.get_width() / float(frames), tex.get_height())
	var index := mini(int(k * frames), frames - 1)
	var size := frame * px
	draw_texture_rect_region(tex, Rect2(p - size / 2.0, size), Rect2(Vector2(index * frame.x, 0), frame))


## Pojedyncza grafika w skali pixel artu, wyśrodkowana w p i obrócona o angle.
func _draw_sprite(tex: Texture2D, p: Vector2, angle: float) -> void:
	var size := tex.get_size()
	draw_set_transform(p, angle, Vector2.ONE * LevelScene.PIXEL)
	draw_texture_rect(tex, Rect2(-size / 2.0, size), false)
	draw_set_transform(Vector2.ZERO)
