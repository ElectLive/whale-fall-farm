class_name Farm
extends Node2D
## The farm grid. Owns tile state and paints the ground layer.

const W := GameData.FARM_W
const H := GameData.FARM_H
const T := GameData.TILE

const GRASS := [
	preload("res://assets/generated/tiles/grass_0.png"),
	preload("res://assets/generated/tiles/grass_1.png"),
	preload("res://assets/generated/tiles/grass_2.png"),
	preload("res://assets/generated/tiles/grass_3.png"),
]
const SOIL := preload("res://assets/generated/tiles/soil.png")
const SOIL_WET := preload("res://assets/generated/tiles/soil_wet.png")
const TUFT := preload("res://assets/generated/tiles/tuft.png")
const FLOWER := preload("res://assets/generated/tiles/flower.png")
const STONE := preload("res://assets/generated/tiles/stone.png")

var tiles: Array[Dictionary] = []
var decos: Array[Dictionary] = []
var map_seed := 0


func _ready() -> void:
	z_index = -20


func setup(seed_value: int) -> void:
	map_seed = seed_value
	tiles.clear()
	decos.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for i in range(W * H):
		tiles.append({"tilled": false, "wet": false})
	for y in range(H):
		for x in range(W):
			var r := rng.randf()
			if r < 0.065:
				var kind := "tuft"
				if r < 0.014:
					kind = "flower"
				elif r < 0.026:
					kind = "stone"
				var off := Vector2(rng.randf_range(0, 6), rng.randf_range(0, 6))
				decos.append({"kind": kind, "pos": Vector2(x * T + off.x, y * T + off.y), "tile": Vector2i(x, y)})
	queue_redraw()


func in_bounds(t: Vector2i) -> bool:
	return t.x >= 0 and t.y >= 0 and t.x < W and t.y < H


func idx(t: Vector2i) -> int:
	return t.y * W + t.x


func tile_center(t: Vector2i) -> Vector2:
	return Vector2(t.x * T + T * 0.5, t.y * T + T * 0.5)


func world_to_tile(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x / T), floori(p.y / T))


func is_tilled(t: Vector2i) -> bool:
	return in_bounds(t) and tiles[idx(t)]["tilled"]


func till(t: Vector2i) -> void:
	if not in_bounds(t):
		return
	tiles[idx(t)]["tilled"] = true
	tiles[idx(t)]["wet"] = false
	queue_redraw()


func set_wet(t: Vector2i, value: bool) -> void:
	if not in_bounds(t):
		return
	tiles[idx(t)]["wet"] = value
	queue_redraw()


func clear(t: Vector2i) -> void:
	if not in_bounds(t):
		return
	tiles[idx(t)]["tilled"] = false
	tiles[idx(t)]["wet"] = false
	queue_redraw()


func _draw() -> void:
	for y in range(H):
		for x in range(W):
			var t := Vector2i(x, y)
			var d := tiles[idx(t)]
			var variant := (x * 7 + y * 13 + map_seed) % 4
			draw_texture(GRASS[variant], Vector2(x * T, y * T))
			if d["tilled"]:
				draw_texture(SOIL_WET if d["wet"] else SOIL, Vector2(x * T, y * T))
	for deco in decos:
		if tiles[idx(deco["tile"])]["tilled"]:
			continue
		var tex: Texture2D = TUFT
		if deco["kind"] == "flower":
			tex = FLOWER
		elif deco["kind"] == "stone":
			tex = STONE
		draw_texture(tex, deco["pos"])
