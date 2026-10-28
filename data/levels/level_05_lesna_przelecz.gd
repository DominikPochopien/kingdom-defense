## Poziom 5 - Leśna Przełęcz. Opis kluczy: data/level_data.gd
## Tunel przez góry (systems/path_network.gd) i Leśni Łucznicy (systems/forest_archer_camp.gd).
## Mapa, trasy i miejsca na wieże są w scenie levels/level_05.tscn (edycja w Godocie).
## Trasy: 1 - z lewej, 2 - z dołu, 3 - z prawej.

const DATA := {
	"name": "Leśna Przełęcz", "desc": "Trzy wejścia: z lewej idzie najwięcej i najsilniejszych wrogów, z dołu sporo, z prawej garstka słabszych. Wrogowie przechodzą przez tunel w górach i są w nim niewidzialni. Z gniazd w górach co jakiś czas wychodzą Leśni Łucznicy i pomagają ci dmuchawkami. Uwaga na Magicznych Rycerzy: są odporni na obrażenia fizyczne, wyłączają wieże i przyspieszają innych wrogów.",
	"waves": 15, "gold": 450, "lives": 20, "hp": 1.5, "difficulty": "Bardzo trudny", "shamans": true, "magic_knights": true,
	"scene": "res://levels/level_05.tscn",
	"spawn_routes": [
		{"weight": 5, "types": ["goblin", "wolf", "orc", "bat", "shaman", "boss", "magic_knight"]},
		{"weight": 3, "types": ["goblin", "wolf", "orc", "bat"]},
		{"weight": 1, "types": ["goblin", "wolf"]},
	],
	"tunnels": [{"a": Vector2(816, 208), "b": Vector2(1136, 144)}],
	"mountains": [
		[Vector2(-10, -10), Vector2(1290, -10), Vector2(1290, 138), Vector2(1240, 144), Vector2(1190, 136),
			Vector2(1148, 140), Vector2(1110, 140), Vector2(1072, 150), Vector2(1040, 160), Vector2(1000, 166),
			Vector2(975, 188), Vector2(930, 200), Vector2(880, 196), Vector2(831, 197), Vector2(790, 200),
			Vector2(740, 194), Vector2(690, 202), Vector2(630, 196), Vector2(560, 204), Vector2(490, 198),
			Vector2(420, 205), Vector2(350, 198), Vector2(280, 206), Vector2(210, 198), Vector2(175, 180),
			Vector2(160, 140), Vector2(120, 112), Vector2(70, 116), Vector2(20, 108), Vector2(-10, 112)],
	],
	"archer_posts": [Vector2(291, 158), Vector2(722, 104), Vector2(1029, 118)],
	"river": [Vector2(-40, 316), Vector2(120, 318), Vector2(250, 322), Vector2(292, 348), Vector2(282, 420),
		Vector2(248, 520), Vector2(212, 620), Vector2(196, 760),
		Vector2(100, 760), Vector2(118, 680), Vector2(140, 600), Vector2(168, 520), Vector2(180, 462),
		Vector2(150, 430), Vector2(60, 395), Vector2(-40, 370)],
}
