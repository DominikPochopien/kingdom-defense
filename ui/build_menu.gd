class_name BuildMenu
extends Node2D
## Menu wokół wybranego miejsca budowy: budowa wieży, ulepszenie, wybór gałęzi, sprzedaż
## i (dla wież z żołnierzami) okrągły przycisk wyboru punktu zbiórki.
## Węzeł leży w GameWorld (rysuje się nad jednostkami, ale pod paskiem interfejsu).

const COLOR_BUILD := Color(0.2, 0.35, 0.6)
const COLOR_UPGRADE := Color(0.2, 0.5, 0.25)
const COLOR_BRANCH := Color(0.5, 0.28, 0.65)
const COLOR_SELL := Color(0.6, 0.25, 0.2)
const COLOR_RALLY := Color(0.75, 0.6, 0.2)
## odległość od środka miejsca do najbliższej krawędzi przycisku budowy
const BUILD_GAP := 36.0
const BUTTON_SIZE := Vector2(104, 52)
## kwadratowe przyciski z ikoną (budowa wieży i wybór gałęzi)
const ICON_BUTTON_SIZE := Vector2(60, 60)
## promień okrągłego przycisku punktu zbiórki (leży na prawej krawędzi zasięgu wieży)
const RALLY_RADIUS := 17.0

@onready var _world: GameWorld = get_parent()


func _ready() -> void:
	# ikony wież to pixel art - ostre piksele
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


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
	var types: Array = TowerData.BUILD_MENU if spot.only_type == "" else [spot.only_type]
	for i in types.size():
		var type: String = types[i]
		var cost: int = TowerData.TOWERS[type].cost
		var dir := Vector2.from_angle(-PI / 2.0 + i * TAU / types.size())
		# odsuwamy o połowę wymiaru przycisku w danym kierunku, żeby krawędzie były równo od miejsca
		var half_extent := absf(dir.x) * ICON_BUTTON_SIZE.x / 2.0 + absf(dir.y) * ICON_BUTTON_SIZE.y / 2.0
		var center := spot.position + dir * (BUILD_GAP + half_extent)
		var b := _button(Rect2(center - ICON_BUTTON_SIZE / 2.0, ICON_BUTTON_SIZE), "build", TowerData.TOWERS[type].name,
			COLOR_BUILD, "%d zł" % cost, _world.gold >= cost)
		b.tower_type = type
		b.icon = type
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
			var b := _button(Rect2(spot.position + Vector2(-68 + i * 76, -104), ICON_BUTTON_SIZE), "branch",
				options[i].name, COLOR_BRANCH, "%d zł" % cost, _world.gold >= cost)
			b.branch_id = options[i].id
			b.icon = options[i].id
			b.description = options[i].desc
			res.append(b)
	if spot.tower is SoldierTower:
		var center := spot.position + Vector2((spot.tower as SoldierTower).rally_range(), 0)
		var size := Vector2.ONE * RALLY_RADIUS * 2.0
		res.append(_button(Rect2(center - size / 2.0, size), "rally", "Punkt zbiórki", COLOR_RALLY, "", true))
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
		"rally":
			_world.start_rally(spot.tower as SoldierTower)
	return true


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	for b in buttons():
		if b.action == "rally":
			_draw_rally_button(b)
		else:
			b.draw(self)


## Okrągły przycisk z chorągiewką.
func _draw_rally_button(b: UiButton) -> void:
	var c := b.rect.get_center()
	var col := b.color
	if b.contains(get_global_mouse_position()):
		col = col.lightened(0.25)
	draw_circle(c, RALLY_RADIUS + 2.0, Color(0, 0, 0, 0.5))
	draw_circle(c, RALLY_RADIUS, col)
	draw_arc(c, RALLY_RADIUS, 0, TAU, 24, Color(1, 1, 1, 0.85), 2.0)
	UiDraw.rally_flag(self, c + Vector2(-3, 9), 0.9)
