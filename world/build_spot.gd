class_name BuildSpot
extends RefCounted
## Kamienna podstawa na mapie, na której można postawić jedną wieżę.

const CLICK_RADIUS := 30.0
const HOVER_RADIUS := 28.0

## numer miejsca w danych poziomu (używany w zapisie gry)
var index := 0
var position := Vector2.ZERO
var tower: Tower = null
## jedyny typ wieży, który można tu postawić ("" = zwykłe miejsce z menu budowy)
var only_type := ""
## środek obszaru, w którym postawiona tu wieża szuka celów
var aim_center := Vector2.ZERO


func _init(spot_index: int, at: Vector2) -> void:
	index = spot_index
	position = at
	aim_center = at


func is_empty() -> bool:
	return tower == null


func contains(p: Vector2, r := CLICK_RADIUS) -> bool:
	return position.distance_to(p) < r
