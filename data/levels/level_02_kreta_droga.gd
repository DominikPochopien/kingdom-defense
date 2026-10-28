## Poziom 2 - Kręta Droga. Opis kluczy: data/level_data.gd
## Mapa, trasa i miejsca na wieże są w scenie levels/level_02.tscn (edycja w Godocie).

const DATA := {
	"name": "Kręta Droga", "desc": "Długi wąż - wrogowie mają +25% HP i jest 12 fal.",
	"waves": 12, "gold": 350, "lives": 20, "hp": 1.25, "difficulty": "Trudny",
	"scene": "res://levels/level_02.tscn",
	# duża kałuża na środku mapy, droga przechodzi przez nią po moście
	"ponds": [[Vector2(472, 297), Vector2(483, 262), Vector2(525, 231), Vector2(595, 220), Vector2(679, 217),
		Vector2(756, 228), Vector2(808, 259), Vector2(822, 297), Vector2(794, 335), Vector2(728, 357),
		Vector2(644, 363), Vector2(560, 354), Vector2(497, 329)]],
	"fixed_bridges": [{"a": Vector2(455, 304), "b": Vector2(840, 304)}],
}
