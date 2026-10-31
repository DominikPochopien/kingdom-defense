## Poziom 7 - Pirackie Wybrzeże. Opis kluczy: data/level_data.gd
## Statek do kupienia (entities/towers/ship_tower.gd), Palma z kokosami (entities/stun_palm.gd),
## ptaki z jajkami (entities/sea_bird.gd) i Jeżowce (entities/enemies/hedgehog.gd).
## Mapa, trasy, miejsca na wieże, most (meta), Statek i Palma są w scenie levels/level_07.tscn (edycja w Godocie).
## Trasy: 1 - z lewej zygzakiem, 2 - z góry ukośnie, 3 - z dołu.

const DATA := {
	"name": "Pirackie Wybrzeże", "desc": "Trzy ścieżki schodzą się przy Palmie, a meta jest na moście nad morzem. Na morzu możesz kupić Statek z armatami, który ostrzeliwuje duży obszar, a na wysepce postawić wieżę. Palma co 14-19 s zrzuca kokosy i ogłusza wrogów wokół na 3 s. Uważaj na Jeżowce: turlają się, taranując żołnierzy, i rzucają w nich kolcami. Pojawiają się też Smoki i Magiczni Rycerze. Wrogowie mają +45% HP.",
	"waves": 15, "gold": 480, "lives": 20, "hp": 1.45, "difficulty": "Trudny",
	"shamans": true, "hedgehogs": true, "magic_knights": true, "dragons": true, "random_routes_from": 1, "birds": true,
	"scene": "res://levels/level_07.tscn",
	"beach": [Vector2(-10, -10), Vector2(1300, -10), Vector2(1300, 730), Vector2(-10, 730)],
	# droga malowana wzdłuż tras: gładkie łuki (trasa 3 dołącza do trasy 1, trasa 2 do niej przy Palmie)
	"road": "painted",
	# gładki brzeg morza i zaokrąglona wysepka
	"sea": [Vector2(859, -10), Vector2(864, 13), Vector2(869, 37), Vector2(872, 60), Vector2(871, 83),
		Vector2(868, 107), Vector2(866, 130), Vector2(866, 154), Vector2(866, 177), Vector2(868, 200),
		Vector2(873, 221), Vector2(879, 241), Vector2(884, 262), Vector2(888, 284), Vector2(891, 306),
		Vector2(893, 330), Vector2(894, 352), Vector2(894, 374), Vector2(894, 397), Vector2(895, 420),
		Vector2(897, 442), Vector2(900, 463), Vector2(903, 484), Vector2(906, 505), Vector2(910, 527),
		Vector2(915, 548), Vector2(919, 569), Vector2(920, 592), Vector2(919, 615), Vector2(916, 638),
		Vector2(912, 661), Vector2(908, 684), Vector2(903, 707), Vector2(898, 730), Vector2(1300, 730),
		Vector2(1300, -10)],
	"islands": [[Vector2(1035, 470), Vector2(1038, 449), Vector2(1041, 428), Vector2(1052, 412), Vector2(1070, 399),
			Vector2(1089, 395), Vector2(1109, 398), Vector2(1126, 408), Vector2(1140, 423), Vector2(1150, 442),
			Vector2(1156, 464), Vector2(1158, 487), Vector2(1155, 511), Vector2(1147, 533), Vector2(1133, 552),
			Vector2(1117, 566), Vector2(1098, 576), Vector2(1079, 578), Vector2(1060, 571), Vector2(1045, 559),
			Vector2(1035, 540), Vector2(1031, 521), Vector2(1032, 501), Vector2(1034, 480)]],
}
