extends Node2D
## Kingdom Defense - prosta gra tower defense (Godot 4)
## Cała gra jest rysowana kodem. Balans znajdziesz w stałych i słownikach poniżej.

const W = 1280
const H = 720
const TOP = 44

# ================= BALANS (łatwo zmieniać) =================
const SELL_REFUND = 0.6
const FIRE_CD = 30.0
const REINF_CD = 18.0
const EARLY_BONUS = 25

var TOWERS = {
	"archer": {"name": "Łucznicy", "cost": 70, "range": 170.0, "rate": 0.7, "dmg": 8.0, "magic": false, "splash": 0.0},
	"mage": {"name": "Magowie", "cost": 100, "range": 150.0, "rate": 1.8, "dmg": 24.0, "magic": true, "splash": 0.0},
	"barracks": {"name": "Koszary", "cost": 80, "range": 120.0, "rate": 0.0, "dmg": 4.0, "magic": false, "splash": 0.0},
	"artillery": {"name": "Artyleria", "cost": 120, "range": 210.0, "rate": 3.2, "dmg": 30.0, "magic": false, "splash": 70.0},
	"knight_tower": {"name": "Rycerze", "cost": 150, "range": 130.0, "rate": 0.0, "dmg": 7.0, "magic": false, "splash": 0.0},
}

# Ulepszenia 4. poziomu: gracz wybiera jedno z dwóch
var BRANCHES = {
	"archer": [
		{"id": "double", "name": "Podwójny strzał", "desc": "Strzela dwiema strzałami naraz (w 2 różne cele, jeśli są)."},
		{"id": "long", "name": "Sokole oko", "desc": "+40% zasięgu oraz +25% obrażeń."},
	],
	"mage": [
		{"id": "slow", "name": "Lodowa magia", "desc": "Trafienie spowalnia wroga o 40% na 2 sekundy."},
		{"id": "chain", "name": "Błyskawica", "desc": "Pocisk przeskakuje na drugiego wroga (50% obrażeń)."},
	],
	"barracks": [
		{"id": "vets", "name": "Weterani", "desc": "Żołnierze mają +60% HP i +50% obrażeń."},
		{"id": "extra", "name": "Oddział", "desc": "+2 żołnierzy (razem 5) i szybsze odradzanie (4 s)."},
	],
	"artillery": [
		{"id": "blast", "name": "Wielki wybuch", "desc": "+40% promienia wybuchu oraz +20% obrażeń."},
		{"id": "rapid", "name": "Szybki ogień", "desc": "Przeładowanie o 40% szybsze."},
	],
	"knight_tower": [
		{"id": "dmg", "name": "Ostre Włócznie", "desc": "Zadają +40% obrażeń z większym dystansem."},
		{"id": "hp", "name": "Gruby Pancerz", "desc": "Rycerze mają +60% życia."}
	],
}

# armor = redukcja obrażeń fizycznych, mr = redukcja magicznych (0..1)
var ENEMIES = {
	"goblin": {"title": "Goblin", "name": "goblinów", "hp": 40.0, "speed": 60.0, "armor": 0.0, "mr": 0.0, "reward": 8, "lives": 1, "flying": false, "dmg": 3.0, "r": 11.0},
	"wolf": {"title": "Wilk", "name": "wilków", "hp": 30.0, "speed": 115.0, "armor": 0.0, "mr": 0.0, "reward": 9, "lives": 1, "flying": false, "dmg": 4.0, "r": 10.0},
	"orc": {"title": "Ork pancerny", "name": "orków", "hp": 150.0, "speed": 45.0, "armor": 0.5, "mr": 0.3, "reward": 18, "lives": 2, "flying": false, "dmg": 8.0, "r": 15.0},
	"bat": {"title": "Nietoperz", "name": "nietoperzy", "hp": 35.0, "speed": 95.0, "armor": 0.0, "mr": 0.0, "reward": 10, "lives": 1, "flying": true, "dmg": 0.0, "r": 9.0},
	"shaman": {"title": "Szaman Wojenny", "name": "szamanów", "hp": 350.0, "speed": 42.0, "armor": 0.15, "mr": 0.45, "reward": 45, "lives": 3, "flying": false, "dmg": 6.0, "r": 17.0, "ability": "heal"},
	"boss": {"title": "BOSS: Wódz", "name": "BOSS", "hp": 800.0, "speed": 32.0, "armor": 0.3, "mr": 0.3, "reward": 150, "lives": 5, "flying": false, "dmg": 20.0, "r": 24.0},
}

# Poziomy (mapy). path = waypointy, spots = miejsca budowy.
var LEVELS = [
	{
		"name": "Zielone Wzgórza", "desc": "Klasyczna mapa na rozgrzewkę.",
		"waves": 10, "gold": 300, "lives": 20, "hp": 1.0, "difficulty": "Łatwy",
		"path": [Vector2(-40, 200), Vector2(250, 200), Vector2(250, 500), Vector2(560, 500),
			Vector2(560, 200), Vector2(900, 200), Vector2(900, 520), Vector2(1320, 520)],
		"spots": [Vector2(170, 330), Vector2(335, 330), Vector2(335, 110), Vector2(400, 420),
			Vector2(400, 585), Vector2(480, 330), Vector2(645, 340), Vector2(730, 285),
			Vector2(730, 115), Vector2(820, 400), Vector2(985, 400), Vector2(1050, 440),
			Vector2(1050, 610), Vector2(1180, 440)],
	},
	{
		"name": "Kręta Droga", "desc": "Długi wąż - wrogowie mają +25% HP i jest 12 fal.",
		"waves": 12, "gold": 350, "lives": 20, "hp": 1.25, "difficulty": "Trudny",
		"path": [Vector2(-40, 110), Vector2(1050, 110), Vector2(1050, 290), Vector2(230, 290),
			Vector2(230, 470), Vector2(1050, 470), Vector2(1050, 600), Vector2(1320, 600)],
		"spots": [Vector2(140, 200), Vector2(400, 200), Vector2(600, 200), Vector2(800, 200),
			Vector2(1150, 200), Vector2(140, 380), Vector2(450, 380), Vector2(650, 380),
			Vector2(850, 380), Vector2(1150, 380), Vector2(450, 560), Vector2(700, 560),
			Vector2(900, 560)],
	},
	{
		"name": "Rzeka Mostów", "desc": "Dwa zwodzone mosty: otwarty jest zawsze jeden i zmienia się co 20 s, ale nigdy nie zamknie się, gdy wrogowie są na jego zjeździe lub na nim. Wrogowie mają +40% HP, a Szamani Wojenni leczą towarzyszy.",
		"waves": 12, "gold": 520, "lives": 25, "hp": 1.4, "difficulty": "Bardzo trudny", "shamans": true, "bridge_period": 20.0,
		"routes": [
			[Vector2(-40, 130), Vector2(340, 130), Vector2(340, 446), Vector2(900, 446), Vector2(900, 216),
				Vector2(1210, 216), Vector2(1210, 610), Vector2(780, 610), Vector2(780, 790)],
			[Vector2(-40, 130), Vector2(340, 130), Vector2(340, 446), Vector2(900, 446), Vector2(1210, 446),
				Vector2(1210, 610), Vector2(780, 610), Vector2(780, 790)],
		],
		"river": [Vector2(985, 44), Vector2(1010, 250), Vector2(1000, 420), Vector2(960, 520), Vector2(880, 610),
			Vector2(780, 720), Vector2(900, 720), Vector2(1020, 610), Vector2(1100, 520), Vector2(1140, 420),
			Vector2(1150, 250), Vector2(1130, 44)],
		"bridges": [
			{"a": Vector2(996, 216), "b": Vector2(1152, 216), "name": "Most 1", "route": 0, "zone_from": 3, "zone_to": 5},
			{"a": Vector2(982, 446), "b": Vector2(1136, 446), "name": "Most 2", "route": 1, "zone_from": 3, "zone_to": 4},
		],
		"fixed_bridges": [{"a": Vector2(872, 610), "b": Vector2(1030, 610)}],
		"spots": [Vector2(200, 240), Vector2(200, 420), Vector2(200, 590), Vector2(470, 230),
			Vector2(520, 360), Vector2(700, 360), Vector2(520, 545), Vector2(700, 545),
			Vector2(850, 545), Vector2(820, 330), Vector2(800, 170), Vector2(958, 330),
			Vector2(1140, 530), Vector2(1000, 685), Vector2(680, 665)],
	},
	{
		"name": "Rozdroża", "desc": "Dwa starty: drugi włącza się od 4. fali, a wrogowie wybierają losowy. Masz darmową Wieżę Rycerską (pomarańczowa), której rycerze biją też latające wrogi.",
		"waves": 12, "gold": 400, "lives": 20, "hp": 1.4, "difficulty": "Bardzo trudny", "random_routes_from": 4,
		"routes": [
			[Vector2(200, -40), Vector2(200, 600), Vector2(500, 600), Vector2(500, 200), Vector2(1320, 200)],
			[Vector2(1320, 600), Vector2(500, 600), Vector2(500, 200), Vector2(1320, 200)]
		],
		"river": [Vector2(-40, 350), Vector2(1320, 350), Vector2(1320, 450), Vector2(-40, 450)],
		"fixed_bridges": [
			{"a": Vector2(200, 340), "b": Vector2(200, 460), "vertical": true},
			{"a": Vector2(500, 340), "b": Vector2(500, 460), "vertical": true}
		],
		"spots": [
			Vector2(280, 200), Vector2(280, 520), Vector2(350, 670),
			Vector2(610, 270), Vector2(600, 520), Vector2(900, 670),
			Vector2(1050, 120), Vector2(400, 150)
		],
		"special_tower": 7
	}
]

# ================= KLASY DANYCH =================
class Enemy:
	var type = ""
	var hp = 0.0
	var maxhp = 0.0
	var speed = 0.0
	var armor = 0.0
	var mr = 0.0
	var reward = 0
	var lives = 1
	var flying = false
	var dmg = 0.0
	var r = 10.0
	var dist = 0.0
	var pos = Vector2.ZERO
	var dead = false
	var blocked_by = null
	var cd = 0.0
	var flash = 0.0
	var anim = 0.0
	var slow = 0.0
	var route = 0
	var ability = ""
	var heal_cd = 3.0
	var forked = false

class Soldier:
	var type = "soldier"
	var pos = Vector2.ZERO
	var rally = Vector2.ZERO
	var hp = 50.0
	var maxhp = 50.0
	var dmg = 4.0
	var radius = 120.0
	var tower = null
	var target = null
	var cd = 0.0
	var alive = true
	var respawn = 0.0
	var life = -1.0
	var gone = false

class Tower:
	var type = ""
	var branch = ""
	var level = 1
	var spent = 0
	var cd = 0.0
	var pos = Vector2.ZERO
	var soldiers = []
	var rally = Vector2.ZERO

class Spot:
	var pos = Vector2.ZERO
	var tower = null

class Proj:
	var pos = Vector2.ZERO
	var target = null
	var last = Vector2.ZERO
	var speed = 400.0
	var dmg = 0.0
	var magic = false
	var splash = 0.0
	var kind = ""
	var done = false
	var slow = false
	var chain = false

