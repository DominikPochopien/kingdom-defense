extends Node2D
## Kingdom Defense - punkt wejścia gry.
## Ustawia okno, przełącza ekrany (menu, wybór poziomu, gra, koniec gry) i rozdziela
## wejście z myszy i klawiatury. Cała rozgrywka jest w world/game_world.gd.
##
## Gdzie czego szukać:
##   data/      - balans, wrogowie, wieże, fale i poziomy (data/levels/)
##   entities/  - wrogowie, wieże, żołnierze, pociski, efekty
##   world/     - rozgrywka na poziomie i rysowanie mapy
##   systems/   - zapis gry, dźwięk, trasy, mosty, fale, umiejętności
##   ui/        - pasek interfejsu, menu budowy, panele, ekrany

enum Screen { MENU, LEVEL_SELECT, PLAYING, ENDED }

@onready var world: GameWorld = $World
@onready var hud: Hud = $Hud
@onready var info_panel: InfoPanel = $InfoPanel
@onready var end_screen: EndScreen = $EndScreen
@onready var main_menu: MainMenu = $MainMenu
@onready var level_select: LevelSelect = $LevelSelect

var save := SaveManager.new(LevelData.count())
var screen := Screen.MENU


func _ready() -> void:
	_setup_window()
	save.load_progress()
	world.save = save
	hud.world = world
	info_panel.world = world
	level_select.save = save
	_connect_signals()
	world.show_level(0)
	_set_screen(Screen.MENU)


func _setup_window() -> void:
	var win := get_window()
	win.content_scale_size = Vector2i(GameConfig.W, GameConfig.H)
	win.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	win.min_size = Vector2i(640, 360)
	get_tree().set_auto_accept_quit(false)


func _connect_signals() -> void:
	main_menu.play_pressed.connect(_open_level_select)
	level_select.back_pressed.connect(_set_screen.bind(Screen.MENU))
	level_select.new_game_requested.connect(_start_new_game)
	level_select.continue_requested.connect(_continue_game)
	hud.levels_requested.connect(_leave_to_level_select)
	hud.fullscreen_requested.connect(_toggle_fullscreen)
	end_screen.next_level_pressed.connect(func(): _start_level(world.level_index + 1))
	end_screen.retry_pressed.connect(func(): _start_level(world.level_index))
	end_screen.levels_pressed.connect(_open_level_select)
	world.won.connect(_on_level_won)
	world.lost.connect(_on_level_lost)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if screen == Screen.PLAYING:
			world.save_run()
		get_tree().quit()


# ================= EKRANY =================
func _set_screen(new_screen: Screen) -> void:
	screen = new_screen
	if screen != Screen.PLAYING:
		world.active = false
	world.visible = screen != Screen.LEVEL_SELECT
	hud.visible = screen == Screen.PLAYING or screen == Screen.ENDED
	info_panel.visible = screen == Screen.PLAYING
	end_screen.visible = screen == Screen.ENDED
	main_menu.visible = screen == Screen.MENU
	level_select.visible = screen == Screen.LEVEL_SELECT


func _open_level_select() -> void:
	level_select.open_at(world.level_index)
	_set_screen(Screen.LEVEL_SELECT)


func _leave_to_level_select() -> void:
	world.save_run()
	_open_level_select()


func _start_level(index: int) -> void:
	world.start(index)
	_set_screen(Screen.PLAYING)


func _start_new_game(index: int) -> void:
	save.delete_run(index)
	_start_level(index)


func _continue_game(index: int) -> void:
	var data := save.load_run(index)
	if data.is_empty():
		_start_level(index)
		return
	world.restore(index, data)
	_set_screen(Screen.PLAYING)


func _on_level_won() -> void:
	var index := world.level_index
	save.mark_completed(index)
	save.delete_run(index)
	Audio.play("coin")
	end_screen.show_result(true, index + 1 < LevelData.count(), world.lives, world.spawner.wave)
	_set_screen(Screen.ENDED)


func _on_level_lost() -> void:
	save.delete_run(world.level_index)
	Audio.play("hurt")
	end_screen.show_result(false, false, world.lives, world.spawner.wave)
	_set_screen(Screen.ENDED)


func _toggle_fullscreen() -> void:
	# gra osadzona w zakładce Game edytora może działać tylko w oknie
	if Engine.is_embedded_in_editor():
		return
	var win := get_window()
	win.mode = Window.MODE_WINDOWED if win.mode == Window.MODE_FULLSCREEN else Window.MODE_FULLSCREEN


# ================= WEJŚCIE =================
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_handle_click(event.position)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			world.abilities.cancel_targeting()
			world.clear_selection()
	elif event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE:
				world.start_next_wave()
			KEY_P:
				world.paused = not world.paused
			KEY_M:
				Audio.toggle_mute()
			KEY_F11:
				_toggle_fullscreen()
			KEY_ESCAPE:
				world.abilities.cancel_targeting()
				world.cancel_rally()
				world.selected_spot = null


func _handle_click(p: Vector2) -> void:
	match screen:
		Screen.MENU:
			main_menu.handle_click(p)
		Screen.LEVEL_SELECT:
			level_select.handle_click(p)
		Screen.ENDED:
			end_screen.handle_click(p)
		Screen.PLAYING:
			_handle_game_click(p)


## Kolejność ma znaczenie: pasek interfejsu > celowanie umiejętnością > punkt zbiórki
## > menu budowy > mapa.
func _handle_game_click(p: Vector2) -> void:
	if hud.handle_click(p):
		return
	if p.y < GameConfig.TOP or world.paused:
		return
	if world.abilities.is_targeting():
		world.cancel_rally()
		world.cast_ability_at(p)
		return
	if world.is_placing_rally():
		world.place_rally_at(p)
		return
	if world.build_menu.handle_click(p):
		return
	world.select_at(p)
