# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Kingdom Defense is a tower defense game in Godot 4.7 (GDScript, `gl_compatibility` renderer). It has no build step, linter or test suite. To run it, open `project.godot` in the Godot editor and press F5. The main scene is `main.tscn`.

Godot is not on PATH. The executable is `C:/Users/user/Desktop/Godot/Godot_v4.7.2-stable_mono_win64_console.exe`. Useful headless checks:
- `--headless --path . --import`: rescans the project and rebuilds the `class_name` cache. Run it after adding or renaming `class_name` scripts, because it reports parse errors.
- `--headless --path . --quit-after 300`: boots the game into the main menu.
- `--headless --path . --export-release "Windows Desktop" "build/Kingdom Defense.exe"`: builds the standalone game (one exe with the embedded pck; preset in `export_presets.cfg`, templates in `%APPDATA%/Godot/export_templates/4.7.2.stable.mono`). The desktop shortcut `Kingdom Defense.lnk` points to it. Re-export when the user asks to update the desktop version. Icon: `icon.png` / `icon.ico`.
- Headless runs never call `_draw()`, so they cannot catch drawing bugs. To check visuals, run a temporary scene in a window (`--path . --resolution 1280x720 res://<scene>.tscn`) and save `get_viewport().get_texture().get_image()` as a PNG after ~90 frames.

To exercise gameplay, create a temporary scene that instances `main.tscn` and calls `world._tick(dt)` directly. Back up `%APPDATA%/Godot/app_userdata/Kingdom Defense/save.cfg` first, because the game writes to it.

All in-game text, comments and `README.md` are in Polish. Keep new UI strings and comments in Polish to match. **Respond to the user in Polish.**

## Where things live

| Task | File(s) |
|---|---|
| Enemy stats / new enemy type | `data/enemy_data.gd` → sheets in `assets/enemies/` + frame size in `entities/unit_sprites.gd` → subclass + `enemy_factory.gd` entry only if it has an ability or flies |
| Enemy look or special ability | sheets `assets/enemies/<type>_<anim>.png`; `entities/enemies/<type>.gd` (`_sheet_name`, `_draw_under`, `_draw_over`, `_update_ability`) |
| Enemy movement, blocking, damage, death | `entities/enemies/enemy.gd` |
| Tower stats, level-4 branches | `data/tower_data.gd` (`TOWERS`, `BRANCHES`, `BUILD_MENU` order) |
| How stats are computed from level/branch | `entities/towers/tower_stats.gd` |
| Tower look | `assets/towers/<art>_<level>.png` + `art` keys in `data/tower_data.gd`; drawn in `entities/towers/tower.gd` (ship: `ship_tower.gd`) |
| Shooting / targeting (furthest enemy along path) | `entities/towers/shooter_tower.gd` |
| Soldier towers, rally point, formation | `entities/towers/soldier_tower.gd` |
| Soldier AI (targeting, blocking, respawn) and reinforcements | `entities/soldier.gd` (art: `assets/allies/`, drawn via `UnitSprites`) |
| Animated unit sheets (enemies and allies), frame sizes | `entities/unit_sprites.gd` |
| Projectiles (splash, slow, chain lightning) | `entities/projectile.gd` (art: `assets/projectiles/`) |
| Visual effects / fire strike / floating text | `entities/effects/` (art: `assets/effects/`) |
| Economy, abilities, level scaling, upgrade costs | `data/balance.gd` |
| Wave composition and spawn gaps | `data/wave_data.gd`; queue logic in `systems/wave_spawner.gd` |
| Level numbers and rules, water/beach/mountain polygons | `data/levels/level_NN_*.gd` + register in `data/level_data.gd` (`LEVELS`) |
| Level map: tiles, trees, tower spots, enemy routes, objects (bridges, drawbridges, tunnels, archer nests, ship, hero, palms, free knight tower; node `Obiekty`, script `world/level_object.gd`, read by `LevelScene.get_objects()`) (edited in the Godot editor) | `levels/level_NN.tscn`; tile generator in `world/level_scene.gd`; art in `assets/` (generator `tools/gen_art.py`; `sand_road_diagonal.png` from `tools/recolor_diagonal.py`) |
| Painted road (smooth spline route, wider on tight bends, mostly smooth edges with rough patches; level key `road: "painted"`, textures `assets/terrain/road_fill/edge/edge_lit/bits.png`, `sand_road_*` on beaches, generator `tools/gen_road_paint.py`) | `world/level_scene.gd` (`_paint_road`, `_smooth_route`, `_edge_table`) |
| Drawbridge rules | `systems/bridge_system.gd` (logic); drawn in `world/level_map.gd` |
| Bridge art: 5 fixed lengths (48–112 px, longer ones assembled from pieces) and the 6-frame drawbridge (`assets/terrain/bridge_*_N.png`, `drawbridge.png`, generator `tools/gen_bridges.py`) | `world/bridge_art.gd` (used by `level_map.gd` and the editor preview in `level_object.gd`) |
| Path math, nearest road point | `systems/path_network.gd` |
| Enemy war tower (level 8: periodic +35% speed in a circle; object kind `WAR_TOWER`, key `war_towers`) and alternating routes (`alternate_routes`, `GameWorld._pick_alternate_route`) | `entities/war_tower.gd` (art `assets/objects/war_tower.png`, generator `tools/gen_war_tower.py`), numbers `WAR_TOWER_*` in `data/balance.gd` |
| Level 9 undead (skeleton, armored, archer): portals (object kind `PORTAL`, key `portals`: zero-length route segment, `PathNetwork.portal_between`), skeleton archer, Mummy boss (summons, opens the hidden road: keys `hidden_route`, `hidden_routes`, `unpainted_routes`, timed spawn queue `WaveSpawner.add_timed`, scripted final wave `special_wave`, summons sent to `minion_routes`), boss HP bar (`boss_bar` flag, `Hud._draw_boss_bar`) | `entities/enemies/skeleton_archer.gd`, `mummy.gd`; `GameWorld.open_hidden_route/spawn_minion`; `LevelScene.reveal_hidden_road`; art `tools/gen_undead.py` (skeletons, mummy, `objects/pyramid.png`, `objects/portal.png`) |
| Ability cooldowns/targeting state | `systems/abilities.gd`; effects in `GameWorld._cast_fire/_cast_reinforcements` |
| Build/upgrade/sell, win/lose, autosave, selection | `world/game_world.gd` |
| Bridges, tunnel entrances, archer nests, ship berth (drawn over the level scene) | `world/level_map.gd` |
| Range preview & selected-spot ring / enemy ring & ability aim | `world/spot_overlay.gd` / `world/aim_overlay.gd` |
| Radial build menu around a spot | `ui/build_menu.gd` |
| Top/bottom bar, buttons, pause overlay | `ui/hud.gd` (icons: `assets/ui/`) |
| Hover/selection stat panels and their texts | `ui/info_panel.gd` |
| Title, level select (minimap skips `hidden_routes`/`unpainted_routes`, breaks the line at portals), end screen | `ui/main_menu.gd`, `ui/level_select.gd`, `ui/end_screen.gd` |
| Shared drawing helpers (text, button, panel, HP bar, wrap) | `ui/ui_draw.gd`; clickable rect + action in `ui/ui_button.gd` |
| Keyboard shortcuts, click routing, screen switching | `main.gd` |
| Save format | `systems/save_manager.gd` |
| Sounds (names: shoot, magic, boom, coin, build, hurt, wave) | `systems/audio.gd` → `Audio.play("name")` |