# ================= STAN GRY =================
var state = "menu"  # menu / levels / play / win / lose
var cur_level = 0
var unlocked = 1
var completed = []
var total_waves = 10
var hp_mult = 1.0
var selected_enemy = null
var gold = 0
var lives = 0
var wave = 0
var paused = false
var game_speed = 1.0
var muted = false

var spawn_queue = []
var spawn_timer = 0.0
var enemies = []
var soldiers = []
var projectiles = []
var strikes = []
var fx = []
var floats = []
var spots = []

var selected_spot = -1
var targeting = ""
var fire_cd = 0.0
var reinf_cd = 0.0
var mouse = Vector2.ZERO
var level_page = 0       # strona ekranu wyboru poziomu (6 slotów na stronę)
const LEVEL_SLOTS = 6

const SAVE_PATH = "user://save.cfg"
var routes = []        # lista tras: {"pts", "cum", "len"}
var samples = PackedVector2Array()
var active_bridge = 0   # który most jest teraz otwarty
var bridge_timer = 20.0 # czas do następnej zmiany mostu (s)
var bridge_t = [1.0, 0.0]
var was_busy = false
var run_waves = {}     # poziom -> ukończone fale w zapisanej rozgrywce
var decor = []
var font
var sfx_players = []
var sfx_streams = {}

# prostokąty przycisków interfejsu
var R_FULL = Rect2(830, 6, 80, 32)
var R_MENU = Rect2(920, 6, 80, 32)
var R_BACK = Rect2(20, H - 70, 160, 50)
var R_PREV = Rect2(W / 2 - 150, H - 70, 120, 50)
var R_NEXTP = Rect2(W / 2 + 30, H - 70, 120, 50)
var R_PAUSE = Rect2(1100, 6, 80, 32)
var R_SPEED = Rect2(1190, 6, 80, 32)
var R_MUTE = Rect2(1010, 6, 80, 32)
var R_NEXT = Rect2(W - 210, H - 62, 200, 52)
var R_FIRE = Rect2(10, H - 66, 130, 56)
var R_REINF = Rect2(150, H - 66, 130, 56)
var R_PLAY = Rect2(W / 2 - 130, 400, 260, 64)


func _ready():
	font = ThemeDB.fallback_font
	var win = get_window()
	win.content_scale_size = Vector2i(W, H)
	win.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	win.min_size = Vector2i(640, 360)
	get_tree().set_auto_accept_quit(false)
	load_progress()
	setup_level(0)
	_setup_audio()

func setup_level(idx):
	cur_level = idx
	var L = LEVELS[idx]
	routes.clear()
	var rs = L.routes if L.has("routes") else [L.path]
	for r in rs:
		routes.append({"pts": r.duplicate(), "cum": [], "len": 0.0})
	_build_path()
	reset_bridges()
	spots.clear()
	for p in L.spots:
		var s = Spot.new()
		s.pos = p
		spots.append(s)
		
	total_waves = L.waves
	hp_mult = L.hp
	decor.clear()
	var rng = RandomNumberGenerator.new()
	rng.seed = 7 + idx * 13
	var tries = 0
	while decor.size() < 60 and tries < 800:
		tries += 1
		var p = Vector2(rng.randf_range(10, W - 10), rng.randf_range(TOP + 10, H - 10))
		if p.distance_to(nearest_path_point(p)) < 60:
			continue
		if L.has("river"):
			var rv = PackedVector2Array(L.river)
			var near_river = false
			for o in [Vector2.ZERO, Vector2(22, 0), Vector2(-22, 0), Vector2(0, 22), Vector2(0, -22)]:
				if Geometry2D.is_point_in_polygon(p + o, rv):
					near_river = true
			if near_river:
				continue
		var ok = true
		for s in spots:
			if s.pos.distance_to(p) < 50:
				ok = false
		if p.y > H - 80 and (p.x < 300 or p.x > W - 230):
			ok = false
		if ok:
			decor.append([p, rng.randf_range(0.7, 1.2)])

func load_progress():
	var cf = ConfigFile.new()
	if cf.load(SAVE_PATH) == OK:
		unlocked = int(cf.get_value("progress", "unlocked", 1))
		completed = cf.get_value("progress", "completed", [])
		run_waves.clear()
		for i in LEVELS.size():
			var key = "level_%d" % i
			if cf.has_section_key("runs", key):
				run_waves[i] = int(cf.get_value("runs", key).get("wave", 0))
	while completed.size() < LEVELS.size():
		completed.append(false)
	var before = unlocked
	for i in LEVELS.size():
		if completed[i]:
			unlocked = max(unlocked, i + 2)
	unlocked = clamp(unlocked, 1, LEVELS.size())
	if unlocked != before:
		save_progress()

func save_progress():
	var cf = ConfigFile.new()
	cf.load(SAVE_PATH)
	cf.set_value("progress", "unlocked", unlocked)
	cf.set_value("progress", "completed", completed)
	cf.save(SAVE_PATH)

func is_quiet():
	return state == "play" and spawn_queue.is_empty() and enemies.is_empty()

func save_run():
	if not is_quiet():
		return
	var towers = []
	for i in spots.size():
		var t = spots[i].tower
		if t != null:
			towers.append({"spot": i, "type": t.type, "level": t.level, "branch": t.branch, "spent": t.spent})
	var d = {"gold": gold, "lives": lives, "wave": wave, "fire_cd": fire_cd, "reinf_cd": reinf_cd, "towers": towers,
		"bridge": active_bridge, "bridge_timer": bridge_timer}
	var cf = ConfigFile.new()
	cf.load(SAVE_PATH)
	cf.set_value("runs", "level_%d" % cur_level, d)
	cf.save(SAVE_PATH)
	run_waves[cur_level] = wave

func delete_run(idx):
	var cf = ConfigFile.new()
	if cf.load(SAVE_PATH) == OK and cf.has_section_key("runs", "level_%d" % idx):
		cf.erase_section_key("runs", "level_%d" % idx)
		cf.save(SAVE_PATH)
	run_waves.erase(idx)

func continue_run(idx):
	var cf = ConfigFile.new()
	if cf.load(SAVE_PATH) != OK or not cf.has_section_key("runs", "level_%d" % idx):
		start_game(idx)
		return
	var d = cf.get_value("runs", "level_%d" % idx)
	start_game(idx)
	gold = int(d.gold)
	lives = int(d.lives)
	wave = int(d.wave)
	fire_cd = float(d.get("fire_cd", 0.0))
	reinf_cd = float(d.get("reinf_cd", 0.0))
	for td in d.towers:
		var i = int(td.spot)
		if i >= 0 and i < spots.size():
			restore_tower(spots[i], td)
	active_bridge = int(d.get("bridge", 0))
	bridge_timer = float(d.get("bridge_timer", bridge_period()))
	snap_bridges()

func restore_tower(spot, d):
	if spot.tower != null:
		# wieża specjalna utworzona przez start_game - usuń jej żołnierzy, by nie dublować
		for old in spot.tower.soldiers:
			old.gone = true
	var t = Tower.new()
	t.type = d.type
	t.pos = spot.pos
	t.level = int(d.level)
	t.branch = d.branch
	t.spent = int(d.spent)
	spot.tower = t
	if t.type == "barracks" or t.type == "knight_tower":
		t.rally = nearest_path_point(spot.pos)
		var n = 0
		if t.type == "barracks":
			n = 5 if t.branch == "extra" else 3
		else:
			n = min(t.level, 3)
		for i in n:
			add_soldier(t)
		layout_soldiers(t)

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_run()
		get_tree().quit()

# ================= DŹWIĘK =================
func make_tone(freq, dur, noise = false, vol = 0.5):
	var s = AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_8_BITS
	s.mix_rate = 22050
	var n = int(22050 * dur)
	var data = PackedByteArray()
	data.resize(n)
	for i in n:
		var t = float(i) / 22050.0
		var env = 1.0 - float(i) / float(n)
		var v = 0.0
		if noise:
			v = randf() * 2.0 - 1.0
		else:
			v = sin(TAU * freq * t)
		var iv = int(clamp(v * env * vol * 127.0, -127, 127))
		data[i] = iv & 0xFF
	s.data = data
	return s

func _setup_audio():
	sfx_streams["shoot"] = make_tone(900, 0.07)
	sfx_streams["magic"] = make_tone(500, 0.16)
	sfx_streams["boom"] = make_tone(0, 0.25, true, 0.6)
	sfx_streams["coin"] = make_tone(1300, 0.08, false, 0.35)
	sfx_streams["build"] = make_tone(300, 0.12)
	sfx_streams["hurt"] = make_tone(140, 0.25, false, 0.6)
	sfx_streams["wave"] = make_tone(220, 0.4)
	for i in 8:
		var p = AudioStreamPlayer.new()
		add_child(p)
		sfx_players.append(p)

func sfx(name):
	if muted or not sfx_streams.has(name):
		return
	for p in sfx_players:
		if not p.playing:
			p.stream = sfx_streams[name]
			p.volume_db = -8.0
			p.play()
			return


# ================= ŚCIEŻKA =================
func _build_path():
	samples = PackedVector2Array()
	for r in routes:
		var pts = r.pts
		r.cum = [0.0]
		for i in range(1, pts.size()):
			r.cum.append(r.cum[i - 1] + pts[i].distance_to(pts[i - 1]))
		r.len = r.cum[r.cum.size() - 1]
		var d = 0.0
		while d <= r.len:
			samples.append(path_pos(d, routes.find(r)))
			d += 8.0

func path_pos(d, ri = 0):
	var r = routes[ri]
	d = clamp(d, 0.0, r.len)
	for i in range(1, r.pts.size()):
		if d <= r.cum[i]:
			var seg = r.cum[i] - r.cum[i - 1]
			return r.pts[i - 1].lerp(r.pts[i], (d - r.cum[i - 1]) / seg)
	return r.pts[r.pts.size() - 1]

func nearest_path_point(p):
	var best = samples[0]
	var bd = 1e12
	for q in samples:
		var dd = q.distance_squared_to(p)
		if dd < bd:
			bd = dd
			best = q
	return best

# ================= START / RESET =================
# Darmowa wieża poziomu (np. Wieża Rycerska) - tworzona po wyczyszczeniu list jednostek
func spawn_special_tower():
	var L = LEVELS[cur_level]
	if not L.has("special_tower"):
		return
	var sp = spots[L.special_tower]
	var t = Tower.new()
	t.type = "knight_tower"
	t.pos = sp.pos
	t.spent = 0
	t.level = 1
	sp.tower = t
	t.rally = nearest_path_point(sp.pos)
	add_soldier(t)
	layout_soldiers(t)

func start_game(idx = 0):
	setup_level(idx)
	was_busy = false
	gold = LEVELS[idx].gold
	lives = LEVELS[idx].lives
	selected_enemy = null
	wave = 0
	paused = false
	game_speed = 1.0
	enemies.clear()
	soldiers.clear()
	projectiles.clear()
	strikes.clear()
	fx.clear()
	floats.clear()
	spawn_queue.clear()
	spawn_timer = 0.0
	selected_spot = -1
	targeting = ""
	fire_cd = 0.0
	reinf_cd = 0.0
	spawn_special_tower()
	state = "play"


