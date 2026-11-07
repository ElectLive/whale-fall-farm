class_name DerpPet
extends Node2D
## 呆瓜：一只反应慢半拍的小跟班。白天挖东西，晚上用脑袋顶怪。

const SHEET := preload("res://assets/generated/chars/derp.png")

var game: Node
var sprite: Sprite2D
var _t := 0.0
var dig_cd := 5.0
var bonk_cd := 3.0


func setup(game_ref: Node) -> void:
	game = game_ref


func _ready() -> void:
	sprite = Sprite2D.new()
	sprite.texture = SHEET
	sprite.hframes = 2
	sprite.vframes = 1
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.position = Vector2(0, -3)
	add_child(sprite)


func _process(delta: float) -> void:
	if game == null or game.player == null:
		return
	var target: Vector2 = game.player.position + Vector2(20, 14)
	position = position.lerp(target, 1.0 - exp(-2.1 * delta))
	z_index = int(position.y) + 2
	_t += delta
	sprite.frame = int(_t * 2.2) % 2
	sprite.position.y = -3.0 + sin(_t * 2.4) * 1.5
	if game.is_day_phase():
		dig_cd -= delta
		if dig_cd <= 0.0:
			dig_cd = 6.0
			game.derp_dig(self)
	elif game.is_night_phase():
		bonk_cd -= delta
		if bonk_cd <= 0.0:
			bonk_cd = 4.5
			game.derp_bonk(self)
