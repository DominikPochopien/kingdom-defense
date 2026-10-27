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
static func composition(n: int, total_waves: int, with_shamans: bool) -> Array:
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
	if n % 5 == 0:
		groups.append(["boss", floori(n / 5.0)])
	elif n == total_waves:
		groups.append(["boss", 1])
	return groups


## Odstęp między kolejnymi wrogami danego typu w grupie (s).
static func spawn_gap(type: String) -> float:
	return WOLF_GAP if type == "wolf" else DEFAULT_GAP
