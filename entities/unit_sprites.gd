class_name UnitSprites
## Animowane postacie pixel art: wrogowie (assets/enemies/) i sojusznicy (assets/allies/).
## Arkusz "<postać>_<animacja>.png" to poziomy pasek klatek jednakowej wielkości; postać patrzy
## w prawo (w lewo się ją odbija), stopy w dolnym środku klatki. Opis: assets/README_grafiki.md.

const FPS := 8.0
## wielkość klatki w pikselach obrazka (wspólna dla wszystkich arkuszy postaci, także wariantów aur)
const FRAME_SIZE := {
	"goblin": Vector2(16, 16), "wolf": Vector2(20, 14), "orc": Vector2(20, 24), "bat": Vector2(16, 12),
	"shaman": Vector2(18, 24), "boss": Vector2(32, 32), "magic_knight": Vector2(20, 28),
	"dragon": Vector2(48, 32), "hedgehog": Vector2(20, 16), "desert_bird": Vector2(16, 12),
	"soldier": Vector2(12, 16), "spear_knight": Vector2(14, 18), "hero": Vector2(16, 22),
	"forest_ranger": Vector2(12, 16),
}


## wczytane arkusze: ścieżka -> tekstura. Trzymamy referencje, bo tekstura bez właściciela
## zostaje zwolniona, zanim karta graficzna ją narysuje (widać wtedy biały prostokąt albo nic)
static var _sheets := {}


static func sheet(path: String) -> Texture2D:
	if not _sheets.has(path):
		_sheets[path] = load("res://assets/%s.png" % path)
	return _sheets[path]


## Rozmiar klatki postaci w jednostkach gry.
static func size_of(unit: String) -> Vector2:
	return FRAME_SIZE[unit] * LevelScene.PIXEL


## Fragment arkusza z klatką dla czasu t (s); animacja się zapętla.
static func frame_region(tex: Texture2D, frame: Vector2, t: float) -> Rect2:
	var frames := int(tex.get_width() / frame.x)
	return Rect2(Vector2(int(t * FPS) % frames * frame.x, 0), frame)


## Rysuje klatkę postaci `unit` z arkusza `path` (np. "allies/soldier_walk") stopami w punkcie foot.
## facing = 1 (w prawo) albo -1 (w lewo). Węzeł canvas powinien mieć filtr NEAREST.
static func draw(canvas: CanvasItem, path: String, unit: String, foot: Vector2, t: float, facing: float,
		tint := Color.WHITE) -> void:
	var tex := sheet(path)
	var size := size_of(unit)
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing, 1.0))
	canvas.draw_texture_rect_region(tex, Rect2(Vector2(foot.x * facing, foot.y) - Vector2(size.x / 2.0, size.y), size),
		frame_region(tex, FRAME_SIZE[unit], t), tint)
	canvas.draw_set_transform(Vector2.ZERO)
