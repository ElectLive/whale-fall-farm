class_name ClickMarker
extends Node2D
## Short-lived ring shown where the player clicked to move or work.

var color := Color.WHITE
var _t := 0.0


func setup(pos: Vector2, c: Color) -> void:
	position = pos
	color = c
	z_index = 1500


func _process(delta: float) -> void:
	_t += delta
	scale = Vector2.ONE * (1.0 + _t * 1.4)
	modulate.a = clampf(1.0 - _t / 0.45, 0.0, 1.0)
	if _t >= 0.45:
		queue_free()


func _draw() -> void:
	draw_arc(Vector2.ZERO, 6.0, 0.0, TAU, 20, Color(color.r, color.g, color.b, 0.9), 1.2)
	draw_circle(Vector2.ZERO, 1.2, Color(color.r, color.g, color.b, 0.9))
