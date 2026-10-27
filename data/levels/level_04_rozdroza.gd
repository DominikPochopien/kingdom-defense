## Poziom 4 - Rozdroża. Opis kluczy: data/level_data.gd

const DATA := {
	"name": "Rozdroża", "desc": "Dwa starty: drugi włącza się od 4. fali, a wrogowie wybierają losowy. Masz darmową Wieżę Rycerską (pomarańczowa), której rycerze biją też latające wrogi.",
	"waves": 12, "gold": 400, "lives": 20, "hp": 1.4, "difficulty": "Bardzo trudny", "random_routes_from": 4,
	"routes": [
		[Vector2(200, -40), Vector2(200, 600), Vector2(500, 600), Vector2(500, 200), Vector2(1320, 200)],
		[Vector2(1320, 600), Vector2(500, 600), Vector2(500, 200), Vector2(1320, 200)],
	],
	"river": [Vector2(-40, 350), Vector2(1320, 350), Vector2(1320, 450), Vector2(-40, 450)],
	"fixed_bridges": [
		{"a": Vector2(200, 340), "b": Vector2(200, 460), "vertical": true},
		{"a": Vector2(500, 340), "b": Vector2(500, 460), "vertical": true},
	],
	"spots": [
		Vector2(280, 200), Vector2(280, 520), Vector2(350, 670),
		Vector2(610, 270), Vector2(600, 520), Vector2(900, 670),
		Vector2(1050, 120), Vector2(400, 150),
	],
	"special_tower": 7,
}
