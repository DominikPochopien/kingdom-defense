# Kingdom Defense – grafiki, etap 1 (teren)

Wypakuj do katalogu głównego projektu (powstaną `assets/` i `tools/`).
Ponowne wygenerowanie: `pip install pillow`, potem `python tools/gen_art.py`.

Styl: pixel art, czytelność jak w klasycznych tower defense, przygaszone kolory.
Wszystkie kolory pochodzą z palety Resurrect 64 (skrypt to sprawdza).
Światło z lewej-góry, cienie po prawej-dole. Biomy: łąka/las i pustynia.

## Jak działają kafelki przejść

`road.png`, `sand_overlay.png`, `desert_path.png`, `water.png`, `oasis_water.png` to **nakładki**:
poza kształtem są przezroczyste. Kładzie się je na osobnej warstwie TileMapLayer nad trawą lub piaskiem.

Każdy kafelek jest opisany tym, które jego rogi należą do terenu (jak „Match Corners” w Godot 4).
Bity rogów: NW=1, NE=2, SW=4, SE=8. Maska = suma bitów.

- `road.png`, `sand_overlay.png`, `desert_path.png` (64x80): kafelek o masce `m` leży w kolumnie `m % 4`, wierszu `m // 4`.
  Wiersz 4 to 4 dodatkowe warianty pełnego kafelka (maska 15) do losowania.
- `water.png`, `oasis_water.png` (64x256): wiersz = maska 0..15, kolumny 0..3 = klatki animacji (proponowane 4 fps).
- Pełny opis jest w `assets/terrain/terrain_meta.json`.

Droga szeroka na 2 rogi daje pas 32 px grafiki (64 jednostki gry).
Proste odcinki, zakręty, skrzyżowania i rozwidlenia wychodzą same z ułożenia rogów.

## Uwaga techniczna

360 nie dzieli się przez 16, więc mapa ma 22,5 rzędu kafelków. Ostatni rząd jest przycinany
(albo mapa może mieć 368 px wysokości i kamera pokazuje 360).

W Godocie: Project Settings → Rendering → Textures → Default Texture Filter = Nearest.

## Etap 1b – dodatki

Nakładki dopasowywane po rogach (ten sam układ 64×80 co `road.png`):
- `beach.png` – trawa → piasek, miękka, postrzępiona krawędź, kępki trawy na piasku. Piasek jaśniejszy i mniej żółty.
- `sand_road.png` – droga na piasku: ubita ziemia z płaskimi kamieniami.
- `mountain.png` – skalny płaskowyż; od południa ma ścianę klifu, która schodzi ok. 5 px poniżej krawędzi.

Animowane (64×256, wiersz = maska, kolumny = 4 klatki):
- `sea.png` – morze z brzegiem pod plażę.
- `sea_foam.png` – sama piana; kładź na warstwie nad `sea.png`, z tą samą maską.

Skośna droga (`road_diagonal.png` + `road_diagonal_layout.json`):
- 4 gotowe układy po 11×11 kafelków: wejście z góry, skręt 45° w prawo lub w lewo, potem w poziom albo z powrotem w pion.
- Proste odcinki są piksel w piksel takie same jak w `road.png`, więc obie części się łączą.
- Podgląd: `preview_road_diagonal.png`.

Pojedyncze grafiki:
- `terrain/tunnel_entrance.png` 32×32 (stawiasz na ścianie klifu, droga wchodzi od dołu).
- `nature/peak_snow_a`, `peak_snow_b`, `peak_rock_a`, `peak_rock_b` – 48×48.
- `nature/lily_pad`, `lily_pad_flower` – 8×8; `shell_scallop`, `shell_spiral`, `shell_clam` – 6×6.
- `objects/archer_nest.png` 24×24, `objects/drawbridge_winch.png` 8×8.
- `objects/palm_sway.png` – 2 klatki 24×40; `objects/palm_coconut_fall.png` – 4 klatki 24×40.
- `objects/war_tower.png` – Wieża wroga, 3 klatki 24×44 (0 – spokojna, 1–2 – płonie); generator `tools/gen_war_tower.py`.
- Poziom 9 (generator `tools/gen_undead.py`): `enemies/skeleton_*` i `enemies/skeleton_archer_*` (klatki 16×20), `enemies/skeleton_armored_*` (18×22), `enemies/mummy_*` (28×32, także `mummy_cast` – przywołanie), `objects/pyramid.png` (80×64, drzwi w pikselu 31,62), `objects/portal.png` – 4 klatki 28×18 wiru (środek = punkt trasy).

## Etap 2 i 3 – wrogowie, wieże, statek

Generuje je `tools/gen_units.py` (uruchamiany automatycznie na końcu `gen_art.py`).

