class_name EnemyData
## Statystyki wrogów. Wygląd każdego typu jest w entities/enemies/<typ>.gd.
##
## title  - nazwa w panelu informacji, name - dopełniacz w zapowiedzi fali ("5 goblinów")
## hp, speed (px/s), reward (złoto), lives (ile żyć odbiera), dmg (obrażenia/s vs żołnierz), r (promień)
## armor = redukcja obrażeń fizycznych, mr = redukcja magicznych (0..1)
## flying = omija blokadę żołnierzy, ability = specjalna umiejętność ("heal")

const ENEMIES := {
	"goblin": {"title": "Goblin", "name": "goblinów", "hp": 40.0, "speed": 60.0, "armor": 0.0, "mr": 0.0,
		"reward": 8, "lives": 1, "flying": false, "dmg": 3.0, "r": 11.0},
	"wolf": {"title": "Wilk", "name": "wilków", "hp": 30.0, "speed": 115.0, "armor": 0.0, "mr": 0.0,
		"reward": 9, "lives": 1, "flying": false, "dmg": 4.0, "r": 10.0},
	"orc": {"title": "Ork pancerny", "name": "orków", "hp": 150.0, "speed": 45.0, "armor": 0.5, "mr": 0.3,
		"reward": 18, "lives": 2, "flying": false, "dmg": 8.0, "r": 15.0},
	"bat": {"title": "Nietoperz", "name": "nietoperzy", "hp": 35.0, "speed": 95.0, "armor": 0.0, "mr": 0.0,
		"reward": 10, "lives": 1, "flying": true, "dmg": 0.0, "r": 9.0},
	"shaman": {"title": "Szaman Wojenny", "name": "szamanów", "hp": 350.0, "speed": 42.0, "armor": 0.15, "mr": 0.45,
		"reward": 45, "lives": 3, "flying": false, "dmg": 6.0, "r": 17.0,
		"ability": "heal", "heal_first": 3.0, "heal_interval": 6.0, "heal_radius": 140.0, "heal_pct": 0.12},
	"boss": {"title": "BOSS: Wódz", "name": "BOSS", "hp": 800.0, "speed": 32.0, "armor": 0.3, "mr": 0.3,
		"reward": 150, "lives": 5, "flying": false, "dmg": 20.0, "r": 24.0},
}


static func get_info(type: String) -> Dictionary:
	return ENEMIES[type]
