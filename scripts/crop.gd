class_name Crop
extends Node2D
## A planted crop. Growth only advances while watered; one watering per stage
## would be busywork, so a single watering carries it to maturity.

const TEX := {
	"radish": [
		preload("res://assets/generated/crops/radish_0.png"),
		preload("res://assets/generated/crops/radish_1.png"),
		preload("res://assets/generated/crops/radish_2.png"),
		preload("res://assets/generated/crops/radish_3.png"),
	],
	"pumpkin": [
		preload("res://assets/generated/crops/pumpkin_0.png"),
		preload("res://assets/generated/crops/pumpkin_1.png"),
		preload("res://assets/generated/crops/pumpkin_2.png"),
		preload("res://assets/generated/crops/pumpkin_3.png"),
	],
	"star": [
		preload("res://assets/generated/crops/star_0.png"),
		preload("res://assets/generated/crops/star_1.png"),
		preload("res://assets/generated/crops/star_2.png"),
		preload("res://assets/generated/crops/star_3.png"),
	],
	"moonwheat": [
		preload("res://assets/generated/crops/moonwheat_0.png"),
		preload("res://assets/generated/crops/moonwheat_1.png"),
		preload("res://assets/generated/crops/moonwheat_2.png"),
		preload("res://assets/generated/crops/moonwheat_3.png"),
	],
	"chili": [
		preload("res://assets/generated/crops/chili_0.png"),
		preload("res://assets/generated/crops/chili_1.png"),
		preload("res://assets/generated/crops/chili_2.png"),
		preload("res://assets/generated/crops/chili_3.png"),
	],
}
const GLOW := preload("res://assets/generated/fx/glow.png")

var kind := "radish"
var cell := Vector2i.ZERO
var growth := 0.0
var grow_time := 7.0
var watered := false
var mature := false
var stage := 0
var value := 0
var seed_drop := 0.0
var night_only := false
var golden := false
var farm: Farm
var game: Node
var sprite: Sprite2D
var glow: Sprite2D
var _pulse := 0.0


func setup(crop_kind: String, at: Vector2i, farm_ref: Farm, game_ref: Node) -> void:
	kind = crop_kind
	cell = at
	farm = farm_ref
	game = game_ref
	var info: Dictionary = GameData.CROPS[kind]
	grow_time = float(info["grow"])
	value = int(info["value"])
	seed_drop = float(info["seed_drop"])
	night_only = bool(info.get("night_only", false))
	position = farm.tile_center(cell)
	z_index = int(position.y)


func _ready() -> void:
	sprite = Sprite2D.new()
	sprite.texture = TEX[kind][stage]
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.position = Vector2(0, -2)
	add_child(sprite)
	glow = Sprite2D.new()
	glow.texture = GLOW
	glow.modulate = _glow_color(0.55 if mature else 0.0)
	glow.scale = Vector2(0.5, 0.5)
	glow.position = Vector2(0, -2)
	add_child(glow)
	queue_redraw()


func _glow_color(alpha: float) -> Color:
	if golden:
		return Color(1.0, 0.84, 0.32, alpha)
	return Color(1.0, 0.95, 0.6, alpha)


func make_golden() -> void:
	if golden:
		return
	golden = true
	value *= 3
	seed_drop = minf(1.0, seed_drop + 0.15)
	if sprite:
		sprite.modulate = Color(1.25, 1.08, 0.55)
	if glow:
		glow.modulate = _glow_color(0.55)


func water() -> void:
	if mature:
		return
	watered = true
	farm.set_wet(cell, true)
	queue_redraw()


func advance(seconds: float) -> void:
	## Fast-forward growth when the player skips the rest of the day (no banners).
	if mature or not watered:
		return
	if night_only and not bool(game.is_night_phase()):
		return
	growth = minf(grow_time, growth + seconds * float(game.growth_mult()))
	if growth >= grow_time:
		mature = true
		stage = 3
		sprite.texture = TEX[kind][stage]
		glow.modulate = _glow_color(0.65)
	else:
		stage = clampi(int(growth / grow_time * 3.0), 0, 2)
		sprite.texture = TEX[kind][stage]
	queue_redraw()


func _process(delta: float) -> void:
	if not watered or mature:
		return
	if night_only and not bool(game.is_night_phase()):
		queue_redraw()
		return
	growth += delta * float(game.growth_mult())
	if growth >= grow_time:
		growth = grow_time
		mature = true
		stage = 3
		sprite.texture = TEX[kind][stage]
		glow.modulate = _glow_color(0.65)
		_pop()
		game.on_crop_matured(self)
	else:
		var s := clampi(int(growth / grow_time * 3.0), 0, 2)
		if s != stage:
			stage = s
			sprite.texture = TEX[kind][stage]
			_pop()
	_pulse += delta
	glow.modulate = _glow_color(0.35 + 0.2 * sin(_pulse * 3.0))
	queue_redraw()


func _pop() -> void:
	if sprite == null:
		return
	sprite.scale = Vector2(1.2, 1.2)
	var pop := create_tween()
	pop.tween_property(sprite, "scale", Vector2.ONE, 0.2)


func harvest() -> int:
	game.on_crop_harvested(self)
	queue_free()
	return value


func eaten() -> void:
	game.on_crop_eaten(self)
	queue_free()


func _draw() -> void:
	if not mature:
		var w := 14.0
		var y := -13.0
		draw_rect(Rect2(-w * 0.5 - 1, y - 1, w + 2, 4), Color(0.05, 0.07, 0.11, 0.8))
		var ratio := clampf(growth / grow_time, 0.0, 1.0) if watered else 0.0
		var col := Color("#8fe0b0") if watered else Color("#607080")
		draw_rect(Rect2(-w * 0.5, y, w * ratio, 2), col)
		if not watered:
			# little blue droplet hint
			draw_rect(Rect2(-1, -18, 2, 3), Color("#7ec8e3"))
			draw_rect(Rect2(-2, -16, 4, 2), Color("#7ec8e3"))
