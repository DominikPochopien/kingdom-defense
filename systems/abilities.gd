class_name Abilities
extends RefCounted
## Umiejętności gracza: czasy odnowienia i tryb celowania.
## Samo działanie umiejętności (uderzenia, posiłki) jest w GameWorld.cast_*.

enum Kind { NONE, FIRE, REINFORCEMENTS }

var targeting := Kind.NONE
var fire_cooldown := 0.0
var reinf_cooldown := 0.0


func reset() -> void:
	targeting = Kind.NONE
	fire_cooldown = 0.0
	reinf_cooldown = 0.0


func update(dt: float) -> void:
	if fire_cooldown > 0:
		fire_cooldown -= dt
	if reinf_cooldown > 0:
		reinf_cooldown -= dt


func is_ready(kind: Kind) -> bool:
	match kind:
		Kind.FIRE:
			return fire_cooldown <= 0
		Kind.REINFORCEMENTS:
			return reinf_cooldown <= 0
	return false


func cooldown_of(kind: Kind) -> float:
	return fire_cooldown if kind == Kind.FIRE else reinf_cooldown


func is_targeting() -> bool:
	return targeting != Kind.NONE


## Włącza celowanie (albo wyłącza, jeśli ta umiejętność już jest wybrana).
func toggle_targeting(kind: Kind) -> void:
	if is_ready(kind):
		targeting = Kind.NONE if targeting == kind else kind


func cancel_targeting() -> void:
	targeting = Kind.NONE


## Uruchamia odnowienie wybranej umiejętności i zwraca, która to była.
func consume_targeting() -> Kind:
	var kind := targeting
	targeting = Kind.NONE
	if kind == Kind.FIRE:
		fire_cooldown = Balance.FIRE_COOLDOWN
	elif kind == Kind.REINFORCEMENTS:
		reinf_cooldown = Balance.REINF_COOLDOWN
	return kind