## Conventions

- Identifiers in English, comments/UI strings in Polish. `##` doc comment at the top of every script says what it is for.
- Static typing everywhere (`var x := ...`, typed params/returns, `Array[Enemy]`). Values read from the `const` data dictionaries are `Variant` — declare the type explicitly (`var cost: int = TowerData.TOWERS[t].cost`) instead of `:=`.
- Shared state is reached through `world` (every entity has `var world: GameWorld`, set by `GameWorld._add_unit`). Add new entities via `GameWorld.add_*` / `_add_unit` so they land in both the list and the right layer.
- Entity positions use Node2D `position`; drawing is in local coordinates around `Vector2.ZERO`.
- Script-only subclasses (enemy/tower types) have no `class_name`; base classes and helpers do.
- A texture drawn in `_draw()` must stay referenced (a `preload` const, a member var or a static cache like `UnitSprites._sheets`). A `load()` result used only inside `_draw()` is freed before rendering and shows as a white rectangle or nothing.
- `.gd.uid` files are generated by Godot — commit them alongside new scripts.

## Architecture

Maps, units, towers, projectiles, most effects and the UI icons are pixel art from `assets/` (generated by `tools/gen_art.py`, which also runs `gen_units.py`, `gen_fx.py`, `gen_road_paint.py`, `gen_bridges.py`, `gen_war_tower.py` and `gen_undead.py`; needs Pillow; formats in `assets/README_grafiki.md`) (1 art pixel = 2 game units; every node that draws pixel art sets `texture_filter = NEAREST` in `_ready`). Everything is still drawn from `_draw()` (no Sprite2D nodes outside level scenes); text, buttons, panels, HP bars and a few effects (heal, zap, seal, flame) are drawn in code. There are no audio files: `systems/audio.gd`, autoloaded as `Audio`, synthesizes its sounds. Logical resolution is 1280×720 (`GameConfig.W/H/TOP`), and the window scales via `content_scale_mode`.

