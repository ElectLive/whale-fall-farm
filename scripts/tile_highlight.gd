class_name TileHighlight
extends Node2D
## Soft outline drawn under the cursor when it points at a farm tile.

var color := Color(1, 1, 1, 0.8)


func set_color(c: Color) -> void:
	color = c
	queue_redraw()


func _draw() -> void:
	var rect := Rect2(-7.5, -7.5, 15.0, 15.0)
	draw_rect(rect, Color(color.r, color.g, color.b, 0.16), true)
	draw_rect(rect, Color(color.r, color.g, color.b, 0.85), false, 1.0)
	draw_line(Vector2(-3, 0), Vector2(3, 0), Color(color.r, color.g, color.b, 0.9), 1.0)
	draw_line(Vector2(0, -3), Vector2(0, 3), Color(color.r, color.g, color.b, 0.9), 1.0)
