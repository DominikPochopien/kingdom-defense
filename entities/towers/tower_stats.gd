class_name TowerStats
extends RefCounted
## Statystyki wieży dla typu, poziomu i gałęzi ulepszenia - same obliczenia, bez stanu gry.
## Używane przez wieże w grze oraz do podglądu "po ulepszeniu" w panelu informacji.
## Dane bazowe: data/tower_data.gd, skalowanie z poziomem: data/balance.gd.

const MAX_LEVEL := 3
const BRANCH_LEVEL := 4

var type := ""
## 1-3 = zwykłe poziomy, 4 = wybrana gałąź ulepszenia
var level := 1
var branch := ""
var info: Dictionary


func _init(tower_type: String, tower_level := 1, branch_id := "") -> void:
	type = tower_type
	level = tower_level
	branch = branch_id
	info = TowerData.TOWERS[tower_type]


## Kopia z innym poziomem / gałęzią (do podglądu ulepszeń).
func preview(new_level: int, new_branch: String) -> TowerStats:
	return TowerStats.new(type, new_level, new_branch)


func display_name() -> String:
	return info.name


func title() -> String:
	return "%s (poz. %d)" % [display_name(), level]


## Poziom użyty do skalowania statystyk (gałąź liczy się jak poziom 3).
func tier() -> int:
	return mini(level, MAX_LEVEL)


func branch_info() -> Dictionary:
	if branch == "":
		return {}
	for b in TowerData.BRANCHES[type]:
		if b.id == branch:
			return b
	return {}


func branch_options() -> Array:
	return TowerData.BRANCHES[type]


func _branch_value(key: String, default_value: Variant) -> Variant:
	return branch_info().get(key, default_value)


# ---------------- walka ----------------
func damage() -> float:
	return info.dmg * (1.0 + Balance.DMG_PER_LEVEL * (tier() - 1)) * _branch_value("dmg_mult", 1.0)


func attack_range() -> float:
	return info.range * (1.0 + Balance.RANGE_PER_LEVEL * (tier() - 1)) * _branch_value("range_mult", 1.0)


## Czas między strzałami (s).
func reload_time() -> float:
	return info.rate * (1.0 - Balance.RATE_PER_LEVEL * (tier() - 1)) * _branch_value("rate_mult", 1.0)


func splash_radius() -> float:
	return info.splash * _branch_value("splash_mult", 1.0)


func is_magic() -> bool:
	return info.magic


func is_ground_only() -> bool:
	return info.get("ground_only", false)


func projectile_speed() -> float:
	return info.get("projectile_speed", 400.0)


## Pociski naraz; Statek ma tyle armat, ile wynosi jego poziom.
func shots() -> int:
	var base: int = info.cannons_per_level * tier() if info.has("cannons_per_level") else 1
	return _branch_value("shots", base)


func has_cannons() -> bool:
	return info.has("cannons_per_level")


func burn_damage() -> float:
	return _branch_value("burn_dmg", 0.0)


func burn_time() -> float:
	return _branch_value("burn_time", 0.0)


func volley_shots() -> int:
	return _branch_value("volley_shots", 0)


func volley_period() -> float:
	return _branch_value("volley_period", 0.0)


func slow_time() -> float:
	return _branch_value("slow_time", 0.0)


func chain_damage() -> float:
	return _branch_value("chain_dmg", 0.0)


func chain_range() -> float:
	return _branch_value("chain_range", 0.0)


func targets_description() -> String:
	return info.targets


# ---------------- żołnierze ----------------
func uses_soldiers() -> bool:
	return info.has("soldiers")


func has_knights() -> bool:
	return info.get("knights", false)


func soldier_count() -> int:
	return info.soldiers + info.get("soldiers_per_level", 0) * (tier() - 1) + _branch_value("extra_soldiers", 0)


func soldier_hp() -> float:
	return (info.soldier_hp + info.soldier_hp_per_level * (tier() - 1)) * _branch_value("hp_mult", 1.0)


func respawn_time() -> float:
	return _branch_value("respawn", info.respawn) * Balance.SOLDIER_RESPAWN_MULT


# ---------------- ekonomia ----------------
func can_upgrade() -> bool:
	return level < MAX_LEVEL


func can_choose_branch() -> bool:
	return level == MAX_LEVEL


func upgrade_cost() -> int:
	return int(info.cost * (Balance.UPGRADE_COST_TO_2 if level == 1 else Balance.UPGRADE_COST_TO_3))


func branch_cost() -> int:
	return int(info.cost * Balance.BRANCH_COST)


func is_sellable() -> bool:
	return info.get("sellable", true)


static func sell_value(spent: int) -> int:
	return int(spent * Balance.SELL_REFUND)