- **`main.gd`:** the screen state machine (`Screen.MENU/LEVEL_SELECT/PLAYING/ENDED`). It toggles node visibility and routes all input. Game clicks are resolved in a fixed priority order: HUD, then ability targeting, then build menu, then map selection (`_handle_game_click`). UI screens report actions back to `main.gd` through signals.
- **`world/game_world.gd` (`GameWorld`):** a single level's gameplay. It owns:
  - gold, lives, `spawner`, `abilities`, `paths`, `bridges`, `spots`, the selection state
  - typed lists of entities (`enemies`, `soldiers`, `projectiles`, `strikes`, `effects`, `texts`)
- **Rendering order:** `GameWorld`'s child layers in `main.tscn`. `Map` (`LevelMap`) holds the level scene (`show_behind_parent`, so it is drawn under everything) and a pixel-art layer for bridges, tunnels and archer nests. `Enemies` is `y_sort_enabled`. `BuildMenu` is a child of `World` so it draws above units but below the HUD.
- **Game time vs. real time:** entities never use `_process` for logic. `GameWorld._tick(dt)` calls `tick(dt)` on every entity in a fixed order and runs only while `active and not paused`, with `dt` scaled by `game_speed`. After all ticks, `_remove_finished` frees entities whose `is_finished()` returns true. The bridge animation is the exception: it runs on real time.
- **Freed references:** entities can hold references to enemies or soldiers that have already been freed. Check them with `Enemy.is_alive(e)` or `is_instance_valid()`, never with `!= null`.
- **Entities (`entities/`):** `Enemy` and `Tower` are base classes. Enemy subclasses exist only for types with abilities or flight (behaviour hooks such as `Shaman._update_ability`, sheet choice in `_sheet_name`); plain types are a bare `Enemy`. Tower subclasses pick the behaviour class (`ShooterTower`/`SoldierTower`). `EnemyFactory` and `TowerFactory` map type strings to scripts.
  - `ShooterTower` fires projectiles.
  - `SoldierTower` keeps its soldier count equal to `stats.soldier_count()`.
