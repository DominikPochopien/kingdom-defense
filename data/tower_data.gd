class_name TowerData
## Statystyki wież i ich ulepszeń 4. poziomu. Wygląd: grafiki assets/towers/<art>_<poziom 1-3>.png,
## a na 4. poziomie assets/towers/<art gałęzi>.png (Statek: entities/towers/ship_tower.gd).
##
## Wspólne: name, art (przedrostek grafik), cost, range, dmg, magic (obrażenia magiczne), targets (opis celów w panelu)
## Wieże strzelające: rate (s między strzałami), splash (promień wybuchu), projectile_speed,
##   shot_sound, ground_only (nie strzela do latających)
## Wieże z żołnierzami: soldiers (liczba na 1. poziomie), soldiers_per_level, soldier_hp,
##   soldier_hp_per_level, respawn (s), knights (rycerze: dłuższy zasięg ciosu, biją latających),
##   sellable (false = nie można sprzedać)
## Statek: cannons_per_level (armaty = pociski naraz na każdy poziom). Typów spoza BUILD_MENU nie ma
##   w menu budowy - stawia się je tylko na specjalnych miejscach (BuildSpot.only_type).

const TOWERS := {
	"archer": {"art": "archer", "name": "Łucznicy", "cost": 70, "range": 170.0, "rate": 0.7, "dmg": 8.0, "magic": false, "splash": 0.0,
		"projectile_speed": 520.0, "shot_sound": "shoot", "targets": "naziemne i latające"},
	"mage": {"art": "mage", "name": "Magowie", "cost": 100, "range": 150.0, "rate": 1.8, "dmg": 24.0, "magic": true, "splash": 0.0,
		"projectile_speed": 380.0, "shot_sound": "magic", "targets": "naziemne i latające (ignoruje pancerz)"},
	"barracks": {"art": "barracks", "name": "Koszary", "cost": 80, "range": 120.0, "rate": 0.0, "dmg": 4.0, "magic": false, "splash": 0.0,
		"soldiers": 3, "soldier_hp": 50.0, "soldier_hp_per_level": 25.0, "respawn": 8.0,
		"targets": "tylko naziemne"},
	"artillery": {"art": "artillery", "name": "Artyleria", "cost": 120, "range": 210.0, "rate": 3.2, "dmg": 30.0, "magic": false, "splash": 70.0,
		"projectile_speed": 260.0, "shot_sound": "shoot", "ground_only": true, "targets": "tylko naziemne"},
	"knight_tower": {"art": "knight", "name": "Rycerze", "cost": 150, "range": 130.0, "rate": 0.0, "dmg": 7.0, "magic": false, "splash": 0.0,
		"soldiers": 1, "soldiers_per_level": 1, "soldier_hp": 80.0, "soldier_hp_per_level": 30.0, "respawn": 8.0,
		"knights": true, "sellable": false, "targets": "ziemia i latające (Włócznie)"},
	"ship": {"name": "Statek", "cost": 220, "range": 330.0, "rate": 2.2, "dmg": 24.0, "magic": false, "splash": 0.0,
		"projectile_speed": 430.0, "shot_sound": "boom", "cannons_per_level": 1, "targets": "naziemne i latające"},
}

## Wieże dostępne w menu budowy (kolejność: góra, prawo, dół, lewo).
const BUILD_MENU := ["archer", "mage", "barracks", "artillery"]

## Ulepszenia 4. poziomu: gracz wybiera jedno z dwóch. art = grafika wieży z tym ulepszeniem.
## Modyfikatory (brak klucza = bez zmian):
##   dmg_mult, range_mult, rate_mult, splash_mult, hp_mult (HP żołnierzy) - mnożniki
##   shots - liczba pocisków naraz, slow_time - spowolnienie celu (s),
##   chain_dmg / chain_range - przeskok na drugiego wroga (ułamek obrażeń / zasięg),
##   extra_soldiers - dodatkowi żołnierze, respawn - czas odradzania (s)
##   burn_dmg / burn_time - podpalenie: obrażenia rozłożone na tyle sekund (ignorują pancerz)
##   volley_shots / volley_period - co volley_period s salwa tylu pocisków w losowych wrogów
const BRANCHES := {
	"archer": [
		{"id": "double", "art": "archer_4b_crossbow", "name": "Podwójny strzał", "desc": "Strzela dwiema strzałami naraz (w 2 różne cele, jeśli są).",
			"shots": 2},
		{"id": "long", "art": "archer_4a_ranger", "name": "Sokole oko", "desc": "+40% zasięgu oraz +25% obrażeń.",
			"range_mult": 1.4, "dmg_mult": 1.25},
	],
	"mage": [
		{"id": "slow", "art": "mage_4a_arcane", "name": "Lodowa magia", "desc": "Trafienie spowalnia wroga o 40% na 2 sekundy.",
			"slow_time": 2.0},
		{"id": "chain", "art": "mage_4b_storm", "name": "Błyskawica", "desc": "Pocisk przeskakuje na drugiego wroga (50% obrażeń).",
			"chain_dmg": 0.5, "chain_range": 110.0},
	],
	"barracks": [
		{"id": "vets", "art": "barracks_4a_templar", "name": "Weterani", "desc": "Żołnierze mają +60% HP i +50% obrażeń.",
			"hp_mult": 1.6, "dmg_mult": 1.5},
		{"id": "extra", "art": "barracks_4b_barbarian", "name": "Oddział", "desc": "+2 żołnierzy (razem 5) i szybsze odradzanie.",
			"extra_soldiers": 2, "respawn": 6.0},
	],
	"artillery": [
		{"id": "blast", "art": "artillery_4a_mortar", "name": "Wielki wybuch", "desc": "+40% promienia wybuchu oraz +20% obrażeń.",
			"splash_mult": 1.4, "dmg_mult": 1.2},
		{"id": "rapid", "art": "artillery_4b_firecatapult", "name": "Szybki ogień", "desc": "Przeładowanie o 40% szybsze.",
			"rate_mult": 0.6},
	],
	"knight_tower": [
		{"id": "dmg", "art": "knight_4b_darkknight", "name": "Ostre Włócznie", "desc": "Zadają +40% obrażeń z większym dystansem.",
			"dmg_mult": 1.4, "range_mult": 1.3},
		{"id": "hp", "art": "knight_4a_paladin", "name": "Gruby Pancerz", "desc": "Rycerze mają +60% życia.",
			"hp_mult": 1.6},
	],
	"ship": [
		{"id": "fire_shot", "name": "Ogniste pociski", "desc": "Pociski są o 40% mocniejsze i podpalają wroga: 20 obrażeń przez 3 s.",
			"dmg_mult": 1.4, "burn_dmg": 20.0, "burn_time": 3.0},
		{"id": "lance", "name": "Szybka lanca", "desc": "Co 6 s wystrzeliwuje naraz 10 pocisków w losowych wrogów w zasięgu.",
			"volley_shots": 10, "volley_period": 6.0},
	],
}
