class_name Island
extends Node2D
## Floating whale-back island: sand ring, wooden fence and beach props.

const SAND := preload("res://assets/generated/tiles/sand.png")
const FENCE_H := preload("res://assets/generated/tiles/fence_h.png")
const FENCE_V := preload("res://assets/generated/tiles/fence_v.png")
const STONE := preload("res://assets/generated/tiles/stone.png")
const FLOWER := preload("res://assets/generated/tiles/flower.png")
const TUFT := preload("res://assets/generated/tiles/tuft.png")

const LEFT := -16
const TOP := -16
const RIGHT := 256
const BOTTOM := 144


func _ready() -> void:
	z_index = -50
	queue_redraw()


func _draw() -> void:
	# drop shadow in the water
	draw_rect(Rect2(LEFT + 3, TOP + 8, RIGHT - LEFT, BOTTOM - TOP), Color(0.02, 0.05, 0.09, 0.55))
	# sand plate with rounded corners
	var sand := Color("#c6b07a")
	draw_rect(Rect2(LEFT + 4, TOP + 4, RIGHT - LEFT - 8, BOTTOM - TOP - 8), sand)
	for c in [Vector2(LEFT + 10, TOP + 10), Vector2(RIGHT - 10, TOP + 10), Vector2(LEFT + 10, BOTTOM - 10), Vector2(RIGHT - 10, BOTTOM - 10)]:
		draw_circle(c, 6.0, sand)
	# sand texture speckles
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	for i in range(420):
		var p := Vector2(rng.randf_range(LEFT + 5, RIGHT - 5), rng.randf_range(TOP + 5, BOTTOM - 5))
		var edge := minf(minf(p.x - LEFT, RIGHT - p.x), minf(p.y - TOP, BOTTOM - p.y))
		if edge < 8.0:
			continue
		var col := Color(0.72, 0.63, 0.44, 0.5) if i % 2 == 0 else Color(0.86, 0.79, 0.6, 0.45)
		draw_rect(Rect2(p, Vector2(1.5, 1.5)), col)
	# wet rim
	draw_rect(Rect2(LEFT, BOTTOM - 3, RIGHT - LEFT, 3), Color(0.35, 0.45, 0.5, 0.25))
	draw_rect(Rect2(LEFT, TOP, RIGHT - LEFT, 2), Color(1, 0.96, 0.82, 0.16))
	# fences: top and bottom
	var x := LEFT
	while x < RIGHT:
		draw_texture(FENCE_H, Vector2(x, TOP))
		draw_texture(FENCE_H, Vector2(x, BOTTOM - 16))
		x += 16
	var y := TOP
	while y < BOTTOM:
		draw_texture(FENCE_V, Vector2(LEFT, y))
		draw_texture(FENCE_V, Vector2(RIGHT - 16, y))
		y += 16
	# corner posts
	for c in [Vector2(LEFT, TOP), Vector2(RIGHT - 16, TOP), Vector2(LEFT, BOTTOM - 16), Vector2(RIGHT - 16, BOTTOM - 16)]:
		draw_rect(Rect2(c + Vector2(6, 0), Vector2(4, 16)), Color("#8b5e3a"))
		draw_rect(Rect2(c + Vector2(6, 0), Vector2(2, 16)), Color("#b07a4a"))
		draw_rect(Rect2(c + Vector2(4, 1), Vector2(8, 3)), Color("#5c3a22"))
	# beach props on the sand ring
	draw_texture(STONE, Vector2(LEFT + 2, 56))
	draw_texture(FLOWER, Vector2(LEFT + 2, 104))
	draw_texture(TUFT, Vector2(RIGHT - 14, 40))
	draw_texture(STONE, Vector2(RIGHT - 14, 100))
	draw_texture(TUFT, Vector2(40, BOTTOM - 14))
	draw_texture(FLOWER, Vector2(190, BOTTOM - 14))
	draw_texture(TUFT, Vector2(210, TOP + 2))
	draw_texture(FLOWER, Vector2(70, TOP + 2))
	# small wooden sign near the farmhouse corner
	draw_rect(Rect2(LEFT + 6, 20, 2, 12), Color("#5c3a22"))
	draw_rect(Rect2(LEFT + 2, 18, 10, 7), Color("#8b5e3a"))
	draw_rect(Rect2(LEFT + 3, 19, 8, 2), Color("#b07a4a"))