# ================= FALE =================
func wave_comp(n):
	var c = []
	c.append(["goblin", 3 + n * 2])
	if n >= 2:
		c.append(["wolf", int(n * 1.2)])
	if n >= 3:
		c.append(["orc", int(n * 0.8)])
	if n >= 4:
		c.append(["bat", int(n * 0.7)])
	if LEVELS[cur_level].get("shamans", false) and n >= 4:
		c.append(["shaman", int(n / 4)])
	if n % 5 == 0:
		c.append(["boss", n / 5])
	elif n == total_waves:
		c.append(["boss", 1])
	return c

func start_next_wave():
	if state != "play" or wave >= total_waves or spawn_queue.size() > 0:
		return
	if enemies.size() > 0:
		gold += EARLY_BONUS
		add_float(Vector2(W - 110, H - 80), "+%d bonus" % EARLY_BONUS, Color(1, 0.85, 0.3))
	wave += 1
	var shamans = 0
	for g in wave_comp(wave):
		if g[0] == "shaman":
			shamans = g[1]
			continue
		var gap = 0.5 if g[0] == "wolf" else 0.9
		for i in g[1]:
			spawn_queue.append([g[0], 2.0 if i == 0 else gap])
	var n0 = spawn_queue.size()
	for k in shamans:
		spawn_queue.insert(int(float(k + 1) * n0 / float(shamans + 1)) + k, ["shaman", 1.6])
	spawn_timer = 0.8
	sfx("wave")

func spawn_enemy(type):
	var d = ENEMIES[type]
	var e = Enemy.new()
	e.type = type
	e.hp = d.hp * hp_mult
	e.maxhp = e.hp
	e.speed = d.speed
	e.armor = d.armor
	e.mr = d.mr
	e.reward = d.reward
	e.lives = d.lives
	e.flying = d.flying
	e.dmg = d.dmg
	e.r = d.r
	
	e.route = 0
	var LV = LEVELS[cur_level]
	if has_bridges():
		e.route = active_bridge
	elif LV.has("random_routes_from") and wave >= LV.random_routes_from:
		e.route = randi() % routes.size()
	e.ability = d.get("ability", "")
	e.pos = path_pos(0.0, e.route)
	enemies.append(e)


# ================= WIEŻE =================
func lvl_base(t):
	return min(t.level, 3)

func t_dmg(t):
	var d = TOWERS[t.type].dmg * (1.0 + 0.5 * (lvl_base(t) - 1))
	if t.branch == "long":
		d *= 1.25
	elif t.branch == "blast":
		d *= 1.2
	elif t.branch == "vets":
		d *= 1.5
	elif t.branch == "dmg":
		d *= 1.4
	return d

func t_range(t):
	var r = TOWERS[t.type].range * (1.0 + 0.08 * (lvl_base(t) - 1))
	if t.branch == "long":
		r *= 1.4
	elif t.branch == "dmg":
		r *= 1.3
	return r

func t_rate(t):
	var r = TOWERS[t.type].rate * (1.0 - 0.1 * (lvl_base(t) - 1))
	if t.branch == "rapid":
		r *= 0.6
	return r

func t_splash(t):
	var r = TOWERS[t.type].splash
	if t.branch == "blast":
		r *= 1.4
	return r

func upgrade_cost(t):
	var base = TOWERS[t.type].cost
	return int(base * (0.9 if t.level == 1 else 1.3))

func branch_cost(t):
	return int(TOWERS[t.type].cost * 1.8)

func soldier_hp(t):
	if t.type == "knight_tower":
		var h = 80.0 + 30.0 * (lvl_base(t) - 1)
		if t.branch == "hp": h *= 1.6
		return h
	var h = 50.0 + 25.0 * (lvl_base(t) - 1)
	if t.branch == "vets":
		h *= 1.6
	return h

func respawn_time(t):
	return 4.0 if t.branch == "extra" else 8.0

func branch_info(t):
	if t.branch == "":
		return null
	for b in BRANCHES[t.type]:
		if b.id == t.branch:
			return b
	return null

func add_soldier(t):
	var s = Soldier.new()
	s.pos = t.pos
	s.tower = t
	s.type = "knight" if t.type == "knight_tower" else "soldier"
	s.hp = soldier_hp(t)
	s.maxhp = s.hp
	s.dmg = t_dmg(t)
	s.radius = t_range(t)
	soldiers.append(s)
	t.soldiers.append(s)

func layout_soldiers(t):
	var n = t.soldiers.size()
	for i in n:
		var a = i * TAU / float(n)
		t.soldiers[i].rally = t.rally + Vector2(cos(a), sin(a)) * 16.0

func refresh_soldiers(t):
	for s in t.soldiers:
		s.maxhp = soldier_hp(t)
		s.hp = s.maxhp
		s.dmg = t_dmg(t)
		s.radius = t_range(t)

func build_tower(spot, type):
	var cost = TOWERS[type].cost
	if gold < cost:
		return
	gold -= cost
	var t = Tower.new()
	t.type = type
	t.pos = spot.pos
	t.spent = cost
	spot.tower = t
	if type == "barracks":
		t.rally = nearest_path_point(spot.pos)
		for i in 3:
			add_soldier(t)
		layout_soldiers(t)
	sfx("build")
	selected_spot = -1
	save_run()

func upgrade_tower(t):
	if t.level >= 3:
		return
	var c = upgrade_cost(t)
	if gold < c:
		return
	gold -= c
	t.spent += c
	t.level += 1
	if t.type == "knight_tower":
		add_soldier(t)
		layout_soldiers(t)
	refresh_soldiers(t)
	sfx("build")
	save_run()

func choose_branch(t, id):
	if t.level != 3:
		return
	var c = branch_cost(t)
	if gold < c:
		return
	gold -= c
	t.spent += c
	t.level = 4
	t.branch = id
	if t.type == "barracks" and id == "extra":
		add_soldier(t)
		add_soldier(t)
		layout_soldiers(t)
	refresh_soldiers(t)
	add_fx(t.pos, "ring", 40.0)
	sfx("build")
	save_run()

func sell_tower(spot):
	var t = spot.tower
	gold += int(t.spent * SELL_REFUND)
	for s in t.soldiers:
		s.gone = true
	spot.tower = null
	selected_spot = -1
	sfx("coin")
	save_run()

# ================= UMIEJĘTNOŚCI =================
func cast_fire(p):
	fire_cd = FIRE_CD
	for i in 8:
		var off = Vector2.from_angle(randf() * TAU) * randf_range(0, 100)
		strikes.append({"pos": p + off, "delay": 0.25 + i * 0.17})

func cast_reinf(p):
	reinf_cd = REINF_CD
	var c = nearest_path_point(p)
	for i in 2:
		var s = Soldier.new()
		s.pos = c
		s.rally = c + Vector2(-14 + i * 28, 0)
		s.hp = 70.0
		s.maxhp = 70.0
		s.dmg = 6.0
		s.radius = 110.0
		s.life = 15.0
		soldiers.append(s)
	add_fx(c, "ring", 30.0)
	sfx("build")


# ================= LOGIKA =================
func _process(delta):
	if state == "play" and not paused:
		update_game(delta * game_speed)
	if state != "levels":
		update_bridges(delta)
		
	queue_redraw()

func has_bridges():
	return LEVELS[cur_level].has("bridges")

func bridge_period():
	return float(LEVELS[cur_level].get("bridge_period", 20.0))

func reset_bridges():
	active_bridge = 0
	bridge_timer = bridge_period()
	bridge_t = [1.0, 0.0]

# dystans na trasie, w którym trasy się rozwidlają (wspólny początek obu tras)
func fork_dist():
	var br = LEVELS[cur_level].bridges[0]
	return routes[br.route].cum[br.zone_from]

# czy wróg jest w "strefie mostu" i (od rozwidlenia do końca przeprawy) - wtedy most nie może się zamknąć
func in_bridge_zone(e, i):
	if e.dead or e.route != i or not e.forked:
		return false
	var br = LEVELS[cur_level].bridges[i]
	var r = routes[i]
	return e.dist >= r.cum[br.zone_from] and e.dist <= r.cum[br.zone_to]

func bridge_zone_busy(i):
	for e in enemies:
		if in_bridge_zone(e, i):
			return true
	return false

# logika gry (liczona w czasie gry, zatrzymuje się na pauzie)
func update_bridge_logic(dt):
	if not has_bridges():
		return
	if bridge_timer > 0.0:
		bridge_timer = max(0.0, bridge_timer - dt)
		if bridge_timer > 0.0:
			return
	# czas minął: zmiana dopiero gdy nikt nie jest na moście ani na jego zjeździe
	if bridge_zone_busy(0) or bridge_zone_busy(1):
		return
	active_bridge = 1 - active_bridge
	bridge_timer = bridge_period()
	var nm = LEVELS[cur_level].bridges[active_bridge].name
	add_float(Vector2(W / 2.0 - 60.0, 90.0), nm + " otwarty!", Color(0.5, 1.0, 0.5))
	sfx("wave")

# animacja opuszczania/podnoszenia (liczona w czasie rzeczywistym)
func update_bridges(dt):
	if not has_bridges():
		return
	for i in 2:
		bridge_t[i] = move_toward(bridge_t[i], 1.0 if active_bridge == i else 0.0, dt * 1.5)

func snap_bridges():
	if not has_bridges():
		return
	for i in 2:
		bridge_t[i] = 1.0 if active_bridge == i else 0.0

func update_game(dt):
	update_bridge_logic(dt)
	if fire_cd > 0:
		fire_cd -= dt
	if reinf_cd > 0:
		reinf_cd -= dt
	if spawn_queue.size() > 0:
		spawn_timer -= dt
		if spawn_timer <= 0:
			var item = spawn_queue.pop_front()
			spawn_enemy(item[0])
			if spawn_queue.size() > 0:
				spawn_timer = spawn_queue[0][1]
	for e in enemies:
		update_enemy(e, dt)
	for s in soldiers:
		update_soldier(s, dt)
	for sp in spots:
		if sp.tower != null:
			update_tower(sp.tower, dt)
	for p in projectiles:
		update_proj(p, dt)
	for st in strikes:
		st.delay -= dt
		if st.delay <= 0:
			st.done = true
			explode(st.pos, 60.0, 50.0, true, false)
	for f in fx:
		f.t += dt
	for f in floats:
		f.t += dt
		f.pos.y -= 28.0 * dt
	enemies = enemies.filter(func(e): return not e.dead)
	soldiers = soldiers.filter(func(s): return not s.gone)
	projectiles = projectiles.filter(func(p): return not p.done)
	strikes = strikes.filter(func(s): return not s.has("done"))
	fx = fx.filter(func(f): return f.t < f.dur)
	floats = floats.filter(func(f): return f.t < 1.0)
	if selected_enemy != null and selected_enemy.dead:
		selected_enemy = null
	var busy = spawn_queue.size() > 0 or enemies.size() > 0
	if was_busy and not busy and wave < total_waves and lives > 0:
		was_busy = false
		save_run()
	was_busy = busy
	if lives <= 0:
		lives = 0
		state = "lose"
		delete_run(cur_level)
		sfx("hurt")
	elif wave >= total_waves and spawn_queue.is_empty() and enemies.is_empty():
		state = "win"
		completed[cur_level] = true
		if cur_level + 1 < LEVELS.size():
			unlocked = max(unlocked, cur_level + 2)
		save_progress()
		delete_run(cur_level)
		sfx("coin")

