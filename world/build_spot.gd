class_name BuildSpot
extends RefCounted
## Kamienna podstawa na mapie, na której można postawić jedną wieżę.

const CLICK_RADIUS := 30.0
const HOVER_RADIUS := 28.0

## numer miejsca w danych poziomu (używany w zapisie gry)
var index := 0
var position := Vector2.ZERO
var tower: Tower = null


func _init(spot_index: int, at: Vector2) -> void:
	index = spot_index
	position = at


func is_empty() -> bool:
	return tower == null


func contains(p: Vector2, r := CLICK_RADIUS) -> bool:
	return position.distance_to(p) < r
