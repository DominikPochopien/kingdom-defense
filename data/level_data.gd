class_name LevelData
## Lista poziomów. Każdy poziom to osobny plik w data/levels/ ze stałą DATA.
## Nowy poziom: skopiuj istniejący plik, zmień dane i dopisz go na koniec LEVELS.
##
## Klucze poziomu:
##   name, desc, difficulty ("Łatwy" rysuje się na zielono)
##   waves, gold, lives, hp (mnożnik HP wrogów)
##   path - jedna trasa (lista punktów) LUB routes - kilka tras
##   spots - miejsca budowy wież
## Opcjonalne:
##   river - wielokąt rzeki (lewy brzeg w jedną stronę, prawy z powrotem)
##   fixed_bridges - stałe mosty {"a", "b", "vertical"}
##   bridges - 2 zwodzone mosty {"a", "b", "name", "route", "zone_from", "zone_to"}
##             (strefa = indeksy punktów trasy, w której wrogowie blokują zamknięcie mostu)
##   bridge_period - co ile sekund zmienia się otwarty most
##   shamans - fale zawierają Szamanów Wojennych
##   random_routes_from - od tej fali wrogowie losują trasę
##   special_tower - indeks miejsca z darmową Wieżą Rycerską

const LEVELS := [
	preload("res://data/levels/level_01_zielone_wzgorza.gd"),
	preload("res://data/levels/level_02_kreta_droga.gd"),
	preload("res://data/levels/level_03_rzeka_mostow.gd"),
	preload("res://data/levels/level_04_rozdroza.gd"),
]


static func count() -> int:
	return LEVELS.size()


static func get_level(index: int) -> Dictionary:
	return LEVELS[index].DATA


## Trasy poziomu jako lista list punktów (niezależnie od tego, czy użyto "path" czy "routes").
static func routes_of(level: Dictionary) -> Array:
	return level.routes if level.has("routes") else [level.path]