func update_enemy(e, dt):
	e.anim += dt
	if e.flash > 0:
		e.flash -= dt
	if e.ability == "heal":
		e.heal_cd -= dt
		if e.heal_cd <= 0:
			e.heal_cd = 6.0
			for o in enemies:
				if not o.dead and o.pos.distance_to(e.pos) <= 140.0:
					o.hp = min(o.maxhp, o.hp + o.maxhp * 0.12)
			add_fx(e.pos, "heal", 140.0)
			add_float(e.pos + Vector2(0, -44), "Rytuał!", Color(0.5, 1, 0.5))
	var b = e.blocked_by
	if b != null and (b.gone or not b.alive):
		e.blocked_by = null
		b = null
	if b != null:
		e.cd -= dt
		if e.cd <= 0:
			e.cd = 1.0
			hurt_soldier(b, e.dmg)
			if not b.alive:
				e.blocked_by = null
		return
	var spd = e.speed
	if e.slow > 0:
		e.slow -= dt
		spd *= 0.6
	e.dist += spd * dt
	if has_bridges() and not e.forked and e.dist >= fork_dist():
		e.forked = true
		e.route = active_bridge
	e.pos = path_pos(e.dist, e.route)
	if e.dist >= routes[e.route].len:
		e.dead = true
		lives -= e.lives
		add_float(Vector2(W - 120, 90), "-%d życie" % e.lives, Color(1, 0.3, 0.3))
		sfx("hurt")

func hurt_soldier(s, d):
	s.hp -= d
	if s.hp <= 0:
		s.alive = false
		s.target = null
		if s.tower == null:
			s.gone = true
		else:
			s.respawn = respawn_time(s.tower)

func update_soldier(s, dt):
	if s.gone:
		return
	if not s.alive:
		s.respawn -= dt
		if s.respawn <= 0:
			s.alive = true
			s.hp = s.maxhp
			s.pos = s.tower.pos
		return
	if s.life > 0:
		s.life -= dt
		if s.life <= 0:
			s.gone = true
			return
	var tg = s.target
	if tg != null:
		if tg.dead or (tg.blocked_by != null and tg.blocked_by != s) or tg.pos.distance_to(s.rally) > s.radius * 1.5:
			s.target = null
			tg = null
	if tg == null:
		var best = null
		var bd = 1e9
		for e in enemies:
			if e.dead or (e.flying and s.type != "knight"):
				continue
			if e.blocked_by != null and e.blocked_by != s:
				continue
			var d = e.pos.distance_to(s.rally)
			if d < s.radius and d < bd:
				bd = d
				best = e
		s.target = best
		tg = best
		
	var dest = s.rally
	if tg != null:
		dest = tg.pos
	var to = dest - s.pos
	var dist = to.length()
	
	var reach = 40.0 if s.type == "knight" else 20.0
	
	if tg != null and dist <= reach:
		if not tg.flying:
			tg.blocked_by = s
		s.cd -= dt
		if s.cd <= 0:
			s.cd = 1.0
			damage_enemy(tg, s.dmg, false)
	elif dist > 3.0:
		s.pos += to.normalized() * min(90.0 * dt, dist)

func pick_target(t, exclude):
	var rng = t_range(t)
	var best = null
	var bd = -1.0
	for e in enemies:
		if e.dead or exclude.has(e):
			continue
		if t.type == "artillery" and e.flying:
			continue
		if e.pos.distance_to(t.pos) > rng:
			continue
		if e.dist > bd:
			bd = e.dist
			best = e
	return best

func update_tower(t, dt):
	if t.type == "barracks" or t.type == "knight_tower":
		return
	t.cd -= dt
	if t.cd > 0:
		return
	var shots = 2 if t.branch == "double" else 1
	var chosen = []
	for k in shots:
		var best = pick_target(t, chosen)
		if best == null:
			if k == 0:
				return
			best = chosen[0]
		chosen.append(best)
	t.cd = t_rate(t)
	var info = TOWERS[t.type]
	for k in chosen.size():
		var p = Proj.new()
		p.pos = t.pos + Vector2(-4 + k * 8, -20)
		p.target = chosen[k]
		p.last = chosen[k].pos
		p.dmg = t_dmg(t)
		p.magic = info.magic
		p.splash = t_splash(t)
		p.kind = t.type
		p.slow = t.branch == "slow"
		p.chain = t.branch == "chain"
		if t.type == "archer":
			p.speed = 520.0
		elif t.type == "mage":
			p.speed = 380.0
		else:
			p.speed = 260.0
		projectiles.append(p)
	if t.type == "mage":
		sfx("magic")
	else:
		sfx("shoot")

func update_proj(p, dt):
	if p.target != null and not p.target.dead:
		p.last = p.target.pos
	var to = p.last - p.pos
	var step = p.speed * dt
	if to.length() <= step + 4.0:
		p.done = true
		if p.splash > 0:
			explode(p.last, p.splash, p.dmg, p.magic, p.kind == "artillery")
		elif p.target != null and not p.target.dead:
			damage_enemy(p.target, p.dmg, p.magic)
			if p.slow and not p.target.dead:
				p.target.slow = 2.0
			if p.chain:
				var best = null
				var bd = 110.0
				for e in enemies:
					if e.dead or e == p.target:
						continue
					var d = e.pos.distance_to(p.target.pos)
					if d < bd:
						bd = d
						best = e
				if best != null:
					var f = add_fx(p.target.pos, "zap", 0.0)
					f.to = best.pos
					f.dur = 0.2
					damage_enemy(best, p.dmg * 0.5, true)
	else:
		p.pos += to.normalized() * step

func explode(pos, radius, dmg, magic, ground_only):
	for e in enemies:
		if e.dead:
			continue
		if ground_only and e.flying:
			continue
		if e.pos.distance_to(pos) <= radius:
			damage_enemy(e, dmg, magic)
	add_fx(pos, "boom", radius)
	sfx("boom")

func damage_enemy(e, dmg, magic):
	if e.dead:
		return
	var reduce = e.mr if magic else e.armor
	var d = dmg * (1.0 - reduce)
	e.hp -= d
	e.flash = 0.1
	add_float(e.pos + Vector2(randf_range(-8, 8), -26), str(int(round(d))), Color(1, 0.95, 0.6))
	if e.hp <= 0:
		e.dead = true
		gold += e.reward
		add_float(e.pos + Vector2(0, -40), "+%d" % e.reward, Color(1, 0.85, 0.2))
		add_fx(e.pos, "death", 22.0)
		sfx("coin")

func add_fx(pos, kind, r):
	var f = {"pos": pos, "kind": kind, "r": r, "t": 0.0, "dur": 0.4, "to": pos}
	fx.append(f)
	return f

func add_float(pos, text, col):
	floats.append({"pos": pos, "text": text, "col": col, "t": 0.0})


# ================= WEJŚCIE =================
func _input(event):
	if event is InputEventMouseMotion:
		mouse = event.position
	elif event is InputEventMouseButton and event.pressed:
		mouse = event.position
		
		if event.button_index == MOUSE_BUTTON_LEFT:
			handle_click(event.position)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			targeting = ""
			selected_spot = -1
			selected_enemy = null
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			start_next_wave()
		elif event.keycode == KEY_P:
			paused = not paused
		elif event.keycode == KEY_M:
			muted = not muted
		elif event.keycode == KEY_F11:
			toggle_fullscreen()
		elif event.keycode == KEY_ESCAPE:
			targeting = ""
			selected_spot = -1

func toggle_fullscreen():
	var win = get_window()
	if win.mode == Window.MODE_FULLSCREEN:
		win.mode = Window.MODE_WINDOWED
	else:
		win.mode = Window.MODE_FULLSCREEN

func handle_click(p):
	if state == "menu":
		if R_PLAY.has_point(p):
			open_levels()
		return
	if state == "levels":
		if R_BACK.has_point(p):
			state = "menu"
			return
		if level_pages() > 1:
			if R_PREV.has_point(p) and level_page > 0:
				level_page -= 1
				return
			if R_NEXTP.has_point(p) and level_page < level_pages() - 1:
				level_page += 1
				return
		for i in LEVELS.size():
			for b in level_buttons(i):
				if b.rect.has_point(p):
					if b.act == "continue":
						continue_run(i)
					else:
						delete_run(i)
						start_game(i)
					return
		return
	if state == "win" or state == "lose":
		for b in end_buttons():
			if b.rect.has_point(p):
				if b.act == "again":
					start_game(cur_level)
				elif b.act == "next":
					start_game(cur_level + 1)
				else:
					open_levels()
				return
		return
	# górny pasek i stałe przyciski
	if R_FULL.has_point(p):
		toggle_fullscreen()
		return
	if R_MENU.has_point(p):
		save_run()
		open_levels()
		return
	if R_PAUSE.has_point(p):
		paused = not paused
		return
	if R_SPEED.has_point(p):
		game_speed = 2.0 if game_speed == 1.0 else 1.0
		return
	if R_MUTE.has_point(p):
		muted = not muted
		return
	if R_NEXT.has_point(p):
		start_next_wave()
		return
	if R_FIRE.has_point(p):
		if fire_cd <= 0:
			targeting = "" if targeting == "fire" else "fire"
			selected_spot = -1
		return
	if R_REINF.has_point(p):
		if reinf_cd <= 0:
			targeting = "" if targeting == "reinf" else "reinf"
			selected_spot = -1
		return
	if p.y < TOP:
		return
	if paused:
		return
	# celowanie umiejętności
	if targeting != "":
		if targeting == "fire":
			cast_fire(p)
		else:
			cast_reinf(p)
		targeting = ""
		return
	# menu wieży
	if selected_spot >= 0:
		for b in menu_buttons():
			if b.rect.has_point(p):
				if not b.enabled:
					return
				var sp = spots[selected_spot]
				if b.act == "build":
					build_tower(sp, b.type)
				elif b.act == "upgrade":
					upgrade_tower(sp.tower)
				elif b.act == "branch":
					choose_branch(sp.tower, b.branch)
					selected_spot = -1
				elif b.act == "sell":
					sell_tower(sp)
				return
	# wybór miejsca
	for i in spots.size():
		if spots[i].pos.distance_to(p) < 30.0:
			selected_spot = i if selected_spot != i else -1
			selected_enemy = null
			return
	selected_spot = -1
	var e = enemy_at(p)
	selected_enemy = e if e != selected_enemy else null

func mbtn(rect, act, label, sub, enabled, type = "", branch = "", desc = ""):
	return {"rect": clamp_rect(rect), "act": act, "label": label, "sub": sub, "enabled": enabled,
		"type": type, "branch": branch, "desc": desc}

