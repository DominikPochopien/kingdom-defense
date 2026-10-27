class_name Effect
extends Node2D
## Bazowa klasa krótkotrwałych efektów (wybuchy, napisy, uderzenia ognia).
## Efekt kończy się, gdy ustawi done = true; GameWorld wtedy go usuwa.

var world: GameWorld
var done := false


func is_finished() -> bool:
	return done


func tick(_dt: float) -> void:
	pass


func _process(_delta: float) -> void:
	queue_redraw()
