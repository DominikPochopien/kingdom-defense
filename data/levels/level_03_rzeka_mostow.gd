## Poziom 3 - Rzeka Mostów. Opis kluczy: data/level_data.gd
## Dwa zwodzone mosty - logika w systems/bridge_system.gd.

const DATA := {
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
}