func menu_buttons():
	var res = []
	if selected_spot < 0:
		return res
	var s = spots[selected_spot]
	if s.tower == null:
		var types = ["archer", "mage", "barracks", "artillery"]
		for i in types.size():
			var dir = Vector2.from_angle(-PI / 2.0 + i * TAU / 4.0)
			var c = s.pos + dir * 80.0
			var cost = TOWERS[types[i]].cost
			res.append(mbtn(Rect2(c - Vector2(52, 26), Vector2(104, 52)), "build", TOWERS[types[i]].name,
				str(cost) + " zł", gold >= cost, types[i]))
	else:
		var t = s.tower
		if t.level < 3:
			var c = upgrade_cost(t)
			res.append(mbtn(Rect2(s.pos + Vector2(-52, -100), Vector2(104, 52)), "upgrade", "Ulepsz",
				str(c) + " zł", gold >= c))
		elif t.level == 3:
			var br = BRANCHES[t.type]
			var c = branch_cost(t)
			for i in 2:
				res.append(mbtn(Rect2(s.pos + Vector2(-135 + i * 140, -100), Vector2(130, 52)), "branch",
					br[i].name, str(c) + " zł", gold >= c, "", br[i].id, br[i].desc))
					
		if t.type == "knight_tower":
			res.append(mbtn(Rect2(s.pos + Vector2(-52, 48), Vector2(104, 52)), "sell", "Zablokowane", "Baza Złota", false))
		else:
			res.append(mbtn(Rect2(s.pos + Vector2(-52, 48), Vector2(104, 52)), "sell", "Sprzedaj",
				"+" + str(int(t.spent * SELL_REFUND)) + " zł", true))
	return res

# ---------- obiekty pod kursorem ----------
func enemy_draw_pos(e):
	if e.type == "bat":
		return e.pos + Vector2(0, -22)
	return e.pos

func enemy_at(p):
	var best = null
	var bd = 1e9
	for e in enemies:
		if e.dead:
			continue
		var d = enemy_draw_pos(e).distance_to(p)
		if d <= e.r + 10.0 and d < bd:
			bd = d
			best = e
	return best

func soldier_at(p):
	for s in soldiers:
		if s.alive and not s.gone and s.pos.distance_to(p) < 14.0:
			return s
	return null

func tower_at(p):
	for sp in spots:
		if sp.tower != null and sp.pos.distance_to(p) < 28.0:
			return sp.tower
	return null

func clamp_rect(r):
	r.position.x = clamp(r.position.x, 4.0, W - r.size.x - 4.0)
	r.position.y = clamp(r.position.y, TOP + 4.0, H - r.size.y - 4.0)
	return r


# ================= RYSOWANIE =================
func txt(p, s, size = 16, col = Color.WHITE, align = HORIZONTAL_ALIGNMENT_LEFT, w = -1.0):
	draw_string(font, p, s, align, w, size, col)

func txt_in(r, s, size, col):
	draw_string(font, Vector2(r.position.x, r.position.y + r.size.y / 2.0 + size * 0.35), s,
		HORIZONTAL_ALIGNMENT_CENTER, r.size.x, size, col)

func draw_btn(r, label, col, enabled = true, sub = "", hover = true):
	var c = col if enabled else Color(0.3, 0.3, 0.3)
	if enabled and hover and r.has_point(mouse):
		c = c.lightened(0.2)
	draw_rect(r, Color(0, 0, 0, 0.5), true)
	draw_rect(r.grow(-2), c, true)
	draw_rect(r, Color(1, 1, 1, 0.8), false, 2.0)
	if sub == "":
		txt_in(r, label, 18, Color.WHITE)
	else:
		txt_in(Rect2(r.position + Vector2(0, -9), r.size), label, 16 if label.length() < 12 else 13, Color.WHITE)
		txt_in(Rect2(r.position + Vector2(0, 12), r.size), sub, 14, Color(1, 0.9, 0.5))

func _draw():
	if state == "levels":
		draw_levels()
		return
	draw_world()
	if state == "menu":
		draw_menu()
		return
	draw_ui()
	draw_info()
	if state == "win" or state == "lose":
		draw_end()

func draw_world():
	draw_rect(Rect2(0, 0, W, H), Color(0.36, 0.62, 0.3))
	for i in 8:
		draw_rect(Rect2(0, i * 90, W, 45), Color(0.38, 0.65, 0.32, 0.5))
	var LV = LEVELS[cur_level]
	if LV.has("river"):
		draw_river(LV.river)
	for r in routes:
		draw_polyline(PackedVector2Array(r.pts), Color(0.42, 0.3, 0.18), 64.0)
		for p in r.pts:
			draw_circle(p, 32.0, Color(0.42, 0.3, 0.18))
	for r in routes:
		draw_polyline(PackedVector2Array(r.pts), Color(0.76, 0.62, 0.4), 52.0)
		for p in r.pts:
			draw_circle(p, 26.0, Color(0.76, 0.62, 0.4))
	if LV.has("fixed_bridges"):
		for fb in LV.fixed_bridges:
			draw_bridge_planks(fb.a, fb.b, 1.0, fb.get("vertical", false))
	if LV.has("bridges"):
		for i in LV.bridges.size():
			draw_drawbridge(i, LV.bridges[i])
	for d in decor:
		var p = d[0]
		var sc = d[1]
		draw_rect(Rect2(p + Vector2(-3, 4) * sc, Vector2(6, 12) * sc), Color(0.4, 0.27, 0.15))
		draw_circle(p + Vector2(0, -6) * sc, 16.0 * sc, Color(0.15, 0.42, 0.2))
		draw_circle(p + Vector2(-4, -10) * sc, 9.0 * sc, Color(0.22, 0.52, 0.27))
	for i in spots.size():
		var s = spots[i]
		draw_circle(s.pos, 27.0, Color(0.3, 0.3, 0.32))
		draw_circle(s.pos, 23.0, Color(0.55, 0.55, 0.58) if s.tower == null else Color(0.45, 0.45, 0.48))
		if i == selected_spot:
			draw_arc(s.pos, 30.0, 0, TAU, 32, Color(1, 1, 0.3), 3.0)
	draw_range_preview()
	for s in spots:
		if s.tower != null:
			draw_tower(s.tower)
	for s in soldiers:
		if s.alive and not s.gone:
			draw_soldier(s)
	var sorted = enemies.duplicate()
	sorted.sort_custom(func(a, b): return a.pos.y < b.pos.y)
	for e in sorted:
		draw_enemy(e)
	if selected_enemy != null and not selected_enemy.dead:
		draw_arc(enemy_draw_pos(selected_enemy), selected_enemy.r + 8.0, 0, TAU, 24, Color(1, 1, 0.3), 2.0)
	for p in projectiles:
		if p.kind == "archer":
			var d = (p.last - p.pos).normalized()
			draw_line(p.pos, p.pos - d * 12.0, Color(0.9, 0.8, 0.5), 2.5)
		elif p.kind == "mage":
			draw_circle(p.pos, 7.0, Color(0.6, 0.4, 1.0, 0.4))
			draw_circle(p.pos, 4.0, Color(0.8, 0.7, 1.0))
		else:
			draw_circle(p.pos, 6.0, Color(0.15, 0.15, 0.15))
	for st in strikes:
		draw_arc(st.pos, 60.0, 0, TAU, 32, Color(1, 0.4, 0.1, 0.5), 2.0)
		draw_circle(st.pos + Vector2(0, -max(0.0, st.delay) * 400.0), 9.0, Color(1, 0.6, 0.1))
	for f in fx:
		var k = f.t / f.dur
		if f.kind == "boom":
			draw_circle(f.pos, f.r * (0.4 + 0.6 * k), Color(1, 0.55, 0.1, 0.6 * (1.0 - k)))
			draw_arc(f.pos, f.r * k, 0, TAU, 32, Color(1, 0.9, 0.4, 1.0 - k), 3.0)
		elif f.kind == "death":
			draw_circle(f.pos, f.r * k, Color(0.9, 0.9, 0.9, 0.5 * (1.0 - k)))
		elif f.kind == "heal":
			draw_arc(f.pos, f.r * k, 0, TAU, 40, Color(0.4, 1, 0.5, 1.0 - k), 4.0)
			draw_circle(f.pos, f.r * k, Color(0.3, 1, 0.4, 0.15 * (1.0 - k)))
		elif f.kind == "zap":
			var mid = (f.pos + f.to) / 2.0 + Vector2(randf_range(-8, 8), randf_range(-8, 8))
			draw_line(f.pos, mid, Color(0.85, 0.95, 1.0), 3.0)
			draw_line(mid, f.to, Color(0.85, 0.95, 1.0), 3.0)
		elif f.kind == "ring":
			draw_arc(f.pos, f.r * (0.3 + k), 0, TAU, 32, Color(0.4, 0.8, 1, 1.0 - k), 3.0)
	if targeting == "fire":
		draw_circle(mouse, 100.0, Color(1, 0.3, 0.1, 0.2))
		draw_arc(mouse, 100.0, 0, TAU, 48, Color(1, 0.4, 0.1), 2.0)
	elif targeting == "reinf":
		var c = nearest_path_point(mouse)
		draw_circle(c, 24.0, Color(0.3, 0.7, 1, 0.3))
		draw_arc(c, 24.0, 0, TAU, 24, Color(0.4, 0.8, 1), 2.0)
	for f in floats:
		var col = f.col
		col.a = 1.0 - f.t
		txt(f.pos, f.text, 15, col)
	if state == "play":
		for b in menu_buttons():
			var col = Color(0.2, 0.35, 0.6)
			if b.act == "sell":
				col = Color(0.6, 0.25, 0.2)
			elif b.act == "upgrade":
				col = Color(0.2, 0.5, 0.25)
			elif b.act == "branch":
				col = Color(0.5, 0.28, 0.65)
			draw_btn(b.rect, b.label, col, b.enabled, b.sub)

func draw_range_preview():
	var pos = null
	var r = 0.0
	if selected_spot >= 0:
		var s = spots[selected_spot]
		if s.tower != null:
			pos = s.pos
			r = t_range(s.tower)
		else:
			for b in menu_buttons():
				if b.rect.has_point(mouse) and b.type != "":
					pos = s.pos
					r = TOWERS[b.type].range
	else:
		for s in spots:
			if s.tower != null and s.pos.distance_to(mouse) < 28.0:
				pos = s.pos
				r = t_range(s.tower)
	if pos != null:
		draw_circle(pos, r, Color(1, 1, 1, 0.12))
		draw_arc(pos, r, 0, TAU, 64, Color(1, 1, 1, 0.7), 2.0)

