## Poziom 9 - Piramida Umarłych. Opis kluczy: data/level_data.gd
## Mapa, trasy, miejsca na wieże, portale i piramida są w scenie levels/level_09.tscn (edycja w Godocie).
## Trasy (kolejność Path2D w scenie):
##   1 - z góry, zachodnim zakrętem w dół, przez środek mapy do wyjścia na dole po prawej,
##   2 - z góry na zachód do portalu 1, z portalu 2 (prawa strona) w dół do tej samej drogi,
##   3 - z piramidy (Szkielety i łucznicy) w górę na środek mapy i dalej do wyjścia,
##   4 - Mumia: z piramidy na środek, w lewo i w górę do portalu 1, z portalu 2 do wyjścia (bez malowania),
##   5 - ukryta droga z lewej (różowa na szkicu): otwiera ją Mumia na środku mapy ("hidden_route").

## zwykli wrogowie (wchodzą z góry: drogą w dół albo przez portal)
const NORMAL := ["goblin", "wolf", "orc", "bat", "shaman", "hedgehog", "boss"]
## Grupy wrogów o ustalonych porach: [typ, liczba, start (s), odstęp między kolejnymi (s)].
## Kompania nieumarłych = przodem Szkielet pancerny, za nim 10 Szkieletów i 3 łuczników.

const DATA := {
	"name": "Piramida Umarłych", "desc": "Wrogowie schodzą z góry: część skręca w dół zwykłą drogą, a część idzie do portalu i wychodzi z drugiego po prawej. Z piramidy wychodzą Szkielety, Szkielety pancerne i Szkielety łucznicy, które stają i strzelają w żołnierzy. W ostatniej fali budzi się Mumia: przywołuje Szkielety, idzie przez portal, a na środku mapy otwiera drogę umarłych. Z trzech stron nadciągają wtedy kompanie Szkieletów, Magiczni Rycerze, Smoki i Jeżowce.",
	"waves": 12, "gold": 800, "lives": 20, "hp": 1.6, "difficulty": "Bardzo trudny",
	"shamans": true, "hedgehogs": true, "undead": true,
	"scene": "res://levels/level_09.tscn",
	"road": "painted",
	# trasa Mumii biegnie po drogach innych tras (w drugą stronę), więc się nie maluje
	"unpainted_routes": [3],
	# ukryta droga: w grze pojawia się dopiero po otwarciu przez Mumię
	"hidden_routes": [4],
	# z ukrytej drogi (czas od jej otwarcia): najpierw 2 kompanie, potem 2 Magicznych Rycerzy, na końcu 2 Smoki;
	# co jakiś czas Jeżowiec
	"hidden_route": {"route": 4, "gate": Vector2(577, 340),
		"enemies": [["skeleton_armored", 1, 2.0, 0.0], ["skeleton", 10, 3.0, 0.8], ["skeleton_archer", 3, 12.0, 1.2],
			["skeleton_armored", 1, 40.0, 0.0], ["skeleton", 10, 41.0, 0.8], ["skeleton_archer", 3, 50.0, 1.2],
			["magic_knight", 2, 95.0, 70.0], ["dragon", 2, 140.0, 60.0], ["hedgehog", 3, 20.0, 45.0],
			["skeleton_armored", 1, 240.0, 0.0], ["skeleton", 10, 241.0, 0.8], ["skeleton_archer", 3, 250.0, 1.2]]},
	# przywołani przez Mumię przed portalem wracają na najbliższą z tych tras (prosto do wyjścia)
	"minion_routes": [0, 2],
	# 12. fala zamiast zwykłego składu: Mumia z piramidy, a z góry (drogą w dół i przez portal) najpierw
	# po 2 kompanie Szkieletów, dopiero potem po 1 Magicznym Rycerzu, a na końcu po 1 Smoku (razem z ukrytą drogą
	# 4 Rycerze i 4 Smoki, każdy osobno);
	# co jakiś czas Jeżowiec, a na koniec co jakiś czas kolejne kompanie. Trzecia strona to ukryta droga (wyżej)
	"special_wave": {"wave": 12, "routes": {
		3: [["mummy", 1, 0.0, 0.0]],
		0: [["skeleton_armored", 1, 8.0, 0.0], ["skeleton", 10, 9.0, 0.8], ["skeleton_archer", 3, 18.0, 1.2],
			["skeleton_armored", 1, 45.0, 0.0], ["skeleton", 10, 46.0, 0.8], ["skeleton_archer", 3, 55.0, 1.2],
			["magic_knight", 1, 80.0, 0.0], ["dragon", 1, 120.0, 0.0], ["hedgehog", 4, 30.0, 40.0],
			["skeleton_armored", 1, 200.0, 0.0], ["skeleton", 10, 201.0, 0.8], ["skeleton_archer", 3, 210.0, 1.2],
			["skeleton_armored", 1, 265.0, 0.0], ["skeleton", 10, 266.0, 0.8], ["skeleton_archer", 3, 275.0, 1.2]],
		1: [["skeleton_armored", 1, 25.0, 0.0], ["skeleton", 10, 26.0, 0.8], ["skeleton_archer", 3, 35.0, 1.2],
			["skeleton_armored", 1, 62.0, 0.0], ["skeleton", 10, 63.0, 0.8], ["skeleton_archer", 3, 72.0, 1.2],
			["magic_knight", 1, 115.0, 0.0], ["dragon", 1, 155.0, 0.0], ["hedgehog", 3, 50.0, 45.0],
			["skeleton_armored", 1, 230.0, 0.0], ["skeleton", 10, 231.0, 0.8], ["skeleton_archer", 3, 240.0, 1.2],
			["skeleton_armored", 1, 295.0, 0.0], ["skeleton", 10, 296.0, 0.8], ["skeleton_archer", 3, 305.0, 1.2]],
	}},
	"spawn_routes": [
		{"weight": 1.0, "types": NORMAL},
		{"weight": 1.0, "types": NORMAL},
		{"weight": 1.0, "types": ["skeleton", "skeleton_archer", "skeleton_armored"]},
		{"weight": 1.0, "types": ["mummy"]},
		{"weight": 0.0, "types": []},
	],
	# pustynia: piasek na całej mapie
	"beach": [Vector2(-10, -10), Vector2(1300, -10), Vector2(1300, 730), Vector2(-10, 730)],
	# rzeka zakosami z góry do lewej krawędzi
	"river": [Vector2(70, -10), Vector2(125, -10), Vector2(100, 60), Vector2(158, 160), Vector2(120, 255),
		Vector2(88, 340), Vector2(48, 420), Vector2(-10, 470), Vector2(-10, 385), Vector2(15, 380),
		Vector2(30, 330), Vector2(70, 245), Vector2(110, 165), Vector2(45, 70)],
	# oaza na dole środka mapy
	"ponds": [[Vector2(705, 500), Vector2(740, 470), Vector2(820, 465), Vector2(890, 480), Vector2(905, 540),
		Vector2(895, 610), Vector2(850, 640), Vector2(760, 640), Vector2(712, 610), Vector2(700, 550)]],
	# morze w prawym dolnym rogu
	"sea": [Vector2(1320, 450), Vector2(1250, 470), Vector2(1195, 520), Vector2(1160, 590), Vector2(1150, 660),
		Vector2(1160, 740), Vector2(1320, 740)],
}