Wrogowie (`assets/enemies/<typ>_<animacja>.png`): poziome paski klatek, wszyscy patrzą w prawo,
stopy w dolnym środku, cień w ostatnim wierszu.
| typ | klatka | animacje |
|---|---|---|
| goblin | 16×16 | walk 4, attack 3, hit 1 |
| wolf | 20×14 | walk 4, attack 3, hit 1 |
| orc | 20×24 | walk 4, attack 3, hit 1 |
| bat | 16×12 | fly 4, hit 1 |
| shaman | 18×24 | walk 4, attack 3, hit 1 |
| boss | 32×32 | walk 4, attack 3, hit 1 |
| magic_knight, magic_knight_purple, magic_knight_blue | 20×28 | walk 4, attack 3, hit 1 (aura wbudowana w klatki) |
| dragon | 48×32 | fly 4, breathe 3, hit 1 |
| dragon_fire | 32×16 | 3 klatki; efekt doklejany lewą krawędzią do pyska |
| hedgehog | 20×16 | walk 4, roll 4 (kula), hit 1 |

Klatka `hit` to biała sylwetka przesunięta o 1 px do tyłu.

Wieże (`assets/towers/`, każda 32×40, podstawa w dolnym środku, pasuje na `build_spot.png`):
- `archer_1..3`, `archer_4a_ranger`, `archer_4b_crossbow`
- `mage_1..3`, `mage_4a_arcane`, `mage_4b_storm`
- `artillery_1..3`, `artillery_4a_mortar`, `artillery_4b_firecatapult`
- `barracks_1..3`, `barracks_4a_templar`, `barracks_4b_barbarian`
- `knight_1..3`, `knight_4a_paladin`, `knight_4b_darkknight`

Statek: `assets/objects/ship_sway.png` – 2 klatki 64×32, dziób w prawo, linia wody na dole.

## Etap 4 – sojusznicy, pociski, efekty, interfejs

Generuje je `tools/gen_fx.py` (uruchamiany na końcu `gen_art.py`). Podgląd: `overview_allies_fx.png`, `preview_ui.png`.

Sojusznicy (`assets/allies/`, patrzą w prawo):
| plik | klatka | animacje |
|---|---|---|
| soldier | 12×16 | walk 4, attack 3, hit 1 (miecz i tarcza) |
| spear_knight | 14×18 | walk 4, attack 3 (pchnięcie dzidą), hit 1 |
| hero | 16×22 | walk 4, attack 3, spin 4 (obrót: prawo, przód, lewo, tył), hit 1 |
| forest_ranger | 12×16 | walk 4, attack 3 (dmuchawka: przyłożenie, wydmuch, lot strzałki), hit 1 |

Wróg: `assets/enemies/desert_bird_fly.png` 16×12, 4 klatki (+ `desert_bird_hit`).

Pociski (`assets/projectiles/`, lecą w prawo): `arrow` 8×2, `magic_ball` 6×6 ×2 klatki,
`cannonball` 6×6, `coconut` 6×6, `egg` 4×5, `hedgehog_spike` 4×4.

Efekty (`assets/effects/`):
- `explosion` – 32×32, 5 klatek (błysk, kula ognia, ogień z dymem, dym, rozwiewanie).
- `fire_rain` – 24×32, 4 klatki (meteor wysoko, meteor nisko, uderzenie, płonąca ziemia).
- `death_puff` – 16×16, 4 klatki.
- `assets/enemies/dragon_fire.png` – 32×12, 3 klatki (zastępuje wersję 32×16).

Interfejs (`assets/ui/`):
- `icon_tower_archer`, `_mage`, `_artillery`, `_barracks`, `_knight`, `_forest` – 24×24, kamienna ramka.
- `icon_skill_fire_rain`, `_reinforcements`, `_hero_spin` – 24×24, złota ramka.
- `icon_gold`, `icon_life`, `icon_wave` – 12×12.

## Droga malowana wzdłuż trasy

Generuje ją `tools/gen_road_paint.py` (uruchamiany na końcu `gen_art.py`).
Podglądy: `preview_road_paint.png` (łuki, rozwidlenie, odcinek na plaży) i `preview_road_fill_tiling.png` (test szwów 3×3).