func draw_tower(t):
	var p = t.pos
	draw_circle(p + Vector2(0, 18), 18.0, Color(0, 0, 0, 0.25))
	if t.type == "archer":
		draw_rect(Rect2(p + Vector2(-16, -8), Vector2(32, 28)), Color(0.55, 0.4, 0.25))
		draw_rect(Rect2(p + Vector2(-16, -8), Vector2(32, 28)), Color(0.3, 0.2, 0.1), false, 2.0)
		draw_colored_polygon(PackedVector2Array([p + Vector2(-23, -8), p + Vector2(23, -8), p + Vector2(0, -36)]), Color(0.2, 0.6, 0.3))
		draw_circle(p + Vector2(0, 2), 5.0, Color(0.15, 0.1, 0.05))
	elif t.type == "mage":
		draw_rect(Rect2(p + Vector2(-13, -22), Vector2(26, 42)), Color(0.45, 0.3, 0.65))
		draw_rect(Rect2(p + Vector2(-13, -22), Vector2(26, 42)), Color(0.25, 0.15, 0.4), false, 2.0)
		draw_colored_polygon(PackedVector2Array([p + Vector2(-17, -22), p + Vector2(17, -22), p + Vector2(0, -46)]), Color(0.3, 0.2, 0.6))
		draw_circle(p + Vector2(0, -50), 6.0, Color(0.5, 0.9, 1.0))
	elif t.type == "barracks":
		draw_rect(Rect2(p + Vector2(-22, -10), Vector2(44, 30)), Color(0.7, 0.3, 0.25))
		draw_rect(Rect2(p + Vector2(-22, -10), Vector2(44, 30)), Color(0.4, 0.15, 0.1), false, 2.0)
		draw_rect(Rect2(p + Vector2(-6, 2), Vector2(12, 18)), Color(0.2, 0.1, 0.05))
		draw_line(p + Vector2(0, -10), p + Vector2(0, -34), Color(0.3, 0.2, 0.1), 3.0)
		draw_colored_polygon(PackedVector2Array([p + Vector2(0, -34), p + Vector2(16, -28), p + Vector2(0, -22)]), Color(0.9, 0.8, 0.2))
	elif t.type == "knight_tower":
		draw_circle(p + Vector2(0, 4), 24.0, Color(1, 0.5, 0.1))
		draw_arc(p + Vector2(0, 4), 24.0, 0, TAU, 32, Color(1, 0.9, 0.2), 3.0)
		draw_rect(Rect2(p + Vector2(-16, -10), Vector2(32, 28)), Color(0.7, 0.7, 0.75))
		draw_rect(Rect2(p + Vector2(-16, -10), Vector2(32, 28)), Color(0.4, 0.4, 0.45), false, 2.0)
		draw_line(p + Vector2(0, -10), p + Vector2(0, -34), Color(0.9, 0.9, 0.9), 3.0)
		draw_circle(p + Vector2(0, -36), 6.0, Color(1, 0.8, 0.2))
	else:
		draw_circle(p + Vector2(0, 4), 22.0, Color(0.45, 0.45, 0.5))
		draw_circle(p + Vector2(0, 4), 22.0, Color(0.2, 0.2, 0.25), false, 2.0)
		draw_line(p + Vector2(0, 2), p + Vector2(18, -16), Color(0.15, 0.15, 0.18), 11.0)
		draw_circle(p + Vector2(0, 2), 9.0, Color(0.3, 0.3, 0.35))
	for i in t.level:
		var pc = Color(1, 0.85, 0.2) if i < 3 else Color(0.3, 0.95, 1.0)
		draw_circle(p + Vector2(-12 + i * 8, 28), 3.2, pc)
	if t.level == 4:
		draw_arc(p, 30.0, 0, TAU, 32, Color(0.3, 0.95, 1.0, 0.8), 2.0)

func draw_soldier(s):
	draw_circle(s.pos + Vector2(0, 8), 7.0, Color(0, 0, 0, 0.25))
	var col = Color(0.3, 0.5, 0.9) if s.tower != null else Color(0.3, 0.85, 0.9)
	if s.type == "knight":
		col = Color(0.9, 0.55, 0.1)
	draw_circle(s.pos, 8.0, col)
	draw_circle(s.pos + Vector2(0, -9), 5.0, Color(0.95, 0.8, 0.65))
	
	if s.type == "knight":
		draw_line(s.pos + Vector2(-5, -2), s.pos + Vector2(16, -16), Color(0.8, 0.8, 0.8), 2.0)
	else:
		draw_line(s.pos + Vector2(8, 0), s.pos + Vector2(14, -10), Color(0.85, 0.85, 0.9), 2.5)
	
	draw_hp(s.pos + Vector2(0, -20), s.hp / s.maxhp, 20.0, Color(0.3, 0.8, 1))

func draw_hp(p, frac, w, col):
	draw_rect(Rect2(p + Vector2(-w / 2.0, 0), Vector2(w, 4)), Color(0, 0, 0, 0.7))
	draw_rect(Rect2(p + Vector2(-w / 2.0, 0), Vector2(w * clamp(frac, 0.0, 1.0), 4)), col)

func draw_enemy(e):
	var p = e.pos
	var tint = Color(1, 1, 1) if e.flash <= 0 else Color(1, 0.6, 0.6)
	if e.slow > 0:
		tint = tint * Color(0.65, 0.8, 1.2)
	draw_circle(p + Vector2(0, e.r * 0.8), e.r * 0.8, Color(0, 0, 0, 0.25))
	if e.type == "bat":
		p += Vector2(0, -22 + sin(e.anim * 8.0) * 3.0)
		var wing = sin(e.anim * 18.0) * 6.0
		draw_colored_polygon(PackedVector2Array([p, p + Vector2(-20, -8 + wing), p + Vector2(-12, 6)]), Color(0.35, 0.2, 0.45) * tint)
		draw_colored_polygon(PackedVector2Array([p, p + Vector2(20, -8 + wing), p + Vector2(12, 6)]), Color(0.35, 0.2, 0.45) * tint)
		draw_circle(p, 8.0, Color(0.45, 0.25, 0.55) * tint)
		draw_circle(p + Vector2(-3, -2), 1.8, Color(1, 0.3, 0.3))
		draw_circle(p + Vector2(3, -2), 1.8, Color(1, 0.3, 0.3))
		draw_hp(p + Vector2(0, -18), e.hp / e.maxhp, 24.0, Color(0.9, 0.2, 0.2))
		return
	if e.type == "goblin":
		draw_circle(p, e.r, Color(0.35, 0.7, 0.25) * tint)
		draw_colored_polygon(PackedVector2Array([p + Vector2(-9, -6), p + Vector2(-18, -12), p + Vector2(-8, -12)]), Color(0.35, 0.7, 0.25) * tint)
		draw_colored_polygon(PackedVector2Array([p + Vector2(9, -6), p + Vector2(18, -12), p + Vector2(8, -12)]), Color(0.35, 0.7, 0.25) * tint)
	elif e.type == "wolf":
		draw_circle(p, e.r, Color(0.55, 0.55, 0.6) * tint)
		draw_circle(p + Vector2(-10, 0), 7.0, Color(0.5, 0.5, 0.55) * tint)
		draw_colored_polygon(PackedVector2Array([p + Vector2(-12, -6), p + Vector2(-9, -15), p + Vector2(-5, -6)]), Color(0.45, 0.45, 0.5) * tint)
	elif e.type == "orc":
		draw_circle(p, e.r, Color(0.2, 0.5, 0.2) * tint)
		draw_arc(p, e.r - 2, PI, TAU, 16, Color(0.6, 0.6, 0.65), 5.0)
	elif e.type == "shaman":
		draw_circle(p, e.r, Color(0.45, 0.2, 0.55) * tint)
		draw_colored_polygon(PackedVector2Array([p + Vector2(-13, -8), p + Vector2(13, -8), p + Vector2(0, -34)]), Color(0.3, 0.1, 0.4) * tint)
		draw_line(p + Vector2(15, 8), p + Vector2(20, -22), Color(0.5, 0.35, 0.2), 3.0)
		var glow = 0.6 + 0.4 * sin(e.anim * 5.0)
		draw_circle(p + Vector2(20, -24), 6.0, Color(0.3, 1.0, 0.5, glow))
	else:
		draw_circle(p, e.r, Color(0.75, 0.15, 0.15) * tint)
		draw_colored_polygon(PackedVector2Array([p + Vector2(-16, -14), p + Vector2(-24, -34), p + Vector2(-8, -20)]), Color(0.9, 0.85, 0.7))
		draw_colored_polygon(PackedVector2Array([p + Vector2(16, -14), p + Vector2(24, -34), p + Vector2(8, -20)]), Color(0.9, 0.85, 0.7))
	draw_circle(p + Vector2(-4, -3), 2.5, Color.WHITE)
	draw_circle(p + Vector2(4, -3), 2.5, Color.WHITE)
	draw_circle(p + Vector2(-4, -3), 1.2, Color.BLACK)
	draw_circle(p + Vector2(4, -3), 1.2, Color.BLACK)
	draw_hp(p + Vector2(0, -e.r - 10), e.hp / e.maxhp, max(24.0, e.r * 2.0), Color(0.9, 0.2, 0.2))

func draw_ui():
	draw_rect(Rect2(0, 0, W, TOP), Color(0.1, 0.08, 0.06, 0.92))
	txt(Vector2(14, 29), "Życia: %d" % lives, 20, Color(1, 0.45, 0.45))
	txt(Vector2(150, 29), "Złoto: %d" % gold, 20, Color(1, 0.88, 0.3))
	txt(Vector2(300, 29), "Fala: %d / %d" % [wave, total_waves], 20, Color(0.9, 0.95, 1))
	draw_btn(R_FULL, "Ekran F11", Color(0.35, 0.35, 0.4))
	draw_btn(R_MENU, "Poziomy", Color(0.35, 0.35, 0.4))
	txt(Vector2(440, 29), LEVELS[cur_level].name, 16, Color(0.8, 0.9, 0.8))
	draw_btn(R_MUTE, "Dźwięk" if not muted else "Cisza", Color(0.35, 0.35, 0.4))
	draw_btn(R_PAUSE, "Pauza" if not paused else "Start", Color(0.35, 0.35, 0.4))
	draw_btn(R_SPEED, "Tempo x%d" % int(game_speed), Color(0.35, 0.35, 0.4))
	var fl = "Deszcz ognia"
	var fsub = "gotowe" if fire_cd <= 0 else "%ds" % int(ceil(fire_cd))
	draw_btn(R_FIRE, fl, Color(0.75, 0.3, 0.1) if targeting != "fire" else Color(0.95, 0.5, 0.1), fire_cd <= 0, fsub)
	var rsub = "gotowe" if reinf_cd <= 0 else "%ds" % int(ceil(reinf_cd))
	draw_btn(R_REINF, "Posiłki", Color(0.15, 0.5, 0.7) if targeting != "reinf" else Color(0.2, 0.7, 0.9), reinf_cd <= 0, rsub)
	if wave < total_waves:
		var can = spawn_queue.is_empty()
		var sub = ""
		if enemies.size() > 0 and can:
			sub = "+%d zł bonus" % EARLY_BONUS
		draw_btn(R_NEXT, "Następna fala", Color(0.2, 0.55, 0.25), can, sub)
		var parts = []
		for g in wave_comp(wave + 1):
			parts.append("%d %s" % [g[1], ENEMIES[g[0]].name])
		var line = "Fala %d: %s" % [wave + 1, ", ".join(parts)]
		txt(Vector2(R_NEXT.position.x - 440, H - 20), line, 14, Color(1, 1, 1, 0.9), HORIZONTAL_ALIGNMENT_RIGHT, 430.0)
	if targeting != "":
		txt(Vector2(0, 80), "Kliknij na mapie, aby użyć umiejętności (PPM - anuluj)", 18, Color(1, 1, 1), HORIZONTAL_ALIGNMENT_CENTER, W)
	if paused:
		draw_rect(Rect2(0, TOP, W, H - TOP), Color(0, 0, 0, 0.35))
		txt(Vector2(0, H / 2.0), "PAUZA", 48, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, W)
	if selected_spot >= 0 and spots[selected_spot].tower != null:
		var t = spots[selected_spot].tower
		var info = TOWERS[t.type]
		var line = "%s  (poz. %d)" % [info.name, t.level]
		if t.type != "barracks" and t.type != "knight_tower":
			line += "   Obrażenia: %d" % int(t_dmg(t))
		else:
			line += "   Żołnierze: %d HP" % int(soldier_hp(t))
		txt(Vector2(300, H - 22), line, 16, Color(1, 1, 1))

