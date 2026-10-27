class_name EnemyFactory
## Tworzy wroga właściwej klasy dla typu z data/enemy_data.gd.
## Nowy typ wroga: dodaj dane w EnemyData, plik z wyglądem tutaj obok i wpis poniżej.

const SCRIPTS := {
	"goblin": preload("res://entities/enemies/goblin.gd"),
	"wolf": preload("res://entities/enemies/wolf.gd"),
	"orc": preload("res://entities/enemies/orc.gd"),
	"bat": preload("res://entities/enemies/bat.gd"),
	"shaman": preload("res://entities/enemies/shaman.gd"),
	"boss": preload("res://entities/enemies/boss.gd"),
}


static func create(type: String, hp_mult: float, route: int) -> Enemy:
	var enemy: Enemy = SCRIPTS[type].new()
	enemy.setup(type, hp_mult, route)
	return enemy
