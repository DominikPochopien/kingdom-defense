## Poziom 3 - Rzeka Mostów. Opis kluczy: data/level_data.gd
## Dwa zwodzone mosty - logika w systems/bridge_system.gd.
## Mapa, trasy i miejsca na wieże są w scenie levels/level_03.tscn (edycja w Godocie).

const DATA := {
	"name": "Rzeka Mostów", "desc": "Dwa zwodzone mosty: otwarty jest zawsze jeden i zmienia się co 20 s, ale nigdy nie zamknie się, gdy wrogowie są na jego zjeździe lub na nim. Wrogowie mają +40% HP, a Szamani Wojenni leczą towarzyszy.",
	"waves": 12, "gold": 520, "lives": 25, "hp": 1.4, "difficulty": "Bardzo trudny", "shamans": true, "bridge_period": 20.0,
	"scene": "res://levels/level_03.tscn",
	"river": [Vector2(985, 44), Vector2(1010, 250), Vector2(1000, 420), Vector2(960, 520), Vector2(880, 610),
		Vector2(780, 720), Vector2(900, 720), Vector2(1020, 610), Vector2(1100, 520), Vector2(1140, 420),
		Vector2(1150, 250), Vector2(1130, 44)],
	"bridges": [
		{"a": Vector2(996, 208), "b": Vector2(1152, 208), "name": "Most 1", "route": 0, "zone_from": 3, "zone_to": 5},
		{"a": Vector2(982, 432), "b": Vector2(1136, 432), "name": "Most 2", "route": 1, "zone_from": 3, "zone_to": 4},
	],
	"fixed_bridges": [{"a": Vector2(872, 624), "b": Vector2(1030, 624)}],
}
