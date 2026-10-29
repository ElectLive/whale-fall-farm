class_name PetWhale
extends Node2D
## A tiny whale companion that follows the farmer and pecks at nearby monsters.

const SHEET := preload("res://assets/generated/chars/pet_whale.png")

var game: Node
var sprite: Sprite2D
var level := 1
var xp := 0
var atk_cd := 1.2
var _t := 0.0


func setup(game_ref: Node) -> void:
	game = game_ref


func _ready() -> void:
	sprite = Sprite2D.new()
	sprite.texture = SHEET
	sprite.hframes = 2
	sprite.vframes = 1
	sprite.frame = 0
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.position = Vector2(0, -3)
	add_child(sprite)


func _process(delta: float) -> void:
	if game == null or game.player == null:
		return
	var target: Vector2 = game.player.position + Vector2(-18, 10)
	position = position.lerp(target, 1.0 - exp(-3.2 * delta))
	z_index = int(position.y) + 2
	_t += delta
	sprite.frame = int(_t * 3.0) % 2
	sprite.position.y = -3.0 + sin(_t * 3.0) * 1.2
	atk_cd -= delta
	if atk_cd <= 0.0:
		atk_cd = maxf(0.8, 1.8 - level * 0.1)
		try_attack()


func try_attack() -> bool:
	if game == null:
		return false
	var best: Enemy = null
	var best_d := 78.0
	for e in game.enemies:
		if not is_instance_valid(e) or e.dead:
			continue
		var d: float = global_position.distance_to(e.global_position)
		if d < best_d:
			best_d = d
			best = e
	if best == null:
		return false
	best.take_damage(level, best.global_position - global_position)
	game.burst(best.global_position, Color("#7ec8e3"), 4)
	var tw := create_tween()
	tw.tween_property(sprite, "position", Vector2(10, -6), 0.08)
	tw.tween_property(sprite, "position", Vector2(0, -3), 0.12)
	return true


func gain_xp(amount: int) -> void:
	xp += amount
	while xp >= 10:
		xp -= 10
		level += 1
		game.float_text("小鲸鱼升级 · Lv%d" % level, position + Vector2(0, -16), Color("#7ee3d4"), 9)
		game.burst(position, Color("#7ee3d4"), 10)
		if game.hud:
			game.hud.set_pet_level(level)