| plik | rozmiar | opis |
|---|---|---|
| `road_fill.png` | 32×32 | ubita ziemia, kamyki; powtarza się bez szwów w obu osiach, bez kierunku |
| `road_edge.png` | 8×1 | piksel 0 = skraj (ciemna trawa), 1–3 = ciemniejsza ziemia, 4–7 = kolor wnętrza |
| `road_edge_lit.png` | 8×1 | opcjonalnie: brzeg po stronie światła (jasna trawa na skraju) |
| `road_bits.png` | 64×16 | 16 drobiazgów 8×8: rząd 0 kamyki, koleiny, kałuża, patyk; rząd 1 kępki trawy, kwiatki, źdźbła |
| `sand_road_fill.png` | 32×32 | ciemna ubita ziemia z płaskimi kamieniami, jak `sand_road.png` |
| `sand_road_edge.png` / `_lit.png` | 8×1 | brzeg na plaży |
| `sand_road_bits.png` | 64×16 | jak wyżej, ale suche źdźbła, muszelki i jasny piasek |

Jak podgląd składa drogę (tak samo może to robić gra):
1. `d` = odległość piksela od najbliższej linii trasy, `i = floor(16 - d)` (połowa szerokości = 16 px).
2. Do `i` dodawane jest drganie ±1 px okresowe co 16 px (`edge_noise` w `gen_art.py`), żeby brzeg nie był idealnie gładki.
3. `i < 0` → trawa. `i` 0–7 → kolor z `road_edge`; po stronie, gdzie normalna wskazuje prawy-dół, z `road_edge_lit`.
4. Gdy kolor z paska jest równy kolorowi wnętrza (piksel 7) albo `i ≥ 8` → piksel z `road_fill` w (x mod 32, y mod 32).
5. Drobiazgi z `road_bits` rozrzucone w pasie od 7 px w głąb drogi do 1 px na zewnątrz.

W podglądzie droga łąkowa i plażowa po prostu nachodzą na siebie; w grze wystarczy przełączać komplet tekstur według podłoża.

## Mosty stałe i most zwodzony

Generuje je `tools/gen_bridges.py` (uruchamiany na końcu `gen_art.py`). Wymiary są dokładne co do piksela.
Podglądy: `preview_bridges.png` (most 96 poziomo i 80 pionowo na rzece z drogą o połowie szerokości 20 px),
`preview_drawbridge.png` (6 klatek nad rzeką), `preview_drawbridge.gif` (podnoszenie i opuszczanie).

Wspólne dla wszystkich mostów: szerokość 46 px = 3 px poręcz + 40 px pokładu + 3 px poręcz,
słupki poręczy co 8 px, światło z lewej-góry, deski w poprzek drogi.

| plik | rozmiar | opis |
|---|---|---|
| `bridge_h_48/64/80/96/112.png` | L×50 | droga poziomo; wiersze 0–45 to most, 46–49 półprzezroczysty cień na wodzie |
| `bridge_v_48/64/80/96/112.png` | 50×L | droga pionowo; kolumny 0–45 to most, 46–49 cień na wodzie |
| `bridges.png` | 496×210 | arkusz: rząd 1 poziome, rząd 2 pionowe, 16 px odstępu |
| `drawbridge.png` | 576×64 | most zwodzony, 6 klatek 96×64 w poziomym pasku |

Przyczółki: po 6 px na każdym końcu (wliczone w długość L). Pierwsze 3 px to ubita ziemia w kolorze
`road_fill`, potem kamienny próg; w narożnikach kamienne bloki kończące poręcze. Cień jest tylko pod
częścią nad wodą.

Wersje pionowe są narysowane osobno, nie obrócone: przy świetle z lewej-góry i widoku prosto z góry
poprawne cieniowanie wychodzi z odbicia względem przekątnej (cień poręczy pada na pokład, cień mostu
na prawo), a szum desek i słojów jest losowany od nowa.

Most zwodzony (`drawbridge.png`), w każdej klatce w tym samym miejscu:
- x 0–13: kamienny przyczółek z brukiem; filary nad i pod pokładem (y 2–11 i 52–61) z kołowrotami;
- x 14–79: ruchomy pokład 66 px, zawias przy x = 14; pokład zajmuje y 9–54 (46 px);
- x 80–95: miejsce na wydłużający się cień.

Klatki: kąt podniesienia 0°, 22°, 42°, 60°, 76°, 90°. Pokład skraca się do 66·cos(kąt), od ~40°
jaśnieje (zwraca się do światła), a z prawej rośnie ciemne czoło (grubość 4 px). Łańcuchy idą od
kołowrotów do okuć na końcu pokładu: w klatce 1 luźne, w 2 lekko ugięte, dalej napięte. Klatka 6:
widać tylko przyczółek i górę pionowego pokładu, rzeka jest odkryta. Opuszczanie = klatki od tyłu.

W grze rysuje je `world/bridge_art.gd`: most o długości 48/64/80/96/112 px to gotowa grafika, inny jest składany z końców
najdłuższej i powtarzanych kawałków po 16 px. Most zwodzony pokazuje klatkę według stanu animacji z `systems/bridge_system.gd`.
