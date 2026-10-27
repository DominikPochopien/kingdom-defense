class_name BuildMenu
extends Node2D
## Menu wokół wybranego miejsca budowy: budowa wieży, ulepszenie, wybór gałęzi, sprzedaż.
## Węzeł leży w GameWorld (rysuje się nad jednostkami, ale pod paskiem interfejsu).

const COLOR_BUILD := Color(0.2, 0.35, 0.6)
const COLOR_UPGRADE := Color(0.2, 0.5, 0.25)
const COLOR_BRANCH := Color(0.5, 0.28, 0.65)
const COLOR_SELL := Color(0.6, 0.25, 0.2)
const BUILD_DISTANCE := 80.0
const BUTTON_SIZE := Vector2(104, 52)

@onready var _world: GameWorld = get_parent()


## Przyciski dla aktualnie wybranego miejsca (pusta lista, gdy nic nie wybrano).
func buttons() -> Array[UiButton]:
	var res: Array[UiButton] = []
	var spot := _world.selected_spot
	if spot == null or not _world.active:
		return res
	if spot.is_empty():
		_add_build_buttons(res, spot)
	else:
		_add_tower_buttons(res, spot)
	return res


func hovered_button() -> UiButton:
	return UiButton.find_at(buttons(), get_global_mouse_position())


func _add_build_buttons(res: Array[UiButton], spot: BuildSpot) -> void:
	var types := TowerData.BUILD_MENU
	for i in types.size():
		var type: String = types[i]
		var cost: int = TowerData.TOWERS[type].cost
		var dir := Vector2.from_angle(-PI / 2.0 + i * TAU / types.size())
		var center := spot.position + dir * BUILD_DISTANCE
		var b := _button(Rect2(center - BUTTON_SIZE / 2.0, BUTTON_SIZE), "build", TowerData.TOWERS[type].name,
			COLOR_BUILD, "%d zł" % cost, _world.gold >= cost)
		b.tower_type = type
		res.append(b)


func _add_tower_buttons(res: Array[UiButton], spot: BuildSpot) -> void:
	var stats := spot.tower.stats
	if stats.can_upgrade():
		var cost := stats.upgrade_cost()
		res.append(_button(Rect2(spot.position + Vector2(-52, -100), BUTTON_SIZE), "upgrade", "Ulepsz",
			COLOR_UPGRADE, "%d zł" % cost, _world.gold >= cost))
	elif stats.can_choose_branch():
		var cost := stats.branch_cost()
		var options := stats.branch_options()
		for i in options.size():
			var b := _button(Rect2(spot.position + Vector2(-135 + i * 140, -100), Vector2(130, 52)), "branch",
				options[i].name, COLOR_BRANCH, "%d zł" % cost, _world.gold >= cost)
			b.branch_id = options[i].id
			b.description = options[i].desc
			res.append(b)
	var sell_rect := Rect2(spot.position + Vector2(-52, 48), BUTTON_SIZE)
	if stats.is_sellable():
		res.append(_button(sell_rect, "sell", "Sprzedaj", COLOR_SELL, "+%d zł" % spot.tower.sell_value(), true))
	else:
		res.append(_button(sell_rect, "sell", "Zablokowane", COLOR_SELL, "Baza Złota", false))


func _button(r: Rect2, action: String, label: String, color: Color, sub: String, enabled: bool) -> UiButton:
	return UiButton.new(UiDraw.clamp_to_screen(r), action, label, color, sub, enabled)


## Obsługa kliknięcia; zwraca true, jeśli trafiono w przycisk menu.
func handle_click(p: Vector2) -> bool:
	var b := UiButton.find_at(buttons(), p)
	if b == null:
		return false
	if not b.enabled:
		return true
	var spot := _world.selected_spot
	match b.action:
		"build":
			_world.build_tower(spot, b.tower_type)
		"upgrade":
			_world.upgrade_tower(spot)
		"branch":
			_world.choose_branch(spot, b.branch_id)
			_world.selected_spot = null
		"sell":
			_world.sell_tower(spot)
	return true


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	for b in buttons():
		b.draw(self)
