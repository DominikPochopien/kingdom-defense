## Poziom 3 - Rzeka Mostów. Opis kluczy: data/level_data.gd
## Dwa zwodzone mosty - logika w systems/bridge_system.gd.
## Mapa, trasy, miejsca na wieże i mosty są w scenie levels/level_03.tscn (edycja w Godocie).

const DATA := {
	"name": "Rzeka Mostów", "desc": "Dwa zwodzone mosty: otwarty jest zawsze jeden i zmienia się co 20 s, ale nigdy nie zamknie się, gdy wrogowie są na jego zjeździe lub na nim. Wrogowie mają +40% HP, a Szamani Wojenni leczą towarzyszy.",
	"waves": 12, "gold": 520, "lives": 25, "hp": 1.4, "difficulty": "Bardzo trudny", "shamans": true, "bridge_period": 20.0,
	"scene": "res://levels/level_03.tscn",
	# droga malowana wzdłuż tras: rozwidlenie przed mostami zwodzonymi, połączenie przy wyjściu na dole
	"road": "painted",
	# rzeka przez środek mapy, oba mosty zwodzone nad nią
	"river": [Vector2(615, 30), Vector2(612, 195), Vector2(578, 300), Vector2(540, 411), Vector2(500, 520),
		Vector2(505, 620), Vector2(555, 740), Vector2(690, 740), Vector2(630, 620), Vector2(620, 520),
		Vector2(660, 411), Vector2(702, 300), Vector2(732, 195), Vector2(745, 30)],
}