func draw_menu():
	draw_rect(Rect2(0, 0, W, H), Color(0, 0, 0, 0.6))
	txt(Vector2(0, 230), "KINGDOM DEFENSE", 72, Color(1, 0.88, 0.3), HORIZONTAL_ALIGNMENT_CENTER, W)
	txt(Vector2(0, 290), "Obroń królestwo przed hordami potworów!", 24, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, W)
	txt(Vector2(0, 335), "Klikaj kamienne podstawy, aby budować wieże. Najedź na wroga lub wieżę, aby zobaczyć statystyki. Spacja = następna fala, P = pauza.", 16, Color(0.9, 0.9, 0.9), HORIZONTAL_ALIGNMENT_CENTER, W)
	draw_btn(R_PLAY, "GRAJ", Color(0.2, 0.6, 0.25))

func end_buttons():
	var res = []
	var y = H / 2.0 + 30.0
	if state == "win" and cur_level + 1 < LEVELS.size():
		res.append({"rect": Rect2(W / 2.0 - 130, y, 260, 56), "act": "next", "label": "Następny poziom"})
		y += 70.0
	res.append({"rect": Rect2(W / 2.0 - 130, y, 260, 56), "act": "again", "label": "Zagraj ponownie"})
	y += 70.0
	res.append({"rect": Rect2(W / 2.0 - 130, y, 260, 56), "act": "levels", "label": "Wybór poziomu"})
	return res

func draw_end():
	draw_rect(Rect2(0, 0, W, H), Color(0, 0, 0, 0.65))
	if state == "win":
		txt(Vector2(0, 250), "ZWYCIĘSTWO!", 72, Color(1, 0.88, 0.3), HORIZONTAL_ALIGNMENT_CENTER, W)
		txt(Vector2(0, 310), "Królestwo uratowane. Pozostało żyć: %d" % lives, 24, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, W)
	else:
		txt(Vector2(0, 250), "PORAŻKA", 72, Color(0.95, 0.3, 0.3), HORIZONTAL_ALIGNMENT_CENTER, W)
		txt(Vector2(0, 310), "Doszedłeś do fali %d. Spróbuj jeszcze raz!" % wave, 24, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, W)
	for b in end_buttons():
		draw_btn(b.rect, b.label, Color(0.2, 0.55, 0.25))


# ================= WYBÓR POZIOMU =================
func open_levels():
	level_page = clamp(cur_level / LEVEL_SLOTS, 0, level_pages() - 1)
	state = "levels"

func level_pages():
	return max(1, int(ceil(float(LEVELS.size()) / float(LEVEL_SLOTS))))

# nr poziomu w slocie (0-5) na bieżącej stronie, albo -1 jeśli slot jest pusty
func slot_level(slot):
	var i = level_page * LEVEL_SLOTS + slot
	return i if i < LEVELS.size() else -1

func slot_rect(slot):
	var col = slot % 3
	var row = slot / 3
	return Rect2(35 + col * 410, 112 + row * 268, 390, 252)

func level_card(i):
	return slot_rect(i - level_page * LEVEL_SLOTS)

func level_buttons(i):
	var res = []
	var slot = i - level_page * LEVEL_SLOTS
	if slot < 0 or slot >= LEVEL_SLOTS or i >= unlocked:
		return res
	var r = level_card(i)
	var y = r.position.y + r.size.y - 54.0
	if run_waves.has(i):
		res.append({"rect": Rect2(r.position.x + 12, y, 178, 44), "act": "new", "label": "Nowa gra"})
		res.append({"rect": Rect2(r.position.x + 200, y, 178, 44), "act": "continue",
			"label": "Kontynuuj (fala %d)" % (run_waves[i] + 1)})
	else:
		res.append({"rect": Rect2(r.position.x + 12, y, 366, 44), "act": "new", "label": "Graj"})
	return res

func draw_levels():
	draw_rect(Rect2(0, 0, W, H), Color(0.1, 0.12, 0.16))
	for i in 12:
		draw_rect(Rect2(0, i * 60, W, 30), Color(0.12, 0.14, 0.19))
	txt(Vector2(0, 80), "WYBIERZ POZIOM", 50, Color(1, 0.88, 0.3), HORIZONTAL_ALIGNMENT_CENTER, W)
	for slot in LEVEL_SLOTS:
		var i = slot_level(slot)
		if i < 0:
			draw_empty_slot(slot_rect(slot))
		else:
			draw_level_card(i)
	draw_btn(R_BACK, "Wstecz", Color(0.35, 0.35, 0.4))
	if level_pages() > 1:
		draw_btn(R_PREV, "< Poprz.", Color(0.35, 0.35, 0.4), level_page > 0)
		draw_btn(R_NEXTP, "Nast. >", Color(0.35, 0.35, 0.4), level_page < level_pages() - 1)
		txt(Vector2(0, H - 38), "Strona %d / %d" % [level_page + 1, level_pages()], 16, Color(0.85, 0.85, 0.9), HORIZONTAL_ALIGNMENT_CENTER, W)

