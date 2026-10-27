class_name TowerData
## Statystyki wież i ich ulepszeń 4. poziomu. Wygląd: entities/towers/<typ>_tower.gd.
##
## Wspólne: name, cost, range, dmg, magic (obrażenia magiczne), targets (opis celów w panelu)
## Wieże strzelające: rate (s między strzałami), splash (promień wybuchu), projectile_speed,
##   shot_sound, ground_only (nie strzela do latających)
## Wieże z żołnierzami: soldiers (liczba na 1. poziomie), soldiers_per_level, soldier_hp,
##   soldier_hp_per_level, respawn (s), knights (rycerze: dłuższy zasięg ciosu, biją latających),
##   sellable (false = nie można sprzedać)

const TOWERS := {
	"archer": {"name": "Łucznicy", "cost": 70, "range": 170.0, "rate": 0.7, "dmg": 8.0, "magic": false, "splash": 0.0,
		"projectile_speed": 520.0, "shot_sound": "shoot", "targets": "naziemne i latające"},
	"mage": {"name": "Magowie", "cost": 100, "range": 150.0, "rate": 1.8, "dmg": 24.0, "magic": true, "splash": 0.0,
		"projectile_speed": 380.0, "shot_sound": "magic", "targets": "naziemne i latające (ignoruje pancerz)"},
	"barracks": {"name": "Koszary", "cost": 80, "range": 120.0, "rate": 0.0, "dmg": 4.0, "magic": false, "splash": 0.0,
		"soldiers": 3, "soldier_hp": 50.0, "soldier_hp_per_level": 25.0, "respawn": 8.0,
		"targets": "tylko naziemne"},
	"artillery": {"name": "Artyleria", "cost": 120, "range": 210.0, "rate": 3.2, "dmg": 30.0, "magic": false, "splash": 70.0,
		"projectile_speed": 260.0, "shot_sound": "shoot", "ground_only": true, "targets": "tylko naziemne"},
	"knight_tower": {"name": "Rycerze", "cost": 150, "range": 130.0, "rate": 0.0, "dmg": 7.0, "magic": false, "splash": 0.0,
		"soldiers": 1, "soldiers_per_level": 1, "soldier_hp": 80.0, "soldier_hp_per_level": 30.0, "respawn": 8.0,
		"knights": true, "sellable": false, "targets": "ziemia i latające (Włócznie)"},
}

## Wieże dostępne w menu budowy (kolejność: góra, prawo, dół, lewo).
const BUILD_MENU := ["archer", "mage", "barracks", "artillery"]

## Ulepszenia 4. poziomu: gracz wybiera jedno z dwóch.
## Modyfikatory (brak klucza = bez zmian):
##   dmg_mult, range_mult, rate_mult, splash_mult, hp_mult (HP żołnierzy) - mnożniki
##   shots - liczba pocisków naraz, slow_time - spowolnienie celu (s),
##   chain_dmg / chain_range - przeskok na drugiego wroga (ułamek obrażeń / zasięg),
##   extra_soldiers - dodatkowi żołnierze, respawn - czas odradzania (s)
const BRANCHES := {
	"archer": [
		{"id": "double", "name": "Podwójny strzał", "desc": "Strzela dwiema strzałami naraz (w 2 różne cele, jeśli są).",
			"shots": 2},
		{"id": "long", "name": "Sokole oko", "desc": "+40% zasięgu oraz +25% obrażeń.",
			"range_mult": 1.4, "dmg_mult": 1.25},
	],
	"mage": [
		{"id": "slow", "name": "Lodowa magia", "desc": "Trafienie spowalnia wroga o 40% na 2 sekundy.",
			"slow_time": 2.0},
		{"id": "chain", "name": "Błyskawica", "desc": "Pocisk przeskakuje na drugiego wroga (50% obrażeń).",
			"chain_dmg": 0.5, "chain_range": 110.0},
	],
	"barracks": [
		{"id": "vets", "name": "Weterani", "desc": "Żołnierze mają +60% HP i +50% obrażeń.",
			"hp_mult": 1.6, "dmg_mult": 1.5},
		{"id": "extra", "name": "Oddział", "desc": "+2 żołnierzy (razem 5) i szybsze odradzanie (4 s).",
			"extra_soldiers": 2, "respawn": 4.0},
	],
	"artillery": [
		{"id": "blast", "name": "Wielki wybuch", "desc": "+40% promienia wybuchu oraz +20% obrażeń.",
			"splash_mult": 1.4, "dmg_mult": 1.2},
		{"id": "rapid", "name": "Szybki ogień", "desc": "Przeładowanie o 40% szybsze.",
			"rate_mult": 0.6},
	],
	"knight_tower": [
		{"id": "dmg", "name": "Ostre Włócznie", "desc": "Zadają +40% obrażeń z większym dystansem.",
			"dmg_mult": 1.4, "range_mult": 1.3},
		{"id": "hp", "name": "Gruby Pancerz", "desc": "Rycerze mają +60% życia.",
			"hp_mult": 1.6},
	],
}
