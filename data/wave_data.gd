class_name WaveData
## Skład fal wrogów i odstępy między nimi.

## Opóźnienie pierwszego wroga po wezwaniu fali (s).
const FIRST_SPAWN_DELAY := 0.8
## Przerwa przed pierwszym wrogiem każdej grupy (s).
const GROUP_GAP := 2.0
const DEFAULT_GAP := 0.9
const WOLF_GAP := 0.5
const SHAMAN_GAP := 1.6


## Skład fali nr n: lista par [typ, liczba].
static func composition(n: int, total_waves: int, with_shamans: bool, with_magic_knights := false,
		with_dragons := false, with_hedgehogs := false, with_undead := false) -> Array:
	var groups := []
	groups.append(["goblin", 3 + n * 2])
	if n >= 2:
		groups.append(["wolf", int(n * 1.2)])
	if n >= 3:
		groups.append(["orc", int(n * 0.8)])
	if n >= 4:
		groups.append(["bat", int(n * 0.7)])
	if with_shamans and n >= 4:
		groups.append(["shaman", floori(n / 4.0)])
	# od 6. fali: 1 rycerz, co 4 fale o jednego więcej
	if with_magic_knights and n >= 6:
		groups.append(["magic_knight", 1 + floori((n - 6) / 4.0)])
	# od 5. fali: 1 smok, co 4 fale o jednego więcej
	if with_dragons and n >= 5:
		groups.append(["dragon", 1 + floori((n - 5) / 4.0)])
	# od 3. fali: 1 jeżowiec, co 3 fale o jednego więcej
	if with_hedgehogs and n >= 3:
		groups.append(["hedgehog", 1 + floori((n - 3) / 3.0)])
	# nieumarli z piramidy: Szkielety od 1. fali (co falę o 2 więcej), łucznicy od 3., pancerni od 4.;
	# w ostatniej fali Mumia zamiast Wodza
	if with_undead:
		groups.append(["skeleton", 4 + n * 2])
		if n >= 3:
			groups.append(["skeleton_archer", floori(n / 2.0)])
		if n >= 4:
			groups.append(["skeleton_armored", 1 + floori((n - 4) / 3.0)])
		if n == total_waves:
			groups.append(["mummy", 1])
			return groups
	if n % 5 == 0:
		groups.append(["boss", floori(n / 5.0)])
	elif n == total_waves:
		groups.append(["boss", 1])
	return groups


## Odstęp między kolejnymi wrogami danego typu w grupie (s).
static func spawn_gap(type: String) -> float:
	return WOLF_GAP if type == "wolf" else DEFAULT_GAP
