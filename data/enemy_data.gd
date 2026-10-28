class_name EnemyData
## Statystyki wrogów. Wygląd każdego typu jest w entities/enemies/<typ>.gd.
##
## title  - nazwa w panelu informacji, name - dopełniacz w zapowiedzi fali ("5 goblinów")
## hp, speed (px/s), reward (złoto), lives (ile żyć odbiera), dmg (obrażenia/s vs żołnierz), r (promień)
## armor = redukcja obrażeń fizycznych, mr = redukcja magicznych (0..1)
## flying = omija blokadę żołnierzy, ability = specjalna umiejętność ("heal", "magic_knight", "breath")
## fixed_hp = true: HP nie jest mnożone przez mnożnik poziomu
## Smok: breath_* = co breath_interval s zieje ogniem w breath_targets żołnierzy w zasięgu
## Jeżowiec: spike_* = co spike_interval s rzuca kolcami w najbliższego żołnierza w zasięgu,
##   roll_* = co roll_interval s turla się przez roll_time s (do roll_max_mult x szybciej),
##   taranując żołnierzy (roll_damage); nie da się go wtedy zablokować
## Magiczny Rycerz: seal_* = fioletowa aura wyłączająca wieże w promieniu na seal_time s,
##   haste_* = niebieska aura (przez haste_time s), w której wrogowie są haste_mult razy szybsi

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
	"magic_knight": {"title": "Magiczny Rycerz", "name": "magicznych rycerzy", "hp": 900.0, "fixed_hp": true, "speed": 26.0, "armor": 0.9, "mr": 0.0,
		"reward": 120, "lives": 4, "flying": false, "dmg": 15.0, "r": 20.0, "ability": "magic_knight",
		"seal_first": 4.0, "seal_interval": 12.0, "seal_radius": 184.0, "seal_time": 4.0,
		"haste_first": 8.0, "haste_interval": 12.0, "haste_time": 5.0, "haste_radius": 130.0, "haste_mult": 2.0},
	"dragon": {"title": "Smok", "name": "smoków", "hp": 900.0, "fixed_hp": true, "speed": 48.0, "armor": 0.2, "mr": 0.2,
		"reward": 90, "lives": 3, "flying": true, "dmg": 0.0, "r": 18.0, "ability": "breath",
		"breath_first": 2.0, "breath_interval": 3.0, "breath_range": 140.0, "breath_damage": 30.0, "breath_targets": 2},
	"hedgehog": {"title": "Jeżowiec", "name": "jeżowców", "hp": 220.0, "speed": 40.0, "armor": 0.35, "mr": 0.1,
		"reward": 28, "lives": 2, "flying": false, "dmg": 7.0, "r": 15.0, "ability": "hedgehog",
		"spike_first": 2.0, "spike_interval": 4.0, "spike_range": 150.0, "spike_damage": 12.0,
		"roll_first": 4.0, "roll_interval": 10.0, "roll_time": 3.5, "roll_max_mult": 3.0, "roll_damage": 25.0},
}


static func get_info(type: String) -> Dictionary:
	return ENEMIES[type]
