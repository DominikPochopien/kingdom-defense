class_name LevelData
## Lista poziomów. Każdy poziom to plik w data/levels/ ze stałą DATA (liczby i zasady)
## oraz scena w levels/ (mapa, trasy, miejsca na wieże i obiekty - edycja w Godocie, world/level_scene.gd).
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
##   road - "painted": droga malowana (gładkie łuki przez punkty trasy) zamiast kafelków (world/level_scene.gd);
##          trasy dowolnych kątów, także z tunelami
## Obiekty ze sceny (węzeł "Obiekty", world/level_object.gd - ustawiane myszką w edytorze);
## get_level() dopisuje z nich klucze:
##   fixed_bridges - stałe mosty {"a", "b", "vertical"}
##   bridges - 2 zwodzone mosty {"a", "b", "name", "route", "zone_from", "zone_to"}
##             (strefa = indeksy punktów trasy, w której wrogowie blokują zamknięcie mostu)
##   tunnels - {"a", "b"}: odcinek trasy od a do b to tunel (wrogowie niewidzialni i nietykalni)
##   portals - {"a", "b"}: wróg wchodzący w portal a od razu wychodzi z portalu b (odcinek zerowej długości)
##   archer_posts - gniazda Leśnych Łuczników (systems/forest_archer_camp.gd)
##   ship - miejsce na Statek {"pos", "aim"}: aim = środek obszaru, w który strzela (ship_tower.gd);
##          dopisywane na koniec listy miejsc budowy
##   special_tower - indeks miejsca z darmową Wieżą Rycerską
##   hero - posterunek Bohatera: Rycerza (entities/hero_knight.gd)
##   palms - palmy z kokosami {"pos", "center", "radius"}: ogłuszają wrogów w okręgu (stun_palm.gd)
##   war_towers - wieże wroga {"pos", "center", "radius"}: co jakiś czas przyspieszają wrogów w okręgu (war_tower.gd)
## Opcjonalne - zasady:
##   bridge_period - co ile sekund zmienia się otwarty most
##   shamans - fale zawierają Szamanów Wojennych
##   magic_knights - fale zawierają Magicznych Rycerzy (pierwszy zawsze zaczyna falę)
##   dragons - fale zawierają Smoki
##   hedgehogs - fale zawierają Jeżowce (od 3. fali)
##   random_routes_from - od tej fali wrogowie losują trasę
##   alternate_routes - lista grup tras: kolejni wrogowie fali biorą kolejne grupy (po ostatniej znów
##                      pierwszą), a w grupie losują trasę, np. [[1, 3], [0, 2]] = na zmianę dolny i górny most
##   spawn_routes - dla każdej trasy {"weight", "types"}: wróg losuje trasę (z wagami)
##                  spośród tych, które przyjmują jego typ
##   archer_period - co ile sekund każde gniazdo wypuszcza łucznika (domyślnie Balance)
##   birds - nad mapą czasem przelatuje ptak zrzucający jajka na wrogów (entities/sea_bird.gd)
##   undead - fale zawierają Szkielety i Szkielety łuczników, a w ostatniej fali Mumię (zamiast Wodza)
##   unpainted_routes - numery tras, które się nie malują (np. trasa idąca po innych drogach w drugą stronę)
##   hidden_routes - numery tras, których droga pojawia się na mapie dopiero po reveal (LevelScene.reveal_hidden_road)
##   hidden_route - {"route", "gate", "enemies"}: gdy Mumia przejdzie przez punkt gate, droga trasy route
##                  pojawia się i wychodzą z niej wrogowie enemies (grupy [typ, liczba, start (s), odstęp (s)],
##                  czas liczony od otwarcia drogi)
##   minion_routes - trasy, na które Mumia przywołuje Szkielety, póki ma przed sobą portal
##   special_wave - {"wave", "routes": {trasa: grupy}}: fala nr wave zamiast zwykłego składu - wrogowie
##                  o ustalonych porach na podanych trasach (grupy jak w hidden_route, czas od startu fali)

const LEVELS := [
	preload("res://data/levels/level_01_zielone_wzgorza.gd"),
	preload("res://data/levels/level_02_kreta_droga.gd"),
	preload("res://data/levels/level_03_rzeka_mostow.gd"),
	preload("res://data/levels/level_04_rozdroza.gd"),
	preload("res://data/levels/level_05_lesna_przelecz.gd"),
	preload("res://data/levels/level_06_sloneczna_zatoka.gd"),
	preload("res://data/levels/level_07_pirackie_wybrzeze.gd"),
	preload("res://data/levels/level_08_wieza_wojny.gd"),
	preload("res://data/levels/level_09_piramida.gd"),
]

## indeks poziomu -> DATA uzupełnione o trasy i miejsca na wieże ze sceny
static var _levels := {}


static func count() -> int:
	return LEVELS.size()


## Dane poziomu razem z trasami ("routes"), miejscami na wieże ("spots") i obiektami odczytanymi z jego sceny.
static func get_level(index: int) -> Dictionary:
	if not _levels.has(index):
		var data: Dictionary = LEVELS[index].DATA
		var scene: LevelScene = (load(data.scene) as PackedScene).instantiate()
		var level := data.duplicate()
		level["routes"] = scene.get_routes()
		level["spots"] = scene.get_spots()
		level.merge(scene.get_objects(), true)
		scene.free()
		_levels[index] = level
	return _levels[index]


## Same dane (DATA) poziomu, którego scena leży pod podaną ścieżką; pusty słownik, gdy brak.
static func scene_data(scene_path: String) -> Dictionary:
	for level in LEVELS:
		if level.DATA.scene == scene_path:
			return level.DATA
	return {}
