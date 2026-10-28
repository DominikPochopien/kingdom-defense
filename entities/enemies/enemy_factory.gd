class_name EnemyFactory
## Tworzy wroga właściwej klasy dla typu z data/enemy_data.gd.
## Nowy typ wroga: dodaj dane w EnemyData i arkusze w assets/enemies/ (wielkość klatki w UnitSprites);
## jeśli ma własną umiejętność albo lata - plik z podklasą Enemy tutaj obok i wpis poniżej.

## typy z własną podklasą; pozostałe (goblin, wilk, ork, boss) to zwykły Enemy
const SCRIPTS := {
	"bat": preload("res://entities/enemies/bat.gd"),
	"shaman": preload("res://entities/enemies/shaman.gd"),
	"magic_knight": preload("res://entities/enemies/magic_knight.gd"),
	"dragon": preload("res://entities/enemies/dragon.gd"),
	"hedgehog": preload("res://entities/enemies/hedgehog.gd"),
}


static func create(type: String, hp_mult: float, route: int) -> Enemy:
	var enemy: Enemy = SCRIPTS[type].new() if SCRIPTS.has(type) else Enemy.new()
	enemy.setup(type, hp_mult, route)
	return enemy
