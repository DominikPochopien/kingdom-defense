class_name LevelData
## Lista poziomów. Każdy poziom to plik w data/levels/ ze stałą DATA (liczby i zasady)
## oraz scena w levels/ (mapa, trasy i miejsca na wieże - edycja w Godocie, world/level_scene.gd).
## Nowy poziom: skopiuj plik danych i scenę, zmień je i dopisz plik danych na koniec LEVELS.
##
## Klucze poziomu:
##   name, desc, difficulty ("Łatwy" rysuje się na zielono)
##   waves, gold, lives, hp (mnożnik HP wrogów)
##   scene - ścieżka sceny poziomu; get_level() dopisuje z niej routes (trasy) i spots (miejsca budowy)
## Opcjonalne - teren (generator kafelków sceny i miniatura w wyborze poziomu):
##   river - wielokąt rzeki
##   ponds - lista wielokątów kałuż
##   sea - wielokąt morza
##   beach - wielokąt plaży (piasek)
##   islands - wielokąty wysepek na morzu (piasek)
##   mountains - lista wielokątów gór (szczyty to ozdoby w scenie)
## Opcjonalne - elementy rysowane przez world/level_map.gd:
##   fixed_bridges - stałe mosty {"a", "b", "vertical"}
##   bridges - 2 zwodzone mosty {"a", "b", "name", "route", "zone_from", "zone_to"}
##             (strefa = indeksy punktów trasy, w której wrogowie blokują zamknięcie mostu)
##   tunnels - {"a", "b"}: odcinek trasy od a do b to tunel (wrogowie niewidzialni i nietykalni;
##             a i b muszą być kolejnymi punktami trasy w scenie)
##   archer_posts - gniazda Leśnych Łuczników (systems/forest_archer_camp.gd)
##   ship - miejsce na Statek {"pos", "aim"}: aim = środek obszaru, w który strzela (ship_tower.gd);
##          dopisywane na koniec listy miejsc budowy
## Opcjonalne - zasady:
##   bridge_period - co ile sekund zmienia się otwarty most
##   shamans - fale zawierają Szamanów Wojennych
##   magic_knights - fale zawierają Magicznych Rycerzy (pierwszy zawsze zaczyna falę)
##   dragons - fale zawierają Smoki
##   hedgehogs - fale zawierają Jeżowce (od 3. fali)
##   random_routes_from - od tej fali wrogowie losują trasę
##   spawn_routes - dla każdej trasy {"weight", "types"}: wróg losuje trasę (z wagami)
##                  spośród tych, które przyjmują jego typ
##   special_tower - indeks miejsca z darmową Wieżą Rycerską
##   archer_period - co ile sekund każde gniazdo wypuszcza łucznika (domyślnie Balance)
##   hero - posterunek Bohatera: Rycerza (entities/hero_knight.gd)
##   birds - nad mapą czasem przelatuje ptak zrzucający jajka na wrogów (entities/sea_bird.gd)
##   palms - palmy z kokosami {"pos", "center", "radius"}: ogłuszają wrogów w okręgu (stun_palm.gd)

const LEVELS := [
	preload("res://data/levels/level_01_zielone_wzgorza.gd"),
	preload("res://data/levels/level_02_kreta_droga.gd"),
	preload("res://data/levels/level_03_rzeka_mostow.gd"),
	preload("res://data/levels/level_04_rozdroza.gd"),
	preload("res://data/levels/level_05_lesna_przelecz.gd"),
	preload("res://data/levels/level_06_sloneczna_zatoka.gd"),
	preload("res://data/levels/level_07_pirackie_wybrzeze.gd"),
]

## indeks poziomu -> DATA uzupełnione o trasy i miejsca na wieże ze sceny
static var _levels := {}


static func count() -> int:
	return LEVELS.size()


## Dane poziomu razem z trasami ("routes") i miejscami na wieże ("spots") odczytanymi z jego sceny.
static func get_level(index: int) -> Dictionary:
	if not _levels.has(index):
		var data: Dictionary = LEVELS[index].DATA
		var scene: LevelScene = (load(data.scene) as PackedScene).instantiate()
		var level := data.duplicate()
		level["routes"] = scene.get_routes()
		level["spots"] = scene.get_spots()
		scene.free()
		_levels[index] = level
	return _levels[index]


## Same dane (DATA) poziomu, którego scena leży pod podaną ścieżką; pusty słownik, gdy brak.
static func scene_data(scene_path: String) -> Dictionary:
	for level in LEVELS:
		if level.DATA.scene == scene_path:
			return level.DATA
	return {}