- **`TowerStats`:** a stateless object holding (type, level, branch). It computes all tower numbers from `TowerData` plus `Balance`. Branch effects are data-driven modifier keys in `TowerData.BRANCHES` (`dmg_mult`, `shots`, `extra_soldiers`, …). The info panel builds "after upgrade" previews with `stats.preview()`.
- **Data (`data/`):** content lives in `const` dictionaries.
  - Each level has its own file in `data/levels/` exposing `const DATA`, and must also be registered in `LevelData.LEVELS`. All level keys are documented in `level_data.gd`'s header.
  - Each level also has a scene `levels/level_NN.tscn` (`DATA.scene`, root script `LevelScene`). `LevelData.get_level()` adds `routes` (the scene's `Path2D` children, in order) and `spots` (children of `MiejscaNaWieze`, in order; the order is the save-file index) from it. Empty tile layers are generated from the level's polygons and routes.
  - A new enemy type needs a data entry and sprite sheets (plus a subclass and factory entry if it has an ability). A new tower type needs a data entry with `art`, art files, a subclass file and a factory entry.
- **Save file (`systems/save_manager.gd`):** `user://save.cfg`, kept compatible with the original single-file version.
  - `[progress]` holds unlocked and completed levels.
  - `[runs] level_N` holds the mid-level checkpoint, built by `GameWorld.save_run()`. It saves only when quiet (between waves). `GameWorld.restore()` reads it back.
  - Any new per-run state must be added to both `save_run()` and `restore()`.

## Painted roads: route design rules (reference: level 2)

The user likes level 2's road (`levels/level_02.tscn`, `Trasa1`); new painted roads should feel the same. The route is a centripetal Catmull-Rom spline through the `Path2D` points (`LevelScene._smooth_route`), so the points alone decide the shape.
- **Enable:** `"road": "painted"` in the level's `DATA`. Tunnels work: the tunnel stays a straight, unpainted segment between its exact ends (`_split_at_tunnels`), and the spline is computed separately before and after it. A route joining another one (same Path2D points from the join to the end) takes the earlier route's curve from the join (`_share_suffixes`). Drawbridges work: `zone_from`/`zone_to` stay Path2D point indices (mapped onto the spline in `get_objects`), routes sharing their first points share the smoothed curve up to the fork (`_share_prefixes`), and stretches shared with an earlier route are painted once. Clear the `Droga`/`DrogaSkos` tile data in the scene.
- **Sparse points:** put points only where the direction changes. A 90° turn is 3–4 points 50–70 units apart along a broad arc, e.g. level 2's loop `(925,115) (990,148) (1030,205) (1035,270)`. Aim for a turn radius of at least ~60 units.
- **Straight stretches:** collinear points. A bridge needs 4 collinear points (point before, both bridge ends, point after), e.g. `(870,304) (840,304) (455,304) (420,304)`.
- **No S-kinks:** never zigzag the direction within ~120 units. A wobbly sketch becomes one long arc (level 2's U-turn branches, tiles 9,16 / 16,18 / 17,13).
- **Screen limits:** the road is ~76 units wide (half 38, up to ~44 on tight bends). Keep the centre ≥ 100 from the top (HUD is 44), ≤ ~600 under the bottom buttons (x < 290 or x > 1060) and ≤ ~655 elsewhere. Routes start and end off-screen (x = -40 / 1320).
- **Clearances from the centre line:** water ≥ ~60 except at bridges, tower spots (64×44) ≥ ~75, decorations ≥ ~45. Two parallel road stretches with tower spots between them need ≥ ~150 between centres.
- **Look** (width, bends, rough patches, bridge taper) is set by the constants at the top of `world/level_scene.gd` (`HALF_MID`, `HALF_BEND`, `EDGE_ROUGH`, `ROUGH_FROM`, `BRIDGE_HALF`, `BRIDGE_TAPER`). Don't change them for one level without asking, because they affect every painted level.
- **User sketches** (screenshots in `assets/my/`): the user draws on an editor screenshot and names spots by tile coordinates (`x,y` = cell of 32 units, so tile 16,18 is around (528,592)). Map the screenshot through two known route points, convert the sketch to sparse points by the rules above, then move tower spots and decorations that collide (keep the spot order). Without Godot, check shape and clearances with a throwaway Python script that rebuilds the spline and the road edge.

## Praca z Claude — testowanie i oszczędzanie tokenów

### Zasady dla Claude
- **Użytkownik sam testuje zmiany w grze.** Nie uruchamiaj Godota, nie twórz scen testowych i nie wywołuj `world._tick(dt)`, chyba że użytkownik wprost o to poprosi. Po zmianie napisz krótko, co i gdzie sprawdzić w grze (np. „zbuduj łucznika na poziomie 2 i sprawdź zasięg”).
- Czytaj tylko pliki potrzebne do zadania. Najpierw sprawdź tabelę „Where things live”, zamiast przeszukiwać cały projekt.
- Jeśli zadanie dało się zlecić taniej (np. użytkownik mógł wskazać plik, funkcję albo podać treść błędu), dodaj na końcu odpowiedzi jedną linijkę **💡 Wskazówka:** z konkretną podpowiedzią, jak sformułować podobną prośbę następnym razem.
- Gdy zauważysz nowy sposób na oszczędzanie tokenów lub lepszą współpracę, zaproponuj dopisanie go do listy poniżej.

### Podpowiedzi dla użytkownika
- **Wskazuj plik i funkcję.** „W `entities/towers/shooter_tower.gd` w celowaniu…” jest dużo tańsze niż „gdzieś w wieżach…”. Pliki znajdziesz w tabeli „Where things live”. Możesz też dołączyć plik przez `@ścieżka/do/pliku`.
- **Podawaj konkretne wartości.** „Zmień zasięg łucznika ze 150 na 180” zamiast „zrób łucznika mocniejszego”.
- **Wklejaj dokładny błąd** z debuggera Godota (komunikat + plik:linia), zamiast opisywać objawy.
- **Jedno zadanie na rozmowę.** Między niezwiązanymi tematami wpisz `/clear`. Gdy rozmowa robi się długa, użyj `/compact`.
- **Grupuj drobne zmiany** w jednej wiadomości zamiast wysyłać je po kolei.
- **Duże zmiany zaczynaj od planu** (tryb planowania, Shift+Tab), żeby nie przerabiać kodu kilka razy.
- **Proste poprawki rób tańszym modelem** (`/model`), a mocniejszy zostaw na trudne problemy.
- **Nie proś o „przejrzyj cały projekt”**, jeśli chodzi o jedną rzecz. Zawęź zakres do pliku lub funkcji.
- **Nowa kręta droga na poziomie N** (szablon prośby):
  > Poziom N (`levels/level_0N.tscn`): zrób drogę malowaną jak na poziomie 2, według zasad z „Painted roads” w CLAUDE.md. Szkic trasy: `assets/my/lvl N.png` (czerwona linia, scena przeładowana przed zrzutem). Zakręty mają być szerokie jak na lvl 2 w miejscu 31,4. Na kafelkach X,Y chcę [prosty odcinek / pętlę / most]. Przestaw miejsca na wieże i ozdoby, które kolidują z drogą.
