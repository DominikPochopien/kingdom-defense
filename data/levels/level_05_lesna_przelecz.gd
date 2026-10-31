## Poziom 5 - Leśna Przełęcz. Opis kluczy: data/level_data.gd
## Tunel przez góry (systems/path_network.gd) i Leśni Łucznicy (systems/forest_archer_camp.gd).
## Mapa, trasy, miejsca na wieże, tunel i gniazda są w scenie levels/level_05.tscn (edycja w Godocie).
## Trasy: 1 - z lewej, 2 - z dołu, 3 - z prawej.

const DATA := {
	"name": "Leśna Przełęcz", "desc": "Trzy wejścia: z lewej idzie najwięcej i najsilniejszych wrogów, z dołu sporo, z prawej garstka słabszych. Wrogowie przechodzą przez tunel w górach i są w nim niewidzialni. Z gniazd w górach co jakiś czas wychodzą Leśni Łucznicy i pomagają ci dmuchawkami. Uwaga na Magicznych Rycerzy: są odporni na obrażenia fizyczne, wyłączają wieże i przyspieszają innych wrogów.",
	"waves": 15, "gold": 450, "lives": 20, "hp": 1.5, "difficulty": "Bardzo trudny", "shamans": true, "magic_knights": true,
	"scene": "res://levels/level_05.tscn",
	# droga malowana wzdłuż tras: gładkie łuki; tunel to prosty, niewidoczny odcinek trasy
	"road": "painted",
	"spawn_routes": [
		{"weight": 5, "types": ["goblin", "wolf", "orc", "bat", "shaman", "boss", "magic_knight"]},
		{"weight": 3, "types": ["goblin", "wolf", "orc", "bat"]},
		{"weight": 1, "types": ["goblin", "wolf"]},
	],
	"mountains": [
		[Vector2(-10, -10), Vector2(1290, -10), Vector2(1290, 138), Vector2(1240, 144), Vector2(1190, 136),
			Vector2(1148, 140), Vector2(1110, 140), Vector2(1072, 150), Vector2(1040, 160), Vector2(1000, 166),
			Vector2(975, 188), Vector2(930, 200), Vector2(880, 196), Vector2(831, 197), Vector2(790, 200),
			Vector2(740, 194), Vector2(690, 202), Vector2(630, 196), Vector2(560, 204), Vector2(490, 198),
			Vector2(420, 205), Vector2(350, 198), Vector2(280, 206), Vector2(210, 198), Vector2(175, 180),
			Vector2(160, 140), Vector2(120, 112), Vector2(70, 116), Vector2(20, 108), Vector2(-10, 112)],
	],
	# rzeka szerokim, gładkim łukiem z lewej krawędzi w dół mapy (rozlewa się na zakręcie)
	"river": [Vector2(-61, 362), Vector2(-38, 362), Vector2(-16, 363), Vector2(6, 363), Vector2(27, 364),
		Vector2(46, 365), Vector2(67, 367), Vector2(89, 372), Vector2(108, 378), Vector2(125, 384),
		Vector2(141, 391), Vector2(155, 402), Vector2(166, 413), Vector2(173, 422), Vector2(179, 431),
		Vector2(182, 443), Vector2(185, 455), Vector2(187, 467), Vector2(188, 483), Vector2(185, 503),
		Vector2(182, 519), Vector2(177, 539), Vector2(170, 561), Vector2(162, 580), Vector2(155, 598),
		Vector2(145, 620), Vector2(136, 647), Vector2(130, 671), Vector2(127, 695), Vector2(124, 718),
		Vector2(122, 742), Vector2(120, 763), Vector2(118, 774), Vector2(202, 786), Vector2(203, 774),
		Vector2(206, 751), Vector2(209, 728), Vector2(213, 707), Vector2(216, 688), Vector2(220, 673),
		Vector2(227, 657), Vector2(237, 640), Vector2(249, 620), Vector2(259, 598), Vector2(270, 577),
		Vector2(282, 554), Vector2(291, 527), Vector2(297, 499), Vector2(302, 469), Vector2(301, 435),
		Vector2(292, 404), Vector2(277, 375), Vector2(257, 348), Vector2(233, 328), Vector2(207, 314),
		Vector2(180, 304), Vector2(155, 295), Vector2(129, 289), Vector2(103, 286), Vector2(77, 284),
		Vector2(54, 281), Vector2(30, 280), Vector2(7, 279), Vector2(-15, 279), Vector2(-37, 278),
		Vector2(-59, 278)],
}