func draw_empty_slot(r):
	draw_rect(r, Color(0.14, 0.16, 0.2))
	draw_rect(r, Color(0.35, 0.37, 0.42), false, 2.0)
	txt(Vector2(r.position.x, r.position.y + r.size.y / 2.0 - 6.0), "?", 54, Color(0.35, 0.37, 0.42), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	txt(Vector2(r.position.x, r.position.y + r.size.y / 2.0 + 28.0), "Wkrótce", 18, Color(0.5, 0.52, 0.58), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)

func draw_level_card(i):
	var L = LEVELS[i]
	var r = level_card(i)
	var locked = i >= unlocked
	var hov = r.has_point(mouse) and not locked
	draw_rect(r, Color(0.2, 0.22, 0.28) if not hov else Color(0.26, 0.3, 0.38))
	draw_rect(r, Color(1, 0.88, 0.3) if hov else Color(0.6, 0.6, 0.65), false, 3.0)
	# miniatura mapy (16:9)
	var pr = Rect2(r.position + Vector2(12, 12), Vector2(176, 99))
	var sc = pr.size.x / W
	draw_rect(pr, Color(0.36, 0.62, 0.3))
	if L.has("river"):
		var rp = PackedVector2Array()
		for q in L.river:
			rp.append(pr.position + Vector2(clamp(q.x, 0.0, float(W)), clamp(q.y, 0.0, float(H))) * sc)
		draw_colored_polygon(rp, Color(0.0, 0.62, 0.9))
	var rs = L.routes if L.has("routes") else [L.path]
	for route in rs:
		var pts = PackedVector2Array()
		for p in route:
			pts.append(pr.position + Vector2(clamp(p.x, 0.0, float(W)), clamp(p.y, 0.0, float(H))) * sc)
		draw_polyline(pts, Color(0.76, 0.62, 0.4), 6.0)
	for sp in L.spots:
		draw_circle(pr.position + sp * sc, 2.5, Color(0.6, 0.6, 0.65))
	if locked:
		draw_rect(pr, Color(0, 0, 0, 0.7))
		txt(Vector2(pr.position.x, pr.position.y + 56), "ZABLOKOWANY", 16, Color(1, 1, 1, 0.9), HORIZONTAL_ALIGNMENT_CENTER, pr.size.x)
	# opis obok miniatury
	var x0 = r.position.x + 200.0
	txt(Vector2(x0, r.position.y + 34), "%d. %s" % [i + 1, L.name], 20, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, 180.0)
	var dcol = Color(0.5, 0.9, 0.5) if L.difficulty == "Łatwy" else Color(1, 0.5, 0.4)
	txt(Vector2(x0, r.position.y + 58), L.difficulty, 15, dcol)
	txt(Vector2(x0, r.position.y + 80), "Fale: %d   Życia: %d" % [L.waves, L.lives], 14, Color(0.9, 0.9, 0.9))
	txt(Vector2(x0, r.position.y + 100), "Złoto: %d" % L.gold, 14, Color(1, 0.88, 0.3))
	if i < completed.size() and completed[i]:
		txt(Vector2(x0 + 90.0, r.position.y + 100), "✔ Ukończono", 14, Color(0.5, 1, 0.5))
	# opis (max 4 linie)
	var lines = wrap_text(L.desc, 58)
	for k in min(lines.size(), 4):
		var line = lines[k]
		if k == 3 and lines.size() > 4:
			line += "…"
		txt(Vector2(r.position.x + 14, r.position.y + 132 + k * 17), line, 13, Color(0.8, 0.85, 0.9))
	if locked:
		txt(Vector2(r.position.x, r.position.y + r.size.y - 30), "Ukończ poprzedni poziom, aby odblokować", 14, Color(1, 0.7, 0.4), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	for b in level_buttons(i):
		draw_btn(b.rect, b.label, Color(0.2, 0.55, 0.25) if b.act == "new" else Color(0.2, 0.4, 0.7))

# ================= PANELE INFORMACYJNE =================
func wrap_text(text, n):
	var out = []
	var cur = ""
	for w in text.split(" "):
		if cur != "" and cur.length() + w.length() + 1 > n:
			out.append(cur)
			cur = w
		else:
			cur = w if cur == "" else cur + " " + w
	if cur != "":
		out.append(cur)
	return out

func draw_panel(pos, title, lines, col):
	var all = []
	for l in lines:
		if l[0].length() > 34:
			for part in wrap_text(l[0], 34):
				all.append([part, l[1]])
		else:
			all.append(l)
	var w = 250.0
	var h = 36.0 + all.size() * 19.0 + 6.0
	var r = Rect2(pos, Vector2(w, h))
	r.position.x = clamp(r.position.x, 4.0, W - w - 4.0)
	r.position.y = clamp(r.position.y, TOP + 4.0, H - h - 4.0)
	draw_rect(r, Color(0.05, 0.05, 0.09, 0.93))
	draw_rect(r, col, false, 2.0)
	txt(r.position + Vector2(10, 22), title, 17, col)
	for i in all.size():
		txt(r.position + Vector2(10, 44 + i * 19), all[i][0], 14, all[i][1])

func pct(v):
	return "%d%%" % int(round(v * 100.0))

func enemy_lines(e):
	var W2 = Color(0.92, 0.92, 0.95)
	var L = []
	L.append(["HP: %d / %d" % [int(ceil(e.hp)), int(e.maxhp)], Color(1, 0.5, 0.5)])
	L.append(["Pancerz (fizyczny): " + pct(e.armor), W2])
	L.append(["Odporność na magię: " + pct(e.mr), W2])
	var spd = "Prędkość: %d" % int(e.speed)
	if e.slow > 0:
		spd += " (spowolniony)"
	L.append([spd, Color(0.6, 0.85, 1.0) if e.slow > 0 else W2])
	L.append(["Typ: " + ("latający (omija blokadę)" if e.flying else "naziemny"), W2])
	if e.dmg > 0:
		L.append(["Obrażenia vs żołnierz: %d / s" % int(e.dmg), W2])
	L.append(["Odbiera żyć: %d" % e.lives, Color(1, 0.6, 0.5)])
	L.append(["Nagroda: %d zł" % e.reward, Color(1, 0.88, 0.3)])
	if e.ability == "heal":
		L.append(["Umiejętność - Rytuał: co 6 s leczy wrogów w promieniu 140 o 12% ich max HP", Color(0.5, 1.0, 0.6)])
	if e.blocked_by != null:
		L.append(["Zablokowany przez żołnierza", Color(0.5, 0.9, 1.0)])
	return L

func tower_lines(t, preview):
	var W2 = Color(0.92, 0.92, 0.95)
	var info = TOWERS[t.type]
	var L = []
	if t.type == "barracks" or t.type == "knight_tower":
		var alive = 0
		for s in t.soldiers:
			if s.alive:
				alive += 1
		if preview:
			L.append(["Żołnierze: " + str(3 if t.type == "barracks" else 1), W2])
		else:
			L.append(["Żołnierze: %d / %d żywych" % [alive, t.soldiers.size()], W2])
		L.append(["HP żołnierza: %d" % int(soldier_hp(t)), Color(1, 0.5, 0.5)])
		L.append(["Obrażenia: %d / s (fizyczne)" % int(t_dmg(t)), Color(1, 0.88, 0.5)])
		L.append(["Zasięg walki: %d" % int(t_range(t)), W2])
		L.append(["Odradzanie: %d s" % int(respawn_time(t)), W2])
		if t.type == "knight_tower":
			L.append(["Cele: ziemia i latające (Włócznie)", Color(0.4, 0.9, 0.5)])
		else:
			L.append(["Cele: tylko naziemne", W2])
	else:
		var dtype = "magiczne" if info.magic else "fizyczne"
		L.append(["Obrażenia: %d (%s)" % [int(t_dmg(t)), dtype], Color(1, 0.88, 0.5)])
		L.append(["Szybkość: %.1f strzału / s" % (1.0 / t_rate(t)), W2])
		L.append(["DPS (bez pancerza): %d" % int(t_dmg(t) / t_rate(t)), Color(1, 0.7, 0.4)])
		L.append(["Zasięg: %d" % int(t_range(t)), W2])
		if info.splash > 0:
			L.append(["Promień wybuchu: %d" % int(t_splash(t)), W2])
		if t.type == "archer":
			L.append(["Cele: naziemne i latające", W2])
		elif t.type == "mage":
			L.append(["Cele: naziemne i latające (ignoruje pancerz)", W2])
		else:
			L.append(["Cele: tylko naziemne", W2])
	var bi = branch_info(t)
	if bi != null:
		L.append(["Ulepszenie: " + bi.name, Color(0.4, 0.95, 1.0)])
		L.append([bi.desc, Color(0.7, 0.9, 1.0)])
	if not preview and t.type != "knight_tower":
		L.append(["Sprzedaż: +%d zł" % int(t.spent * SELL_REFUND), Color(0.7, 0.7, 0.7)])
	return L

func tower_title(t):
	return "%s (poz. %d)" % [TOWERS[t.type].name, t.level]

func clone_tower(t):
	var c = Tower.new()
	c.type = t.type
	c.level = t.level
	c.branch = t.branch
	c.spent = t.spent
	return c

func draw_info():
	if state != "play":
		return
	if selected_spot >= 0:
		var sp = spots[selected_spot]
		for b in menu_buttons():
			if not b.rect.has_point(mouse):
				continue
			var pos = sp.pos + Vector2(150, -60)
			if pos.x + 250 > W:
				pos.x = sp.pos.x - 150 - 250
			if b.act == "build":
				var pt = Tower.new()
				pt.type = b.type
				draw_panel(pos, TOWERS[b.type].name + " (nowa)", tower_lines(pt, true), Color(0.5, 0.8, 1.0))
			elif b.act == "upgrade":
				var pt = clone_tower(sp.tower)
				pt.level += 1
				draw_panel(pos, "Po ulepszeniu: poz. %d" % pt.level, tower_lines(pt, true), Color(0.5, 1.0, 0.5))
			elif b.act == "branch":
				var pt = clone_tower(sp.tower)
				pt.level = 4
				pt.branch = b.branch
				var lines = [[b.desc, Color(0.8, 0.95, 1.0)], ["", Color.WHITE]]
				lines.append_array(tower_lines(pt, true))
				draw_panel(pos, b.label, lines, Color(0.75, 0.5, 0.95))
			return
		if sp.tower != null:
			var pos = sp.pos + Vector2(150, -60)
			if pos.x + 250 > W:
				pos.x = sp.pos.x - 150 - 250
			draw_panel(pos, tower_title(sp.tower), tower_lines(sp.tower, false), Color(0.5, 0.8, 1.0))
	var e = enemy_at(mouse)
	if e == null:
		e = selected_enemy
	if e != null:
		var d = ENEMIES[e.type]
		draw_panel(enemy_draw_pos(e) + Vector2(28, -50), d.title, enemy_lines(e), Color(1, 0.5, 0.45))
		return
	var so = soldier_at(mouse)
	if so != null:
		var lines = [
			["HP: %d / %d" % [int(ceil(so.hp)), int(so.maxhp)], Color(1, 0.5, 0.5)],
			["Obrażenia: %d / s" % int(so.dmg), Color(1, 0.88, 0.5)],
			["Zasięg walki: %d" % int(so.radius), Color(0.92, 0.92, 0.95)],
		]
		if so.life > 0:
			lines.append(["Znika za: %d s" % int(ceil(so.life)), Color(0.7, 0.9, 1.0)])
		var title = "Żołnierz"
		if so.type == "knight": title = "Rycerz z Włócznią"
		elif so.tower == null: title = "Posiłki"
		draw_panel(so.pos + Vector2(24, -40), title, lines, Color(0.4, 0.75, 1.0))
		return
	var t = tower_at(mouse)
	if t != null and not (selected_spot >= 0 and spots[selected_spot].tower == t):
		draw_panel(t.pos + Vector2(40, -50), tower_title(t), tower_lines(t, false), Color(0.5, 0.8, 1.0))

# ================= RZEKA I MOSTY =================
var RIVER_COL = Color(0.0, 0.62, 0.9)

func draw_river(poly):
	draw_colored_polygon(PackedVector2Array(poly), RIVER_COL)
	var n = poly.size() / 2
	var mid = PackedVector2Array()
	for i in n:
		mid.append((poly[i] + poly[poly.size() - 1 - i]) / 2.0)
	draw_polyline(mid, Color(0.55, 0.85, 1.0, 0.35), 5.0)
	var left = PackedVector2Array()
	var right = PackedVector2Array()
	for i in n:
		left.append(poly[i])
		right.append(poly[poly.size() - 1 - i])
	draw_polyline(left, Color(0.85, 0.95, 1.0, 0.6), 3.0)
	draw_polyline(right, Color(0.85, 0.95, 1.0, 0.6), 3.0)

func draw_bridge_planks(a, b, frac, vertical = false):
	if vertical:
		var h = (b.y - a.y) * frac
		draw_rect(Rect2(a.x - 30.0, a.y, 60.0, h), Color(0.55, 0.38, 0.2))
		var y = a.y + 6.0
		while y < a.y + h - 2.0:
			draw_line(Vector2(a.x - 30.0, y), Vector2(a.x + 30.0, y), Color(0.33, 0.22, 0.1), 2.0)
			y += 14.0
		draw_line(Vector2(a.x - 30.0, a.y), Vector2(a.x - 30.0, a.y + h), Color(0.3, 0.2, 0.1), 4.0)
		draw_line(Vector2(a.x + 30.0, a.y), Vector2(a.x + 30.0, a.y + h), Color(0.3, 0.2, 0.1), 4.0)
		return
	var len = (b.x - a.x) * frac
	var r = Rect2(a.x, a.y - 30.0, len, 60.0)
	draw_rect(r, Color(0.55, 0.38, 0.2))
	var x = a.x + 6.0
	while x < a.x + len - 2.0:
		draw_line(Vector2(x, a.y - 30.0), Vector2(x, a.y + 30.0), Color(0.33, 0.22, 0.1), 2.0)
		x += 14.0
	draw_line(Vector2(a.x, a.y - 30.0), Vector2(a.x + len, a.y - 30.0), Color(0.3, 0.2, 0.1), 4.0)
	draw_line(Vector2(a.x, a.y + 30.0), Vector2(a.x + len, a.y + 30.0), Color(0.3, 0.2, 0.1), 4.0)

func draw_drawbridge(i, br):
	var a = br.a
	var b = br.b
	var t = bridge_t[i]
	draw_rect(Rect2(a.x - 2.0, a.y - 34.0, b.x - a.x + 4.0, 68.0), RIVER_COL)
	var frac = 0.14 + 0.86 * t
	draw_bridge_planks(a, b, frac)
	draw_circle(a + Vector2(0, -30), 6.0, Color(0.25, 0.25, 0.28))
	draw_circle(a + Vector2(0, 30), 6.0, Color(0.25, 0.25, 0.28))
	if t < 0.99:
		draw_line(a + Vector2(0, -30), a + Vector2(frac * (b.x - a.x), -30), Color(0.7, 0.7, 0.75, 0.6), 2.0)
	var is_open = active_bridge == i
	var col = Color(0.5, 1.0, 0.5) if is_open else Color(1.0, 0.45, 0.4)
	var label = "%s: %s" % [br.name, "OTWARTY" if is_open else "PODNIESIONY"]
	if is_open:
		if bridge_timer > 0.0:
			label += " (zmiana za %d s)" % int(ceil(bridge_timer))
		else:
			label += " (czeka na wrogów)"
	var mid = (a + b) / 2.0
	draw_rect(Rect2(mid.x - 125.0, a.y - 62.0, 250.0, 22.0), Color(0, 0, 0, 0.6))
	txt(Vector2(mid.x - 125.0, a.y - 46.0), label, 13, col, HORIZONTAL_ALIGNMENT_CENTER, 250.0)
	# podczas oczekiwania zaznacz strefę, w której wrogowie blokują zamknięcie mostu
	if is_open and bridge_timer <= 0.0:
		var r = routes[br.route]
		draw_polyline(PackedVector2Array(r.pts.slice(br.zone_from, br.zone_to + 1)), Color(1, 0.3, 0.2, 0.35), 40.0)
