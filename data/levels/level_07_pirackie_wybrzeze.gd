## Poziom 7 - Pirackie Wybrzeże. Opis kluczy: data/level_data.gd
## Statek do kupienia (entities/towers/ship_tower.gd), Palma z kokosami (entities/stun_palm.gd),
## ptaki z jajkami (entities/sea_bird.gd) i Jeżowce (entities/enemies/hedgehog.gd).
## Mapa, trasy i miejsca na wieże są w scenie levels/level_07.tscn (edycja w Godocie).
## Trasy: 1 - z lewej zygzakiem, 2 - z góry ukośnie, 3 - z dołu.

const DATA := {
	"name": "Pirackie Wybrzeże", "desc": "Trzy ścieżki schodzą się przy Palmie, a meta jest na moście nad morzem. Na morzu możesz kupić Statek z armatami, który ostrzeliwuje duży obszar, a na wysepce postawić wieżę. Palma co 14-19 s zrzuca kokosy i ogłusza wrogów wokół na 3 s. Uważaj na Jeżowce: turlają się, taranując żołnierzy, i rzucają w nich kolcami. Wrogowie mają +45% HP.",
	"waves": 15, "gold": 480, "lives": 20, "hp": 1.45, "difficulty": "Trudny",
	"shamans": true, "hedgehogs": true, "random_routes_from": 1, "birds": true,
	"scene": "res://levels/level_07.tscn",
	"beach": [Vector2(-10, -10), Vector2(1300, -10), Vector2(1300, 730), Vector2(-10, 730)],
	"sea": [Vector2(859, -10), Vector2(880, 60), Vector2(872, 117), Vector2(862, 195), Vector2(880, 250),
		Vector2(892, 292), Vector2(890, 409), Vector2(905, 500), Vector2(924, 594), Vector2(915, 640),
		Vector2(896, 682), Vector2(892, 730), Vector2(1300, 730), Vector2(1300, -10)],
	"islands": [[Vector2(1040, 420), Vector2(1075, 392), Vector2(1110, 395), Vector2(1140, 425), Vector2(1158, 470),
		Vector2(1150, 520), Vector2(1125, 560), Vector2(1090, 582), Vector2(1055, 572), Vector2(1030, 540),
		Vector2(1025, 490), Vector2(1028, 450)]],
	# meta: most nad morzem
	"fixed_bridges": [{"a": Vector2(895, 624), "b": Vector2(1290, 624)}],
	"ship": {"pos": Vector2(997, 193), "aim": Vector2(823, 360)},
	"palms": [{"pos": Vector2(500, 234), "center": Vector2(560, 304), "radius": 90.0}],
}
