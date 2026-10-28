extends Enemy
## Nietoperz - latający: unosi się nad drogą i omija blokadę żołnierzy.

const HOVER_HEIGHT := 22.0


func _body_offset() -> Vector2:
	return Vector2(0, -HOVER_HEIGHT)


## Klatka wyśrodkowana na ciele, które lekko buja się w locie.
func _sprite_foot() -> Vector2:
	return Vector2(0, -HOVER_HEIGHT + 12.0 + sin(anim * 8.0) * 3.0)


func _sheet_name() -> String:
	return "bat_hit" if _flash > 0 else "bat_fly"
