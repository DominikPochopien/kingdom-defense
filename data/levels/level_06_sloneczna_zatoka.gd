## Poziom 6 - Słoneczna Zatoka. Opis kluczy: data/level_data.gd
## Bohater: Rycerz (entities/hero_knight.gd), smoki (entities/enemies/dragon.gd).
## Mapa, trasy i miejsca na wieże są w scenie levels/level_06.tscn (edycja w Godocie).
## Trasy: 1 - z lewej, 2 - z góry.

const DATA := {
	"name": "Słoneczna Zatoka", "desc": "Najtrudniejszy poziom. Dwa wejścia, a wrogowie losują, którym idą. Pomaga ci Rycerz-bohater z umiejętnością Obrót (rani wszystkich wokół). Uważaj na Smoki, które ziejąc ogniem palą naraz dwóch żołnierzy, i na Magicznych Rycerzy.",
	"waves": 14, "gold": 520, "lives": 20, "hp": 1.7, "difficulty": "Ekstremalny",
	"shamans": true, "magic_knights": true, "dragons": true, "random_routes_from": 1,
	"scene": "res://levels/level_06.tscn",
	"hero": Vector2(671, 592),
	"beach": [Vector2(506, -10), Vector2(622, 52), Vector2(694, 130), Vector2(709, 207), Vector2(667, 328),
		Vector2(606, 449), Vector2(561, 562), Vector2(578, 657), Vector2(644, 730), Vector2(1300, 730), Vector2(1300, -10)],
	"sea": [Vector2(1109, -10), Vector2(1140, 100), Vector2(1161, 166), Vector2(1211, 389), Vector2(1250, 560),
		Vector2(1278, 730), Vector2(1300, 730), Vector2(1300, -10)],
	"fixed_bridges": [{"a": Vector2(1125, 80), "b": Vector2(1290, 80)}],
}
