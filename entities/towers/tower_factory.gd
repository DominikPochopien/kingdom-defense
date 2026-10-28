class_name TowerFactory
## Tworzy wieżę właściwej klasy dla typu z data/tower_data.gd.
## Nowy typ wieży: dodaj dane w TowerData, plik z wyglądem tutaj obok i wpis poniżej.

const SCRIPTS := {
	"archer": preload("res://entities/towers/archer_tower.gd"),
	"mage": preload("res://entities/towers/mage_tower.gd"),
	"barracks": preload("res://entities/towers/barracks_tower.gd"),
	"artillery": preload("res://entities/towers/artillery_tower.gd"),
	"knight_tower": preload("res://entities/towers/knight_tower.gd"),
	"ship": preload("res://entities/towers/ship_tower.gd"),
}


static func create(type: String) -> Tower:
	return SCRIPTS[type].new()
