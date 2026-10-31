## Poziom 8 - Wieża Wojny. Opis kluczy: data/level_data.gd
## Wieża wroga (entities/war_tower.gd) i wrogowie na zmianę z dwóch wejść ("alternate_routes").
## Mapa, trasy, miejsca na wieże, mosty i Wieża wroga są w scenie levels/level_08.tscn (edycja w Godocie).
## Trasy: 1 - z lewej górą, w prawo i w dół przez most na wschodnim ramieniu jeziora (most 2),
##        2 - z lewej dołem, łukiem pod Wieżą wroga i przez most nad kanałem (most 1).
## Obie łączą się przy wyjściu w prawym dolnym rogu.

const DATA := {
	"name": "Wieża Wojny", "desc": "Dwa wejścia z lewej: górna droga prowadzi przez most na wschodzie, dolna łukiem przez most nad kanałem. Wrogowie wchodzą na zmianę górą i dołem. Między drogami stoi Wieża wroga: co jakiś czas rozpala ogień i wtedy wrogowie w jej czerwonym okręgu biegną o 35% szybciej. Pojawiają się Szamani, Magiczni Rycerze i Smoki. Wrogowie mają +55% HP.",
	"waves": 15, "gold": 500, "lives": 20, "hp": 1.55, "difficulty": "Bardzo trudny",
	"shamans": true, "magic_knights": true, "dragons": true,
	"scene": "res://levels/level_08.tscn",
	# droga malowana wzdłuż tras: gładkie łuki (obie trasy łączą się przy wyjściu)
	"road": "painted",
	# na zmianę: wróg nr 1, 3, 5... wchodzi dolnym wejściem (trasa 2), nr 2, 4, 6... górnym (trasa 1)
	"alternate_routes": [[1], [0]],
	# piasek wszędzie poza dwoma pasami trawy wzdłuż zachodniego brzegu jeziora
	"beach": [Vector2(-10, -10), Vector2(1300, -10), Vector2(1300, 730), Vector2(850, 730), Vector2(848, 650),
		Vector2(858, 570), Vector2(872, 500), Vector2(862, 452), Vector2(835, 470), Vector2(805, 515),
		Vector2(777, 582), Vector2(760, 660), Vector2(752, 730), Vector2(502, 730), Vector2(515, 645),
		Vector2(550, 562), Vector2(590, 480), Vector2(628, 402), Vector2(672, 348), Vector2(730, 305),
		Vector2(775, 278), Vector2(795, 262), Vector2(735, 262), Vector2(665, 290), Vector2(595, 335),
		Vector2(530, 393), Vector2(470, 467), Vector2(430, 550), Vector2(410, 640), Vector2(402, 730),
		Vector2(-10, 730)],
	# jezioro: główna część schodzi do dolnej krawędzi, ramię na wschód pod górnym mostem
	"ponds": [[Vector2(1320, 236), Vector2(1220, 240), Vector2(1140, 248), Vector2(1080, 255), Vector2(1020, 262),
			Vector2(960, 262), Vector2(900, 258), Vector2(850, 262), Vector2(805, 285), Vector2(760, 315),
			Vector2(712, 346), Vector2(672, 366), Vector2(656, 385), Vector2(656, 495), Vector2(626, 540), Vector2(590, 600),
			Vector2(560, 665), Vector2(540, 740), Vector2(720, 740), Vector2(728, 660), Vector2(748, 590), Vector2(780, 535),
			Vector2(816, 498), Vector2(816, 380), Vector2(848, 368), Vector2(900, 374), Vector2(960, 382), Vector2(1020, 372),
			Vector2(1090, 362), Vector2(1160, 356), Vector2(1230, 352), Vector2(1320, 350)]],
}
