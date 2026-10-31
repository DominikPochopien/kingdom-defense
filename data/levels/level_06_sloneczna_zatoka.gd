## Poziom 6 - Słoneczna Zatoka. Opis kluczy: data/level_data.gd
## Bohater: Rycerz (entities/hero_knight.gd), smoki (entities/enemies/dragon.gd).
## Mapa, trasy, miejsca na wieże, most i posterunek Rycerza są w scenie levels/level_06.tscn (edycja w Godocie).
## Trasy: 1 - z lewej, 2 - z góry.

const DATA := {
	"name": "Słoneczna Zatoka", "desc": "Najtrudniejszy poziom. Dwa wejścia, a wrogowie losują, którym idą. Pomaga ci Rycerz-bohater z umiejętnością Obrót (rani wszystkich wokół). Uważaj na Smoki, które ziejąc ogniem palą naraz dwóch żołnierzy, i na Magicznych Rycerzy.",
	"waves": 14, "gold": 520, "lives": 20, "hp": 1.7, "difficulty": "Ekstremalny",
	"shamans": true, "magic_knights": true, "dragons": true, "random_routes_from": 1,
	"scene": "res://levels/level_06.tscn",
	# droga malowana wzdłuż tras: gładkie łuki, trasa 2 dołącza do trasy 1 przed mostem
	"road": "painted",
	# pustynia po prawej i pas plaży wzdłuż dolnej krawędzi (łagodny brzeg trawy), morze z gładkim brzegiem
	"beach": [Vector2(534, -10), Vector2(547, 6), Vector2(559, 22), Vector2(572, 38), Vector2(586, 53),
		Vector2(600, 70), Vector2(612, 88), Vector2(622, 106), Vector2(632, 126), Vector2(640, 147),
		Vector2(647, 169), Vector2(652, 190), Vector2(656, 212), Vector2(659, 235), Vector2(660, 257),
		Vector2(660, 279), Vector2(659, 301), Vector2(657, 324), Vector2(654, 347), Vector2(650, 369),
		Vector2(645, 390), Vector2(639, 414), Vector2(631, 437), Vector2(625, 459), Vector2(620, 481),
		Vector2(619, 502), Vector2(616, 522), Vector2(605, 539), Vector2(586, 552), Vector2(566, 557),
		Vector2(546, 557), Vector2(523, 553), Vector2(501, 549), Vector2(478, 547), Vector2(456, 545),
		Vector2(433, 544), Vector2(410, 542), Vector2(388, 541), Vector2(367, 539), Vector2(345, 538),
		Vector2(323, 536), Vector2(299, 534), Vector2(275, 531), Vector2(252, 528), Vector2(228, 526),
		Vector2(205, 523), Vector2(181, 520), Vector2(157, 518), Vector2(136, 516), Vector2(114, 515),
		Vector2(91, 513), Vector2(70, 512), Vector2(48, 512), Vector2(24, 512), Vector2(2, 512),
		Vector2(-10, 512), Vector2(-10, 730), Vector2(1300, 730), Vector2(1300, -10)],
	"sea": [Vector2(1040, -10), Vector2(1054, 5), Vector2(1069, 20), Vector2(1083, 35), Vector2(1097, 50),
		Vector2(1110, 66), Vector2(1120, 84), Vector2(1128, 104), Vector2(1135, 125), Vector2(1140, 146),
		Vector2(1144, 168), Vector2(1148, 190), Vector2(1152, 212), Vector2(1155, 234), Vector2(1159, 257),
		Vector2(1163, 280), Vector2(1167, 302), Vector2(1171, 324), Vector2(1176, 347), Vector2(1181, 369),
		Vector2(1185, 391), Vector2(1190, 413), Vector2(1196, 436), Vector2(1201, 458), Vector2(1206, 480),
		Vector2(1211, 502), Vector2(1217, 525), Vector2(1222, 548), Vector2(1227, 569), Vector2(1233, 592),
		Vector2(1239, 615), Vector2(1245, 638), Vector2(1250, 660), Vector2(1254, 684), Vector2(1258, 707),
		Vector2(1262, 730), Vector2(1300, 730), Vector2(1300, -10)],
}
