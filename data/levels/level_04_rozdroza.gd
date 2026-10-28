## Poziom 4 - Rozdroża. Opis kluczy: data/level_data.gd
## Mapa, trasy i miejsca na wieże są w scenie levels/level_04.tscn (edycja w Godocie).

const DATA := {
	"name": "Rozdroża", "desc": "Dwa starty: drugi włącza się od 4. fali, a wrogowie wybierają losowy. Masz darmową Wieżę Rycerską (pomarańczowa), której rycerze biją też latające wrogi.",
	"waves": 12, "gold": 400, "lives": 20, "hp": 1.4, "difficulty": "Bardzo trudny", "random_routes_from": 4,
	"scene": "res://levels/level_04.tscn",
	"river": [Vector2(-40, 350), Vector2(1320, 350), Vector2(1320, 450), Vector2(-40, 450)],
	"fixed_bridges": [
		{"a": Vector2(208, 340), "b": Vector2(208, 460), "vertical": true},
		{"a": Vector2(496, 340), "b": Vector2(496, 460), "vertical": true},
	],
	"special_tower": 7,
}
