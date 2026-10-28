# Kingdom Defense

Gra typu tower defense w pixel arcie, napisana w Godocie 4 (GDScript). Stawiasz wieże na kamiennych
miejscach budowy, ulepszasz je i bronisz królestwa przed falami wrogów idących po drogach.

## Uruchomienie

1. Zainstaluj **Godot 4.7** (wymagany co najmniej 4.4).
2. W Godocie: **Import** → wskaż plik `project.godot`.
3. Naciśnij **F5**.

Pełny ekran (F11) działa, gdy gra jest uruchomiona w osobnym oknie. W zakładce **Game** edytora
wyłącz osadzanie gry („Embed Game on Next Play”).

## Sterowanie

| Klawisz / mysz | Działanie |
|---|---|
| LPM | budowa, menu wieży, wybór, cel umiejętności |
| PPM lub Esc | anuluj |
| Spacja | następna fala (wcześniej = bonus złota) |
| P | pauza |
| M | dźwięk |
| F11 | pełny ekran |

Najedź na wroga, żołnierza lub wieżę, aby zobaczyć statystyki (kliknięcie wroga przypina panel).
Gra liczy wszystko w 1280×720 i skaluje obraz do okna. Na monitorze Full HD pixel art wyświetla się
równo (1 piksel grafiki = 3 piksele ekranu).

## Zawartość

- **7 poziomów:** łąka, kręta droga z kałużą, rzeka z mostami zwodzonymi, rozdroża, górska przełęcz
  z tunelem, słoneczna zatoka, pirackie wybrzeże.
- **Wieże:** Łucznicy, Magowie, Koszary, Artyleria, Rycerze i Statek. Każda ma 3 poziomy
  i dwa ulepszenia do wyboru na 4. poziomie (każde z własnym wyglądem).
- **Wrogowie:** goblin, wilk, ork, nietoperz, Szaman Wojenny (leczy), boss, Magiczny Rycerz
  (wyłącza wieże i przyspiesza innych), Smok (zieje ogniem w żołnierzy), Jeżowiec (turla się
  i rzuca kolcami).
- **Sojusznicy i pomocnicy:** żołnierze z Koszar, rycerze z włóczniami, Bohater z Obrotem,
  Leśni Łucznicy z dmuchawkami, Palma z kokosami, ptak zrzucający jajka.
- **Umiejętności:** Deszcz ognia i Posiłki.

### Ciekawsze zasady poziomów

- **Rzeka Mostów:** nowi wrogowie idą przez otwarty most, a co 20 s otwiera się drugi. Poprzedni
  most zostaje opuszczony, dopóki są na nim wrogowie, i dopiero potem się podnosi.
- **Rozdroża:** darmowa Wieża Rycerska, drugi start od 4. fali.
- **Leśna Przełęcz:** w tunelu wrogowie są niewidzialni; z gniazd w górach wychodzą Leśni Łucznicy.
- **Słoneczna Zatoka:** Bohater-Rycerz, Smoki i Magiczni Rycerze.
- **Pirackie Wybrzeże:** Statek do kupienia na morzu, Palma ogłuszająca wrogów, wieża na wysepce.

## Zapis gry

Odblokowane poziomy i stan rozgrywki zapisują się automatycznie: po każdej wyczyszczonej fali oraz
przy budowie i ulepszaniu między falami. Na ekranie wyboru poziomu pojawia się wtedy przycisk
„Kontynuuj”. Plik: `user://save.cfg`.

## Edycja poziomów w Godocie

Każdy poziom to scena `levels/level_NN.tscn`, którą edytuje się myszką w edytorze:

| Węzeł | Co to jest |
|---|---|
| `Trawa`, `Piasek`, `Woda`, `Piana`, `Droga`, `DrogaSkos`, `Gory` | kafelki (TileMapLayer). Piasek, wodę, drogi i góry maluje się pędzlem terenu (TileMap → Terrains) |
| `MiejscaNaWieze` | miejsca budowy. Nowe dopisuj na końcu i nie zmieniaj kolejności, bo zapis gry pamięta wieże po numerze |
| `Ozdoby` | drzewa, szczyty, krzaki, kamienie, lilie, muszelki (punkt węzła = podstawa) |
| `Trasa1`, `Trasa2`, … | trasy wrogów (Path2D). Punkty na środkach kafelków (32k + 16), skosy dokładnie 45° |

W Inspektorze głównego węzła są przyciski **„Wygeneruj cały teren”** i **„Wygeneruj drogę z tras”**.
Generator bierze wodę, plażę, góry i tunele z pliku danych poziomu (`data/levels/`). Puste warstwy
wypełniają się same przy otwarciu sceny. Po zmianach zapisz scenę (Ctrl+S).

Liczby i zasady poziomu (fale, złoto, mosty, tunele, Bohater…) są w `data/levels/level_NN_*.gd`,
a opis wszystkich kluczy jest w nagłówku `data/level_data.gd`.

## Grafika

Cała grafika to pixel art w `assets/` (1 piksel obrazka = 2 jednostki gry, filtr Nearest):

```
assets/terrain/      kafelki terenu dopasowywane po rogach, mosty, miejsca budowy, tunel
assets/nature/       drzewa, krzaki, kamienie, szczyty, kwiaty, lilie, muszelki
assets/objects/      palma, statek, gniazdo łucznika, wciągarka mostu
assets/enemies/      arkusze animacji wrogów (<typ>_<animacja>.png)
assets/allies/       arkusze animacji żołnierzy, rycerzy, Bohatera i Leśnego Łucznika
assets/towers/       25 wież (5 typów × 3 poziomy + 2 ulepszenia)
assets/projectiles/  pociski
assets/effects/      wybuch, deszcz ognia, dymek
assets/ui/           ikony wież, umiejętności i paska
```

Grafiki generuje `tools/gen_art.py` (wymaga Pillow: `pip install pillow`, uruchamiany z katalogu
projektu). Formaty arkuszy są opisane w `assets/README_grafiki.md`. Wersję skośnej drogi na piasek
tworzy `tools/recolor_diagonal.py`. Dźwięki są syntezowane w kodzie, więc gra nie ma plików audio.

## Struktura kodu

```
data/        balans i treść: balance.gd, enemy_data.gd, tower_data.gd, wave_data.gd,
             level_data.gd (lista poziomów i opis kluczy), levels/ (jeden plik na poziom)
levels/      sceny poziomów (mapa, trasy, miejsca na wieże)
entities/    wrogowie (enemies/), wieże (towers/), żołnierze, Bohater, pociski, efekty,
             unit_sprites.gd (animacje postaci)
world/       rozgrywka na poziomie (game_world.gd), scena poziomu i generator kafelków
             (level_scene.gd), mosty i tunele na mapie (level_map.gd)
systems/     zapis gry, dźwięk, trasy, mosty, fale, umiejętności, Leśni Łucznicy
ui/          pasek interfejsu, menu budowy, panele, ekrany, ikony
tools/       generatory grafik
main.gd      przełączanie ekranów i obsługa klawiatury/myszy
```

Wskazówki dla pracy z Claude Code są w `CLAUDE.md`.
